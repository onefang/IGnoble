#!/bin/bash

if [ x$1 = x ]
then
    MYSQL_PASSWORD="OpenSimSucks"
else
    MYSQL_PASSWORD=$1
fi
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
sudo mkdir -p /opt/opensim/config /opt/opensim/modules /opt/opensim/setup
sudo chown opensim:opensim /opt/opensim
sudo chown -R opensim:opensim /opt/opensim
sudo chmod -R 757 /opt/opensim
cp start-sim-in-rest /opt/opensim/setup
cp opensim-monit.conf /opt/opensim/setup
cat opensim-crontab.txt | sudo crontab -u opensim -

cd /opt/opensim
if [ ! -e opensim-0.7.1.1-infinitegrid-03.tar.bz2 ]
then
    wget https://github.com/downloads/infinitegrid/InfiniteGrid-Opensim/opensim-0.7.1.1-infinitegrid-03.tar.bz2
fi

if [ ! -e opensim-0.7.1.1-infinitegrid-03 ]
then
    tar xjf opensim-0.7.1.1-infinitegrid-03.tar.bz2
fi
ln -fs opensim-0.7.1.1-infinitegrid-03 current

cd current/bin
mv -f OpenSim.Forge.Currency.dll ../../modules/
ln -fs ../../modules/OpenSim.Forge.Currency.dll OpenSim.Forge.Currency.dll
mv -f OpenSimSearch.Modules.dll ../../modules/
ln -fs ../../modules/OpenSimSearch.Modules.dll OpenSimSearch.Modules.dll
mv -f NSLModules.Messaging.MuteList.dll ../../modules/
ln -fs ../../modules/NSLModules.Messaging.MuteList.dll NSLModules.Messaging.MuteList.dll
mv -f OpenSimProfile.Modules.dll ../../modules/
ln -fs ../../modules/OpenSimProfile.Modules.dll OpenSimProfile.Modules.dll
ln -fs ../../config config

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

# Setting screen to be suid.  EWWWWWW!!!  Security hole!!
#ImReallyParanoid="true"
if [ "x$ImReallyParanoid" = "x" ]
then
    sudo chmod u+s /usr/bin/screen
    sudo chmod g+s /usr/bin/screen
    sudo chmod 755 /var/run/screen
    sudo chown root:utmp /var/run/screen
fi

sudo chown -R opensim:opensim /opt/opensim
sudo chmod -R a-x *
sudo chmod -R a+X *
sudo chmod a+x /opt/opensim/setup/start-sim-in-rest

