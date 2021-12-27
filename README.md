# backupator

Backupator is a backup system for systems using ZFS as storage. It uses ZFS snapshots to make the backups small and only take the space which was occupied after the last snapshot. It has a WebUI for easier management.

## Requirements for the backup software
 - systemd linux distribution (currently tested with Ubuntu 20.04 LTS and CentOS 8)
 - MySQL client
 - MySQL database server
 - zfs
 - mbuffer

## WEBUI Requirements
- Apache 2.4 with mod_php
- PHP 7.3 or newer
- php7.4-mysql
- mod rewrite enabled

## Installation
```
./install.sh backupator # Install the backupator software on the storage server
./install.sh db         # Install the database structure
./install.sh www        # Install the web interface
```

## Cleanup
```
./cleanup.sh backupator # Cleanup the backupator software in /opt/backupator
./cleanup.sh db         # Drop the database
```

## To be fixed
 - Issues with the web UI
 -- Logging

## Features to be addded
 - parallelisation of the backups

## Monitor disk usage
To monitor the disk usage of the backupator storage node, the script /opt/backupator/bin/collect_disk_usage_stats.sh can be executed.
It can be added to cron as follows:
```
27 * * * * /opt/backupator/bin/collect_disk_usage_stats.sh >/dev/null 2>&1
```
The script will populate the DB with the disk usage of all backed up datasets on the local backupator storage.
This can be observed in the **Storage Nodes** and **Clients** pages in the Web UI.
