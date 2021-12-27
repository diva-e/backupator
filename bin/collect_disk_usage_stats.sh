#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/puppetlabs/bin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin

if [ -z "$1" ]; then
    HOSTNAME=$(hostname -f)
else
	HOSTNAME=$1
fi

CONFIGDIR="/opt/backupator/etc"
DBNAME="backupator"
MY_CREDENTIALS="${CONFIGDIR}/backupator_mysql.cnf"
MYSQL_COMMAND="mysql --defaults-extra-file=${MY_CREDENTIALS} ${DBNAME}"
POOL=$(${MYSQL_COMMAND} -e "SELECT pool FROM storage_nodes WHERE hostname='${HOSTNAME}'")
STORAGE_PATH=$(${MYSQL_COMMAND} -e "SELECT storage_path FROM storage_nodes WHERE hostname='${HOSTNAME}'")

if [ -z "${STORAGE_PATH}" ];then
    echo "Unable to get STORAGE_PATH, probably an invalid hostname"
    exit 1
fi
human_readable(){
    VALUE=$1
    for unit in B KB MB GB TB; do
        if [ "$(echo ${VALUE} |awk -F. '{print $1}')" -gt "1024" ];then
            VALUE=$(echo ${VALUE}/1024 |bc -l)
        else
            UNIT=${unit}
            break
        fi
    done
    NEW_VALUE=$(echo "scale=2; (0+${VALUE})/1"|bc -l)
    echo ${NEW_VALUE}${UNIT}
}

TOTAL=0
for dataset in $(${MYSQL_COMMAND} -e "SELECT dataset FROM clients"); do
    client=$(${MYSQL_COMMAND} -e "SELECT hostname FROM clients where dataset='${dataset}'")
    DATASET=$(echo ${dataset} | awk -F: '{print $3}')
    BACKUPSIZE=$(zfs list -Hp -o refer ${POOL}/${client}/${DATASET} 2>/dev/null)
    if [ -z "${BACKUPSIZE}" ];then
        continue
    fi
    SNAPSIZE=$(zfs list -Hpo usedsnap ${POOL}/${client}/${DATASET})

    let CLIENT_TOTAL=${SNAPSIZE}+${BACKUPSIZE}
    if [ -z "$1" ]; then
        echo ${client}:
        echo -e "\tBackup size: $(human_readable ${BACKUPSIZE})"
        echo -e "\tSnapshots size: $(human_readable ${SNAPSIZE})"
        echo -e "\tTotal: $(human_readable ${CLIENT_TOTAL})"
    fi
    let TOTAL=${CLIENT_TOTAL}+${TOTAL}
    ${MYSQL_COMMAND} -e "UPDATE clients SET backup_size='${BACKUPSIZE}', snapshots_size='${SNAPSIZE}' WHERE hostname='${client}' and dataset='${dataset}' and storage='${HOSTNAME}'"
done

if [ -z "$1" ]; then
    echo ""
    echo TOTAL: $(human_readable ${TOTAL})
fi
FREESPACE=$(df -B1 ${STORAGE_PATH} |awk '{print $4}' |tail -n1)
${MYSQL_COMMAND} -e "UPDATE storage_nodes SET used_space='${TOTAL}', free_space='${FREESPACE}' WHERE hostname='${HOSTNAME}'"