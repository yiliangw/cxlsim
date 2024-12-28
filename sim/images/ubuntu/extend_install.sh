#!/bin/bash

mkdir -p /tmp/input
cd /tmp/input
tar xf /tmp/input.tar

source var

sudo -E bash -c "echo $HOSTNAME > /etc/hostname"

# netplan
sudo rm -rf /etc/netplan/*
sudo cp netplan/* /etc/netplan

# openstack
cp devstack/local.conf ${HOME}/devstack

# common
sudo cp hosts /etc/hosts 
