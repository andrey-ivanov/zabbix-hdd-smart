#!/bin/bash

if [ $(id --user) -ne 0 ]; then
  echo "This script should be run using sudo or as the root user"
  exit 1
fi

install --group=zabbix --mode=750 -D -t /usr/local/bin/ zabbix-hdd-smart.sh &&
install --mode=400 -t /etc/sudoers.d/ etc/sudoers.d/zabbix-hdd-smart &&
install --group=zabbix --mode=640 -t /etc/zabbix/zabbix_agentd.conf.d etc/zabbix/zabbix_agentd.conf.d/hdd-smart.conf &&

systemctl restart zabbix-agent
