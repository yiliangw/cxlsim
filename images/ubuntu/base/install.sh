#!/bin/bash

set -xe

# These groups will only take effect from the next login
sudo usermod -aG sudo $USER
sudo usermod -aG disk $USER
sudo usermod -aG kvm $USER

# Do not wait for the network during boot
sudo systemctl mask systemd-networkd-wait-online

# OpenStack 2024.1 (Caracal)
sudo add-apt-repository -y cloud-archive:caracal
sudo apt-get update
