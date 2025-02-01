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

export DEBIAN_FRONTEND=noninteractive && sudo -E apt-get install -y \
  build-essential \
  libncurses-dev \
  bison \
  flex \
  libssl-dev \
  libelf-dev \
  bc \
  dwarves

mkdir ~/input
cd ~/input
sudo tar xf /dev/sdb
sudo chown -R $(id -u):$(id -g) .

cd linux
cp /boot/config-* .config
./scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
./scripts/config --disable MODULE_SIG_CERT
./scripts/config --disable SYSTEM_REVOCATION_KEYS

./scripts/config --disable CONFIG_WIRELESS
./scripts/config --disable CONFIG_CFG80211
./scripts/config --disable CONFIG_MAC80211
./scripts/config --disable CONFIG_IWLWIFI

yes "" | make oldconfig

make -j$(nproc)
sudo make modules_install
sudo make install

sudo mkdir /output
sudo cp .config /output/config
sudo cp vmlinux /output/vmlinux
sudo cp arch/x86/boot/bzImage /output/bzImage
