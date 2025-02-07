UBUNTU_SECONDARY_DISK_SZ := 250G

# Disk images output directory
ubuntu_img_o := $(o)
ubuntu_dimg_o := $(o)disks/
ubuntu_dimgs :=

.PRECIOUS: $(ubuntu_dimg_o)%

$(eval $(call include_rules,$(d)base/rules.mk))
$(eval $(call include_rules,$(d)hosts/rules.mk))

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

$(o)basetmp/disk.qcow2: $(ubuntu_base_dimg) | $(o)basetmp/
	rm -f $@
	$(qemu_img) create -f qcow2 -o backing_file=$(realpath --relative-to=$(@D) $<) -F qcow2 $@

qemu := $(simbricks_dir)sims/external/qemu/build/x86_64-softmmu/qemu-system-x86_64
	
.PHONY: qemu-ubuntu-basetmp
qemu-ubuntu-basetmp: $(o)basetmp/disk.qcow2 $(ubuntu_vmlinux) $(ubuntu_initrd)
	sudo -E $(qemu) -machine q35 -cpu Skylake-Server -smp $(shell echo $$((`nproc` / 2))) -m $(shell echo $$((`free -m | awk '/^Mem:/ {print $$4}'` / 2)))M  \
	-drive file=$(word 1,$^),media=disk,format=qcow2,if=ide,index=0 \
	-netdev user,id=user-net \
	-kernel $(word 2,$^) \
	-initrd $(word 3,$^) \
	-append "earlyprintk=ttyS0 console=ttyS0 root=/dev/sda1 rw" \
	-device virtio-net-pci,netdev=user-net \
	-boot c \
	-display none -serial mon:stdio

	