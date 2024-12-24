#!/bin/bash

input_d=${HOME}/input
mkdir -p $input_d
tar xf /dev/sdc -C $input_d

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y net-tools

# Do not wait for the network during boot
sudo systemctl mask systemd-networkd-wait-online
