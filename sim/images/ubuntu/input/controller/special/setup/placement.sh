#!/bin/bash
d=`dirname ${BASH_SOURCE[0]}`
. ${HOME}/env/passwdrc

set -xe

# Create the glance database
cat <<EOF | sudo mysql -u root
CREATE DATABASE placement;
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY '${PLACEMENT_DBPASS}';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY '${PLACEMENT_DBPASS}';
EOF

. ${HOME}/env/admin_openrc

openstack user create --domain default --password ${PLACEMENT_PASS} placement
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement

openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778

sudo bash -c "sed 's/{{PLACEMENT_DBPASS}}/${PLACEMENT_DBPASS}/g; s/{{PLACEMENT_PASS}}/${PLACEMENT_PASS}/g' ${d}/placement.conf.tpl > /etc/placement/placement.conf"

sudo su -s /bin/sh -c "placement-manage db sync" placement

sudo systemctl restart apache2
