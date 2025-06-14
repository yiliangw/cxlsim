UBUNTU_SECONDARY_DISK_SZ := 250G

# Disk images output directory
ubuntu_img_o := $(o)
ubuntu_dimg_o := $(o)disks/
ubuntu_input_tar_o := $(o)input_tars/
ubuntu_install_script_o := $(o)install_scripts/
ubuntu_dimgs :=

.PRECIOUS: $(ubuntu_dimg_o)% $(ubuntu_input_tar_o)%

$(eval $(call include_rules,$(d)base/rules.mk))
$(eval $(call include_rules,$(d)hosts/rules.mk))
$(eval $(call include_rules,$(d)gateway/rules.mk))

ubuntu_vmlinux := $(o)vmlinux
ubuntu_bzImage := $(o)bzImage
ubuntu_initrd := $(o)initrd.img

$(ubuntu_vmlinux): $(ubuntu_base_dimg) | $(o)
	sudo $(virt_copy_out) -a $< /root/output/vmlinux $(@D)
	sudo chown $(shell id -u):$(shell id -g) $@
	touch $@

$(ubuntu_bzImage): $(ubuntu_base_dimg) | $(o)
	sudo $(virt_copy_out) -a $< /root/output/bzImage $(@D)
	sudo chown $(shell id -u):$(shell id -g) $@
	touch $@

$(ubuntu_initrd): $(ubuntu_base_dimg) | $(o)
	sudo $(virt_copy_out) -a $< /root/output/initrd.img $(@D)
	sudo chown $(shell id -u):$(shell id -g) $@
	touch $@

$(ubuntu_img_o)config: $(ubuntu_base_dimg) | $(o)
	sudo $(virt_copy_out) -a $< /root/output/config $(@D)
	sudo chown $(shell id -u):$(shell id -g) $@
	touch $@

ubuntu_kernel_cmdline := earlyprintk=ttyS0 console=ttyS0 root=/dev/sda1 net.ifnames=0 rw

$(o)tmpdisks/%/disk.qcow2: $(ubuntu_dimg_o)%/disk.qcow2 | $(o)tmpdisks/%/
	@rm -f $@
	$(QEMU_IMG) create -f qcow2 -o backing_file=$(realpath --relative-to=$(@D) $<) -F qcow2 $@ 

.PHONY: qemu-ubuntu-base
qemu-ubuntu-base: $(o)tmpdisks/base/disk.qcow2 $(ubuntu_vmlinux) $(ubuntu_initrd)
	sudo -E $(qemu) -machine q35 -cpu Skylake-Server -smp $(shell echo $$((`nproc` / 2))) -m $(shell echo $$((`free -m | awk '/^Mem:/ {print $$4}'` / 2)))M  \
	-drive file=$(word 1,$^),media=disk,format=qcow2,if=ide,index=0 \
	-netdev user,id=user-net \
	-kernel $(word 2,$^) \
	-initrd $(word 3,$^) \
	-append "earlyprintk=ttyS0 console=ttyS0 root=/dev/sda1 rw" \
	-device virtio-net-pci,netdev=user-net \
	-boot c \
	-display none -serial mon:stdio


define ubuntu_disk_rules # $1: name, $2: disk (paths)
.PHONY: ubuntu-$(1) clean-ubuntu-$(1)
ubuntu-$(1): $(addprefix $(ubuntu_dimg_o),$(addsuffix /disk.qcow2,$(2)))
clean-ubuntu-$(1):
	rm -rf $(addprefix $(ubuntu_dimg_o),$(addsuffix /disk.qcow2,$(2)))
endef

define ubuntu_raw_disk_rules
.PHONY: ubuntu-raw-$(1) clean-ubuntu-raw-$(1)
ubuntu-raw-$(1): $(addprefix $(ubuntu_dimg_o),$(addsuffix /disk.raw,$(2)))
clean-ubuntu-raw-$(1):
	rm -rf $(addprefix $(ubuntu_dimg_o),$(addsuffix /disk.raw,$(2)))
endef

define ubuntu_setup_rule
$(eval node := $(1))
$(eval management_mac := $(call conffget,host,.qemu_mac_list[$(2)]))
$(eval provider_mac := $(call conffget,host,.qemu_mac_list[$(3)]))

.PRECIOUS: $(ubuntu_dimg_o)setup/$(node)/disk.qcow2
$(ubuntu_dimg_o)setup/$(node)/disk.qcow2: $(ubuntu_dimg_o)base/$(node)/disk.qcow2 $(ubuntu_input_tar_o)$(node)_phase2.tar $(ubuntu_install_script_o)$(node)_phase2.sh
	@rm -rf $$@ && mkdir -p $$(@D)
	$(QEMU_IMG) create -f qcow2 -F qcow2 -b $$(realpath --relative-to=$$(@D) $$<) $$@

.PHONY: qemu-ubuntu-setup/$(node)
qemu-ubuntu-setup/$(node): $(ubuntu_dimg_o)setup/$(node)/disk.qcow2 $(ubuntu_input_tar_o)$(node)_phase2.tar $(ubuntu_install_script_o)$(node)_phase2.sh $(host_config_deps) $(ubuntu_vmlinux) $(ubuntu_initrd)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp 8 -m 16G \
	-kernel $(ubuntu_vmlinux) \
	-append "$(ubuntu_kernel_cmdline)" \
	-initrd $(ubuntu_initrd) \
	-drive file=$$(word 1, $$^),media=disk,format=qcow2,if=ide,index=0 \
	-drive file=$${word 2, $$^},media=disk,format=raw,if=ide,index=1 \
	-drive file=$${word 3, $$^},media=disk,format=raw,if=ide,index=2 \
	-netdev bridge,id=net-management,br=$$(call conffget,host,.bridges.management.name) \
	-device virtio-net-pci,netdev=net-management,mac=$(management_mac) \
	-netdev bridge,id=net-provider,br=$$(call conffget,host,.bridges.provider.name) \
	-device virtio-net-pci,netdev=net-provider,mac=$(provider_mac) \
	-boot c \
	-display none -serial mon:stdio
	touch $$<
endef

$(eval $(call ubuntu_setup_rule,controller,0,1))
$(eval $(call ubuntu_setup_rule,compute1,2,3))
$(eval $(call ubuntu_setup_rule,compute2,4,5))
$(eval $(call ubuntu_disk_rules,setup,setup/controller setup/compute1 setup/compute2))

$(eval $(call include_rules,$(d)apps/rules.mk))
