bridge_script := $(d)bridge.sh
nat_script := $(d)nat.sh

.PHONY: setup-bridges cleanup-bridges setup-nat cleanup-nat

setup-bridges: $(config_deps)
	INTERNET_IF=$(call confget,.host.internet_if) \
	BRIDGE_IF=$(call confget,.host.bridges.management.name) \
	BRIDGE_IF_CIDR=$(call confget,.openstack.network.management.gateway)/$(call confget,.openstack.network.management.mask_len) \
	$(bridge_script) setup
	INTERNET_IF=$(call confget,.host.internet_if) \
	BRIDGE_IF=$(call confget,.host.bridges.provider.name) \
	BRIDGE_IF_CIDR=$(call confget,.openstack.network.provider.gateway)/$(call confget,.openstack.network.provider.mask_len) \
	$(bridge_script) setup
	INTERNET_IF=$(call confget,.host.internet_if) \
	BRIDGE_IF=$(call confget,.host.bridges.selfservice.name) \
	BRIDGE_IF_CIDR=$(call confget,.openstack.network.selfservice.gateway)/$(call confget,.openstack.network.selfservice.mask_len) \
	$(bridge_script) setup 

cleanup-bridges: $(config_deps)
	INTERNET_IF=$(call confget,.host.internet_if) \
	BRIDGE_IF=$(call confget,.host.bridges.management.name) \
	BRIDGE_IF_CIDR=$(call confget,.openstack.network.management.gateway)/$(call confget,.openstack.network.management.mask_len) \
	$(bridge_script) cleanup 
	INTERNET_IF=$(call confget,.host.internet_if) \
	BRIDGE_IF=$(call confget,.host.bridges.provider.name) \
	BRIDGE_IF_CIDR=$(call confget,.openstack.network.provider.gateway)/$(call confget,.openstack.network.provider.mask_len) \
	$(bridge_script) cleanup 
	INTERNET_IF=$(call confget,.host.internet_if) \
	BRIDGE_IF=$(call confget,.host.bridges.selfservice.name) \
	BRIDGE_IF_CIDR=$(call confget,.openstack.network.selfservice.gateway)/$(call confget,.openstack.network.selfservice.mask_len) \
	$(bridge_script) cleanup 

setup-nat: $(config_deps)
	INTERNET_IF=$(call confget,.host.internet_if) \
	BRIDGE_IF=$(call confget,.host.bridges.management.name) \
	$(nat_script) setup
	INTERNET_IF=$(call confget,.host.internet_if) \
	BRIDGE_IF=$(call confget,.host.bridges.provider.name) \
	$(nat_script) setup
	INTERNET_IF=$(call confget,.host.internet_if) \
	BRIDGE_IF=$(call confget,.host.bridges.selfservice.name) \
	$(nat_script) setup

cleanup-nat: $(config_deps)
	INTERNET_IF=$(call confget,.host.internet_if) \
	BRIDGE_IF=$(call confget,.host.bridges.management.name) \
	$(nat_script) cleanup
	INTERNET_IF=$(call confget,.host.internet_if) \
	BRIDGE_IF=$(call confget,.host.bridges.provider.name) \
	$(nat_script) cleanup
	INTERNET_IF=$(call confget,.host.internet_if) \
	BRIDGE_IF=$(call confget,.host.bridges.selfservice.name) \
	$(nat_script) cleanup
