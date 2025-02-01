UBUNTU_ISO_URL := https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
UBUNTU_ISO_CKSUM_URL := https://cloud-images.ubuntu.com/jammy/current/SHA256SUMS

UBUNTU_ROOT_DISK_SZ := 250G
UBUNTU_SECONDARY_DISK_SZ := 250G

# Disk images output directory
ubuntu_dimg_o := $(o)disks/
ubuntu_dimgs :=

$(eval $(call include_rules,$(d)base/rules.mk))
$(eval $(call include_rules,$(d)hosts/rules.mk))

.PRECIOUS: $(ubuntu_dimgs)

$(o)vmlinuz: $(ubuntu_base_dimg)
	mkdir -p $(@D)
	rm -f $@
	sudo virt-copy-out -a $< /output/vmlinux $@.tmp
	sudo chown $(shell id -u):$(shell id -g) $@.tmp
	mv $@.tmp $@

$(o)bzImage: $(ubuntu_base_dimg)
	mkdir -p $(@D)
	rm -f $@
	sudo virt-copy-out -a $< /output/bzImage $@.tmp
	sudo chown $(shell id -u):$(shell id -g) $@.tmp
	mv $@.tmp $@
