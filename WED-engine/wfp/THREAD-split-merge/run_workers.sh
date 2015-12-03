#!/bin/bash

#thread-split-merge.wsql

DBS='user=tsm'

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

python ../workers/handyman.py '1' $DBS "d2=d2::integer + 1" &
python ../workers/handyman.py '2' $DBS "d2=d2::integer + 1" &
python ../workers/handyman.py '3' $DBS "d2=d2::integer + 1" &
python ../workers/handyman.py '4' $DBS "d3='1'" &

wait
