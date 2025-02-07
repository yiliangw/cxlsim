#!/bin/bash
set -xe

pushd `dirname ${BASH_SOURCE[0]}`

if [ -f .done ]; then
    echo "Already set up"
    exit 0
fi

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

bash keystone.sh
bash glance.sh
bash placement.sh
bash nova.sh
bash neutron.sh

# Prepare other hosts
while ! ssh compute1 uptime; do
    sleep 1
done
ssh compute1 'cd && bash prepare/run.sh'

# Launch instances
bash instances.sh

touch .done

popd
