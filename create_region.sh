#!/bin/bash

NAME=$1
LOCATION=$2
URL=$3
IP=$4

OSPATH="/opt/opensim"
cd $OSPATH/config

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
    echo "WARNING setting the sim name to [$NAME], this may not be what you want."
fi

if [ "x$LOCATION" = "x" ]
then
    LOCATION="$RANDOM,$RANDOM"	# again UNIQUE (i.e. ONLY ONE) per grid in THIS case!
    echo "WARNING setting the Location to $LOCATION, this may not be what you want."
fi

# Here we make use of an external IP finding service.  Careful, it may move.
# We later reuse the same IP for the default URL, coz that should work at least.
if [ "x$IP" = "x" ]
then
				# 0.0.0.0 will work for a single sim per physical machine, otherwise we need the real internal IP.
    IP=$(wget -q http://automation.whatismyip.com/n09230945.asp -O -)
    echo "WARNING setting the InternalAddress to $IP, this may not be what you want."
    echo "  0.0.0.0 will work for a single sim per physical machine, otherwise we need the real internal IP."
fi

if [ "x$URL" = "x" ]
then
    URL=$IP			# URL is best (without the HTTP://), but IP (e.g. 88.109.81.55) works too.
    echo "WARNING setting the ExternalHostName to $URL, this may not be what you want."
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
InternalAddress = $IP
InternalPort = $(( $PORT + 1 ))
AllowAlternatePorts = False
ExternalHostName = $URL
zzzzEOFzzzz

ln -s ../../setup/start-sim start-sim
ln -s ../../setup/backup-sim start-sim
ln -s ../../setup/sim-console start-sim
ln -s ../../setup/stop-sim start-sim
cp ../../current/bin/OpenSim.exe.config OpenSim.exe.config
sed -i 's@<appender name="LogFileAppender" type="log4net.Appender.FileAppender">@<appender name="LogFileAppender" type="log4net.Appender.RollingFileAppender">@' OpenSim.exe.config
sed -i "s@<file value=\"OpenSim.log\" />@<file value=\"/var/log/opensim/sim$NUM.log\" />@" OpenSim.exe.config

cat > ThisSim.ini << zzzzEOFzzzz
[Startup]
    PIDFile = "/var/run/opensim/sim$NUM.pid"
    regionload_regionsdir="$OSPATH/config/sim$NUM/Regions"
    DecodedSculptMapPath = "caches/sim$NUM/j2kDecodeCache"

[Network]
    console_port = $(( $PORT + 2 ))
    http_listener_port = $(( $PORT + 0))

[AssetCache]
    ;; Damn, this gets overidden later by the FlotsamCache.ini file.
    ;; At least it says it can be shared by multiple instances.
    ; CacheDirectory = "caches/sim$NUM/assetcache"

[XEngine]
    ScriptEnginesPath = "caches/sim$NUM/ScriptEngines"

[GridService]
    MapTileDirectory = "caches/sim$NUM/maptiles"

[DataSnapshot]
    snapshot_cache_directory = "caches/sim$NUM/DataSnapshot"

[Includes]
    Include-Common = config/common.ini

zzzzEOFzzzz
cp ../OpenSim.ConsoleClient.ini OpenSim.ConsoleClient.ini
sed -i "s@; port = 9002@port = $(( $PORT + 2 ))@" OpenSim.ConsoleClient.ini

cp ../../setup/opensim-monit.conf opensim-monit.conf
sed -i "s@sim01@sim$NUM@g" opensim-monit.conf
sudo chown -R opensim:opensim ..
sudo chmod -R g+w ..

