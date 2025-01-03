#!/bin/bash
d=`dirname ${BASH_SOURCE[0]}`

set -xe

sudo tee /etc/chrony/chrony.conf < ${d}/chrony.conf > /dev/null
sudo systemctl restart chrony

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update

sudo apt-get install -y \
  nova-compute neutron-openvswitch-agent

cp -r ${d}/setup ${HOME}/setup
