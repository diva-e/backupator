#!/bin/bash

. /opt/backupator/etc/backupator.conf

LOGFILE="${LOGDIR}/backup_verify.log"
VERIFY_CONFIG_FILE="${CONFIGDIR}/backup_verify_server.cnf"
MYSQL_VERIFY_LOG="/data/backup_verify.log"
MY_CREDENTIALS="${CONFIGDIR}/backupator_mysql.cnf"
MYSQL_COMMAND="mysql --defaults-extra-file=${MY_CREDENTIALS} ${DBNAME}"
MY_VERIFY_CREDENTIALS="${CONFIGDIR}/backup_verify_client.cnf"
MYSQL_VERIFY_COMMAND="mysql --defaults-extra-file=${MY_VERIFY_CREDENTIALS}"
CLICKHOUSE_VERIFY=/opt/backupator/bin/clickhouse_verify.sh

check_queue(){
    # First we check if there is a backup, already running
    BKP_HOSTNAME=$(${MYSQL_COMMAND} -e "SELECT hostname FROM queue WHERE storage_node='${STORAGE_NODE_ID}' and scheduled>0 and started>0 and ended=0")
    if [ -z "${BKP_HOSTNAME}" ]; then
        ${MYSQL_COMMAND} -e "SELECT id FROM queue WHERE type='verify' and storage_node='${STORAGE_NODE_ID}' and started=0 and ended=0 LIMIT 1"
    fi
}

get_client(){
    QUEUE_ID=$1
    ${MYSQL_COMMAND} -e "SELECT hostname FROM queue WHERE id='${QUEUE_ID}'"
}

get_queue_dataset(){
    QUEUE_ID=$1
    ${MYSQL_COMMAND} -e "SELECT dataset FROM queue WHERE id='${QUEUE_ID}'"
}

check_fs(){
    CLIENT=$1
    QUEUE_DATASET=$2
    ${MYSQL_COMMAND} -e "SELECT fstype FROM clients WHERE hostname='${CLIENT}' and dataset='${QUEUE_DATASET}'"
}

get_last_snapshot(){
    CLIENT=$1
    POOL=$2
    BKP_CLIENTDATASET=$3
    ${ZFS_CMD} list -s creation -o name -H -d1 -t snapshot "${POOL}/${CLIENT}/${BKP_CLIENTDATASET}"| tail -n1
}

get_destination(){
    CLIENT=$1
    QUEUE_DATASET=$2
    ${MYSQL_COMMAND} -e "SELECT destination FROM clients WHERE hostname='${CLIENT}' and dataset='${QUEUE_DATASET}'"
}

update_db(){
    if [  "$1" == "start" ];then
        QUEUE_ID=$2
        # Update the DB telling it that the backup verification starts
        ${MYSQL_COMMAND} -e "UPDATE queue SET started=SYSDATE(), status='Started' WHERE id='${QUEUE_ID}'"
    fi

    if [  "$1" == "end" ];then
        echo "$(date +'%d-%m-%Y %H:%M:%S') - Updating the DB with the finish status"
        QUEUE_ID="$2"
        STATUS="$3"
        RESULT=$(echo "$4" |sed 's/"/^/g'|sed "s/'/^/g")
        LAST_SNAPSHOT_ID="$5"
        QUEUE_DATASET=$6

        # If the verify failed, we schedule another backup (up to 3 times to avoid a fail loop for a single client)
        if [ "${STATUS}" == "Failed" ]; then
            CLIENT=$(get_client "${QUEUE_ID}")
            if [ "$(check_failure_count "${CLIENT}" "${QUEUE_DATASET}")" -lt "3" ]; then
                echo "$(date +'%d-%m-%Y %H:%M:%S') - Verify failed, thus scheduling another backup for ${CLIENT} ${QUEUE_DATASET}"
                RESULT=$(echo -e "<font color=red>Verify failed, thus scheduling another backup for ${CLIENT} ${QUEUE_DATASET}</font>\n${RESULT}")
                ${MYSQL_COMMAND} -e "UPDATE clients SET lastrun=0 WHERE hostname='${CLIENT}' and dataset='${QUEUE_DATASET}'"
                sleep 5
            else
                RESULT=$(echo -e "<font color=red>Verify failed 3 times, not scheduling another backup for ${CLIENT}</font>\n${RESULT}")
                echo "$(date +'%d-%m-%Y %H:%M:%S') - Verify failed 3 times, not scheduling another backup for ${CLIENT}"
            fi
            # This will instruct the snapshot manager on the storage node to delete this snapshot
            ${MYSQL_COMMAND} -e "UPDATE backups SET present='0' WHERE backup_name='${LAST_SNAPSHOT_ID}'"
        fi
        ${MYSQL_COMMAND} -e "UPDATE queue SET ended=SYSDATE(), comment='${RESULT}', status='${STATUS}' WHERE id='${QUEUE_ID}'"
        ${MYSQL_COMMAND} -e "UPDATE backups SET status='${STATUS}', verify_queue_id='${QUEUE_ID}' WHERE backup_name='${LAST_SNAPSHOT_ID}'"
    fi
}

check_failure_count(){
    CLIENT=$1
    QUEUE_DATASET=$2
    BACKUP_INTERVAL=$(${MYSQL_COMMAND} -e "SELECT backup_interval FROM clients WHERE hostname='${CLIENT}' and dataset='${QUEUE_DATASET}'")
    ${MYSQL_COMMAND} -e "SELECT count(*) FROM queue WHERE type='backup' and hostname='${CLIENT}' and dataset='${QUEUE_DATASET}' and started > SYSDATE() - interval ${BACKUP_INTERVAL} minute"
}

create_zfs_clone(){
    LAST_SNAPSHOT=$1
    TIMESTAMP=$2
    POOL=$3
    CLIENT=$4
    BKP_CLIENTDATASET=$5
    echo "$(date +'%d-%m-%Y %H:%M:%S') - Creating a clone from the last snapshot ${LAST_SNAPSHOT}, which we can verify." |tee -a "${LOGFILE}"
    ${ZFS_CMD} clone "${LAST_SNAPSHOT}" "${POOL}/${CLIENT}/${BKP_CLIENTDATASET}.VERIFY.${TIMESTAMP}"
}

install_mysql_packages(){
    BKP_CLIENTNAME=$1
    PKG_VERSION=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${BKP_CLIENTNAME}" 'cat /data/mysql/mysql_upgrade_info' 2>&1)
    PKG_DIR="/opt/backupator/packages/mysql/${PKG_VERSION}"
    if dpkg -l percona-server-server |grep -q "${PKG_VERSION}"; then
        echo "$(date +'%d-%m-%Y %H:%M:%S') - The proper MySQL version is already installed, skipping the install step" | tee -a "${LOGFILE}"
    else
        # Order of the first 3 is important. otherwise packages are installed but not configured
        dpkg -i ${PKG_DIR}/percona-server-common* 2>&1 |tee -a "${LOGFILE}"
        dpkg -i ${PKG_DIR}/percona-server-client* 2>&1 |tee -a "${LOGFILE}"
        dpkg -i ${PKG_DIR}/percona-server-server* 2>&1 |tee -a "${LOGFILE}"
        dpkg -i ${PKG_DIR}/percona-server-tokudb* 2>&1 |tee -a "${LOGFILE}"
        dpkg -i ${PKG_DIR}/percona-server-rocksdb* 2>&1 |tee -a "${LOGFILE}"
    fi
}

prepare_mysql(){
    TIMESTAMP=$1
    STORAGE_PATH=$2
    FS=$3
    DESTINATION=$4
    POOL=$5
    CLIENT=$6
    BKP_CLIENTDATASET=$7
    MOUNTPOINT=$8
    echo "$(date +'%d-%m-%Y %H:%M:%S') - Preparing the MySQL directory" |tee -a "${LOGFILE}"
    if [ "${FS}" == "ext4" ]; then
        if [ "${DESTINATION}" == "dataset" ];then
            # Mount the sparse file to the mountpoint
            mount "${STORAGE_PATH}/${CLIENT}/${BKP_CLIENTDATASET}.VERIFY.${TIMESTAMP}/backup" "${MOUNTPOINT}" 2>&1 |tee -a "${LOGFILE}"
        fi
        if [ "${DESTINATION}" == "zvol" ];then
            # Make 5 atempts to mount the zvol, since it does not appear immediately in the /etc/zvol/rpool/backup
            for i in {1..10}; do
                echo "$(date +'%d-%m-%Y %H:%M:%S') - Mount try ${i}" | tee -a "${LOGFILE}"
                mount "/dev/zvol/${POOL}/${CLIENT}/${BKP_CLIENTDATASET}.VERIFY.${TIMESTAMP}" "${MOUNTPOINT}" 2>&1 |tee -a "${LOGFILE}"
                EXIT_CODE=${PIPESTATUS[@]}
                EXIT_CODE=$(echo "${EXIT_CODE}" | sed "s/0//g" |sed "s/ //g")
                if [ "${EXIT_CODE}" == "" ];then
                    echo "$(date +'%d-%m-%Y %H:%M:%S') - Succeeded mounting /dev/zvol/${POOL}/${CLIENT}/${BKP_CLIENTDATASET}.VERIFY.${TIMESTAMP}" |tee -a "${LOGFILE}"
                    break
                fi
                sleep 2
            done
        fi
    fi
    if [ "${FS}" == "zfs" ]; then
        # Bind mount the clone to the mountpoint
        rm -rf "${MOUNTPOINT}"
        echo "zfs set mountpoint=${MOUNTPOINT} ${POOL}/${CLIENT}/${BKP_CLIENTDATASET}.VERIFY.${TIMESTAMP}" | tee -a "${LOGFILE}"
        zfs set mountpoint="${MOUNTPOINT}" "${POOL}/${CLIENT}/${BKP_CLIENTDATASET}.VERIFY.${TIMESTAMP}" 2>&1
    fi
    rm -f "${MOUNTPOINT}/xb_doublewrite"
    rm -f "${MOUNTPOINT}/auto.cnf"
    touch "${MYSQL_VERIFY_LOG}"
    chown mysql: "${MYSQL_VERIFY_LOG}"
    echo > "${MYSQL_VERIFY_LOG}"
    # Cleanup some files, which may prevent the backup from starting
    rm -f /var/run/mysqld/*
}

get_verify_config(){
    CLIENT=$1
    QUEUE_DATASET=$2
    TEMPLATE=$(${MYSQL_COMMAND} -e "SELECT backup_verify_config FROM clients WHERE hostname='${CLIENT}' and dataset='${QUEUE_DATASET}'")
    echo -e $(${MYSQL_COMMAND} -e "SELECT content FROM backup_verify_configs WHERE name='${TEMPLATE}'") | sed "s/\r//g" > "${VERIFY_CONFIG_FILE}"
}

start_mysql(){
    echo "$(date +'%d-%m-%Y %H:%M:%S') - Starting the MySQL instance." |tee -a "${LOGFILE}"
    export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1
    mysqld_safe --defaults-file="${VERIFY_CONFIG_FILE}" --log-error=${MYSQL_VERIFY_LOG} --innodb_doublewrite=0 >/dev/null 2>&1 &
}

verify_mysql_started(){
    lsof /var/run/mysqld/mysqld.sock >/dev/null 2>&1
}

verify_mysql_running(){
    RUNNING=$(pgrep mysql)
    if [ -z "${RUNNING}" ]; then
        RECOVERY_LEVEL=$(awk '{if ($1 == "innodb_force_recovery") print $NF}' "${CONFIGDIR}/backup_verify_server.cnf")
        if [ "${RECOVERY_LEVEL}" == "1" ];then
            CLIENT=$1
            QUEUE_ID=$2
            POOL=$3
            TIMESTAMP=$4
            LAST_SNAPSHOT_ID="$5"
            FS=$6
            BKP_CLIENTDATASET=$7
            QUEUE_DATASET=$8
            echo "$(date +'%d-%m-%Y %H:%M:%S') - MySQL not running, probably died while starting." |tee -a "${LOGFILE}"
            if [ "$(wc -l ${MYSQL_VERIFY_LOG})" -gt "2000" ];then
                LOG_ENTRIES=$( (head -n1000 && tail -n1000) <${MYSQL_VERIFY_LOG}|sed 's/"/^/g'|sed "s/'/^/g")
                cp ${MYSQL_VERIFY_LOG} "${LOGDIR}/${QUEUE_ID}.log"
            else
                LOG_ENTRIES=$(cat ${MYSQL_VERIFY_LOG}|sed 's/"/^/g'|sed "s/'/^/g")
            fi
            RESULT="MySQL unable to start.\n${LOG_ENTRIES}"
            cat ${MYSQL_VERIFY_LOG} >> "${LOGDIR}/mysql_verify.log"
            cleanup "${CLIENT}" "${TIMESTAMP}" "${POOL}" "${FS}" "${BKP_CLIENTDATASET}"
            update_db end "${QUEUE_ID}" Failed "${RESULT}" "${LAST_SNAPSHOT_ID}" "${QUEUE_DATASET}" 2>&1 |tee -a "${LOGFILE}"
        else
            CLIENT=$1
            echo "$(date +'%d-%m-%Y %H:%M:%S') - MySQL for ${CLIENT} not running, trying innodb_force_recovery = 1." >> "${LOGFILE}"
            # if the innodb_force_recovery was not set to 1, try with 1
            sed -i 's/^innodb_force_recovery.*/innodb_force_recovery = 1/g' "${CONFIGDIR}/backup_verify_server.cnf"
            start_mysql >/dev/null 2>&1
            sleep 5
            STALE=false
        fi
    fi
}

wait_mysql_start(){
    CLIENT=$1
    QUEUE_ID=$2
    POOL=$3
    TIMESTAMP=$4
    LAST_SNAPSHOT_ID=$5
    FS=$6
    BKP_CLIENTDATASET=$7
    QUEUE_DATASET=$8
    while true; do
        # Check when the MySQL is accessible so we can continue with the queries
        echo "$(date +'%d-%m-%Y %H:%M:%S') - Waiting for MySQL to start" |tee -a "${LOGFILE}"
        if verify_mysql_started; then
            echo "$(date +'%d-%m-%Y %H:%M:%S') - MySQL started successfully." |tee -a "${LOGFILE}"
            break
        fi

        # Check if MySQL is running and stop the whole verification if not
        if [ -n "$(verify_mysql_running "${CLIENT}" "${QUEUE_ID}" "${POOL}" "${TIMESTAMP}" "${LAST_SNAPSHOT_ID}" "${FS}" "${BKP_CLIENTDATASET}" "${QUEUE_DATASET}")" ] ; then
            STALE=true
            break
        fi
        # Check if MySQL is running for more than ${VERIFY_STALE_TIME} minutes and stop the verify if yes
        if [ -n "$(check_for_stale_mysql_process "${POOL}" "${LAST_SNAPSHOT_ID}" "${QUEUE_ID}" "${TIMESTAMP}" "${FS}" "${BKP_CLIENTDATASET}" "${QUEUE_DATASET}")" ]; then
            STALE=true
            break
        fi
        sleep 5
    done
}

get_verify_template(){
    CLIENT=$1
    QUEUE_DATASET=$2
    ${MYSQL_COMMAND} -e "SELECT verify_template FROM clients WHERE hostname='${CLIENT}' and dataset='${QUEUE_DATASET}'"
}

get_verify_queries(){
    CLIENT=$1
    QUEUE_DATASET=$2
    TEMPLATE=$(get_verify_template "${CLIENT}" "${QUEUE_DATASET}")
    ${MYSQL_COMMAND} -e "SELECT query FROM verify_queries WHERE template='${TEMPLATE}'"
}

verify_queries(){
    CLIENT=$1
    QUEUE_DATASET=$2
    LAST_SNAPSHOT_ID=$3
    get_verify_queries "${CLIENT}" "${QUEUE_DATASET}" | while read -r QUERY; do
        # Starting time for the verify queries will be (backup creation time - 6 hours)
        BACKUP_TIME="${LAST_SNAPSHOT_ID//${SNAPSHOT_PREFIX}_/}"
        VERIFY_TIME=$((BACKUP_TIME-21600))
        QUERY="${QUERY//${VERIFY_TIME}/}"
        echo "$(date +'%d-%m-%Y %H:%M:%S') - Running the query $(echo "${QUERY}" |sed 's/"/^/g'|sed "s/'/^/g")" |tee -a "${LOGFILE}"
        RESULT=$(${MYSQL_VERIFY_COMMAND} -e "${QUERY}" 2>&1 |sed 's/"/^/g'|sed "s/'/^/g" |tee -a "${LOGFILE}")
        ${MYSQL_COMMAND} -e "UPDATE backups SET node_results=CONCAT(node_results, '${RESULT}\n') WHERE backup_name='${LAST_SNAPSHOT_ID}'"
    done
}

kill_mysql(){
    for process in $(ps axufw |grep -v grep |grep mysql |grep -v "${ZFS_CMD}" |awk '{print $2}'); do
        kill -9 "${process}"
    done
}

cleanup(){
    CLIENT=$1
    TIMESTAMP=$2
    POOL=$3
    FS=$4
    BKP_CLIENTDATASET=$5
    echo "$(date +'%d-%m-%Y %H:%M:%S') - Killing the MySQL instance." |tee -a "${LOGFILE}"
    # Kill MySQL
    kill_mysql
    # Unmount the Backup
    UNMOUNTED=false

    echo "$(date +'%d-%m-%Y %H:%M:%S') - Unmounting the MySQL montpoint in ${MOUNTPOINT}" |tee -a "${LOGFILE}"
    for attempt in {1..60}; do
        umount "${MOUNTPOINT}" 2>&1 |tee -a "${LOGFILE}"
        # We check if there are any mounts in the ${MOUNTPOINT} directory
        MOUNTS_CHECK=$(grep "${MOUNTPOINT}" /proc/mounts |awk '{print $2}')
        MOUNTED=false
        for MOUNT in ${MOUNTS_CHECK}; do
            if [ "${MOUNT}" == "${MOUNTPOINT}" ]; then
                # if still mounted, break the check loop, so another umount is attempted
                MOUNTED=true
                break
            fi
        done
        # If no mounts are present in the ${MOUNTPOINT} directory, we consider it unmounted and we proceed further
        if ! ${MOUNTED};then
            echo "$(date +'%d-%m-%Y %H:%M:%S') - ${MOUNTPOINT} unmounted." |tee -a "${LOGFILE}"
            UNMOUNTED=true
            break
        fi
        sleep 1
    done

    if ${UNMOUNTED}; then
        echo "$(date +'%d-%m-%Y %H:%M:%S') - Removing the ZFS clone ${POOL}/${CLIENT}/${BKP_CLIENTDATASET}.VERIFY.${TIMESTAMP}" |tee -a "${LOGFILE}"
        # Destroy the clone
        ${ZFS_CMD} destroy "${POOL}/${CLIENT}/${BKP_CLIENTDATASET}.VERIFY.${TIMESTAMP}"
    fi
}

check_for_stale_mysql_process(){
    POOL=$1
    LAST_SNAPSHOT_ID=$2
    QUEUE_ID=$3
    TIMESTAMP=$4
    FS=$5
    BKP_CLIENTDATASET=$6
    QUEUE_DATASET=$7
    VERIFY_STALE_TIME=$(${MYSQL_COMMAND} -e "SELECT configvalue FROM config WHERE configkey='VERIFY_STALE_TIME'")
    CHECK=$(${MYSQL_COMMAND} -e "SELECT id FROM queue WHERE id='${QUEUE_ID}' and ended=0 and started < SYSDATE() - interval ${VERIFY_STALE_TIME} minute and started!=0 LIMIT 1")
    if [ -n "${CHECK}" ];then
        CLIENT=$(get_client "${QUEUE_ID}")
        echo "$(date +'%d-%m-%Y %H:%M:%S') - Found a stale MySQL process for client ${CLIENT}, aborting it." |tee -a "${LOGFILE}"
        LOG_ENTRIES="$(cat ${MYSQL_VERIFY_LOG}|sed 's/"/^/g'|sed "s/'/^/g")"
        cleanup "${CLIENT}" "${TIMESTAMP}" "${POOL}" "${FS}" "${BKP_CLIENTDATASET}"
        update_db end "${QUEUE_ID}" Failed "Stale MySQL\n${LOG_ENTRIES}" "${LAST_SNAPSHOT_ID}" "${QUEUE_DATASET}" 2>&1 |tee -a "${LOGFILE}"
    fi
}

get_pool(){
    ${MYSQL_COMMAND} -e "SELECT pool FROM storage_nodes WHERE hostname='${STORAGE_NODE_ID}'"
}

get_storage_path(){
    ${MYSQL_COMMAND} -e "SELECT storage_path FROM storage_nodes WHERE hostname='${STORAGE_NODE_ID}'"
}

verify_clickhouse(){
    CLIENT=$1
    POOL=$2
    DATASET=$3
    ${CLICKHOUSE_VERIFY} "${CLIENT}" "${POOL}" "${DATASET}" "${MYSQL_COMMAND}"
}

schedule(){
    QUEUE_ID=$(check_queue)
    if [ -n "${QUEUE_ID}" ]; then
        POOL=$(get_pool)
        STORAGE_PATH=$(get_storage_path)
        CLIENT=$(get_client "${QUEUE_ID}")
        QUEUE_DATASET=$(get_queue_dataset "${QUEUE_ID}")
        BKP_TYPE=$(echo "${QUEUE_DATASET}" |awk -F: '{print $1}')
        BKP_CLIENTNAME=$(echo "${QUEUE_DATASET}" |awk -F: '{print $2}')
        BKP_CLIENTDATASET=$(echo "${QUEUE_DATASET}" |awk -F: '{print $3}')
        FS=$(check_fs "${CLIENT}" "${QUEUE_DATASET}")

        if [ "${FS}" == "ext4" ]; then
            MOUNTPOINT="/data"
        fi
        if [ "${FS}" == "zfs" ]; then
            MOUNTPOINT="/data/mysql"
        fi

        if [ "${BKP_TYPE}" == "mysql" ]; then
            echo "$(date +'%d-%m-%Y %H:%M:%S') - Found a verify job in the queue for the client ${CLIENT}." |tee -a "${LOGFILE}"
            update_db start "${QUEUE_ID}"
            TIMESTAMP=$1
            if ! grep -q "${POOL}/${CLIENT}.VERIFY.${TIMESTAMP}" /proc/mounts; then
                echo "$(date +'%d-%m-%Y %H:%M:%S') - Checking for mbuffer process and if found, delaying the verification" |tee -a "${LOGFILE}"
                # If there is a mbuffer process do not proceed
                while true; do
                    if ps axufw |grep -v grep |grep mbuffer -q; then
                        ps axufw |grep -v grep |grep mbuffer | tee -a ${LOGFILE}
                    else
                        break
                    fi
                    sleep 1
                done

                echo "$(date +'%d-%m-%Y %H:%M:%S') - Checking for last snapshot with: get_last_snapshot ${CLIENT} ${POOL}" |tee -a "${LOGFILE}"
                # We need to check eventually seceral times, since the last snapshot may not be visible immediately after it is transferred.
                for retry in {1..60}; do
                    LAST_SNAPSHOT=$(get_last_snapshot "${CLIENT}" "${POOL}" "${BKP_CLIENTDATASET}")
                    if [ -n "${LAST_SNAPSHOT}" ]; then
                        echo "$(date +'%d-%m-%Y %H:%M:%S') - LAST_SNAP IS: ${LAST_SNAPSHOT}, found from ${retry} try." |tee -a "${LOGFILE}"
                        break
                    else
                        echo "$(date +'%d-%m-%Y %H:%M:%S') - No snap for ${POOL}/${CLIENT}/${BKP_CLIENTDATASET}" |tee -a "${LOGFILE}"
                        zfs list -t snapshot -d1 "${POOL}/${CLIENT}/${BKP_CLIENTDATASET}" 2>&1 |tee -a "${LOGFILE}"
                        zfs list "${POOL}/${CLIENT}/${BKP_CLIENTDATASET}" 2>&1 |tee -a "${LOGFILE}"
                    fi
                    sleep 1
                done

                if [ -n "${LAST_SNAPSHOT}" ]; then
                    LAST_SNAPSHOT_ID=$(echo "${LAST_SNAPSHOT}" |awk -F@ '{print $2}')
                    echo "$(date +'%d-%m-%Y %H:%M:%S') - Last snapshot name is ${LAST_SNAPSHOT_ID}." |tee -a "${LOGFILE}"
                    create_zfs_clone "${LAST_SNAPSHOT}" "${TIMESTAMP}" "${POOL}" "${CLIENT}" "${BKP_CLIENTDATASET}"
                    DESTINATION=$(get_destination "${CLIENT}" "${QUEUE_DATASET}")
                    install_mysql_packages "${BKP_CLIENTNAME}"
                    prepare_mysql "${TIMESTAMP}" "${STORAGE_PATH}" "${FS}" "${DESTINATION}" "${POOL}" "${CLIENT}" "${BKP_CLIENTDATASET}" "${MOUNTPOINT}"
                    get_verify_config "${CLIENT}" "${QUEUE_DATASET}"
                    start_mysql
                    sleep 5
                    STALE=false
                    wait_mysql_start "${CLIENT}" "${QUEUE_ID}" "${POOL}" "${TIMESTAMP}" "${LAST_SNAPSHOT_ID}" "${FS}" "${BKP_CLIENTDATASET}" "${QUEUE_DATASET}"

                    # If mysql is started and not stale, run the verification queries
                    if ! ${STALE}; then
                        echo "$(date +'%d-%m-%Y %H:%M:%S') - Starting verification queries." |tee -a "${LOGFILE}"
                        RESULT=$(verify_queries "${CLIENT}" "${QUEUE_DATASET}" "${LAST_SNAPSHOT_ID}")
                        cleanup "${CLIENT}" "${TIMESTAMP}" "${POOL}" "${FS}" "${BKP_CLIENTDATASET}"
                        update_db end "${QUEUE_ID}" Success "${RESULT}" "${LAST_SNAPSHOT_ID}" "${QUEUE_DATASET}" 2>&1 |tee -a "${LOGFILE}"
                    fi
                else
                    echo "$(date +'%d-%m-%Y %H:%M:%S') - There are no snapshots for ${POOL}/${CLIENT} yet." |tee -a "${LOGFILE}"
                    ps axufw |tee -a "${LOGFILE}"
                    RESULT="There is no snapshot for ${POOL}/${CLIENT} yet."
                    update_db end "${QUEUE_ID}" Failed "${RESULT}" "${LAST_SNAPSHOT_ID}" "${QUEUE_DATASET}" 2>&1 |tee -a "${LOGFILE}"
                fi
            else
                echo "$(date +'%d-%m-%Y %H:%M:%S') - There already seems to be a clone for the client ${CLIENT}" |tee -a "${LOGFILE}"
            fi
        fi

        if [ "${BKP_TYPE}" == "clickhouse" ]; then
            echo "$(date +'%d-%m-%Y %H:%M:%S') - Starting verify job in the queue for the client ${CLIENT}." |tee -a "${LOGFILE}"
            update_db start "${QUEUE_ID}"
            RESULT=$(verify_clickhouse "${CLIENT}" "${POOL}" "${BKP_CLIENTDATASET}")
            if echo -e "${RESULT}" | grep 'done!' -q ; then
                if echo -e "${RESULT}" | grep 'WARNING: Local and remote' -q; then
                    STATUS=Failed
                else
                    STATUS=Success
                fi
            else
                STATUS=Failed
            fi
            update_db end "${QUEUE_ID}" "${STATUS}" "${RESULT}" "${LAST_SNAPSHOT_ID}" "${QUEUE_DATASET}" 2>&1 |tee -a "${LOGFILE}"
        fi
    fi
}

while true; do
    schedule "$(date +'%s')"
    sleep 5
done
