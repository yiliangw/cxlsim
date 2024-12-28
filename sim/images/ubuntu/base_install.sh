#!/bin/bash

# These groups will only take effect from the next login
sudo usermod -aG sudo $USER
sudo usermod -aG disk $USER
sudo usermod -aG kvm $USER

mkdir -p /tmp/input
tar xf /tmp/input.tar -C /tmp/input

cp -r /tmp/input/devstack $HOME

# Do not wait for the network during boot
sudo systemctl mask systemd-networkd-wait-online

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y net-tools
