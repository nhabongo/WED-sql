#!/bin/bash

#AND-split.wsql

DBS='user=ands'

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

python ../workers/handyman.py '1' $DBS "d2='1'" &
python ../workers/handyman.py '2' $DBS "d3='1'" &
python ../workers/handyman.py '3' $DBS "d4='1'" &

wait
