UBUNTU_ROOT_DISK_SZ := 250G
UBUNTU_SECONDARY_DISK_SZ := 250G

$(eval $(call include_rules,$(d)base/rules.mk))
$(eval $(call include_rules,$(d)nodes/rules.mk))

.PHONY: qemu-ubuntu-%
qemu-ubuntu-%: $(o)nodes/%/root/disk.qcow2 $(o)nodes/%/secondary/disk.qcow2 $(ubuntu_config)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp 4 -m 16G \
	-drive file=$(word 1, $^),media=disk,format=qcow2,if=ide,index=0 \
	-drive file=$(word 2, $^),media=disk,format=qcow2,if=ide,index=1 \
	-netdev bridge,id=net-management,br=$(call confget_ubuntu,.network.management.bridge) \
	-device virtio-net-pci,netdev=net-management,mac=$(call confget_ubuntu,.network.management.nodes.$*.mac) \
	-netdev bridge,id=net-service,br=$(call confget_ubuntu,.network.service.bridge) \
	-device virtio-net-pci,netdev=net-service,mac=$(call confget_ubuntu,.network.service.nodes.$*.mac) \
	-boot c \
	-display none -serial mon:stdio
