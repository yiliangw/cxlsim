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

. ~/env/user_openrc

# Add the keypair
openstack keypair create --public-key ~/.ssh/id_rsa.pub default

# Create security groups
openstack security group rule create default --proto any --ingress

popd
