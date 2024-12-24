#!/bin/bash

# These groups will only take effect from the next login
sudo usermod -aG sudo $USER
sudo usermod -aG disk $USER
sudo usermod -aG kvm $USER

input_d=${HOME}/input
mkdir -p $input_d
sudo chmod a+r /dev/sdc
tar xf /dev/sdc -C $input_d

# Do not wait for the network during boot
sudo systemctl mask systemd-networkd-wait-online

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y net-tools
