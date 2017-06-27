#!/bin/bash

version=0.01

SMARTCTL_PATH=/usr/sbin/smartctl
if !($SMARTCTL_PATH -h | grep -q nvme); then
    NVME_PATH=/usr/sbin/nvme
fi

if [[ -e /etc/zabbix/hdd-smart.conf ]]; then
   . /etc/zabbix/hdd-smart.conf
fi

function print_discovery_device_list
{
    Disks=$1
    if [[ $IgnoreDisks ]]; then
        Disks=$(echo $Disks | grep -vE '('$IgnoreDisks')')
    fi
    while read -r line
    do
        print_discovery_device $line
    done <<< "$Disks"
}

function print_discovery_device
{
    Device=$1
    if [[ -z "$Device" ]]; then
         return
    fi
    DiskType=$2
    DiskName=${3:-${Device:5}}
    echo -en "$Delimiter\n    "
    echo -en "{\"{#DISKDEVICE}\":\"${Device}\",\"{#DISKTYPE}\":\"${DiskType}\",\"{#DISKNAME}\":\"${DiskName}\"}"
    Delimiter=","
    if [[  "$4" == "add_to_ignore_list" ]]; then
        if [[ -z $IgnoreDisks ]]; then
            IgnoreDisks=$Device
        elif echo $IgnoreDisks | grep -vq $Device; then
            IgnoreDisks="${IgnoreDisks}|${Device}"
        fi
    fi
}

while getopts ":DNd:c:n:v:ti" optname
do
    case "$optname" in
    "D")
        #
        # Autodiscovery of standard SATA drives
        #
        echo -en '{\n  "data":\n  ['
        if [[ ! -x "$ManualDiscovery" ]]; then
            while read -r line
            do
                # add any drives listed in ManualDiscovery to IgnoreDisks list to keep
                # it from being rediscovered
                if [[ ! -z "${line// }" ]]; then
                    print_discovery_device $line add_to_ignore_list
                fi
            done <<< "$ManualDiscovery"
        fi
        Disks=$($SMARTCTL_PATH --scan | grep '^/dev/' | cut -d' ' -f1,3 | sort | uniq)
        print_discovery_device_list "$Disks"
        echo -e '\n  ]\n}'
        exit 0
    ;;
    "N")
        #
        # Autodiscovery of NVMe drives
        #
        echo -en '{\n  "data":\n  ['
        Delimiter=""
        if [[ -e "$NVME_PATH" ]]; then
            Disks=$($NVME_PATH list | grep '^/dev/' | cut -d' ' -f1 | sort | uniq)
        else
            Disks=$($SMARTCTL_PATH --scan -d nvme | grep '^/dev/' | cut -d' ' -f1,3 | sort | uniq)
        fi
        print_discovery_device_list "$Disks"
        echo -e '\n  ]\n}'
        exit 0
    ;;
    "d")
        # Which device are we working with when called
	    DeviceType=$(echo $OPTARG | awk -F "." '{print $1;}')
	    Device=$(echo $OPTARG | awk -F "." '{print $2;}')
    ;;
    "v")
        # get value for the device SMART
        # --nocheck standby won't wake up drive.
        $SMARTCTL_PATH --nocheck standby -A $Device | grep "$OPTARG" | cut -c88- | grep -oE '([0-9]+)' | head -1
        exit 0
    ;;
    "n")
        # get value for the NVMe device using nvme-cli
        if [[ -e "$NVME_PATH" ]]; then
            Value=$($NVME_PATH smart-log $Device | grep "$OPTARG" | cut -c38- | grep -oE '([0-9,]+)' | head -1)
            echo ${Value//$','/}
            exit 0
        fi
    ;;
    "c")
        # get value for the NVMe device using smartctl
        Value=$($SMARTCTL_PATH -A $Device | grep "$OPTARG" | cut -c37- | grep -oE '([0-9,]+)' | head -1)
        echo ${Value//$','/}
        exit 0
    ;;
    "t")
        if [[ -e "$NVME_PATH" ]]; then
            # TODO: Handle self-test status with nvmi-cli
            echo 'UNKNOWN'
            exit 1
        fi
        # Get overall SMART health information: usually "PASSED" if all is well
        health=$($SMARTCTL_PATH -H $Device | grep -i health | awk 'NF>1{print $NF}')
        if [[ $health == "PASSED" || $health == "OK" ]];
        then
            echo 'PASSED'
            exit 0
        else
            echo 'FAILED!'
            exit 2
        fi
    ;;
    "i")
        # Get overall SMART health information: usually "PASSED" if all is well
        if [[ $Device == *nvme* ]] && [[ -e "$NVME_PATH" ]]; then
            $NVME_PATH list | grep "$Device" | cut -c18-78 | awk '{print $2 "_" $3 "_" $4 "_" $1}' | tr -s '_'
        else
            name=$($SMARTCTL_PATH -i $Device | grep -E "Device Model:|Model Number:|Serial Number:" | awk 'NF>1{print $NF}')
            echo ${name/$'\n'/_}
        fi
        exit 0
    ;;
    "?")
        echo "Unknown option $OPTARG"
        exit 1
    ;;
    ":")
        echo "No argument value for option $OPTARG"
        exit 1
    ;;
    *)
        # This should not occur!
        echo "ERROR on `hostname` in $0"
        exit 1
    ;;
    esac
done
