#!/bin/bash

TEMPLATE='wed_worker_template'
DB=$1
WORKER=${DB}_worker
CONFIG=$2

if [[ $# < 2 ]]
then
	echo "$0 <database name> <postgresql.conf file>"
	exit 1
elif [[ $UID != 0 ]]
then
	echo "Need to be root!"
	exit 1
elif [[ ! -f $2 ]]
then
	echo "File $2 not found"
	exit 1
fi

echo -e "Removing bg_worker ...\n"
python pg_worker_unregister.py $WORKER $CONFIG 
if [[ $? == 0 ]]
then
	rm -f '/usr/share/postgresql/extension'/${WORKER}.control
    rm -f '/usr/share/postgresql/extension'/${WORKER}--1.0.sql
    rm -f '/usr/lib/postgresql'/${WORKER}.so

	echo -e "Restarting postgresql server ..."
	systemctl restart postgresql
fi

echo "DONE !"
exit 0
