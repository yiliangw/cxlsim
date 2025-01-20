PACKER_VERSION := 1.11.2
PACKER_ZIP_URL := https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_linux_amd64.zip

qemu := qemu-system-x86_64
qemu_img := qemu-img

packer := $(b)packer
packer_zip := $(b)packer.zip
packer_cache_dir := $(b).packer_cache/

base_hcl := $(d)base.pkr.hcl
extend_hcl := $(d)extend.pkr.hcl

.INTERMEDIATE: $(packer_zip) $(devstack_zip)
$(packer_zip):
	mkdir -p $(@D)
	wget -O $@ $(PACKER_ZIP_URL)

$(packer): $(packer_zip)
	mkdir -p $(@D)
	unzip -o -d $(@D) $(packer_zip)
	$(packer) plugins install github.com/hashicorp/qemu
	touch $@

$(eval $(call include_rules,$(d)instances/rules.mk))
$(eval $(call include_rules,$(d)ubuntu/rules.mk))
