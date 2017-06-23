# Zabbix SMART (S.M.A.R.T.) mnitor for SATA and NVMe disks using smartctl (smartmontools) or nvme (nvme-cli)

## Features:

* Auto discovery of drive by smartctl (smartmontools) or nvme (nvme-cli)
* Will trigger an alert on monitored disk failue and temperature attributes
* Drives are probed every 1 hour
* Active Zabbix agent discovery and items

## Install:

1. Make sure smartctl (smartmontools) is installed if you plan to monitor SATA drives
2. Make sure smartmontools version 6.6+ is installed to monitor NVMe. Alernatively nvme (nvme-cli) may be installed (e.g. for Ubuntu 16.04 LTS)
3. Download repository files and run to install files
```bash
cd zabbix-hdd-smart-master
sudo bash install.sh
```
4. Import hdd-smart.xml on Zabbix Monitoring Server
5. Create `/etc/zabbix/hdd-smart.conf` and add any RAID devices or ignore device (see example `hdd-smart.conf` in repository)

## Common Problems:
* If all of the SMART values show as `not supported` you most likely need to
install smartmontools on the monitored machine.
* If a drive is missing from the listing, make sure it is listed by
```sh
smartctl --scan
```
* Some drives only give *Temperature_Celsius*, some only give
*Airflow_Temperature_Cel*, and some give both. So in `hdd-smart.xml` look for
*Temperature_Cel* (which will catch both) and in only take the first output.
On drives that provide both temperatures there is no guarantee which one will show up first. This should only be a minor problem and is the
result of S.M.A.R.T not being an official set of standards.

## Known issue
- [ ] nvme cli does not provide a health status of disk (self test result)

## Special Thanks:
Mostly based on zab-smartmon project by Ronald Farrer (@rfarrer)
