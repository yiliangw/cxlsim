#!/bin/bash

set -xe

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update && sudo -E apt-get install -y \
  net-tools \
  isc-dhcp-server \
  iptables \
  iptables-persistent \
  dnsmasq
