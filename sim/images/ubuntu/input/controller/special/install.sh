#!/bin/bash
d=`dirname ${BASH_SOURCE[0]}`

set -xe

sudo apt-get update
sudo apt-get install -y \
  mariadb-server python3-pymysql \
  rabbitmq-server \
  memcached python3-memcache \
  etcd \
  keystone \
  glance \
  placement-api \
  nova-api nova-conductor nova-novncproxy nova-scheduler

pip3 install osc-placement

cp -r ${d}/setup $HOME/setup
