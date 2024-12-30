#!/bin/bash

mkdir -p /tmp/input
cd /tmp/input
tar xf /tmp/input.tar

source ${HOME}/passwdrc
source var

sudo -E bash -c "echo $HOSTNAME > /etc/hostname"

# netplan
sudo rm -rf /etc/netplan/*
sudo cp netplan/* /etc/netplan

# chrony
sudo cp chrony/chrony.conf /etc/chrony

if [ -f special/install.sh ]; then
  bash special/install.sh
fi
