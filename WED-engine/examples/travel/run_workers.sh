#!/bin/bash

#XOR-split-join.wsql

DBS='user=travel'

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

python workers/handyman.py '1' $DBS "customer_status='validated',air_ticket_status='requested',hotel_status='requested',order_status='validated'"  15&
python workers/handyman.py '2' $DBS "hotel_status='reserved',hotel_id='H3333'" &
python workers/handyman.py '3' $DBS "air_ticket_status='purchased',air_ticket_id='AT7777'" &
python workers/handyman.py '4' $DBS "order_status='finalized'" &

wait
