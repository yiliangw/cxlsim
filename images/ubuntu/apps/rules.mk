define ubuntu_disk_backing_rules
$(eval src_disk := $(1))
$(eval disk := $(2))
$(eval management_mac := $(call conffget,host,.qemu_mac_list[$(3)]))
$(eval provider_mac := $(call conffget,host,.qemu_mac_list[$(4)]))
$(eval disk_deps := $(5))

.PRECIOUS: $(ubuntu_dimg_o)$(disk)/disk.qcow2
$(ubuntu_dimg_o)$(disk)/disk.qcow2: $(ubuntu_dimg_o)$(src_disk)/disk.qcow2 $(disk_deps)
	@rm -rf $$@
	@mkdir -p $$(@D)
	$(QEMU_IMG) create -f qcow2 -F qcow2 -b $$(realpath --relative-to=$$(@D) $$<) $$@

.PHONY: qemu-ubuntu-$(disk)
qemu-ubuntu-$(disk): $(ubuntu_dimg_o)$(disk)/disk.qcow2 $(host_config_deps) $(ubuntu_vmlinux) $(ubuntu_initrd)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp 8 -m 16G \
	-kernel $(ubuntu_vmlinux) \
	-append "$(ubuntu_kernel_cmdline)" \
	-initrd $(ubuntu_initrd) \
	-drive file=$$(word 1, $$^),media=disk,format=qcow2,if=ide,index=0 \
	-fsdev local,id=shared_dev,path=$(workload_o),security_model=none,readonly \
	-device virtio-9p-pci,fsdev=shared_dev,mount_tag=workload \
	-netdev bridge,id=net-management,br=$$(call conffget,host,.bridges.management.name) \
	-device virtio-net-pci,netdev=net-management,mac=$(management_mac) \
	-netdev bridge,id=net-provider,br=$$(call conffget,host,.bridges.provider.name) \
	-device virtio-net-pci,netdev=net-provider,mac=$(provider_mac) \
	-boot c \
	-display none -serial mon:stdio
	touch $$<
endef

define ubuntu_disk_convert_raw_rules
$(eval src_disk := $(1))
$(eval disk := $(2))
$(eval management_mac := $(call conffget,host,.qemu_mac_list[$(3)]))
$(eval provider_mac := $(call conffget,host,.qemu_mac_list[$(4)]))
$(eval disk_deps := $(5))

.PRECIOUS: $(ubuntu_dimg_o)$(disk)/disk.raw
$(ubuntu_dimg_o)$(disk)/disk.raw: $(ubuntu_dimg_o)$(src_disk)/disk.qcow2 $(disk_deps)
	@rm -rf $$@
	@mkdir -p $$(@D)
	$(QEMU_IMG) convert -f qcow2 -O raw $$< $$@

.PHONY: qemu-ubuntu-raw-$(disk)
qemu-ubuntu-raw-$(disk): $(ubuntu_dimg_o)$(disk)/disk.raw $(host_config_deps) $(ubuntu_vmlinux) $(ubuntu_initrd)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp 1 -m 16G \
	-kernel $(ubuntu_vmlinux) \
	-append "$(ubuntu_kernel_cmdline)" \
	-initrd $(ubuntu_initrd) \
	-drive file=$$(word 1, $$^),media=disk,format=raw,if=ide,index=0 \
	-fsdev local,id=shared_dev,path=$(workload_o),security_model=none,readonly \
	-device virtio-9p-pci,fsdev=shared_dev,mount_tag=workload \
	-netdev bridge,id=net-management,br=$$(call conffget,host,.bridges.management.name) \
	-device e1000,netdev=net-management,mac=$(management_mac) \
	-netdev bridge,id=net-provider,br=$$(call conffget,host,.bridges.provider.name) \
	-device e1000,netdev=net-provider,mac=$(provider_mac) \
	-boot c \
	-display none -serial mon:stdio
	touch $$<
endef

$(eval $(call ubuntu_disk_backing_rules,setup/controller,mysql/base/controller,0,1,$(mysql_workload_deps)))
$(eval $(call ubuntu_disk_backing_rules,setup/compute1,mysql/base/compute1,2,3,$(mysql_workload_deps)))
$(eval $(call ubuntu_disk_backing_rules,setup/compute2,mysql/base/compute2,4,5,$(mysql_workload_deps)))
$(eval $(call ubuntu_disk_rules,mysql/base,$(addprefix mysql/base/,controller compute1 compute2)))

$(eval $(call ubuntu_disk_convert_raw_rules,mysql/base/controller,mysql/basic/controller,0,1))
$(eval $(call ubuntu_disk_convert_raw_rules,mysql/base/compute1,mysql/basic/compute1,2,3))
$(eval $(call ubuntu_disk_convert_raw_rules,mysql/base/compute2,mysql/basic/compute2,4,5))
$(eval $(call ubuntu_raw_disk_rules,mysql/basic,$(addprefix mysql/basic/,controller compute1 compute2)))

