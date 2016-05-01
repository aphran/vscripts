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
vmdir=/vms

existordie ${fmasters}
existordie ${fvms}
existordie ${vmdir}

masters=$( cat ${fmasters} )
vms=$( cat ${fvms} )

qemubin=$( which qemu-system-x86_64 )
if [ ! -x ${qemubin} ]; then
    echo "Can't execute ${qemubin}" >&2
    exit 3
fi

ext=qcow2

vncid=2
vncopt=''

basemac=52:54:00:12:34:60

machead=${basemac%:*}
mactail=${basemac##*:}

function startvm () {
    thisvm=${1}
    if [ -z ${thisvm} ]; then
        echo "Expected VM name as first parameter, got none" >&2
        return 1
    fi

    cores=${2:-8}
    mem=${3:-16G}

    vmpath=${vmdir}/${thisvm}.${ext}
    if [ -f ${vmpath} ]; then
        echo " [start]  ${thisvm} on ${host}:${vncid} w/mac ${machead}:${mactail}"
        ${qemubin} -enable-kvm -cpu host -smp ${cores} -m ${mem} -hda ${vmpath} -net nic,macaddr=${machead}:${mactail} -net bridge,name=vlan0,br=br0 -daemonize -vnc ${vncopt}:${vncid} 2>/dev/null
        (( mactail++ ))
        (( vncid++ ))
        sleep 1s
    else
        echo "VM not found: ${vmpath}" >&2
    fi  
}

# bring up controller VMs
for vm in ${masters[@]}; do
    startvm ${vm}
done

# bring up worker VMs
for vm in ${vms[@]}; do
    startvm ${vm}
done
