PACKER_VERSION := 1.11.2
PACKER_ZIP_URL := https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_linux_amd64.zip
DEVSTACK_ZIP_URL := https://github.com/openstack/devstack/archive/refs/heads/stable/2024.2.zip

qemu := qemu-system-x86_64
qemu_img := qemu-img

packer := $(b)packer
packer_zip := $(b)packer.zip
packer_cache_dir := $(b).packer_cache/

base_hcl := $(d)base.pkr.hcl
extend_hcl := $(d)extend.pkr.hcl

devstack_dir := $(b)devstack/
devstack_zip := $(b)devstack.zip

.INTERMEDIATE: $(packer_zip) $(devstack_zip)
$(packer_zip):
	mkdir -p $(@D)
	wget -O $@ $(PACKER_ZIP_URL)

$(devstack_zip):
	mkdir -p $(@D)
	wget -O $@ $(DEVSTACK_ZIP_URL)

$(packer): $(packer_zip)
	mkdir -p $(@D)
	unzip -o -d $(@D) $(packer_zip)
	touch $@

$(devstack_dir): $(devstack_zip)
	mkdir -p $(@D)
	unzip -o -d $(@D) $(devstack_zip)
	mv $(@D)/devstack-* $@

$(eval $(call include_rules,$(d)ubuntu/rules.mk))
