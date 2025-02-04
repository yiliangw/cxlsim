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

mkdir /tmp/input
pushd /tmp/input
sudo tar xf /dev/sdb
sudo chown -R $(id -u):$(id -g) .

sudo cp guestinit.sh /sbin/guestinit.sh
sudo chmod +x /sbin/guestinit.sh
sudo cp m5 /sbin/m5
sudo chmod +x /sbin/m5

cp -r linux/ ~/linux
cd ~/linux
cp /boot/config-* .config
./scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
./scripts/config --disable MODULE_SIG_CERT
./scripts/config --disable SYSTEM_REVOCATION_KEYS

./scripts/config --disable CONFIG_WIRELESS
./scripts/config --disable CONFIG_CFG80211
./scripts/config --disable CONFIG_MAC80211
./scripts/config --disable CONFIG_IWLWIFI
./scripts/config --disable CONFIG_BT

./scripts/config --disable WLAN_VENDOR_INTEL
./scripts/config --disable WLAN_VENDOR_REALTEK
./scripts/config --disable WLAN_VENDOR_ATH
./scripts/config --disable WLAN_VENDOR_BROADCOM
./scripts/config --disable WLAN_VENDOR_CISCO
./scripts/config --disable WLAN_VENDOR_MARVELL
./scripts/config --disable WLAN_VENDOR_MEDIATEK
./scripts/config --disable WLAN_VENDOR_RSI
./scripts/config --disable WLAN_VENDOR_ST
./scripts/config --disable WLAN_VENDOR_TI

./scripts/config --disable CONFIG_SOUND
./scripts/config --disable CONFIG_INFINIBAND

yes "" | make oldconfig

make -j$(nproc)
sudo make modules_install
sudo make install

sudo mkdir /output
sudo cp .config /output/config
sudo cp vmlinux /output/vmlinux
sudo cp arch/x86/boot/bzImage /output/bzImage
sudo cp /boot/initrd.img /output/initrd.img

popd
rm -rf /tmp/input
