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
read -p "Do you want to create a new user and delete default one? (y/N): " createUser
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
read -p "Do you want to improve ssh connectivity? (y/N): " improveSsh
if [ "$improveSsh" == "y" ]
then
    echo "Improving ssh connectivity";
    sudo /etc/init.d/ssh restart;
    echo "AllowUsers $user" >> /etc/ssh/sshd_config;
    echo "DenyUsers pi";
    exit;
fi


# setting static ip
read -p "Do you want to set a static ip? (y/N): " setStaticIp
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
read -p "Do you want to install nodejs? (y/N): " installNode
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
read -p "Do you want to install and configure homebridge? (y/N): " installHomebridge
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

    cp  ./raspi-setupconf/conf/loxone.config.json .homebridge/config.json

    sed  s/$env.port/$port/g >> .homebridge/config.json
    sed  s/$env.username/$username/g >> .homebridge/config.json
    sed  s/$env.password/$password/g >> .homebridge/config.json

    sudo cp ./raspi-setupconf/homebridge.default /etc/homebridge

    sudo cp  ./raspi-setupconfig/homebridge.service /etc/systemd/system/homebridge.service

    sudo mkdir /var/homebridge
    sudo cp ~/.homebridge/config.json /var/homebridge/
    sudo cp -r ~/.homebridge/persist /var/homebridge
    sudo chmod -R 0664 /var/homebridge
    sudo systemctl daemon-reload
    sudo systemctl enable homebridge
    sudo systemctl start homebridge
    systemctl status homebridge
fi


# some raspi configurations
read -p "Do you want to configure raspberry? (y/N): " raspiSetup
if [ "$raspiSetup" == "y" ]
then
    sudo raspi-config
fi

read -p "Do you want to reboot now? (y/N): " rebootNow
if [ "$rebootNow" == "y" ]
then
    sudo reboot
fi
