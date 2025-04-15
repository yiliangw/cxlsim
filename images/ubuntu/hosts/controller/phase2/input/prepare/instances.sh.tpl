#!/bin/bash
set -xe

pushd `dirname ${BASH_SOURCE[0]}`

. ~/env/admin_openrc

# Provider network
openstack network create  --share --external \
  --provider-physical-network provider \
  --provider-network-type flat provider
openstack subnet create --network provider \
  --allocation-pool start={{ .openstack.network.provider.ip_pool.start }},end={{ .openstack.network.provider.ip_pool.end }} \
  --dns-nameserver {{ .openstack.network.provider.nameserver }} --gateway {{ .openstack.network.provider.gateway }} \
  --subnet-range {{ .openstack.network.provider.subnet }}/{{ .openstack.network.provider.mask_len }} provider

openstack port create --project {{ .openstack.id.nonadmin.project }} --network provider \
  --fixed-ip ip-address={{ .openstack.instances.mysql.server.ip }} mysql.server
openstack port create --project {{ .openstack.id.nonadmin.project }} --network provider \
  --fixed-ip ip-address={{ .openstack.instances.mysql.client.ip }} mysql.client

# Create flavors
openstack flavor create --vcpus 1 --ram 64 --disk 1 m1.nano
openstack flavor create --vcpus {{ .openstack.instances.mysql.server.vcpus }} --ram {{ .openstack.instances.mysql.server.ram }} --disk {{ .openstack.instances.mysql.server.disk }} mysql.server 
openstack flavor create --vcpus {{ .openstack.instances.mysql.client.vcpus }} --ram {{ .openstack.instances.mysql.client.ram }} --disk {{ .openstack.instances.mysql.client.disk }} mysql.client

. ~/env/user_openrc

# Self-service network
# openstack network create selfservice
# openstack subnet create --network selfservice \
#   --dns-nameserver {{ .openstack.network.selfservice.nameserver }} \
#   --gateway {{ .openstack.network.selfservice.gateway }} \
#   --subnet-range {{ .openstack.network.selfservice.subnet }}/{{ .openstack.network.selfservice.mask_len }}  selfservice

# # Create the router
# openstack router create router && sleep 3
# openstack router add subnet router selfservice
# openstack router set router --external-gateway provider

# Add the keypair
openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey

# Create security groups
openstack security group rule create default --proto any --ingress

mysql_server_ip={{ .openstack.instances.mysql.server.ip }}
mysql_client_ip={{ .openstack.instances.mysql.client.ip }}
user={{ .openstack.instances.user.name }}
password={{ .openstack.instances.user.password }}

openstack server create --flavor mysql.server --image mysql.server \
  --port mysql.server --security-group default \
  --key-name mykey mysql.server

sleep 30

while ! sshpass -p${password} ssh -MNf ${user}@${mysql_server_ip}; do
    ping -c 1 compute1
    openstack server show mysql.server
    sleep 30
done

openstack server create --flavor mysql.client --image mysql.client \
  --port mysql.client --security-group default \
  --key-name mykey mysql.client

sleep 30

while ! sshpass -p${password} ssh -MNf ${user}@${mysql_client_ip}; do
    ping -c 1 compute1
    openstack server show mysql.client
    sleep 30
done

sshpass -p${password} ssh ${user}@${mysql_client_ip} 'bash ~/input/prepare.sh'

popd
