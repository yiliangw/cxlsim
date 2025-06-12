#!/bin/bash
set -xe

pushd `dirname ${BASH_SOURCE[0]}`

if [ -f .done ]; then
    echo "Already set up"
    exit 0
fi

sudo systemctl restart ssh

# Chrony
sudo tee /etc/chrony/chrony.conf < chrony.conf > /dev/null
sudo systemctl restart chrony

# SQL database
sudo cp mysql/99-openstack.cnf /etc/mysql/mariadb.conf.d
sudo systemctl enable mysql
sudo systemctl restart mysql

source ~/env/openstackrc

# Message queue
sudo rabbitmqctl add_user openstack $RABBIT_PASS
# Permit configuration, write, and read
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# Memcached
sudo cp memcached.conf /etc/memcached.conf
sudo systemctl enable memcached
sudo systemctl restart memcached

# Etcd
sudo cp etcd /etc/default/etcd
sudo systemctl enable etcd
sudo systemctl restart etcd

# Bring up ovs interfaces
sudo cp sbin/setup-ovs-iface.sh /usr/local/sbin
sudo chmod +x /usr/local/sbin/setup-ovs-iface.sh
sudo cp services/ovs-iface-up.service /etc/systemd/system
sudo systemctl enable --now ovs-iface-up

bash keystone.sh
bash glance.sh
bash placement.sh
bash nova.sh
bash neutron.sh

# Miscellaneous setup
bash misc.sh

# Set up provider veth interfaces
sudo cp sbin/setup-provider-veth.sh /usr/local/sbin
sudo chmod +x /usr/local/sbin/setup-provider-veth.sh
sudo cp services/provider-veth-up.service /etc/systemd/system
sudo systemctl enable --now provider-veth-up

touch .done

popd
