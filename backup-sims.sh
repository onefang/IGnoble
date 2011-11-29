#!/bin/bash

OSPATH="/opt/opensim"

for i in $(seq 99)
do
    j=$(printf "sim%02d" $i)
    if [ -e "$OSPATH/config/$j" ]
    then
	cd $OSPATH/config/$j
	./backup-sim
	# sleep for three minutes, so that there is plenty of time to do the backup, 
	# and we are not keeping the computer very busy if there are lots of sims.
	sleep 180
    fi
done
