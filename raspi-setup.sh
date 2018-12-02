#!/bin/bash

# DOCS
# https://github.com/nfarina/homebridge
# https://github.com/Sroose/homebridge-loxone-ws
# https://www.raspberrypi.org/learning/networking-lessonsr/pi-static-ip-address
# https://www.instructables.com/id/Install-Nodejs-and-Npm-on-Raspberry-Pi/
# https://timleland.com/setup-homebridge-to-start-on-bootup/


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
    deluser -remove-home pi;
fi


# improve ssh security
read -p "Do you want to improve ssh connectivity? (y/N): " improveSsh
if [ "$improveSsh" == "y" ]
then
    echo "Improving ssh connectivity";
    sudo /etc/init.d/ssh restart;
    echo "AllowUsers $user" >> /etc/ssh/sshd_config;
    echo "DenyUsers pi";
fi

# raspberry version
REVCODE=$(sudo cat /proc/cpuinfo | grep 'Revision' | awk '{print $3}')
if [ "$REVCODE" = "a01041" ]; then
    PIMODEL="Raspberry Pi 2 Model B v1.0, 1 GB RAM"
fi

if [ "$REVCODE" = "a21041" ]; then
    # a21041 (Embest, China)
    PIMODEL="Raspberry Pi 2 Model B v1.1, 1 GB RAM"
fi

if [ "$REVCODE" = "a22042" ]; then
    PIMODEL="Raspberry Pi 2 Model B v1.2, 1 GB RAM"
fi

if [ "$REVCODE" = "a020d3" ]; then
    PIMODEL="Raspberry Pi 3 Model B, 1 GB RAM"
fi

# setting static ip
defaultIP=$(ip addr | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

read -p "Do you want to set a static IP? (y/N): " setStaticIp

if [ "$REVCODE" = "a020d3" ]; then
    read -p "Do you have a $PIMODEL, do you can use Wifi? (y/N):" setWifi
fi

if [ "$setStaticIp" == "y" ]
then
    echo "Setting up a static IP"
    echo "You default IP is:  $defaultIP"
    read -p "Do you want to use you default IP? (y/N):" setDefaultIp 
    
    if [ "$setDefaultIp" == "y" ]
    then
        echo "Setting up a default IP"
        defaultGateway=$(route -n|grep "UG"|grep -v "UGH"|cut -f 10 -d " ")
        ip_address=$defaultIP
        routers=$defaultGateway
        domain_name_servers=$defaultGateway

    else
        echo "Setting up a personal ip"
        read -p "Type the range you want: " range
        read -p "Type the ip you want: " ip
        ip_address="192.168.$range.$ip"
        routes="192.168.$range.1"
        domain_name_servers="192.168.$range.1"
    fi

    sudo echo "interface eth0" >> /etc/dhcpcd.conf
    sudo echo "static ip_address=$ip_address" >> /etc/dhcpcd.conf
    sudo echo "static routers=$routes" >> /etc/dhcpcd.conf
    sudo echo "static domain_name_servers=$domain_name_servers" >> /etc/dhcpcd.conf
fi

if [ "$setWifi" == "y" ]
then
    read -p "Wifi SSID: " wifiSSID
    read -p "Wifi Password: " wifiPassword
   
    {
    echo 'country=ES'
    echo ''
    echo 'network={'
	echo '   ssid="$wifiSSID"'
	echo '   psk="$wifiPassword"'
    echo '}'
    } >> /etc/wpa_supplicant/wpa_supplicant.conf
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

    cp  ~/raspi-homebridge-setup/config/loxone.config.json .homebridge/config.json
    
    sed -i "s/envhost/$host/g" ~/.homebridge/config.json
    sed -i "s/envport/$port/g" ~/.homebridge/config.json
    sed -i "s/envusername/$username/g" ~/.homebridge/config.json
    sed -i "s/envpassword/$password:/g" ~/.homebridge/config.json

    cat ~/.homebridge/config.json

    sudo cp ~/raspi-homebridge-setup/config/homebridge.default /etc/homebridge

    sudo cp  ~/raspi-homebridge-setup/config/homebridge.service /etc/systemd/system/homebridge.service

    sudo mkdir /var/homebridge
    sudo mkdir /var/homebridge/persist
    sudo cp ~/.homebridge/config.json /var/homebridge/
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
