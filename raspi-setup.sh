#!/bin/bash

# DOCS
# https://github.com/nfarina/homebridge
# https://github.com/Sroose/homebridge-loxone-ws
# https://www.raspberrypi.org/learning/networking-lessons/rpi-static-ip-address/
# https://www.instructables.com/id/Install-Nodejs-and-Npm-on-Raspberry-Pi/
# https://timleland.com/setup-homidge-to-start-on-bootup/


# COMMANDS
cd


# create new user and remove the default one
read -p "Do you want to create a new user and delete default one? (y/n): " createUser
if [ "$createUser" = "y" ]
then
    echo "Creating new user. Which username you want?";
    read -p "Username: " user;
    sudo adduser $user;
    sudo adduser $user sudo;
    sudo su;
    sudo deluser pi;
    sudo deluser -remove-home pi;
fi


# improve ssh security
read -p "Do you want to improve ssh connectivity? (y/n): " improveSsh
if [ "$improveSsh" == "y" ]
then
    echo "Improving ssh connectivity";
    apt install openssh-server;
    echo "AllowUsers $user" >> /etc/ssh/sshd_config;
    echo "DenyUsers pi";
    exit;
fi


# setting static ip
read -p "Do you want to set a static ip? (y/n): " setStaticIp
if [ "$setStaticIp" == "y" ]
then
    echo "Setting up a static ip"
    read -p "Type the range you want: " range
    read -p "Type the ip you want: " ip
    sudo su
    echo "interface eth0" >> /etc/dhcpcd.conf
    echo "static ip_address=192.168.$range.$ip" >> /etc/dhcpcd.conf
    echo "static routers=192.168.$range.1" >> /etc/dhcpcd.conf
    echo "static domain_name_servers=192.168.$range.1" >> /etc/dhcpcd.conf
fi


# install nodejs
read -p "Do you want to install nodejs? (y/n): " installNode
if [ "$installNode" == "y" ]
then
    wget https://nodejs.org/dist/v9.9.0/node-v9.9.0-linux-armv6l.tar.gz
    tar -xzf node-v9.9.0-linux-armv6l.tar.gz
    cd node-v9.9.0-linux-armv6l/
    sudo cp -R * /usr/local/
    node -v
    npm -v
    cd
fi


# install and configure homebridge
read -p "Do you want to install and configure homebridge? (y/n): " installHomebridge
if [ "$installHomebridge" == "y" ]
then
    echo "Installing homebridge"
    npm install --global homebridge
    echo "Installing loxone plugin"
    npm install --global homebridge-loxone-ws
    echo "Configuring Loxone platform"
    read -p "Host: " host
    read -p "Port: " port
    read -p "Username: " username
    read -p "Password: " password

    mkdir -p .homebridge
    touch .homebridge/config.json

    echo "{" >> .homebridge/config.json
    echo "    \"bridge\": {" >> .homebridge/config.json
    echo "        \"name\": \"Homebridge\"," >> .homebridge/config.json
    echo "        \"username\": \"CA:AA:12:34:56:78\"," >> .homebridge/config.json
    echo "        \"port\": 51826," >> .homebridge/config.json
    echo "        \"pin\": \"012-34-567\"" >> .homebridge/config.json
    echo "    }," >> .homebridge/config.json
    echo "    \"description\": \"Your config file.\"," >> .homebridge/config.json
    echo "    \"platforms\": [" >> .homebridge/config.json
    echo "        {" >> .homebridge/config.json
    echo "            \"platform\": \"LoxoneWs\"," >> .homebridge/config.json
    echo "            \"name\": \"Loxone\"," >> .homebridge/config.json
    echo "            \"host\": \"$host\"," >> .homebridge/config.json
    echo "            \"port\": \"$port\"," >> .homebridge/config.json
    echo "            \"username\": \"$username\"," >> .homebridge/config.json
    echo "            \"password\": \"$password\"" >> .homebridge/config.json
    echo "        }" >> .homebridge/config.json
    echo "    ]" >> .homebridge/config.json
    echo "}" >> .homebridge/config.json

    echo "# Defaults / Configuration options for homebridge" >> /etc/default/homebridge
    echo "# The following settings tells homebridge where to find the config.json file and where to persist the data (i.e. pairing and others)" >> /etc/default/homebridge
    echo "HOMEBRIDGE_OPTS=-U /var/homebridge" >> /etc/default/homebridge
    echo "" >> /etc/default/homebridge
    echo "# If you uncomment the following line, homebridge will log more " >> /etc/default/homebridge
    echo "# You can display this via systemd's journalctl: journalctl -f -u homebridge" >> /etc/default/homebridge
    echo "# DEBUG=*" >> /etc/default/homebridge

    sudo echo "[Unit]" >> /etc/systemd/system/homebridge.service
    sudo echo "Description=Node.js HomeKit Server " >> /etc/systemd/system/homebridge.service
    sudo echo "After=syslog.target network-online.target" >> /etc/systemd/system/homebridge.service
    sudo echo "" >> /etc/systemd/system/homebridge.service
    sudo echo "[Service]" >> /etc/systemd/system/homebridge.service
    sudo echo "Type=simple" >> /etc/systemd/system/homebridge.service
    sudo echo "User=homebridge" >> /etc/systemd/system/homebridge.service
    sudo echo "EnvironmentFile=/etc/default/homebridge" >> /etc/systemd/system/homebridge.service
    sudo echo "ExecStart=$(which homebridge) $HOMEBRIDGE_OPTS" >> /etc/systemd/system/homebridge.service
    sudo echo "Restart=on-failure" >> /etc/systemd/system/homebridge.service
    sudo echo "RestartSec=10" >> /etc/systemd/system/homebridge.service
    sudo echo "KillMode=process" >> /etc/systemd/system/homebridge.service
    sudo echo "" >> /etc/systemd/system/homebridge.service
    sudo echo "[Install]" >> /etc/systemd/system/homebridge.service
    sudo echo "WantedBy=multi-user.target" >> /etc/systemd/system/homebridge.service

    sudo mkdir /var/homebridge
    sudo cp ~/.homebridge/config.json /var/homebridge/
    sudo cp -r ~/.homebridge/persist /var/homebridge
    sudo chmod -R 0777 /var/homebridge
    sudo systemctl daemon-reload
    sudo systemctl enable homebridge
    sudo systemctl start homebridge
    systemctl status homebridge
fi


# some raspi configurations
read -p "Do you want to configure raspberry? (y/n): " raspiSetup
if [ "$raspiSetup" == "y" ]
then
    sudo raspi-config
fi

read -p "Do you want to reboot now? (y/n): " rebootNow
if [ "$rebootNow" == "y" ]
then
    sudo reboot
fi
