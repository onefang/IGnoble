#!/bin/bash

if [ x$1 = x ]
then
    MYSQL_PASSWORD="OpenSimSucks"
else
    MYSQL_PASSWORD=$1
fi
USER=$(whoami)

sudo apt-get install mysql-server screen mono-complete monit mc
sudo /etc/init.d/mysql restart

echo "Setting up mySQL"
mysql -u root -p -h localhost << zzzzEOFzzz
drop database opensim;
create database opensim;
drop user opensim;
drop user 'opensim'@'localhost';
FLUSH PRIVILEGES;
create user opensim identified by '$MYSQL_PASSWORD';
create user 'opensim'@'localhost' identified by '$MYSQL_PASSWORD';
grant all on opensim.* to opensim;
grant all on opensim.* to 'opensim'@'localhost';
FLUSH PRIVILEGES;
zzzzEOFzzz

echo "Setting up OpenSim"
sudo deluser opensim
sudo adduser --system --shell /bin/false --group opensim
sudo mkdir -p /var/log/opensim
sudo chown opensim:opensim /var/log/opensim
sudo chmod 777 /var/log/opensim
sudo mkdir -p /var/run/opensim
sudo chown opensim:opensim /var/run/opensim
sudo chmod 777 /var/run/opensim
sudo mkdir -p /opt/opensim
sudo chown $USER:$USER /opt/opensim

cd /opt/opensim
wget https://github.com/downloads/infinitegrid/InfiniteGrid-Opensim/opensim-0.7.1.1-infinitegrid-03.tar.bz2
tar xjf opensim-0.7.1.1-infinitegrid-03.tar.bz2
ln -s opensim-0.7.1.1-infinitegrid-03 current
mkdir -p config
mkdir -p modules
mkdir -p setup
cp setup/opensim-crontab.txt config
cat setup/opensim-crontab.txt | sudo crontab -u opensim -

cd current/bin
mv OpenSim.Forge.Currency.dll ../../modules/
ln -s ../../modules/OpenSim.Forge.Currency.dll OpenSim.Forge.Currency.dll
mv OpenSimSearch.Modules.dll ../../modules/
ln -s ../../modules/OpenSimSearch.Modules.dll OpenSimSearch.Modules.dll
mv NSLModules.Messaging.MuteList.dll ../../modules/
ln -s ../../modules/NSLModules.Messaging.MuteList.dll NSLModules.Messaging.MuteList.dll
mv OpenSimProfile.Modules.dll ../../modules/
ln -s ../../modules/OpenSimProfile.Modules.dll OpenSimProfile.Modules.dll
#sudo chown -R opensim:opensim ../../modules
ln -s ../../config config

cat > OpenSim.ConsoleClient.ini << zzzzEOFzzzz
[Startup]
    ; Set here or use the -user command-line switch
    user = RestingUser

    ; Set here or use the -host command-line switch
    host = localhost

    ; Set here or use the -port command-line switch
    ; port = 9002

    ; Set here or use the -pass command-line switch
    ; Please be aware that this is not secure since the password is in the clear
    ; we recommend the use of -pass wherever possible
    pass = SecretRestingPLace
zzzzEOFzzzz

sed -i 's@<appender name="LogFileAppender" type="log4net.Appender.FileAppender">@<appender name="LogFileAppender" type="log4net.Appender.RollingFileAppender">@' OpenSim.exe.config
sed -i 's@; ConsoleUser = "Test"@ConsoleUser = "RestingUser"@' OpenSim.ini
sed -i 's@; ConsolePass = "secret"@ConsolePass = "SecretRestingPlace"@' OpenSim.ini

cd config-include/
sed -i 's@Include-Storage = "config-include/storage/SQLiteStandalone.ini";@; Include-Storage = "config-include/storage/SQLiteStandalone.ini";@' GridCommon.ini
sed -i 's@; StorageProvider = "OpenSim.Data.MySQL.dll"@StorageProvider = "OpenSim.Data.MySQL.dll"@' GridCommon.ini
sed -i "s@; ConnectionString = \"Data Source=localhost;Database=opensim;User ID=opensim;Password=\*\*\*\*;\"@ConnectionString = \"Data Source=localhost;Database=opensim;User ID=opensim;Password=$MYSQL_PASSWORD;\"@" GridCommon.ini

cd ../../..
#sudo chown -R opensim:opensim opensim-0.7.1.1-infinitegrid-03

