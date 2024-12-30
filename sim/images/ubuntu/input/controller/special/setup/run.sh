#!/bin/bash
d=`dirname ${BASH_SOURCE[0]}`

set -x

source ${HOME}/env/passwdrc

sudo apt-get update

# SQL database
sudo apt-get install -y mariadb-server python3-pymysql
sudo cp ${d}/mysql/99-openstack.cnf /etc/mysql/mariadb.conf.d
sudo systemctl enable mysql
sudo systemctl restart mysql

# Message queue
sudo apt-get install -y rabbitmq-server
sudo rabbitmqctl add_user openstack $RABBIT_PASS
# Permit configuration, write, and read
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# Memcached
sudo apt-get install -y memcached python3-memcache
sudo cp ${d}/memcached.conf /etc/memcached.conf
sudo systemctl enable memcached
sudo systemctl restart memcached

# Etcd
sudo apt-get install -y etcd
sudo cp ${d}/etcd /etc/default/etcd
sudo systemctl enable etcd
sudo systemctl restart etcd

bash ${d}/keystone.sh
bash ${d}/glance.sh
