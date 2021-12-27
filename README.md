# backupator

Backupator is a backup system for systems using ZFS as storage. It uses ZFS snapshots to make the backups small and only take the space which was occupied after the last snapshot. It has a WebUI for easier management.

## Requirements for the backup software:
 - systemd linux distribution (currently tested with Ubuntu 20.04 LTS and CentOS 8)
 - Apache 2.4 with mod_php
 - PHP 7.3 or newer
 - MySQL client
 - MySQL database server
 - zfs
 - mbuffer

## WEBUI Requirements:
- Ubuntu 20.04 / Centos 8
- apache2
- libapache2-mod-php7.4
- php7.4-mysql
- mod rewrite enabled

## Installation
```
./install.sh backupator
./install.sh db
./install.sh www
```

## Cleanup
```
./cleanup.sh
```

## To be fixed
 - Issues with the web UI
 -- Logging

## Features to be addded
 - parallelisation of the backups

## License
The Backupator software is licensed with Apache license 2.0
