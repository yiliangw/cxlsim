set -xe

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update && sudo apt-get install -y \
  net-tools chrony python3-openstackclient python3-pip \
  nova-compute neutron-openvswitch-agent
