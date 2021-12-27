#!/bin/bash

CLIENT=$1
POOL=$2
DATASET=$3
MYSQL_COMMAND="$4"
TIMESTAMP=$(zfs list -t snapshot -d1 ${POOL}/${CLIENT}/${DATASET} -H -o name -S creation |head -n1 |awk -F@ '{print $2}')

. /opt/backupator/etc/backupator.conf

user=''
password=''

clickhouse_client="clickhouse-client -u $user --password $password"

logfile=/var/log/backupator/backup_clh_check_$CLIENT
# clean-up logfile before we start
truncate -s0 $logfile

lock_file=/var/lock/clh_verify_backup

# check if lock file exists
if [[ -f $lock_file ]]; then
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - lock file exists, exiting"
  exit 0
else # create it
  touch $lock_file
fi

timeout_value=30m
tries=3600
# today=$(date +%Y-%m-%d)
date_3_days_ago=$(date --date '3 days ago' +%Y-%m-%d)
date_13_days_ago=$(date --date '13 days ago' +%Y-%m-%d)

function start_clh() {
  # Stop clickhouse if currently running
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - systemctl stop clickhouse-server" | tee -a $logfile
  systemctl stop clickhouse-server
  killall -9 clickhouse-server
  # ensure ${POOL}/$CLIENT/${DATASET}.VERIFY is available
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - zfs destroy ${POOL}/$CLIENT/${DATASET}.VERIFY > /dev/null 2>&1" | tee -a $logfile
  zfs destroy ${POOL}/$CLIENT/${DATASET}.VERIFY > /dev/null 2>&1
  # ensure /data/clickhouse is unmounted
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - umount /data/clickhouse  > /dev/null 2>&1" | tee -a $logfile
  umount /data/clickhouse  > /dev/null 2>&1
  # "mount" the snapshot so that we can use it
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - zfs clone ${POOL}/$CLIENT/${DATASET}@$TIMESTAMP ${POOL}/$CLIENT/${DATASET}.VERIFY" | tee -a $logfile
  zfs clone ${POOL}/$CLIENT/${DATASET}@$TIMESTAMP ${POOL}/$CLIENT/${DATASET}.VERIFY
  # mount files to test
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - zfs set overlay=on ${POOL}/$CLIENT/${DATASET}.VERIFY" | tee -a $logfile
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - zfs set mountpoint=/data/clickhouse ${POOL}/$CLIENT/${DATASET}.VERIFY" | tee -a $logfile
  zfs set overlay=on ${POOL}/$CLIENT/${DATASET}.VERIFY
  zfs set mountpoint=/clickhouse_data ${POOL}/$CLIENT/${DATASET}.VERIFY
  mount -o bind /clickhouse_data/clickhouse /data/clickhouse
  # start clickhouse localy
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - service clickhouse-server start" | tee -a $logfile
  service clickhouse-server start
  # wait for clickhouse to be actually started or timeout and send error
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - truncating clickhouse logs: 'echo > /var/log/clickhouse-server/clickhouse-server.log'" | tee -a $logfile
  echo > /var/log/clickhouse-server/clickhouse-server.log
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - waiting for clickhouse-server to start" | tee -a $logfile
  for try in `seq 1 ${tries}`; do
    if $(grep -q "<Information> Application: Ready for connections." /var/log/clickhouse-server/clickhouse-server.log); then
      echo "$(date +'%d-%m-%Y %H:%M:%S') - clickhouse-server start ok"
      break
    fi
    
    if [ "${try}" == "${tries}" ]; then
      echo "$(date +'%d-%m-%Y %H:%M:%S') - timeout on starting the clickhouse-server"
      killall -9 clickhouse-server
      rm -f /var/lock/clh_verify_backup
      umount /data/clickhouse/
      zfs destroy ${POOL}/${CLIENT}/${DATASET}.VERIFY
      exit 0
    fi
    sleep 1
  done
}

function stop_clh() {
  # stop local clickhouse
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - service clickhouse-server stop" | tee -a $logfile
  systemctl stop clickhouse-server
  killall -9 clickhouse-server
  # wait for clickhouse to be actually stopped or timeout and send error
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - waiting for clickhouse-server to stop" | tee -a $logfile
  timeout $timeout_value grep -m 1 "<Information> Application: shutting down" <(tail -f /var/log/clickhouse-server/clickhouse-server.log) > /dev/null 2>&1 && echo "$(date +'%d-%m-%Y %H:%M:%S') - clickhouse-server shutdown ok" || ( echo "$(date +'%d-%m-%Y %H:%M:%S') - timeout on stopping the clickhouse-server" && exit 0 )
  # ensure /data/clickhouse is unmounted
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - umount /data/clickhouse" | tee -a $logfile
  umount /data/clickhouse
  # kill "mountable" VERIFY snapshot
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - zfs destroy ${POOL}/$CLIENT/${DATASET}.VERIFY" | tee -a $logfile
  zfs destroy ${POOL}/$CLIENT/${DATASET}.VERIFY
}


# actually start checks
echo -e "$(date +'%d-%m-%Y %H:%M:%S') - Starting check of backup $CLIENT/${DATASET} timestamp $TIMESTAMP" | tee -a $logfile
VERIFY_TEMPLATE=$(${MYSQL_COMMAND} -e "SELECT verify_template FROM clients WHERE hostname='${CLIENT}' and dataset LIKE '%${DATASET}' ")

echo -e "$(date +'%d-%m-%Y %H:%M:%S') - start_clh" | tee -a $logfile
start_clh
echo -e "$(date +'%d-%m-%Y %H:%M:%S') - Starting queries" | tee -a $logfile
echo "---------------------------------------------------------------------------------------" | tee -a $logfile
# It may have more than one query for each verify template thus we iterate over the results
${MYSQL_COMMAND} -e "SELECT query FROM verify_queries WHERE template='${VERIFY_TEMPLATE}' " | while read QUERY; do

  status=$($clickhouse_client -q "$QUERY" 2>&1)
  return_code=$? # zero if query was executed successfully.

  status_remote=$($clickhouse_client -h $CLIENT -q "$QUERY" 2>&1)
  return_code_remote=$? # zero if query was executed successfully.

  echo -e "Return Code" | tee -a $logfile
  echo -e "Local:  $return_code" | tee -a $logfile
  echo -e "Remote: $return_code_remote" | tee -a $logfile
  echo -e "Status" | tee -a $logfile
  echo -e "Local:\n $status" | tee -a $logfile
  echo -e "Remote:\n $status_remote" | tee -a $logfile
  
  echo -e "$(date +'%d-%m-%Y %H:%M:%S') - Comparing query outputs for: ${QUERY}"  | tee -a $logfile
  if [ "$return_code" -eq "0" ] && [ "$return_code_remote" -eq "0" ]; then
    if ! [ "$status" == "$status_remote" ]; then
        echo -e "WARNING: Local and remote statuses are different !!!" | tee -a $logfile
    fi
  else
    echo -e "WARNING: Local and remote codes are different !!!" | tee -a $logfile
  fi

  echo "---------------------------------------------------------------------------------------" | tee -a $logfile

done

echo -e "$(date +'%d-%m-%Y %H:%M:%S') - Finished queries" | tee -a $logfile

echo -e "$(date +'%d-%m-%Y %H:%M:%S') - stop_clh" | tee -a $logfile
stop_clh

echo -e "$(date +'%d-%m-%Y %H:%M:%S') - done!" | tee -a $logfile
killall tail
rm $lock_file
