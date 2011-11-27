#!/bin/bash

OSPATH="/opt/opensim"

for i in $(seq 99)
do
    j=$(printf "sim%02d" $i)
    if [ -e "$OSPATH/config/$j" ]
    then
	sudo chown -R opensim:opensim $OSPATH/config/$j
	sudo ln -s $OSPATH/config/$j/opensim-monit.conf /etc/monit/conf.d/$j.conf
    fi
done

sudo chmod 755 /var/log/opensim
sudo chmod 755 /var/run/opensim
sudo chown -R opensim:opensim $OSPATH/opensim-0.7.1.1-infinitegrid-03
sudo chown -R opensim:opensim $OSPATH/modules

