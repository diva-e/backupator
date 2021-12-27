#!/bin/bash

. /opt/backupator/etc/backupator.conf

MY_CREDENTIALS="${CONFIGDIR}/backupator_mysql.cnf"
ZFS_REPLICATION_SCRIPT="${BINDIR}/zfs_replication.sh"
BACKUP_SCRIPT="${BINDIR}/backup_start.sh"
LOGFILE="${LOGDIR}/backup_agent.log"

MYSQL_COMMAND="mysql --defaults-extra-file=${MY_CREDENTIALS} ${DBNAME}"

# Ensure the log directory is present
mkdir -p "${LOGDIR}"

# Check the queue
insert_in_queue(){
    QUEUE=$(${MYSQL_COMMAND} -e "SELECT id,hostname FROM queue WHERE storage_node='${STORAGE_NODE_ID}' and ended=0 LIMIT 1")
    if [ -z "${QUEUE}" ]; then
        ${MYSQL_COMMAND} -e "SELECT hostname,dataset,backup_interval FROM clients WHERE storage='${STORAGE_NODE_ID}' and active='1' ORDER BY lastrun ASC" | while read -r clientname dataset backup_interval; do
            id=$($MYSQL_COMMAND -e "SELECT id FROM clients WHERE hostname='${clientname}' and dataset='${dataset}' and lastrun<SYSDATE() - interval ${backup_interval} minute and active='1' ORDER BY lastrun ASC LIMIT 1")
            if [ -n "${id}" ]; then
                ${MYSQL_COMMAND} -e "UPDATE storage_nodes set lastschedule=SYSDATE() WHERE hostname='${STORAGE_NODE_ID}'"
                ${MYSQL_COMMAND} -e "INSERT INTO queue (type,hostname,dataset,storage_node,scheduled,status) VALUES ('backup', '${clientname}', '${dataset}', '${STORAGE_NODE_ID}', SYSDATE(), 'Scheduled')"
                ${MYSQL_COMMAND} -e "UPDATE clients SET lastrun=SYSDATE() WHERE id='${id}'"
                QUEUE_ID=$(${MYSQL_COMMAND} -e "SELECT id FROM queue WHERE type='backup' and dataset='${dataset}' and storage_node='${STORAGE_NODE_ID}' and started=0 ")
                echo "${QUEUE_ID} ${clientname} ${dataset}"
                break
            fi
        done
    fi
}

check_queue_for_new(){
    ${MYSQL_COMMAND} -e "SELECT id,hostname,dataset FROM queue WHERE type='backup' and storage_node='${STORAGE_NODE_ID}' and started=0 and ended=0 LIMIT 1"
}

check_for_stale_job(){
    ${MYSQL_COMMAND} -e "SELECT id FROM queue WHERE type='backup' and storage_node='${STORAGE_NODE_ID}' and ended=0 LIMIT 1"
}

mark_stale_failed(){
    ${MYSQL_COMMAND} -e "UPDATE queue SET ended=SYSDATE(), status='Failed', comment='Stale job' WHERE id='${1}'"
}

check_replicator_queue(){
    REPLICATOR=$1
    ${MYSQL_COMMAND} -e "SELECT count(*) FROM queue WHERE storage_node='${REPLICATOR}' and ended=0"
}

check_fs(){
    QUEUE_HOSTNAME=$1
    QUEUE_DATASET=$2
    ${MYSQL_COMMAND} -e "SELECT fstype FROM clients WHERE hostname='${QUEUE_HOSTNAME}' and dataset='${QUEUE_DATASET}'"
}

last_backup_name(){
    QUEUE_HOSTNAME=$1
    BKP_CLIENTDATASET=$2
    POOL=$(get_storage_pool)
    ${ZFS_CMD} list -H -o name -S name -t snapshot -d1 "${POOL}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET}" |head -n1 |awk -F'@' '{print $NF}'
}

get_storage_pool(){
    ${MYSQL_COMMAND} -e "SELECT pool FROM storage_nodes WHERE hostname='${STORAGE_NODE_ID}'"
}

get_storage_ip(){
    ${MYSQL_COMMAND} -e "SELECT ip FROM storage_nodes WHERE hostname='${STORAGE_NODE_ID}'"
}

get_replicator_pool(){
    REPLICATOR=$1
    ${MYSQL_COMMAND} -e "SELECT pool FROM storage_nodes WHERE hostname='${REPLICATOR}'"
}

get_storage_path(){
    ${MYSQL_COMMAND} -e "SELECT storage_path FROM storage_nodes WHERE hostname='${STORAGE_NODE_ID}'"
}

start_backup(){
    QUEUE_HOSTNAME=$1
    FS_TYPE=$2
    BKP_CLIENTDATASET=$3
    BKP_CLIENTNAME=$4
    BKP_TYPE=$5
    if [ "${FS_TYPE}" == "ext4" ]; then
        STORAGE_POOL=$(get_storage_pool)
        STORAGE_PATH=$(get_storage_path)
        echo "$(date +'%d-%m-%Y %H:%M:%S') - BACKUP for ${QUEUE_HOSTNAME} STARTED" |tee -a "${LOGFILE}"
        if ! zfs list "${STORAGE_POOL}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET}" >/dev/null 2>&1; then
            echo "$(date +'%d-%m-%Y %H:%M:%S') - Dataset not present, assuming first backup and creating a new dataset." |tee -a "${LOGFILE}"
            ${ZFS_CMD} create -p "${STORAGE_POOL}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET}" |tee -a "${LOGFILE}"
        fi
        ${ZFS_CMD} set canmount=noauto "${STORAGE_POOL}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET}"
        ${ZFS_CMD} set overlay=on "${STORAGE_POOL}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET}" 2>&1 |tee -a "${LOGFILE}" # We need this to allow mounting on non empty directories
        ${ZFS_CMD} set mountpoint="${STORAGE_PATH}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET}" "${STORAGE_POOL}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET}" 2>&1 |tee -a "${LOGFILE}"
        ${ZFS_CMD} mount "${STORAGE_POOL}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET}" 2>&1 |tee -a "${LOGFILE}"
        rsync --delete -aHP -e "ssh -c aes128-ctr" ${QUEUE_HOSTNAME}:/${BKP_CLIENTDATASET} ${STORAGE_PATH}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET} >/var/log/backupator/rsync.log 2>&1
        BCK_STATUS=$?
        if [ "${BCK_STATUS}" -eq "0" ]; then
            echo "$(date +'%d-%m-%Y %H:%M:%S') - BACKUP COMPLETED SUCCESSFULLY" |tee -a "${LOGFILE}"
        else
            if $(grep -q "some files vanished before they could be transferred" /var/log/backupator/rsync.log); then
                echo "$(date +'%d-%m-%Y %H:%M:%S') - BACKUP COMPLETED SUCCESSFULLY" |tee -a "${LOGFILE}"
            else
                echo "$(date +'%d-%m-%Y %H:%M:%S') - BACKUP COMPLETED WITH ERRORS" |tee -a "${LOGFILE}"
            fi
        fi
        ${ZFS_CMD} umount "${STORAGE_POOL}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET}" 2>&1 |tee -a "${LOGFILE}"
        ${ZFS_CMD} snapshot "${STORAGE_POOL}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET}@${SNAPSHOT_PREFIX}_$(date +%s)"
    else
        STORAGE_POOL=$(get_storage_pool)
        STORAGE_IP=$(get_storage_ip)
        CLIENT_ID=$(get_client_id "${QUEUE_HOSTNAME}" "${QUEUE_DATASET}")
        PORT=$((35000 + CLIENT_ID))
        DESTINATION=$(get_destination "${QUEUE_HOSTNAME}" "${QUEUE_DATASET}")
        ${BACKUP_SCRIPT} "${QUEUE_HOSTNAME}" "${STORAGE_POOL}" "${PORT}" "${BKP_CLIENTDATASET}" "${DESTINATION}" "${BKP_CLIENTNAME}" "${BKP_TYPE}" "${STORAGE_IP}"
    fi
}

check_failed_backups(){
    QUEUE_HOSTNAME=$1
    QUEUE_DATASET=$2
    BACKUP_INTERVAL=$(${MYSQL_COMMAND} -e "SELECT backup_interval FROM clients WHERE hostname='${QUEUE_HOSTNAME}' and dataset='${QUEUE_DATASET}'")
    ${MYSQL_COMMAND} -e "SELECT count(*) FROM queue WHERE type='backup' and hostname='${QUEUE_HOSTNAME}' and dataset='${QUEUE_DATASET}' and status='Failed' and ended > SYSDATE() - interval ${BACKUP_INTERVAL} minute"
}

# Update the database with the status start/stop
update_db(){
    if [ "$1" == "start" ];then
        QUEUE_ID=$2
        QUEUE_HOSTNAME=$3
        QUEUE_DATASET=$4
        # Tell MySQL that we are starting the backup
        ${MYSQL_COMMAND} -e "UPDATE queue SET started=SYSDATE(), status='Started' WHERE id='${QUEUE_ID}'"
        # Update the client last run
        ${MYSQL_COMMAND} -e "UPDATE clients SET lastrun=SYSDATE() WHERE hostname='${QUEUE_HOSTNAME}' and dataset='${QUEUE_DATASET}'"
    fi

    if [ "$1" == "end" ];then
        QUEUE_ID=$2
        QUEUE_HOSTNAME=$3
        QUEUE_DATASET=$4
        BKP_TYPE=$(echo "${QUEUE_DATASET}" |awk -F: '{print $1}')
        BKP_CLIENTDATASET=$(echo "${QUEUE_DATASET}" |awk -F: '{print $3}')
        BACKUP_LOG=$(echo "$5" |sed 's/"/^/g'|sed "s/'/^/g")
        STATUS=$6
        LASTBACKUP=$(last_backup_name "${QUEUE_HOSTNAME}" "${BKP_CLIENTDATASET}")

        echo "$(date +'%d-%m-%Y %H:%M:%S') - Status is: ${STATUS}." |tee -a "${LOGFILE}"

        if ! [ "${STATUS}" == "Success" ];then
            if [ "$(check_failed_backups ${QUEUE_HOSTNAME} ${QUEUE_DATASET})" -lt "3" ];then
                echo "$(date +'%d-%m-%Y %H:%M:%S') - Backup failed, attempting another one." |tee -a "${LOGFILE}"
                # Schedule another backup if this one failed
                ${MYSQL_COMMAND} -e "UPDATE clients SET lastrun=0 WHERE hostname='${QUEUE_HOSTNAME}' and dataset='${QUEUE_DATASET}'"
            else
                BACKUP_INTERVAL=$(${MYSQL_COMMAND} -e "SELECT backup_interval FROM clients WHERE hostname='${QUEUE_HOSTNAME}' and dataset='${QUEUE_DATASET}'")
                echo "$(date +'%d-%m-%Y %H:%M:%S') - Backup for ${QUEUE_HOSTNAME} failed 3 or more times in the last ${BACKUP_INTERVAL} minutes, moving on to the next cient." |tee -a "${LOGFILE}"
            fi
        fi

        REPLICATOR=$(get_replicator "${QUEUE_HOSTNAME}" "${QUEUE_DATASET}")
        if [ "$(check_replication_enabled)" == "1" ] && [ "$(check_replicator_queue ${REPLICATOR})" -eq "0" ] && [ -n "${REPLICATOR}" ];then
            VERIFY_HOST=${REPLICATOR}
        else
            VERIFY_HOST=${STORAGE_NODE_ID}
        fi
        if [ "${STATUS}" == "Success" ];then
            VERIFICATION_ENABLED=$(${MYSQL_COMMAND} -e "SELECT configvalue FROM config WHERE configkey='VERIFICATION_ENABLED'")
            if [ "${VERIFICATION_ENABLED}" -eq "1" ]; then
                if [ "${BKP_TYPE}" == "mysql" ] || [ "${BKP_TYPE}" == "clickhouse" ]; then
                    VERIFY=$(${MYSQL_COMMAND} -e "SELECT verify FROM clients WHERE hostname='${QUEUE_HOSTNAME}' and dataset='${QUEUE_DATASET}'")
                    if [ "${VERIFY}" -eq "1" ]; then
                        ${MYSQL_COMMAND} -e "INSERT INTO queue (type, hostname, dataset, storage_node, scheduled, status) VALUES ('verify', '${QUEUE_HOSTNAME}', '${QUEUE_DATASET}', '${VERIFY_HOST}', SYSDATE(), 'Scheduled')"
                    fi
                fi
            else
                echo "$(date +'%d-%m-%Y %H:%M:%S') - Verifications are disabled, thus not scheduling one." | tee -a "${LOGFILE}"
            fi
            ${MYSQL_COMMAND} -e "INSERT INTO backups (hostname, dataset, storage_node, backup_name, present, status, verify_queue_id) VALUES ('${QUEUE_HOSTNAME}', '${QUEUE_DATASET}', '${VERIFY_HOST}', '${LASTBACKUP}', '1', 'Success', '${QUEUE_ID}')"
            sleep 5
        fi
        # Tell MySQL that we are done with the backup, but only after some sleep, to prevent the queue manager from scheduling another job in the meantime
        ${MYSQL_COMMAND} -e "UPDATE queue SET ended=SYSDATE(), status='${STATUS}', comment='${BACKUP_LOG}' WHERE id='${QUEUE_ID}'" 2>&1 |tee -a "${LOGFILE}"
    fi
}

check_node_enabled(){
     ${MYSQL_COMMAND} -e "SELECT active FROM storage_nodes WHERE hostname='${STORAGE_NODE_ID}'"
}

check_replication_enabled(){
     ${MYSQL_COMMAND} -e "SELECT replication_enabled FROM storage_nodes WHERE hostname='${STORAGE_NODE_ID}'"
}

get_replicator(){
    QUEUE_HOSTNAME=$1
    QUEUE_DATASET=$2
    ${MYSQL_COMMAND} -e "SELECT replicator FROM clients WHERE hostname='${QUEUE_HOSTNAME}' and dataset='${QUEUE_DATASET}'"
}

get_client_id(){
    CLIENT=$1
    QUEUE_DATASET=$2
    ${MYSQL_COMMAND} -e "SELECT id FROM clients WHERE hostname='${CLIENT}' and dataset='${QUEUE_DATASET}'"
}

get_destination(){
    CLIENT=$1
    QUEUE_DATASET=$2
    ${MYSQL_COMMAND} -e "SELECT destination FROM clients WHERE hostname='${CLIENT}' and dataset='${QUEUE_DATASET}'"
}

port_open() {
    REPLICATOR=$1
    PORT=$2
    POOL=$3
    QUEUE_HOSTNAME=$4
    BKP_CLIENTDATASET=$5
    DESTINATION=$6
    curl -s "http://${REPLICATOR}:23456/?dataset=${BKP_CLIENTDATASET}&pool=${POOL}&client=${QUEUE_HOSTNAME}&port=${PORT}&destination=${DESTINATION}"
}

get_all_local_snapshots(){
    QUEUE_HOSTNAME=$1
    POOL=$2
    BKP_CLIENTDATASET=$3
    zfs list -H -o name -t snapshot -d1 "${POOL}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET}"
}

get_all_mysql_snapshots(){
    QUEUE_HOSTNAME=$1
    QUEUE_DATASET=$2
    ${MYSQL_COMMAND} -e "SELECT backup_name FROM backups WHERE hostname='${QUEUE_HOSTNAME}' and dataset='${QUEUE_DATASET}' and present='1'"
}

get_snapshot_retention(){
    QUEUE_HOSTNAME=$1
    QUEUE_DATASET=$2
    ${MYSQL_COMMAND} -e "SELECT snapshot_retention FROM clients WHERE hostname='${QUEUE_HOSTNAME}' and dataset='${QUEUE_DATASET}'"
}

invalidate_snapshot(){
    POOL=$1
    QUEUE_HOSTNAME=$2
    SNAPSHOT=$3
    QUEUE_DATASET=$4
    BKP_CLIENTDATASET=$(echo "${QUEUE_DATASET}" |awk -F: '{print $3}')
    zfs destroy "${POOL}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET}@${SNAPSHOT}"
    ${MYSQL_COMMAND} -e "UPDATE backups SET present='0' WHERE hostname='${QUEUE_HOSTNAME}' and dataset='${QUEUE_DATASET}' and backup_name='${SNAPSHOT}'"
}

start_replication(){
    CLIENT=${1}
    POOL=${2}
    REPLICATOR=${3}
    PORT=${4}
    DATASET=${5}
    REPLICATOR_POOL=${6}
    ${ZFS_REPLICATION_SCRIPT} "${CLIENT}" "${POOL}" "${REPLICATOR}" "${PORT}" "${DATASET}" "${REPLICATOR_POOL}"
}

scheduler(){
    # Checking if some client can be scheduled
    if [ "$(check_node_enabled)" == "1" ];then
        QUEUE=$(insert_in_queue)
    else
        QUEUE=""
    fi
    # If no client is due for schedule by this script check if we have something scheduled externally
    if [ -z "${QUEUE}" ];then
        QUEUE=$(check_queue_for_new)
    fi

    # Check if there is a backup job running in the DB. If yes end it, since a running job should not allow the script to be at this stage and should wait for it to finish.
    # This usually means that a backup job started but did not update its finish status correctly, either with fail or success.
    if [ -z "${QUEUE}" ];then
        STALE_ID=$(check_for_stale_job)
        if [ -n "${STALE_ID}" ]; then
            mark_stale_failed "${STALE_ID}"
        fi
    fi

    if [ -n "${QUEUE}" ]; then
        QUEUE_ID=$(echo "${QUEUE}" |awk '{print $1}')
        QUEUE_HOSTNAME=$(echo "${QUEUE}" |awk '{print $2}')
        QUEUE_DATASET=$(echo "${QUEUE}" |awk '{print $3}')
        FS=$(check_fs "${QUEUE_HOSTNAME}" "${QUEUE_DATASET}")
        BKP_TYPE=$(echo "${QUEUE_DATASET}" |awk -F: '{print $1}')
        BKP_CLIENTNAME=$(echo "${QUEUE_DATASET}" |awk -F: '{print $2}')
        BKP_CLIENTDATASET=$(echo "${QUEUE_DATASET}" |awk -F: '{print $3}')
        echo "$(date +'%d-%m-%Y %H:%M:%S') - A backup is scheduled in the queue with ID: ${QUEUE_ID} for ${QUEUE_HOSTNAME} / ${QUEUE_DATASET}." | tee -a "${LOGFILE}"
        update_db start "${QUEUE_ID}" "${QUEUE_HOSTNAME}" "${QUEUE_DATASET}"
        BACKUP_LOG=$(start_backup "${QUEUE_HOSTNAME}" "${FS}" "${BKP_CLIENTDATASET}" "${BKP_CLIENTNAME}" "${BKP_TYPE}")
        echo "$(date +'%d-%m-%Y %H:%M:%S') - Backup with queue ID: ${QUEUE_ID} is now completed." | tee -a "${LOGFILE}"
        if $(printf "${BACKUP_LOG}" |grep -q 'BACKUP COMPLETED SUCCESSFULLY');then
            STATUS="Success"
        else
            STATUS="Failed"
        fi

        if [ "${STATUS}" == "Success" ];then
            # If successful backup, rotate snapshots
            echo "$(date +'%d-%m-%Y %H:%M:%S') - Cleaning up old snapshots for ${QUEUE_HOSTNAME}." | tee -a "${LOGFILE}"
            POOL=$(get_storage_pool)
            # We get all snapshot names from the DB and the zfs
            ALL_LOCAL_SNAPSHOTS=$(get_all_local_snapshots "${QUEUE_HOSTNAME}" "${POOL}" "${BKP_CLIENTDATASET}" |sort |uniq)
            SNAPSHOT_RETENTION=$(($(get_snapshot_retention "${QUEUE_HOSTNAME}" "${QUEUE_DATASET}")*60*60*24))
            TIMESTAMP=$(date +%s)
            for SNAPSHOT in ${ALL_LOCAL_SNAPSHOTS}; do
                SNAPSHOT_CREATION=$(date -d "$(${ZFS_CMD} get creation -H -o value "${SNAPSHOT}")" +"%s")
                if [ "$((TIMESTAMP-SNAPSHOT_RETENTION))" -gt "${SNAPSHOT_CREATION}" ]; then
                    SNAPSHOT_NAME=$(echo "${SNAPSHOT}" |awk -F@ '{print $NF}')
                    echo "$(date +'%d-%m-%Y %H:%M:%S') - Invalidating old snapshot ${QUEUE_HOSTNAME} / ${QUEUE_DATASET} / ${SNAPSHOT_NAME}" | tee -a "${LOGFILE}"
                    invalidate_snapshot "${POOL}" "${QUEUE_HOSTNAME}" "${SNAPSHOT_NAME}" "${QUEUE_DATASET}"
                fi
            done
            ALL_MYSQL_SNAPSHOTS=$(get_all_mysql_snapshots "${QUEUE_HOSTNAME}" "${QUEUE_DATASET}")
            for SNAPSHOT_NAME in ${ALL_MYSQL_SNAPSHOTS}; do
                SNAPSHOT_CREATION=$(echo "${SNAPSHOT_NAME}" |awk -F_ '{print $NF}')
                if [ "$((TIMESTAMP-SNAPSHOT_RETENTION))" -gt "${SNAPSHOT_CREATION}" ]; then
                    if ! zfs list "${POOL}/${QUEUE_HOSTNAME}/${BKP_CLIENTDATASET}@${SNAPSHOT_NAME}" 2>/dev/null; then
                        echo "$(date +'%d-%m-%Y %H:%M:%S') - Invalidating MySQL snapshot ${QUEUE_HOSTNAME} / ${QUEUE_DATASET} / ${SNAPSHOT_NAME}" | tee -a "${LOGFILE}"
                        invalidate_snapshot "${POOL}" "${QUEUE_HOSTNAME}" "${SNAPSHOT_NAME}" "${QUEUE_DATASET}"
                    fi
                fi
            done
            # If successful backup and replication is enabled, replicate to the replicator
            if [ "$(check_replication_enabled)" == "1" ];then
                REPLICATOR=$(get_replicator "${QUEUE_HOSTNAME}" "${QUEUE_DATASET}")
                if [ -z "${REPLICATOR}" ]; then
                    echo "$(date +'%d-%m-%Y %H:%M:%S') - No replicator for ${QUEUE_HOSTNAME}, not replicating." | tee -a "${LOGFILE}"
                else
                    echo "$(date +'%d-%m-%Y %H:%M:%S') - Starting the ZFS replication script" | tee -a "${LOGFILE}"
                    echo "$(date +'%d-%m-%Y %H:%M:%S') - Initiating port opening on the replicator ${REPLICATOR}" | tee -a "${LOGFILE}"
                    CLIENT_ID=$(get_client_id "${QUEUE_HOSTNAME}" "${QUEUE_DATASET}")
                    DESTINATION=$(get_destination "${QUEUE_HOSTNAME}" "${QUEUE_DATASET}")
                    let PORT="25000 + ${CLIENT_ID}"
                    REPLICATOR_POOL=$(get_replicator_pool "${REPLICATOR}")
                    PORT_OPEN_RESULT=$(port_open "${REPLICATOR}" "${PORT}" "${REPLICATOR_POOL}" "${QUEUE_HOSTNAME}" "${BKP_CLIENTDATASET}" "${DESTINATION}")
                    echo "$(date +'%d-%m-%Y %H:%M:%S') - Port open result for port ${PORT} is ${PORT_OPEN_RESULT}" | tee -a "${LOGFILE}"
                    if [ "${PORT_OPEN_RESULT}" == "OK" ];then
                        echo "$(date +'%d-%m-%Y %H:%M:%S') - Starting replication" | tee -a "${LOGFILE}"
                        REPLICATION=$(start_replication "${QUEUE_HOSTNAME}" "${POOL}" "${REPLICATOR}" "${PORT}" "${BKP_CLIENTDATASET}" "${REPLICATOR_POOL}")
                        if echo "${REPLICATION}" | grep -q "REPLICATION COMPLETED SUCCESSFULLY"; then
                            STATUS=Success
                        else
                            STATUS=Failed
                        fi
                        BACKUP_LOG=$(printf "${BACKUP_LOG}\n${REPLICATION}")
                        echo "$(date +'%d-%m-%Y %H:%M:%S') - The replication script ${ZFS_REPLICATION_SCRIPT} scheduled with queue ID: ${QUEUE_ID} finished." | tee -a "${LOGFILE}"
                    else
                        echo "$(date +'%d-%m-%Y %H:%M:%S') - Could not open remote port for replication, reply was ${PORT_OPEN_RESULT}" | tee -a "${LOGFILE}"
                        STATUS=Failed
                        BACKUP_LOG=$(printf "${BACKUP_LOG}\nCould not open remote port for replication\nReply was: ${PORT_OPEN_RESULT}")
                    fi
                fi
            fi
        else
            echo "$(date +'%d-%m-%Y %H:%M:%S') - The backup failed, thus not replicating and not rotating snapshots." | tee -a "${LOGFILE}"
        fi
        echo "$(date +'%d-%m-%Y %H:%M:%S') - Updating the DB with the end status" | tee -a "${LOGFILE}"
        update_db end "${QUEUE_ID}" "${QUEUE_HOSTNAME}" "${QUEUE_DATASET}" "${BACKUP_LOG}" "${STATUS}"
    fi
}

# Init the loop
while true; do
    # Check if backup is scheduled and run
    scheduler

    sleep 10
done
