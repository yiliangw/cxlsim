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

.PHONY: ubuntu-host-base-dimgs
ubuntu-host-base-dimgs: $(addprefix $(ubuntu_dimg_o),$(addsuffix /disk.qcow2,controller_base compute1_base compute2_base)) 

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

.PHONY: qemu-ubuntu-bridge-%
qemu-ubuntu-bridge-controller: $(ubuntu_dimg_o)controller/disk.qcow2 $(ubuntu_input_tar_o)controller_phase2.tar $(ubuntu_install_script_o)controller_phase2.sh $(host_config_deps) $(ubuntu_vmlinux) $(ubuntu_initrd)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu Skylake-Server -smp 8 -m 16G \
	-kernel $(ubuntu_vmlinux) \
	-append "$(ubuntu_kernel_cmdline)" \
	-initrd $(ubuntu_initrd) \
	-drive file=$(word 1, $^),media=disk,format=qcow2,if=ide,index=0 \
	-drive file=${word 2, $^},media=disk,format=raw,if=ide,index=1 \
	-drive file=${word 3, $^},media=disk,format=raw,if=ide,index=2 \
	-netdev bridge,id=net-management,br=$(call conffget,host,.bridges.management.name) \
	-device virtio-net-pci,netdev=net-management,mac=$(call conffget,host,.qemu_mac_list[0]) \
	-netdev bridge,id=net-provider,br=$(call conffget,host,.bridges.provider.name) \
	-device virtio-net-pci,netdev=net-provider,mac=$(call conffget,host,.qemu_mac_list[1]) \
	-boot c \
	-display none -serial mon:stdio

qemu-ubuntu-bridge-compute1: $(ubuntu_dimg_o)compute1/disk.qcow2 $(ubuntu_input_tar_o)compute1_phase2.tar $(ubuntu_install_script_o)compute1_phase2.sh $(host_config_deps) $(ubuntu_vmlinux) $(ubuntu_initrd)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu Skylake-Server -smp 8 -m 16G \
	-kernel $(ubuntu_vmlinux) \
	-append "$(ubuntu_kernel_cmdline)" \
	-initrd $(ubuntu_initrd) \
	-drive file=$(word 1, $^),media=disk,format=qcow2,if=ide,index=0 \
	-drive file=${word 2, $^},media=disk,format=raw,if=ide,index=1 \
	-drive file=${word 3, $^},media=disk,format=raw,if=ide,index=2 \
	-netdev bridge,id=net-management,br=$(call conffget,host,.bridges.management.name) \
	-device virtio-net-pci,netdev=net-management,mac=$(call conffget,host,.qemu_mac_list[2]) \
	-netdev bridge,id=net-provider,br=$(call conffget,host,.bridges.provider.name) \
	-device virtio-net-pci,netdev=net-provider,mac=$(call conffget,host,.qemu_mac_list[3]) \
	-boot c \
	-display none -serial mon:stdio

qemu-ubuntu-bridge-compute2: $(ubuntu_dimg_o)compute2/disk.qcow2 $(ubuntu_input_tar_o)compute2_phase2.tar $(ubuntu_install_script_o)compute2_phase2.sh $(host_config_deps) $(ubuntu_vmlinux) $(ubuntu_initrd)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu Skylake-Server -smp 8 -m 16G \
	-kernel $(ubuntu_vmlinux) \
	-append "$(ubuntu_kernel_cmdline)" \
	-initrd $(ubuntu_initrd) \
	-drive file=$(word 1, $^),media=disk,format=qcow2,if=ide,index=0 \
	-drive file=${word 2, $^},media=disk,format=raw,if=ide,index=1 \
	-drive file=${word 3, $^},media=disk,format=raw,if=ide,index=2 \
	-netdev bridge,id=net-management,br=$(call conffget,host,.bridges.management.name) \
	-device virtio-net-pci,netdev=net-management,mac=$(call conffget,host,.qemu_mac_list[4]) \
	-netdev bridge,id=net-provider,br=$(call conffget,host,.bridges.provider.name) \
	-device virtio-net-pci,netdev=net-provider,mac=$(call conffget,host,.qemu_mac_list[5]) \
	-boot c \
	-display none -serial mon:stdio

