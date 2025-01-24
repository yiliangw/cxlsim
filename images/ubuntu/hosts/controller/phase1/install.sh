#!/bin/bash
set -xe

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update && sudo apt-get install -y \
  sshpass net-tools \
  chrony python3-openstackclient python3-pip \
  mariadb-server python3-pymysql \
  rabbitmq-server \
  memcached python3-memcache \
  etcd \
  keystone \
  glance \
  placement-api \
  nova-api nova-conductor nova-novncproxy nova-scheduler \
  neutron-server neutron-plugin-ml2 \
  neutron-openvswitch-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent

pip3 install osc-placement
