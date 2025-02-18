#!/bin/bash
set -xe

INPUT_TAR=${INPUT_TAR:-/dev/sdb}

mkdir -p /tmp/input
pushd /tmp/input

tar xf $INPUT_TAR

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
# Conflicts with neutron-dhcp-agent
# sudo systemctl restart isc-dhcp-server
# sudo systemctl enable isc-dhcp-server
sudo systemctl stop isc-dhcp-server
sudo systemctl mask isc-dhcp-server

sudo systemctl stop dnsmasq
sudo systemctl mask dnsmasq

popd
rm -rf /tmp/input

