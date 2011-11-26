#!/bin/bash

for i in $(seq 99)
do
    j=$(printf "sim%02d" $i)
    if [ -e "/opt/opensim/config/$j" ]
    then
	sudo chown -R opensim:opensim /opt/opensim/config/$j
	sudo ln -s /opt/opensim/config/$j/opensim-monit.conf /etc/monit/conf.d/$j.conf
    fi
done

sudo chmod 755 /var/log/opensim
sudo chmod 755 /var/run/opensim
sudo chown -R opensim:opensim /opt/opensim/opensim-0.7.1.1-infinitegrid-03
sudo chown -R opensim:opensim /opt/opensim/modules

