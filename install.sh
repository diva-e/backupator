#!/bin/bash

INSTALL_TYPE=$1
COL_RED='\e[91m'
COL_BOLD='\e[1m'
COL_RES='\e[0m'

check_mysql_command(){
  which mysql >/dev/null 2>&1
}

check_zfs_command(){
  which zfs >/dev/null 2>&1
}

check_mbuffer_command(){
  which mbuffer >/dev/null 2>&1
}

install_help(){
  echo "Install should be initiated with one of the following options:"
  echo -e "\t backupator  # this will install backupator storage node"
  echo -e "\t db          # this will install backupator database"
  echo -e "\t www         # this will install backupator Web UI"
  exit 1
}

if [ -z "${INSTALL_TYPE}" ]; then
  install_help
fi

if [ "${INSTALL_TYPE}" == "backupator" ];then
  if ! check_mysql_command; then
    echo -e "Prechecks failed: mysql Command missing. Please install MySQL client first.\nYou may run the following to install a MySQL client\napt install mysql-client-core-8.0"
    exit 1
  fi
  if ! check_zfs_command; then
    echo -e "Prechecks failed: zfs Command missing. Please install zfs first.\nYou may run the following to install it\napt install zfsutils-linux"
    exit 1
  fi
  if ! check_mbuffer_command; then
    echo -e "Prechecks failed: mbuffer Command missing. Please install mbuffer first.\nYou may run the following to install it\napt install mbuffer"
    exit 1
  fi

  if ! [ -d "/var/log/backupator" ]; then
    mkdir -p /var/log/backupator
  fi

  if ! [ -d "/opt/backupator" ]; then
    mkdir -p /opt/backupator
  fi
  echo "Copying backuator files to /opt/backupator/"
  cp -a etc bin /opt/backupator/

  echo ""
  echo "Please enter the necessary MySQL database connection parameters that will be used for backupator:"
  echo -n "Database Host [localhost]: "
  read -r DBHOST
  echo -n "Database port [3306]: "
  read -r DBPORT
  echo -n "Database Name [backupator]: "
  read -r DBNAME
  echo -n "Database Username [backupator]: "
  read -r DBUSER
  echo -n "Database Password: "
  read -r -s DBPASS
  echo ""
  echo -n "Enter identifier for this host [Backupator1]: "
  read -r STORAGE_NODE_ID

  if [ -z "${DBHOST}" ]; then
    DBHOST=localhost
  fi

  if [ -z "${DBNAME}" ]; then
    DBNAME=backupator
  fi

  if [ -z "${DBUSER}" ]; then
    DBUSER=backupator
  fi

  if [ -z "${DBPORT}" ]; then
    DBPORT=3306
  fi

  if [ -z "${STORAGE_NODE_ID}" ]; then
    STORAGE_NODE_ID=Backupator1
  fi

  sed -i "s/^DBNAME=.*/DBNAME=\"${DBNAME}\"/" /opt/backupator/etc/backupator.conf
  sed -i "s/^STORAGE_NODE_ID=.*/STORAGE_NODE_ID=\"${STORAGE_NODE_ID}\"/" /opt/backupator/etc/backupator.conf
  sed -i "s/^database=.*/database='${DBNAME}'/" /opt/backupator/etc/backupator_mysql.cnf
  sed -i "s/^user=.*/user='${DBUSER}'/" /opt/backupator/etc/backupator_mysql.cnf
  sed -i "s/^password=.*/password='${DBPASS}'/" /opt/backupator/etc/backupator_mysql.cnf
  sed -i "s/^host=.*/host='${DBHOST}'/" /opt/backupator/etc/backupator_mysql.cnf
  sed -i "s/^port=.*/port='${DBPORT}'/" /opt/backupator/etc/backupator_mysql.cnf

  echo ""
  echo "Please go to your database server and execute the following MySQL statements:"
  echo -e "${COL_BOLD}CREATE DATABASE ${DBNAME};${COL_RES}"
  if [ "${DBHOST}" == "localhost" ] || [ "${DBHOST}" == "127.0.0.1" ];then
    echo -e "${COL_BOLD}CREATE USER '${DBUSER}'@'localhost' IDENTIFIED BY ${COL_RED}'YOUR_PASSWORD'${COL_RES}${COL_BOLD};${COL_RES}"
    echo -e "${COL_BOLD}GRANT ALL ON ${DBNAME}.* TO '${DBUSER}'@'localhost';${COL_RES}"
    echo -e "${COL_BOLD}FLUSH PRIVILEGES;${COL_RES}"
  else
    BACKUPATOR_IP=$(hostname -I |awk '{print $1}')
    echo -e "${COL_BOLD}CREATE USER '${DBUSER}'@'${BACKUPATOR_IP}' IDENTIFIED BY ${COL_RED}'YOUR_PASSWORD'${COL_RES}${COL_BOLD};${COL_RES}"
    echo -e "${COL_BOLD}GRANT ALL ON ${DBNAME}.* TO '${DBUSER}'@'${BACKUPATOR_IP}';${COL_RES}"
    echo -e "${COL_BOLD}FLUSH PRIVILEGES;${COL_RES}"
  fi

  echo ""
  echo -n "Press enter when ready."
  read -r -s bogusvar

  echo ""
  echo "Installing the backupator-backup and backupator-verification services"
  cp services/* /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable backupator-verification
  systemctl enable backupator-backup
  systemctl restart backupator-verification
  systemctl restart backupator-backup
  sleep 2
  echo ""
  echo "Checking if the services are up and running"
  systemctl status backupator-verification
  systemctl status backupator-backup
fi

if [ "${INSTALL_TYPE}" == "db" ];then
  if [ -f "/opt/backupator/etc/backupator_mysql.cnf" ];then
    echo -n "Importing the DB structure ... "
    mysql --defaults-extra-file=/opt/backupator/etc/backupator_mysql.cnf < db_structure.sql
    echo "DONE"
  else
    echo "You need to run the \"$0 backupator\" first"
  fi
fi

if [ "${INSTALL_TYPE}" == "www" ];then
  echo -n "Please enter the path to the directory where you would like to have all your web files copied: "
  read -r WWWDIR

  echo "Please enter the database credentials:"
  echo -n "Database Host [localhost]: "
  read -r DBHOST
  echo -n "Database port [3306]: "
  read -r DBPORT
  echo -n "Database Name [backupator]: "
  read -r DBNAME
  echo -n "Database Username [backupator]: "
  read -r DBUSER
  echo -n "Database Password: "
  read -r -s DBPASS

  if [ -z "${DBHOST}" ]; then
    DBHOST=localhost
  fi

  if [ -z "${DBPORT}" ]; then
    DBPORT=3306
  fi

  if [ -z "${DBNAME}" ]; then
    DBNAME=backupator
  fi

  if [ -z "${DBUSER}" ]; then
    DBUSER=backupator
  fi

  echo ""
  echo -en "Please enter the URI at which the website will be available (example http://www.yoururl.com${COL_BOLD}/URI/${COL_RES}): "
  read -r BASEURI

  echo ""
  mkdir -p "${WWWDIR}"
  cp -r web/.htaccess web/* "${WWWDIR}/"

  # Transform a bit the BASEURI
  if [[ ${BASEURI} =~ ^/.* ]]; then
    BASEURI=$(echo "${BASEURI#/}")
  fi
  if [[ ${BASEURI} =~ .*/$ ]]; then
    BASEURI=$(echo "${BASEURI%/}")
  fi
  if [ -n "${BASEURI}" ];then
    BASEURI="/${BASEURI}"
  fi

  sed -i "s/^\$DBNAME.*/\$DBNAME='${DBNAME}';/" "${WWWDIR}/config/header.php"
  sed -i "s/^\$DBUSER.*/\$DBUSER='${DBUSER}';/" "${WWWDIR}/config/header.php"
  sed -i "s/^\$DBPASS.*/\$DBPASS='${DBPASS}';/" "${WWWDIR}/config/header.php"
  sed -i "s/^\$DBHOST.*/\$DBHOST='${DBHOST}';/" "${WWWDIR}/config/header.php"
  sed -i "s/^\$DBPORT.*/\$DBPORT='${DBPORT}';/" "${WWWDIR}/config/header.php"
  sed -i "s#^\$BASEURI.*#\$BASEURI='${BASEURI}/';#" "${WWWDIR}/config/header.php"
fi
