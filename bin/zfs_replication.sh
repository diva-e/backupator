#!/bin/bash

CLIENT=$1
POOL=$2
REPLICATOR=$3
PORT=$4
DATASET=$5
REPLICATOR_POOL=$6

. /opt/backupator/etc/backupator.conf

LOGFILE="${LOGDIR}/zfs_replicator.log"

SNAP_LIST_OPTS="list -H -d1 -t snapshot -o name"
export HOME=/root # This is necessary for mbuffer

echo -e "\n$(date +'%d-%m-%Y %H:%M:%S') --- BEGIN REPLICATION ---" 2>&1 | tee -a ${LOGFILE}

if [ -z "${CLIENT}" ];then
    echo "$(date +'%d-%m-%Y %H:%M:%S') - No client name supplied" |tee -a ${LOGFILE}
    echo "$(date +'%d-%m-%Y %H:%M:%S') --- REPLICATION COMPLETED WITH ERROR ---" 2>&1 | tee -a ${LOGFILE}
    exit 1
fi

check_client_exists(){
    zfs list ${POOL}/${CLIENT}/${DATASET} >/dev/null 2>&1
}

check_remote_for_existing_backup(){
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${REPLICATOR} "${ZFS_CMD} list -o name |grep ${REPLICATOR_POOL}/${CLIENT}/${DATASET}$ -q" 2>/dev/null
}

get_remote_snapshots(){
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${REPLICATOR} "${ZFS_CMD} ${SNAP_LIST_OPTS} ${REPLICATOR_POOL}/${CLIENT}/${DATASET} |sort"
}

get_local_snapshots(){
    ${ZFS_CMD} ${SNAP_LIST_OPTS} ${POOL}/${CLIENT}/${DATASET} |sort |awk -F@ '{print $NF}'
}

get_last_local_snapshot(){
    ${ZFS_CMD} ${SNAP_LIST_OPTS} ${POOL}/${CLIENT}/${DATASET} |sort |tail -n 1 |awk -F@ '{print $NF}'
}

get_last_remote_snapshot(){
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${REPLICATOR} "${ZFS_CMD} ${SNAP_LIST_OPTS} ${REPLICATOR_POOL}/${CLIENT}/${DATASET} |sort |tail -n 1" |awk -F@ '{print $NF}'
}

cleanup_old_remote_snapshots(){
    LOCAL_SNAPSHOTS=$(get_local_snapshots)
    for snapshot in $(get_remote_snapshots); do
        snapshot_short=$(echo ${snapshot} |awk -F@ '{print $NF}')
        if ! $(echo "${LOCAL_SNAPSHOTS}" |grep ${snapshot_short} -q);then
            ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${REPLICATOR} "${ZFS_CMD} destroy ${snapshot}"
            EXIT_CODE="${PIPESTATUS[@]}"
            if [ "${EXIT_CODE}" == "0" ];then
                echo "$(date +'%d-%m-%Y %H:%M:%S') - Successfully removed ${snapshot} from the replicator ${REPLICATOR}." |tee -a ${LOGFILE}
            else
                echo "$(date +'%d-%m-%Y %H:%M:%S') - Error removing ${snapshot} from the replicator ${REPLICATOR}." |tee -a ${LOGFILE}
                ERROR=1
            fi
        fi
    done
}

start_replication(){
    cleanup_old_remote_snapshots
    if ! check_remote_for_existing_backup; then
        # Send initial backup to the remote server
        LAST_LOCAL_SNAPSHOT=$(get_last_local_snapshot)
        ${ZFS_CMD} send -e -c -R ${POOL}/${CLIENT}/${DATASET}@${LAST_LOCAL_SNAPSHOT} | /usr/bin/mbuffer -q -s 128k -m 100M -O ${REPLICATOR}:${PORT} 2>>${LOGFILE}
        EXIT_CODE=$(echo ${PIPESTATUS[@]} | sed "s/0//g" |sed "s/ //g")
        if [ "${EXIT_CODE}" == "" ];then
            echo "$(date +'%d-%m-%Y %H:%M:%S') - Successfully sent initial backup of ${CLIENT}/${DATASET} to the replicator ${REPLICATOR}." |tee -a ${LOGFILE}
        else
            echo "$(date +'%d-%m-%Y %H:%M:%S') - Error sending the initial backup of ${CLIENT}/${DATASET} to the replicator ${REPLICATOR}." |tee -a ${LOGFILE}
            ERROR=1
        fi
    else
        # Send incremental backup
        LAST_LOCAL_SNAPSHOT=$(get_last_local_snapshot)
        LAST_REMOTE_SNAPSHOT=$(get_last_remote_snapshot)

        if [ "${LAST_REMOTE_SNAPSHOT}" == "" ];then
            LAST_REMOTE_SNAPSHOT="${POOL}/${CLIENT}/${DATASET}" # If for some reason we only have the initial dataset on the replicator, we send everithing.
            REPLICATION_START_POINT="${POOL}/${CLIENT}/${DATASET}"
        else
            REPLICATION_START_POINT=${POOL}/${CLIENT}/${DATASET}@${LAST_REMOTE_SNAPSHOT}
        fi

        if [ "${LAST_LOCAL_SNAPSHOT}" == "${LAST_REMOTE_SNAPSHOT}" ];then
            echo "$(date +'%d-%m-%Y %H:%M:%S') - Local and remote last snapshots are ${LAST_LOCAL_SNAPSHOT}, thus both are in sync and there is no need for replication." |tee -a ${LOGFILE}
            echo "$(date +'%d-%m-%Y %H:%M:%S') - Closing remotely open port ${PORT} by sending a non zfs packet" |tee -a ${LOGFILE}
            echo "non zfs packet"| /usr/bin/mbuffer -q -s 128k -m 100M -O ${REPLICATOR}:${PORT}
        else
            ${ZFS_CMD} send -e -c -R -I ${REPLICATION_START_POINT} ${POOL}/${CLIENT}/${DATASET}@${LAST_LOCAL_SNAPSHOT} 2>&1 | /usr/bin/mbuffer -q -s 128k -m 100M -O ${REPLICATOR}:${PORT} 2>>${LOGFILE}
            EXIT_CODE=$(echo ${PIPESTATUS[@]} | sed "s/0//g" |sed "s/ //g")
            if [ "${EXIT_CODE}" == "" ];then
                echo "$(date +'%d-%m-%Y %H:%M:%S') - Successfully sent the snapshots from ${LAST_REMOTE_SNAPSHOT} to ${LAST_LOCAL_SNAPSHOT} to the replicator ${REPLICATOR}." |tee -a ${LOGFILE}
            else
                echo "$(date +'%d-%m-%Y %H:%M:%S') - Error sending snapshots from ${LAST_REMOTE_SNAPSHOT} to ${LAST_LOCAL_SNAPSHOT} to the replicator ${REPLICATOR}." |tee -a ${LOGFILE}
                ERROR=1
            fi
        fi
    fi
}

if $(check_client_exists);then
    start_replication
else
    echo "$(date +'%d-%m-%Y %H:%M:%S') - Client ${CLIENT} not found." |tee -a ${LOGFILE}
    ERROR=1
fi

if [ "${ERROR}" == "1" ]; then
    echo "$(date +'%d-%m-%Y %H:%M:%S') --- REPLICATION COMPLETED WITH ERRORS ---" 2>&1 | tee -a ${LOGFILE}
else
    echo "$(date +'%d-%m-%Y %H:%M:%S') --- REPLICATION COMPLETED SUCCESSFULLY ---" 2>&1 | tee -a ${LOGFILE}
fi
