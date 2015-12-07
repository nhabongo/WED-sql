#!/bin/bash

#OR-split-mm_v2.wsql

DBS='user=orsmm_v2'

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

python ../workers/handyman.py '1' $DBS "d4='1'" &
python ../workers/handyman.py '2' $DBS "d5='1'" &
python ../workers/handyman.py '3' $DBS "d6='1'" &
python ../workers/handyman.py '4' $DBS "n4='1',d7=d7::integer + 1" &
python ../workers/handyman.py '5' $DBS "n5='1',d7=d7::integer + 1" &
python ../workers/handyman.py '6' $DBS "n6='1',d7=d7::integer + 1" &

wait
