#!/bin/bash
d=`dirname ${BASH_SOURCE[0]}`

set -xe

sudo tee /etc/nova/nova.conf < ${d}/nova.conf > /dev/null

sudo systemctl restart nova-compute

# Let controller discover compute hosts:
ssh controller '\
  cd && source env/admin_openrc && \
  openstack compute service list --service nova-compute && \
  sudo su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova\
'
