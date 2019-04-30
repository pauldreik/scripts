#!/bin/sh
#take the date from the http headers. idea from hanno böck.
#
# Paul Dreik 20190308
set -e

#curl exits nonzero if the host can't be reached, but that is
#not exposed outside
str=$(curl -sI https://ftp.acc.umu.se/ |grep -i ^date: |cut -f2- -d:)

if [ -z "$str" ] ; then
    echo "date string is empty - failed to reach the remote server?"
    exit 1
else
    date -s "$str"
fi

