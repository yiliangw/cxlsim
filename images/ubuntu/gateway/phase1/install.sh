#!/bin/bash

set -eux

if sudo growpart /dev/sda 1; then
  sudo resize2fs /dev/sda1
else
  echo "Root partition cannot be grown"
fi

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update && sudo -E apt-get install -y \
  net-tools \
  isc-dhcp-server \
  iptables \
  iptables-persistent \
  dnsmasq
