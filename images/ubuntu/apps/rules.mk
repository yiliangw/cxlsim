define qemu_ubuntu_app_rule
$(eval app := $(1))
$(eval node := $(2))
$(eval management_mac := $(call conffget,host,.qemu_mac_list[$(3)]))
$(eval provider_mac := $(call conffget,host,.qemu_mac_list[$(4)]))
$(eval app_deps := $(5))

.PRECIOUS: $(ubuntu_dimg_o)$(app)/$(node)/disk.qcow2
$(ubuntu_dimg_o)$(app)/$(node)/disk.qcow2: $(ubuntu_dimg_o)setup/$(node)/disk.qcow2 $(app_deps) | $(ubuntu_dimg_o)$(app)/$(node)/
	@rm -rf $$@
	$(QEMU_IMG) create -f qcow2 -F qcow2 -b $$(realpath --relative-to=$$(@D) $$<) $$@

clean_ubuntu_$(app) += $(ubuntu_dimg_o)$(app)/$(node)/disk.qcow2

.PHONY: qemu-ubuntu-$(app)-$(node)
qemu-ubuntu-$(app)-$(node): $(ubuntu_dimg_o)$(app)/$(node)/disk.qcow2 $(host_config_deps) $(ubuntu_vmlinux) $(ubuntu_initrd)
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
endef

$(eval $(call qemu_ubuntu_app_rule,mysql,controller,0,1,$(mysql_workload_deps)))
$(eval $(call qemu_ubuntu_app_rule,mysql,compute1,2,3))
$(eval $(call qemu_ubuntu_app_rule,mysql,compute2,4,5))

.PHONY: clean-ubuntu-mysql
clean-ubuntu-mysql:
	rm -rf $(clean_ubuntu_mysql)