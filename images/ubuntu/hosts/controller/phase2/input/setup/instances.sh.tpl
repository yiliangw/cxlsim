#!/bin/bash
d=`dirname ${BASH_SOURCE[0]`}

set -xe

. ~/env/admin_openrc

# Provider network
openstack network create  --share --external \
  --provider-physical-network provider \
  --provider-network-type flat provider
openstack subnet create --network provider \
  --allocation-pool start={{ .openstack.network.provider.ip_pool.start }},end={{ .openstack.network.provider.ip_pool.end }} \
  --dns-nameserver {{ .openstack.network.provider.nameserver }} --gateway {{ .openstack.network.provider.gateway }} \
  --subnet-range {{ .openstack.network.provider.subnet }} provider

# Create flavors
openstack flavor create --vcpus 1 --ram 64 --disk 1 m1.nano
# openstack flavor create --vcpus {{ .openstack.instances.mysql.server.vcpus }} --ram {{ .openstack.instances.mysql.server.ram }} --disk {{ .openstack.instances.mysql.server.disk }} mysql.server 
# openstack flavor create --vcpus {{ .openstack.instances.mysql.client.vcpus }} --ram {{ .openstack.instances.mysql.client.ram }} --disk {{ .openstack.instances.mysql.client.disk }} mysql.client

. ~/env/user_openrc

# Self-service network
openstack network create selfservice
openstack subnet create --network selfservice \
  --dns-nameserver {{ .openstack.network.selfservice.nameserver }} \
  --gateway {{ .openstack.network.selfservice.gateway }} \
  --subnet-range {{ .openstack.network.selfservice.subnet }}  selfservice

# Create the router
openstack router create router && sleep 3
openstack router add subnet router selfservice
openstack router set router --external-gateway provider

# Add the keypair
openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey

# Create security groups
openstack security group rule create default --proto any --ingress

# Launch instances
# glance image-create --name "mysql_server" --file ${HOME}/images/mysql_server.qcow1 --disk-format qcow2 \
#   --container-format bare --visibility public
# glance image-create --name "mysql_client" --file ${HOME}/images/mysql_client.qcow1 --disk-format qcow2 \
#   --container-format bare --visibility public

. ~/env/user_openrc
provider_net_id=$(openstack network show provider -f value -c id)
openstack server create --flavor m1.nano --image cirros \
  --nic net-id=${provider} --security-group default \
  --key-name mykey provider-instance

