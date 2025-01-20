UBUNTU_ROOT_DISK_SZ := 250G
UBUNTU_SECONDARY_DISK_SZ := 250G

$(eval $(call include_rules,$(d)base/rules.mk))
$(eval $(call include_rules,$(d)nodes/rules.mk))

.PHONY: qemu-ubuntu-%
qemu-ubuntu-%: $(o)nodes/%/root/disk.qcow2 $(o)nodes/%/secondary/disk.qcow2 $(config_deps)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp 4 -m 16G \
	-drive file=$(word 1, $^),media=disk,format=qcow2,if=ide,index=0 \
	-drive file=$(word 2, $^),media=disk,format=qcow2,if=ide,index=1 \
	-netdev bridge,id=net-management,br=$(call confget,.host.bridges.management.name) \
	-device virtio-net-pci,netdev=net-management,mac=$(call confget,.openstack.network.management.hosts.$*.mac) \
	-netdev bridge,id=net-provider,br=$(call confget,.host.bridges.provider.name) \
	-device virtio-net-pci,netdev=net-provider,mac=$(call confget,.openstack.network.provider.hosts.$*.mac) \
	-boot c \
	-display none -serial mon:stdio
