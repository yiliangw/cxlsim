# output directory 
O ?= out/
# build directory
B ?= $(O)build/

# interface with internet access
INTERNET_IF ?= eno1

# openstack management network
MANAGEMENT_BRIDGE_IF ?= baizebr0
MANAGEMENT_BRIDGE_IF_IP ?= 10.10.10.1
MANAGEMENT_BRIDGE_IF_MASK_LEN ?= 24

# openstack self-service network
SELF_SERVICE_BRIDGE_IF ?= baizebr1
SELF_SERVICE_BRIDGE_IF_IP ?= 10.10.11.1
SELF_SERVICE_BRIDGE_IF_MASK_LEN ?= 24

