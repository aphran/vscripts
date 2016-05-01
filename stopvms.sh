#!/usr/bin/env bash

function existordie () {
    thefile=${1}
    if [ -z ${thefile} ]; then
        echo "Expected a file name as first parameter, got none" >&2
        return 1
    fi

    if [ ! -f ${thefile} ] && [ ! -d ${thefile} ]; then
        echo "Invalid file: ${thefile}" >&2
        exit 1
    fi
    if [ ! -r ${thefile} ]; then
        echo "Can't read file: ${thefile}" >&2
        exit 2
    fi
}

host=$(hostname)
fmasters=/srv/bin/vms-masters
fvms=/srv/bin/vms

existordie ${fmasters}
existordie ${fvms}

masters=$( cat ${fmasters} )
vms=$( cat ${fvms} )

user=auto

function stopvm () {
    thisvm=${1}
    if [ -z ${thisvm} ]; then
        echo "Expected VM name as first parameter, got none" >&2
        return 1
    fi
    ssh ${thisvm} poweroff &
}

# bring down controller VMs
for vm in ${masters[@]}; do
    stopvm ${vm}
done

# bring down worker VMs
for vm in ${vms[@]}; do
    stopvm ${vm}
done
