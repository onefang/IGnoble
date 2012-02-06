sudo apt-get install m4 gcc make autoconf automake gettext libtool
sudo useradd -r -l zabbix
if [ ! -e zabbix-1.8.5.tar.gz ]
then
    wget http://infinitegrid.org/zabbix-1.8.5.tar.gz
fi
if [ ! -e e zabbix-1.8.5 ]
then
    tar xzf zabbix-1.8.5.tar.gz
fi
cd zabbix-1.8.5
./configure --enable-agent
make
sudo make install
sudo /sbin/ldconfig
sudo mkdir /etc/zabbix
sudo cp misc/conf/* /etc/zabbix
# Edit those conf files to suit.
sudo cat > /etc/init/zabbix-agent.conf << zzzzEOFzzzz
    # zabbix-agent - Start zabbix agent
    description     "Zabbix Agent"
    author          "S. CANCHON"
    start on runlevel [2345]
    stop on runlevel [016]
    respawn
    expect daemon
    exec /usr/local/sbin/zabbix_agentd
zzzzEOFzzzz

sudo service zabbix_agent start
# Copy one of the /etc/init.d links to upstart thingy
sudo update-rc.d zabbix-agent defaults

