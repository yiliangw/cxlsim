#!/bin/bash

set -xe

mkdir -p /tmp/input
cd /tmp/input
tar xf /tmp/input.tar

sudo tee /etc/hosts < hosts > /dev/null
sudo tee /etc/hostname < hostname > /dev/null
sudo rm -rf /etc/netplan/*
sudo cp netplan.yaml /etc/netplan/99-netplan-config.yaml
sudo chmod 600 /etc/netplan/99-netplan-config.yaml

cp -r env/ ${HOME}

if [ -f install.sh ]; then
  bash install.sh
fi
