#!/bin/bash
set -xe

sudo usermod -aG disk $USER

sudo apt-get update
sudo apt-get install -y net-tools mysql-client

mkdir ~/input
sudo tar -xf /dev/sdb -C ~/input  
sudo chown -R $USER:$USER ~/input
