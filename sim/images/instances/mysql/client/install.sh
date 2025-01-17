#!/bin/bash

set -xe

sudo systemctl mask systemd-networkd-wait-online

sudo apt-get update
sudo apt-get install -y net-tools mysql-client
