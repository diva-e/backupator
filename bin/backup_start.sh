#!/bin/bash

DSTHOST=$1
STORAGE_POOL=$2
PORT=$3
DATASET=$4
DESTINATION=$5
CLIENT_HOSTNAME=$6
BKP_TYPE=$7
STORAGE_IP=$8

. /opt/backupator/etc/backupator.conf

LOGFILE="${LOGDIR}/backup_exec.log"
TIMESTAMP=$(date +%s)
export HOME=/root # This is necessary for mbuffer

echo -e "\n$(date +'%d-%m-%Y %H:%M:%S') --- BEGIN BACKUP FOR ${DSTHOST}:${DATASET} ---" 2>&1 | tee -a "${LOGFILE}"

check_remote_for_existing_backup(){
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${DSTHOST}" "${ZFS_CMD} list -o name -H -t snapshot -d1 ${DATASET}" |grep "${DATASET}@${SNAPSHOT_PREFIX}_" 2>/dev/null |head -n1
}

check_local_for_existing_backup(){
    ${ZFS_CMD} list -o name -H -t snapshot -d1 "${STORAGE_POOL}/${DSTHOST}/${DATASET}" 2>/dev/null
}

open_port(){
    if [ "${1}" == "initial" ]; then
        if [ "${DESTINATION}" == "dataset" ]; then
            (/usr/bin/mbuffer -q -s 16k -m 100M -I "${PORT}" |${ZFS_CMD} receive -o mountpoint=none -o compression=gzip-9 -F "${STORAGE_POOL}/${DSTHOST}/${DATASET}" >> "${LOGFILE}" 2>&1) &
        else
            (/usr/bin/mbuffer -q -s 16k -m 100M -I "${PORT}" |${ZFS_CMD} receive -o compression=gzip-9 -F "${STORAGE_POOL}/${DSTHOST}/${DATASET}" >> "${LOGFILE}" 2>&1) &
        fi
    else
        if [ "${DESTINATION}" == "dataset" ]; then
            (/usr/bin/mbuffer -q -s 16k -m 100M -I "${PORT}" |${ZFS_CMD} receive -o mountpoint=none -o compression=gzip-9 -F "${STORAGE_POOL}/${DSTHOST}/${DATASET}@${SNAPSHOT_PREFIX}_${TIMESTAMP}" >> "${LOGFILE}" 2>&1) &
        else
            (/usr/bin/mbuffer -q -s 16k -m 100M -I "${PORT}" |${ZFS_CMD} receive -o compression=gzip-9 -F "${STORAGE_POOL}/${DSTHOST}/${DATASET}@${SNAPSHOT_PREFIX}_${TIMESTAMP}" >> "${LOGFILE}" 2>&1) &
        fi
    fi
}

check_connection_to_dsthost(){
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${DSTHOST}" echo -n >/dev/null 2>&1
}

if ! check_connection_to_dsthost ;then
    echo "$(date +'%d-%m-%Y %H:%M:%S') - Unable to connect to the destination host ${DSTHOST}." |tee -a "${LOGFILE}"
    ERROR=1
else
    EXISTING_REMOTE=$(check_remote_for_existing_backup)
    EXISTING_LOCAL=$(check_local_for_existing_backup)
    ${ZFS_CMD} create -p "${STORAGE_POOL}/${DSTHOST}/${DATASET}"
    if [ "${DESTINATION}" == "dataset" ]; then
        ${ZFS_CMD} set mountpoint=none "${STORAGE_POOL}/${DSTHOST}"
    fi
    if [ "${BKP_TYPE}" == "mysql" ]; then
        echo "$(date +'%d-%m-%Y %H:%M:%S') - Binlog file and position" $(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${CLIENT_HOSTNAME} "mysql --defaults-file=/opt/backupator/etc/backup_verify_client.cnf -e \"SELECT binlog_file,binlog_pos FROM Local_Settings.Replication_Status WHERE server_sym NOT LIKE 'db-global-%' \" ") |tee -a ${LOGFILE}
    fi

    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${DSTHOST}" "${ZFS_CMD} snapshot ${DATASET}@${SNAPSHOT_PREFIX}_${TIMESTAMP}"

    # Setting quota to none for the dataset otherwise we get it full sometimes for datasets with lots of snapshots and many changes, also we don't need quota on the backup server.
    ${ZFS_CMD} set quota=none "${STORAGE_POOL}/${DSTHOST}/${DATASET}"

    if [ -z "${EXISTING_REMOTE}" ] || [ -z "${EXISTING_LOCAL}" ]; then
        open_port initial
        PORT_PID=$!
        # Initial backup
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${DSTHOST}" "${ZFS_CMD} send -e -c -R ${DATASET}@${SNAPSHOT_PREFIX}_${TIMESTAMP} | /usr/bin/mbuffer -q -s 16k -m 100M -O ${STORAGE_IP}:${PORT}" 2>&1 |tee -a "${LOGFILE}"
        EXIT_CODE=${PIPESTATUS[@]}
        EXIT_CODE=$(echo "${EXIT_CODE}" | sed "s/0//g" |sed "s/ //g")
        if [ "${EXIT_CODE}" == "" ];then
            echo "$(date +'%d-%m-%Y %H:%M:%S') - Successfully took initial backup of ${DSTHOST}:${DATASET}." |tee -a "${LOGFILE}"
        else
            echo "$(date +'%d-%m-%Y %H:%M:%S') - Error taking the initial backup of ${DSTHOST}:${DATASET}." |tee -a "${LOGFILE}"
            ERROR=1
        fi
    else
        open_port
        PORT_PID=$!
        # Incremental backup without -R otherwise it will have only the snapshots of the destination host and we want to keep more snaps.
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${DSTHOST}" "${ZFS_CMD} send -e -c -i ${EXISTING_REMOTE} ${DATASET}@${SNAPSHOT_PREFIX}_${TIMESTAMP} | /usr/bin/mbuffer -q -s 16k -m 100M -O ${STORAGE_IP}:${PORT}" |tee -a "${LOGFILE}"
        EXIT_CODE=${PIPESTATUS[@]}
        EXIT_CODE=$(echo "${EXIT_CODE}" | sed "s/0//g" |sed "s/ //g")
        echo -e "$(date +'%d-%m-%Y %H:%M:%S') - Mbuffer transfer completed." |tee -a "${LOGFILE}"
        if [ "${EXIT_CODE}" == "" ];then
        SNAPSHOT_PRESENT=false
            for retry in {1..100}; do # Check if the snapshot is present
                if ${ZFS_CMD} list -t snapshot -d1 "${STORAGE_POOL}/${DSTHOST}/${DATASET}@${SNAPSHOT_PREFIX}_${TIMESTAMP}" >/dev/null 2>&1; then
                    SNAPSHOT_PRESENT=true
                    echo -e "$(date +'%d-%m-%Y %H:%M:%S') - Successfully found the snapshot on the ${retry} check try." |tee -a "${LOGFILE}"
                    break
                fi
                sleep 3
            done

            if ${SNAPSHOT_PRESENT}; then
                echo -e "$(date +'%d-%m-%Y %H:%M:%S') - Successfully took incremental backup of ${DSTHOST}:${DATASET}." |tee -a "${LOGFILE}"
            else
                echo -e "$(date +'%d-%m-%Y %H:%M:%S') - Exit code for zfs send is success, but the latest snapshot ${STORAGE_POOL}/${DSTHOST}/${DATASET}@${SNAPSHOT_PREFIX}_${TIMESTAMP} is not present, check the zfs receive output (it should be around this line)." |tee -a "${LOGFILE}"
                ERROR=1
            fi

        else
            echo -e "$(date +'%d-%m-%Y %H:%M:%S') - Error taking the incremental backup of ${DSTHOST}." |tee -a "${LOGFILE}"
            ERROR=1
        fi

        PIDREMAINS=$(ps x |grep -v grep | grep "/usr/bin/mbuffer -q -s 16k -m 100M -I ${PORT}"|awk '{print $1}')
        if [ -n "${PIDREMAINS}" ]; then
            ps x |grep -v grep | grep mbuffer |tee -a "${LOGFILE}"
            kill "${PIDREMAINS}"
            echo -e "$(date +'%d-%m-%Y %H:%M:%S') - Killed the PID ${PIDREMAINS} for ${DSTHOST}" |tee -a "${LOGFILE}"
        fi

        if [ "${ERROR}" == "1" ];then
            echo -e "$(date +'%d-%m-%Y %H:%M:%S') - Backup unsuccessful, skipping the destroy old snapshots step." |tee -a "${LOGFILE}"
        else
            echo -e "$(date +'%d-%m-%Y %H:%M:%S') - Destroying old snapshots on the destination host." |tee -a "${LOGFILE}"
            OLD_SNAPSHOTS=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${DSTHOST}" "${ZFS_CMD} list -o name -H -t snapshot -d1 ${DATASET} |grep -v ${DATASET}@${SNAPSHOT_PREFIX}_${TIMESTAMP} |grep ${DATASET}@${SNAPSHOT_PREFIX}_")
            for OLD_SNAPSHOT in ${OLD_SNAPSHOTS}; do
                OLD_SNAPSTAMP=$(echo "${OLD_SNAPSHOT}" |awk -F@ '{print $NF}')
                ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${DSTHOST}" "${ZFS_CMD} destroy ${OLD_SNAPSHOT} 2>&1" 2>&1 && echo "$(date +'%d-%m-%Y %H:%M:%S') - Destroyed ${OLD_SNAPSHOT}"
            done | tee -a "${LOGFILE}"
            EXIT_CODE=$(echo "${PIPESTATUS[@]}" | sed "s/0//g" |sed "s/ //g")
            if [ "${EXIT_CODE}" == "" ];then
                echo "$(date +'%d-%m-%Y %H:%M:%S') - Successfully destroyed the previous snapshot(s) ${OLD_SNAPSHOTS} on ${DSTHOST}." |tee -a "${LOGFILE}"
            else
                echo "$(date +'%d-%m-%Y %H:%M:%S') - Error destroying the previous snapshot(s) ${OLD_SNAPSHOTS} on ${DSTHOST}." |tee -a "${LOGFILE}"
                ERROR=1
            fi
        fi
    fi
fi


if [ "${ERROR}" == "1" ]; then
    echo "$(date +'%d-%m-%Y %H:%M:%S') --- BACKUP SCRIPT COMPLETED WITH ERRORS ---" 2>&1 | tee -a ${LOGFILE}
else
    echo "$(date +'%d-%m-%Y %H:%M:%S') --- BACKUP COMPLETED SUCCESSFULLY ---" 2>&1 | tee -a ${LOGFILE}
fi

echo -e "$(date +'%d-%m-%Y %H:%M:%S') --- END BACKUP FOR ${DSTHOST}:${DATASET} ---" 2>&1 | tee -a ${LOGFILE}
