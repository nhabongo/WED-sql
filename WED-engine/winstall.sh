#!/bin/bash

TEMPLATE='wed_worker_template'
DB=$1
WORKER=${DB}_worker
USER=$2
CONFIG=$3

if [[ $# < 3 ]]
then
	echo "$0 <database name> <wedflow user> <postgresql.conf file>"
	exit 1
elif [[ $UID != 0 ]]
then
	echo "Need to be root!"
	exit 1
elif [[ ! -f $3 ]]
then
	echo "File $3 not found"
	exit 1
fi
echo -e "Generating new WED-flow"
echo -n "New password for user $USER :" 
read -s PASSX
echo -ne "\nNew password for user $USER :" 
read -s PASSY
echo ''

if [[ $PASSX != $PASSY ]]
then
    echo "Passwords don't match, aborting ..."
    exit 1 
fi

sudo -u postgres psql -c "CREATE ROLE $USER WITH LOGIN PASSWORD '$PASSX' ;" &&
sudo -u postgres psql -c "CREATE DATABASE $DB ;"
if [[ $? != 0 ]]
then
    exit 1
fi 
echo -e  "Generating new bg_worker ..."
rm -rf $WORKER > /dev/null 2>&1
cp -r $TEMPLATE $WORKER
cd $WORKER
rename wed_worker $WORKER *
sed -i "s/wed_worker/$WORKER/g" *
sed -i "s/__DB_NAME__/\"$DB\"/" $WORKER.c
make > /dev/null

echo -e "Installing bg_worker ...\n"
make install
cd ../
echo ""
python pg_worker_register.py $WORKER $CONFIG 
if [[ $? != 0 ]]
then
	cd $WORKER
	make uninstall
else
	echo -e "Restarting postgresql server ..."
	systemctl restart postgresql
fi

echo "DONE !"
exit 0
