#!/bin/bash

#AND-split-one-M.wsql

DBS='user=andsom'

intexit(){
    kill -HUP -$$
}
hupexit(){
    echo
    echo "Done"
    exit
}

trap intexit INT
trap hupexit HUP

python ../workers/handyman.py '1' $DBS "d2='1'" 5 &
python ../workers/handyman.py '2' $DBS "d3='1'" 5 &
python ../workers/handyman.py '3' $DBS "d4='1'" 5 &
python ../workers/handyman.py '4' $DBS "d5='1'" &

wait
