#!/bin/bash

echo ""
echo -n "Please confirm that you wish to destroy your backupator installation [yes/no]: "
read -r CONFIRM

if [ "${CONFIRM}" == "yes" ];then
  DBNAME=$(grep ^DBNAME /opt/backupator/etc/backupator.conf |awk -F'"' '{print $2}')
  mysql --defaults-extra-file=/opt/backupator/etc/backupator_mysql.cnf -e "DROP DATABASE ${DBNAME}"
  rm -rf /opt/backupator
  rm -rf /var/log/backupator
  systemctl stop backupator-verification
  systemctl stop backupator-backup
  rm -f /etc/systemd/system/backupator-*
  systemctl daemon-reload
else
  echo "Cleanup aborted!"
fi
