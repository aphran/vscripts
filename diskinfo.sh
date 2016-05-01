#!/usr/bin/env bash

devs=${1:-$( ls -1 /dev/sd? )}

for ddev in "${devs}"; do
    printf "*** ${ddev} ***\n\n"
    printf "    *** lvm ***\n"
    pvdisplay ${ddev}
    printf "    *** hdparm ***\n"
    hdparm -I ${ddev}
    printf "\n"
done
