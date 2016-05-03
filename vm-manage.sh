#!/usr/bin/env bash

function _exists () {
    local thefile=${1}
    if [ -z ${thefile} ]; then
        echo "Expected a path as first parameter, got none" >&2
        return 1
    fi

    if [ ! -f ${thefile} ] && [ ! -d ${thefile} ]; then
        echo "Invalid path: ${thefile}" >&2
        return 2
    fi
    if [ ! -r ${thefile} ]; then
        echo "Can't read path: ${thefile}" >&2
        return 3
    fi
    return 0
}

function _existsordie () {
    local thefile=${1}
    local msg=$( _exists ${thefile} )
    local ret=${?}
    if [ 0 -ne ${ret} ]; then
        echo "${msg}"
        exit ${ret}
    fi
}

wd=$( dirname $( realpath ${0} ) )
self=$( basename ${0} )
action=${1:-start}
host=$(hostname)

invdir=${wd}/inventory
fmasters=${invdir}/vms-masters
fworkers=${invdir}/vms-workers
vmdir=/vms

_existsordie ${vmdir}

_exists ${fmasters}
[ 0 -eq ${?} ] && masters=$( cat ${fmasters} ) || masters=""

_exists ${fworkers}
[ 0 -eq ${?} ] && workers=$( cat ${fworkers} ) || workers=""

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

function _vmstart () {
    local thisvm=${1}
    if [ -z ${thisvm} ]; then
        echo "Expected VM name as first parameter, got none" >&2
        return 1
    fi

    local cores=${2:-8}
    local mem=${3:-16G}

    local vmpath=${vmdir}/${thisvm}.${ext}
    if [ -f ${vmpath} ]; then
        echo "[start]  ${thisvm} on ${host}:${vncid} w/mac ${machead}:${mactail}"
        ${qemubin} -enable-kvm -daemonize -cpu host -net bridge,name=vlan0,br=br0 -hda ${vmpath} -smp ${cores} -m ${mem} -net nic,macaddr=${machead}:${mactail} -vnc ${vncopt}:${vncid} 2>>/dev/null &
        (( mactail++ ))
        (( vncid++ ))
        #sleep 1s
    else
        echo "[error]  VM not found: ${vmpath}" >&2
    fi  
}

function _vmstop () {
    local thisvm=${1}
    local stopcmd="poweroff"
    if [ -z ${thisvm} ]; then
        echo "Expected VM name as first parameter, got none" >&2
        return 1
    fi
    echo "[stop]   ${thisvm}, sent ${stopcmd} command"
    ssh ${thisvm} "${stopcmd}" 2>>/dev/null &
}

function up () {
    # check that NO VMs are running
    [ -n "$( st 2>/dev/null )" ] && exit 4

    echo -e "\nStarting all VMs:\n"
    # bring up master VMs
    for vm in ${masters[@]}; do
        _vmstart ${vm} 2 4G
    done
    # bring up on worker VMs
    for vm in ${workers[@]}; do
        _vmstart ${vm}
    done; echo
}

function dn () {
    # check that some VMs are running   
    [ -z "$( st 2>/dev/null )" ] && exit 5

    echo -e "\nStopping all VMs:\n"
    # bring down master and worker VMs
    local allvms=( ${workers[@]} ${masters[@]} )
    for vm in "${allvms[@]}"; do
        _vmstop ${vm}
    done; echo
}

function st () {
    local vmprocs=$( pgrep -u root -a qemu-system )
    if [ -n "${vmprocs}" ]; then
        echo -e "\nCurrent running VMs:\n"
        vmprocs=$( echo 'PID HD P M MAC VNC'; echo "${vmprocs}" )
        echo -e "${vmprocs}\n" | sed -r -e 's/-[a-Z0-9-]+ //g' -e "s#${qemubin}.*br0 ##g" -e 's/nic.*=//g' | column -et
    else
        echo -e "\nNo VMs currently up\n" >&2
    fi
}

function h () {
    cat << EOF

Usage:

${self} <action>

Where <action> can be:

  h   -  show this usage information
  up  -  start all vms
  dn  -  stop all vms
  st  -  show vm info

EOF

}

# die if action starts with underscore '_'
if [ '_' == ${action:0:1} ]; then
    echo "Error: actions can't start with an underscore '_', with action ${action}" >&2
    exit 2
fi

# check action maps to a function or die
if [ -z $( declare -F ${action} ) ]; then
    echo "Invalid action '${action}'!" >&2
    h
    exit 3
fi

# execute action
${action}

#EOF
