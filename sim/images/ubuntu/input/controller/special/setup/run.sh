#!/bin/bash
d=`dirname ${BASH_SOURCE[0]}`
source ${HOME}/passwdrc

set -x

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

# Create the keystone database
cat <<EOF | sudo mysql -u root
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}'; 
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DBPASS}';
EOF

# Install keystone
sudo apt-get install keystone -y
# Edit /etc/keystone/keystone.conf
sudo sed -i "/^\[database\]/,/^\[/{s/^connection /# connection /}" /etc/keystone/keystone.conf
sudo sed -i "/^\[database\]/a connection = mysql+pymysql://keystone:${KEYSTONE_DBPASS}@controller/keystone" /etc/keystone/keystone.conf
sudo sed -i "/^\[token\]/a provider = fernet" /etc/keystone/keystone.conf
# Populate the Identity service database
sudo su -s /bin/sh -c "keystone-manage db_sync" keystone
# Initialize Fernet key repositories
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
# Bootstrap the Identity service
sudo keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

# Configure the Apache HTTP server
sudo sed -i '/^ServerName /s/^/# /; $a ServerName controller' /etc/apache2/apache2.conf
sudo systemctl restart apache2
