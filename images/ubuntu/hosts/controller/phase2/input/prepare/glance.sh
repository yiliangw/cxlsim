#!/bin/bash
set -xe

pushd `dirname ${BASH_SOURCE[0]}`

# Create the glance database
cat <<EOF | sudo mysql -u root
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${GLANCE_DBPASS}';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${GLANCE_DBPASS}';
EOF

. ~/env/admin_openrc

# Create the glance user
openstack user create --domain default --password ${GLANCE_PASS} glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image

# Create the Image service API endpoints
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

# Edit /etc/glance/glance-api.conf
sudo tee /etc/glance/glance-api.conf < glance-api.conf > /dev/null

# Permit reader access to glance
openstack role add --user glance --user-domain Default --system all reader

# Populate the Image service database
sudo su -s /bin/sh -c "glance-manage db_sync" glance

sudo systemctl restart glance-api

# # Ensure there is cirros in the output, otherwise fail
# glance image-list | grep -q cirros

popd
