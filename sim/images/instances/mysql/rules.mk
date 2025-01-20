$(eval $(call include_rules,$(d)server/rules.mk))
$(eval $(call include_rules,$(d)client/rules.mk))

.PHONY: qemu-mysql-server qemu-mysql-client

qemu-mysql-server: $(mysql_server_disk_image)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp 4 -m 16G \
	-drive file=$<,media=disk,format=qcow2,if=ide,index=0 \
	-netdev bridge,id=net-bridge,br=$(call confget,.host.bridges.selfservice.name) \
	-device virtio-net-pci,netdev=net-bridge,mac=$(call confget,.host.qemu_mac_list[0]) \
	-boot c \
	-display none -serial mon:stdio

qemu-mysql-client: $(mysql_client_disk_image)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp 4 -m 16G \
	-drive file=$<,media=disk,format=qcow2,if=ide,index=0 \
	-netdev bridge,id=net-bridge,br=$(call confget,.host.bridges.selfservice.name) \
	-device virtio-net-pci,netdev=net-bridge,mac=$(call confget,.host.qemu_mac_list[1]) \
	-boot c \
	-display none -serial mon:stdio
