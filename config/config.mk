# output directory 
O ?= out/
# build directory
B ?= $(O)build/

# interface with internet access
INTERNET_IF ?= eno1
# bridge for running VMs
BRIDGE_IF ?= baizebr0
# IP address for the bridge
BRIDGE_IF_IP ?= 10.10.10.1
# mask for the bridge
BRIDGE_IF_MASK_LEN ?= 24
