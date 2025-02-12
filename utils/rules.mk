bridge_script := $(d)bridge.sh
nat_script := $(d)nat.sh

.PHONY: setup-bridges cleanup-bridges setup-nat cleanup-nat

INTERNET_IF := $(call conffget,host,.internet_if)
MANAGEMENT_BRIDGE := $(call conffget,host,.bridges.management.name)
MANAGEMENT_BRIDGE_CIDR := $(call conffget,host,.bridges.management.ip)/$(call conffget,host,.bridges.management.netmask_len)
PROVIDER_BRIDGE := $(call conffget,host,.bridges.provider.name)
PROVIDER_BRIDGE_CIDR := $(call conffget,host,.bridges.provider.ip)/$(call conffget,host,.bridges.provider.netmask_len)
SELFSERVICE_BRIDGE := $(call conffget,host,.bridges.selfservice.name)
SELFSERVICE_BRIDGE_CIDR := $(call conffget,host,.bridges.selfservice.ip)/$(call conffget,host,.bridges.selfservice.netmask_len)

setup-bridges: $(host_config_deps)
	INTERNET_IF=$(INTERNET_IF) \
	BRIDGE_IF=$(MANAGEMENT_BRIDGE) \
	BRIDGE_IF_CIDR=$(MANAGEMENT_BRIDGE_CIDR) \
	$(bridge_script) setup
	INTERNET_IF=$(INTERNET_IF) \
	BRIDGE_IF=$(PROVIDER_BRIDGE) \
	BRIDGE_IF_CIDR=$(PROVIDER_BRIDGE_CIDR) \
	$(bridge_script) setup
	INTERNET_IF=$(INTERNET_IF) \
	BRIDGE_IF=$(SELFSERVICE_BRIDGE) \
	BRIDGE_IF_CIDR=$(SELFSERVICE_BRIDGE_CIDR) \
	$(bridge_script) setup 

cleanup-bridges: $(host_config_deps)
	INTERNET_IF=$(INTERNET_IF) \
	BRIDGE_IF=$(MANAGEMENT_BRIDGE) \
	BRIDGE_IF_CIDR=$(MANAGEMENT_BRIDGE_CIDR) \
	$(bridge_script) cleanup 
	INTERNET_IF=$(INTERNET_IF) \
	BRIDGE_IF=$(PROVIDER_BRIDGE) \
	BRIDGE_IF_CIDR=$(PROVIDER_BRIDGE_CIDR) \
	$(bridge_script) cleanup 
	INTERNET_IF=$(INTERNET_IF) \
	BRIDGE_IF=$(SELFSERVICE_BRIDGE) \
	BRIDGE_IF_CIDR=$(SELFSERVICE_BRIDGE_CIDR) \
	$(bridge_script) cleanup 

setup-nat: $(config_deps)
	INTERNET_IF=$(INTERNET_IF) \
	BRIDGE_IF=$(MANAGEMENT_BRIDGE) \
	$(nat_script) setup
	INTERNET_IF=$(INTERNET_IF) \
	BRIDGE_IF=$(PROVIDER_BRIDGE) \
	$(nat_script) setup
	INTERNET_IF=$(INTERNET_IF) \
	BRIDGE_IF=$(SELFSERVICE_BRIDGE) \
	$(nat_script) setup

cleanup-nat: $(config_deps)
	INTERNET_IF=$(INTERNET_IF) \
	BRIDGE_IF=$(MANAGEMENT_BRIDGE) \
	$(nat_script) cleanup
	INTERNET_IF=$(INTERNET_IF) \
	BRIDGE_IF=$(PROVIDER_BRIDGE) \
	$(nat_script) cleanup
	INTERNET_IF=$(INTERNET_IF) \
	BRIDGE_IF=$(SELFSERVICE_BRIDGE) \
	$(nat_script) cleanup
