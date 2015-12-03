#!/bin/bash

#OR-split.wsql

DBS='user=orsssm'

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
python ../workers/handyman.py '4' $DBS "d7='1'" &

wait
