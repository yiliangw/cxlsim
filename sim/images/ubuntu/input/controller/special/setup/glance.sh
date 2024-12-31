#!/bin/bash
d=`dirname ${BASH_SOURCE[0]}`
source ${HOME}/env/passwdrc
sed_tpl="${HOME}/env/utils/sed_tpl.sh"

set -xe

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

# Edit /etc/glance/glance-api.conf
sudo bash -c "${sed_tpl} ${d}/glance-api.conf.tpl > /etc/glance/glance-api.conf"

# Permit reader access to glance
openstack role add --user glance --user-domain Default --system all reader

# Populate the Image service database
sudo su -s /bin/sh -c "glance-manage db_sync" glance

sudo systemctl restart glance-api

# Verify
images=cirros-0.4.0-x86_64-disk.img
wget -O /tmp/$images http://download.cirros-cloud.net/0.4.0/$images
glance image-create --name "cirros" --file /tmp/$images --disk-format qcow2 \
  --container-format bare --visibility public
# Ensure there is cirros in the output, otherwise fail
glance image-list | grep -q cirros
