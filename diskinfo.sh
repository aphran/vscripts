#!/usr/bin/env bash

arg=${1}
sysdevs=$( ls -1 --color=none /dev/sd? )
devs=${arg:-${sysdevs}}

for ddev in ${devs[@]}; do
    printf "*** ${ddev} ***\n****************\n\n"
    printf "    *** lvm ***\n"
    pvdisplay ${ddev}
    printf "    *** hdparm ***\n"
    hdparm -I ${ddev}
    printf "\n"
done
