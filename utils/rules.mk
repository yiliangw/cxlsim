bridge_script := $(d)bridge.sh
nat_script := $(d)nat.sh

.PHONY: setup-bridges cleanup-bridges setup-nat cleanup-nat

setup-bridges: $(ubuntu_config)
	INTERNET_IF=$(call confget_ubuntu,.network.host.internet_if) \
	BRIDGE_IF=$(call confget_ubuntu,.network.management.bridge) \
	BRIDGE_IF_CIDR=$(call confget_ubuntu,.network.management.ip)/$(call confget_ubuntu,.network.management.mask_len) \
	$(bridge_script) setup
	INTERNET_IF=$(call confget_ubuntu,.network.host.internet_if) \
	BRIDGE_IF=$(call confget_ubuntu,.network.service.bridge) \
	BRIDGE_IF_CIDR=$(call confget_ubuntu,.network.service.ip)/$(call confget_ubuntu,.network.service.mask_len) \
	$(bridge_script) setup

cleanup-bridges: $(ubuntu_config)
	INTERNET_IF=$(call confget_ubuntu,.network.host.internet_if) \
	BRIDGE_IF=$(call confget_ubuntu,.network.management.bridge) \
	BRIDGE_IF_CIDR=$(call confget_ubuntu,.network.management.ip)/$(call confget_ubuntu,.network.management.mask_len) \
	$(bridge_script) cleanup
	INTERNET_IF=$(call confget_ubuntu,.network.host.internet_if) \
	BRIDGE_IF=$(call confget_ubuntu,.network.service.bridge) \
	BRIDGE_IF_CIDR=$(call confget_ubuntu,.network.service.ip)/$(call confget_ubuntu,.network.service.mask_len) \
	$(bridge_script) setup

setup-nat: $(ubuntu_config)
	INTERNET_IF=$(call confget_ubuntu,.network.host.internet_if) \
	BRIDGE_IF=$(call confget_ubuntu,.network.management.bridge) \
	$(nat_script) setup
	INTERNET_IF=$(call confget_ubuntu,.network.host.internet_if) \
	BRIDGE_IF=$(call confget_ubuntu,.network.service.bridge) \
	$(nat_script) setup

cleanup-nat: $(ubuntu_config)
	INTERNET_IF=$(call confget_ubuntu,.network.host.internet_if) \
	BRIDGE_IF=$(call confget_ubuntu,.network.management.bridge) \
	$(nat_script) cleanup
	INTERNET_IF=$(call confget_ubuntu,.network.host.internet_if) \
	BRIDGE_IF=$(call confget_ubuntu,.network.service.bridge) \
	$(nat_script) cleanup
