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

WORKLOAD_MNT=$(realpath $(dirname ${BASH_SOURCE[0]})/..)/
MYSQL_DIR=${WORKLOAD_MNT}mysql/
USER_DATA=${WORKLOAD_MNT}user-data

source ~/env/user_openrc

for h in compute1 compute2; do
    while ! ssh $h true; do sleep 3; done
    while ! openstack compute service list | grep $h | grep -q 'enabled.*up'; do sleep 3; done
done

ssh -T compute1 <<EOF
sed -i "s/^virt_type=.*/virt_type=kvm/" /etc/nova/nova-compute.conf
systemctl restart nova-compute
EOF

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
    --file ${WORKLOAD_MNT}disks/ubuntu \
    ubuntu

openstack flavor create \
    --vcpus $SERVER_VCPUS --ram $SERVER_RAM --disk $SERVER_DISK \
    server

openstack flavor create \
    --vcpus $CLIENT_VCPUS --ram $CLIENT_RAM --disk $CLIENT_DISK \
    client

# Wait for the compute node to be online
while ! openstack compute service list | grep compute1 | grep -q 'enabled.*up'; do
    sleep 5
done

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

sleep 30

while ! ssh $SERVER_IP 'true'; do sleep 3; done
while ! ssh $CLIENT_IP 'true'; do sleep 3; done

sleep 10

scp -r ${MYSQL_DIR}server/* $SERVER_IP:
tmux new -s server -d "ssh $SERVER_IP 'bash setup.sh' &> server.log"

scp -r ${MYSQL_DIR}client/* $CLIENT_IP:
tmux new -s client -d "ssh $CLIENT_IP 'bash setup.sh' &> client.log"

# Wait until bot tmux sessions are done
while tmux has-session -t server 2>/dev/null; do
    sleep 5
done
while tmux has-session -t client 2>/dev/null; do
    sleep 5
done

source ~/env/user_openrc

openstack server stop server client
while ! openstack server show server -c status | grep -q 'SHUTOFF'; do sleep 3; done
while ! openstack server show client -c status | grep -q 'SHUTOFF'; do sleep 3; done

openstack server migrate server --host compute2 --os-compute-api-version 2.56 --wait
openstack server migration confirm server
openstack server migrate client --host compute2 --os-compute-api-version 2.56 --wait
openstack server migration confirm client

ssh -T compute1 <<EOF
sed -i "s/^virt_type=.*/virt_type=qemu/" /etc/nova/nova-compute.conf
systemctl restart nova-compute
EOF

sleep 5

openstack server migrate server --host compute1 --os-compute-api-version 2.56 --wait
openstack server migration confirm server
