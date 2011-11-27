#!/bin/bash

if [ x$1 = x ]
then
    MYSQL_PASSWORD="OpenSimSucks"
else
    MYSQL_PASSWORD=$1
fi
REST_USER="RestingUser"
REST_PASSWORD="SecretRestingPlace"

OSPATH="/opt/opensim"
USER=$(whoami)
VERSION_CONTROL="off"

sudo apt-get install mysql-server screen mono-complete monit mc
sudo /etc/init.d/mysql restart

echo "Setting up mySQL"
mysql -u root -p -h localhost << zzzzEOFzzz
create database if not exists opensim;
create user opensim identified by '$MYSQL_PASSWORD';
create user 'opensim'@'localhost' identified by '$MYSQL_PASSWORD';
grant all on opensim.* to opensim;
grant all on opensim.* to 'opensim'@'localhost';
FLUSH PRIVILEGES;
zzzzEOFzzz

echo "Setting up OpenSim"
sudo adduser --system --shell /bin/false --group opensim
sudo addgroup $USER opensim
sudo cp opensim.screenrc /home/opensim/.screenrc
sudo chown $USER /home/opensim/.screenrc
echo -e "acladd root,$USER\n" >> /home/opensim/.screenrc
sudo chown opensim:opensim /home/opensim/.screenrc
sudo chmod 644 /home/opensim/.screenrc
sudo mkdir -p /var/log/opensim
sudo chown opensim:opensim /var/log/opensim
sudo chmod 757 /var/log/opensim
sudo mkdir -p /var/run/opensim
sudo chown opensim:opensim /var/run/opensim
sudo chmod 757 /var/run/opensim
sudo mkdir -p $OSPATH/config $OSPATH/setup $OSPATH/caches/assetcache
sudo chown opensim:opensim $OSPATH
sudo chown -R opensim:opensim $OSPATH
sudo chmod -R 757 $OSPATH
cp * $OSPATH/setup
cp common.ini $OSPATH/config
sed -i "s@MYSQL_PASSWORD@$MYSQL_PASSWORD@g" $OSPATH/config/common.ini
sed -i "s@REST_PASSWORD@$REST_PASSWORD@g" $OSPATH/config/common.ini
sed -i "s@REST_USER@$REST_USER@g" $OSPATH/config/common.ini
cat opensim-crontab.txt | sudo crontab -u opensim -

cd $OSPATH
if [ ! -e opensim-0.7.1.1-infinitegrid-03.tar.bz2 ]
then
    wget https://github.com/downloads/infinitegrid/InfiniteGrid-Opensim/opensim-0.7.1.1-infinitegrid-03.tar.bz2
fi
if [ ! -e opensim-0.7.1.1-infinitegrid-03 ]
then
    tar xjf opensim-0.7.1.1-infinitegrid-03.tar.bz2
fi
ln -fs opensim-0.7.1.1-infinitegrid-03 current

# Create the REST client config file.
cat > config/OpenSim.ConsoleClient.ini << zzzzEOFzzzz
[Startup]
    ; Set here or use the -user command-line switch
    user = $REST_USER

    ; Set here or use the -host command-line switch
    host = localhost

    ; Set here or use the -port command-line switch
    ; port = 9002

    ; Set here or use the -pass command-line switch
    ; Please be aware that this is not secure since the password is in the clear
    ; we recommend the use of -pass wherever possible
    pass = $REST_PASSWORD
zzzzEOFzzzz

cd current/bin
# Not sure why we are moving these.  Hopefully we can get rid of having to move them.
# Comenting them out, until Alice or Rizzy remember why they seed to be moved.  See if things still work.
#mv -f OpenSim.Forge.Currency.dll ../../modules/
#ln -fs ../../modules/OpenSim.Forge.Currency.dll OpenSim.Forge.Currency.dll
#mv -f OpenSimSearch.Modules.dll ../../modules/
#ln -fs ../../modules/OpenSimSearch.Modules.dll OpenSimSearch.Modules.dll
#mv -f NSLModules.Messaging.MuteList.dll ../../modules/
#ln -fs ../../modules/NSLModules.Messaging.MuteList.dll NSLModules.Messaging.MuteList.dll
#mv -f OpenSimProfile.Modules.dll ../../modules/
#ln -fs ../../modules/OpenSimProfile.Modules.dll OpenSimProfile.Modules.dll

ln -fs ../../config config
mv -f addon-modules ../../config
ln -fs ../../config/addon-modules addon-modules

# Try to make the OS distro directory suited to being read only.
ln -fs ../../caches caches
mv -f ScriptEngines ../../caches
ln -fs ../../caches/ScriptEngines ScriptEngines
# Grumble, OS has it's own silly ideas, and recreates this.
# "Cannot create /opt/opensim/opensim-0.7.1.1-infinitegrid-03/bin/addin-db-001 because a file with the same name already exists."
#ln -fs ../../caches/addin-db-001 addin-db-001

cd config-include/
# Damn, can't overide these, we could change them for the next IG OS release.
sed -i 's@Include-Storage = "config-include/storage/SQLiteStandalone.ini";@; Include-Storage = "config-include/storage/SQLiteStandalone.ini";@' GridCommon.ini
sed -i 's@CacheDirectory = ./assetcache@CacheDirectory = caches/assetcache@' FlotsamCache.ini
cd ../../..

# Setting screen to be suid.  EWWWWWW!!!  Security hole!!
#ImReallyParanoid="true"
if [ "x$ImReallyParanoid" = "x" ]
then
    sudo chmod u+s /usr/bin/screen
    sudo chmod g+s /usr/bin/screen
    sudo chmod 755 /var/run/screen
    sudo chown root:utmp /var/run/screen
fi

sudo chown -R opensim:opensim $OSPATH
sudo chmod -R a-x $OSPATH
sudo chmod -R a+X $OSPATH
sudo chmod -R g+w $OSPATH
sudo chmod a+x $OSPATH/setup/start-sim

