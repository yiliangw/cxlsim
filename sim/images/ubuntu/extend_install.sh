#!/bin/bash

mkdir -p /tmp/input
cd /tmp/input
tar xf /tmp/input.tar

source passwdrc
source var

sudo -E bash -c "echo $HOSTNAME > /etc/hostname"

# netplan
sudo rm -rf /etc/netplan/*
sudo cp netplan/* /etc/netplan

# chrony
sudo cp chrony/chrony.conf /etc/chrony

# openstack
cp devstack/local.conf ${HOME}/devstack

# hostnames
sudo cp hosts /etc/hosts 

if [ -f special/install.sh ]; then
  bash special/install.sh
fi
