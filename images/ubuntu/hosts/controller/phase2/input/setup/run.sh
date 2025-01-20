#!/bin/bash
d=`dirname ${BASH_SOURCE[0]}`

fdone=${d}/.done

if [ -f $fdone ]; then
    echo "Already set up"
    exit 0
fi

set -xe

# Chrony
sudo tee /etc/chrony/chrony.conf < ${d}/chrony.conf > /dev/null
sudo systemctl restart chrony

# SQL database
sudo cp ${d}/mysql/99-openstack.cnf /etc/mysql/mariadb.conf.d
sudo systemctl enable mysql
sudo systemctl restart mysql

source ~/env/openstackrc

# Message queue
sudo rabbitmqctl add_user openstack $RABBIT_PASS
# Permit configuration, write, and read
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# Memcached
sudo cp ${d}/memcached.conf /etc/memcached.conf
sudo systemctl enable memcached
sudo systemctl restart memcached

# Etcd
sudo cp ${d}/etcd /etc/default/etcd
sudo systemctl enable etcd
sudo systemctl restart etcd

bash ${d}/keystone.sh
bash ${d}/glance.sh
bash ${d}/placement.sh
bash ${d}/nova.sh
bash ${d}/neutron.sh

# Remote setup
while ! ssh compute1 uptime; do
    sleep 1
done
ssh compute1 'cd && bash setup/run.sh'

touch $fdone
