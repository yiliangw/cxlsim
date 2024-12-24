bridge_script := $(d)bridge.sh

.PHONY: setup-bridge cleanup-bridge
setup-bridge:
	INTERNET_IF=$(INTERNET_IF) BRIDGE_IF=$(BRIDGE_IF) BRIDGE_IF_CIDR=$(BRIDGE_IF_IP)/$(BRIDGE_IF_MASK_LEN) $(bridge_script) setup

cleanup-bridge:
	INTERNET_IF=$(INTERNET_IF) BRIDGE_IF=$(BRIDGE_IF) BRIDGE_IF_CIDR=$(BRIDGE_IF_IP)/$(BRIDGE_IF_MASK_LEN) $(bridge_script) cleanup
