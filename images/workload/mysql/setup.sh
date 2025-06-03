#!/bin/bash
set -xe

SERVER_VCPUS=1
SERVER_RAM=4096
SERVER_DISK=10
CLIENT_VCPUS=1
CLIENT_RAM=4096
CLIENT_DISK=10

SERVER_IP=${SERVER_IP:-10.10.11.111}
CLIENT_IP=${CLIENT_IP:-10.10.11.112}

WORKLOAD_MNT=$(realpath $(dirname ${BASH_SOURCE[0]})/..)
USER_DATA=/${WORKLOAD_MNT}/user-data

source ~/env/user_openrc

PROJECT_NAME=$OS_PROJECT_NAME

source ~/env/admin_openrc
# Seems that there are some issues when creating the ports using the non-admin user

openstack port create --project $PROJECT_NAME --network provider \
    --security-group mygroup --fixed-ip ip-address=$SERVER_IP \
    server

openstack port create --project $PROJECT_NAME --network provider \
    --security-group mygroup --fixed-ip ip-address=$CLIENT_IP \
    client

source ~/env/user_openrc

openstack image create \
    --disk-format qcow2 --container-format bare \
    --file ${WORKLOAD_MNT}/disks/ubuntu \
    ubuntu

openstack flavor create \
    --vcpus $SERVER_VCPUS --ram $SERVER_RAM --disk $SERVER_DISK \
    server

openstack flavor create \
    --vcpus $CLIENT_VCPUS --ram $CLIENT_RAM --disk $CLIENT_DISK \
    client

openstack server create \
    --flavor server --image ubuntu --key-name mykey \
    --security-group mygroup --port server --user-data ${USER_DATA} \
    --os-compute-api-version 2.74 --host compute1 \
    server

sleep 5

openstack server create \
    --flavor client --image ubuntu --key-name mykey \
    --security-group mygroup --port client --user-data ${USER_DATA} \
    --os-compute-api-version 2.74 --host compute1 \
    client
