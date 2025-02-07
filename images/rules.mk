PACKER_VERSION := 1.11.2
PACKER_ZIP_URL := https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_linux_amd64.zip

qemu := qemu-system-x86_64
qemu_img := qemu-img
virt_copy_out := virt-copy-out

packer := $(b)packer
packer_run := PACKER_PLUGIN_PATH=$(b).packer_plugins/ PACKER_CACHE_DIR=$(b).packer_cache/ $(packer)
packer_zip := $(b)packer.zip

base_hcl := $(d)base.pkr.hcl
extend_hcl := $(d)extend.pkr.hcl

%disk.raw: %disk.qcow2
	$(qemu_img) convert -f qcow2 -O raw $< $@ 

$(packer): $(packer_zip)
	mkdir -p $(@D)
	unzip -o -d $(@D) $<
	$(packer_run) plugins install github.com/hashicorp/qemu
	touch $@

$(packer_zip):
	mkdir -p $(@D)
	wget -O $@ $(PACKER_ZIP_URL)

linux_dir := $(project_root)apps/linux/

$(eval $(call include_rules,$(d)instances/rules.mk))
$(eval $(call include_rules,$(d)ubuntu/rules.mk))

DIMG_ALL := $(addprefix $(o)ubuntu/disks/, controller/disk.qcow2 compute1/disk.qcow2)
RAW_DIMG_ALL := $(subst .qcow2,.raw,$(DIMG_ALL)) 

IMAGE_ALL := $(DIMG_ALL) $(RAW_DIMG_ALL) $(o)ubuntu/bzImage $(o)ubuntu/vmlinux
.PRECIOUS: $(IMAGE_ALL)

.PHONY: images
images: $(IMAGE_ALL)