#!/bin/bash
d=`dirname ${BASH_SOURCE[0]}`
. ${HOME}/env/passwdrc

set -x

# Create the glance database
cat <<EOF | sudo mysql -u root
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${GLANCE_DBPASS}';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${GLANCE_DBPASS}';
EOF

. ${HOME}/env/admin_openrc

# Create the glance user
openstack user create --domain default --password ${GLANCE_PASS} glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image

# Create the Image service API endpoints
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

# Install glance
sudo apt install glance -y

# Edit /etc/glance/glance-api.conf
sudo bash -c "sed 's/{{GLANCE_DBPASS}}/${GLANCE_DBPASS}/g; s/{{GLANCE_PASS}}/${GLANCE_PASS}/g' ${d}/glance-api.conf.tpl > /etc/glance/glance-api.conf"

# Permit reader access to glance
openstack role add --user glance --user-domain Default --system all reader

# Populate the Image service database
sudo su -s /bin/sh -c "glance-manage db_sync" glance

sudo systemctl restart glance-api
