#!/bin/bash

NAME=$1
LOCATION=$2
URL=$3
IP=$4

cd /opt/opensim/config

k=0
for i in $(seq 99)
do
    j=$(printf "sim%02d" $i)
    if [ -e "$j" ]
    then 
	k=$i
    fi
done

if [ "x$NAME" = "x" ]
then
    NAME="No name sim $RANDOM"	# Should be unique per grid.
fi

if [ "x$LOCATION" = "x" ]
then
    LOCATION="$RANDOM,$RANDOM"	# again UNIQUE (i.e. ONLY ONE) per grid in THIS case!
fi

if [ "x$URL" = "x" ]
then
    URL=$(hostname)		# URL is best (without the HTTP://), but IP (e.g. 88.109.81.55) works too.
fi

if [ "x$IP" = "x" ]
then
    IP="0.0.0.0"		# 0.0.0.0 will work for a single sim per physical machine, otherwise we need the real internal IP.
fi

NUM=$(printf "%02d" $(($k + 1)) )
PORT=$(( 9005 + ($k * 5) ))	# 9002 is used for HTTP/UDP so START with port 9003! CAUTION Diva/D2 starts at port 9000.
UUID=$(uuidgen)

echo "Creating sim$NUM on port $PORT @ $LOCATION - $NAME."

mkdir -p sim$NUM/Regions
cd sim$NUM
cat > Regions/sim.ini << zzzzEOFzzzz
[$NAME]
RegionUUID = $UUID
Location = $LOCATION
InternalAddress = 0.0.0.0
InternalPort = $(( $PORT + 1 ))
AllowAlternatePorts = False
ExternalHostName = $URL
zzzzEOFzzzz

ln -s ../../setup/start-sim-in-rest start-sim-in-rest
#ln -s ../../current current
cp ../../current/bin/OpenSim.exe.config OpenSim.exe.config
sed -i "s@<file value=\"OpenSim.log\" />@<file value=\"/var/log/opensim/sim$NUM.log\" />@" OpenSim.exe.config

#cp current/bin/OpenSim.ini OpenSim.ini
#sed -i "s@regionload_regionsdir=\"/opt/opensim/config\"@regionload_regionsdir=\"/opt/opensim/config/sim$NUM/Regions\"@" OpenSim.ini
#sed -i "s@; PIDFile = \"/var/run/opensim/opensim.pid\"@PIDFile = \"/var/run/opensim/sim$NUM.pid\"@" OpenSim.ini
#sed -i "s@;http_listener_port = 9000@http_listener_port = $(( $PORT + 0))@" OpenSim.ini
#sed -i "s@; console_port = 0@console_port = $(( $PORT + 2 ))@" OpenSim.ini

cat > ThisSim.ini << zzzzEOFzzzz
[Startup]
    PIDFile = "/var/run/opensim/sim$NUM.pid"
    regionload_regionsdir="/opt/opensim/config/sim$NUM/Regions"

[Network]
    console_port = $(( $PORT + 2 ))
    http_listener_port = $(( $PORT + 0))
zzzzEOFzzzz

cp ../../current/bin/OpenSim.ConsoleClient.ini OpenSim.ConsoleClient.ini
sed -i "s@; port = 9002@port = $(( $PORT + 2 ))@" OpenSim.ConsoleClient.ini

cp ../../setup/opensim-monit.conf opensim-monit.conf
sed -i "s@sim01@sim$NUM@g" opensim-monit.conf

