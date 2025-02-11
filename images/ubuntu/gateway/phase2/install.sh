#!/bin/bash
set -xe

mkdir -p /tmp/input
pushd /tmp/input

tar xf /dev/sdb

# Configure network interfaces
sudo rm -rf /etc/netplan/*
sudo cp netplan.yaml /etc/netplan/99-netplan-config.yaml
sudo chmod 600 /etc/netplan/99-netplan-config.yaml
sudo netplan apply

# Enalbe IP forwarding
sudo sed -i 's/^#\?net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p

# Setup DHCP server
sudo tee /etc/default/isc-dhcp-server < isc-dhcp-server > /dev/null
sudo tee /etc/dhcp/dhcpd.conf < dhcpd.conf > /dev/null
sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server

popd
rm -rf /tmp/input

