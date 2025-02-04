UBUNTU_SECONDARY_DISK_SZ := 250G

# Disk images output directory
ubuntu_dimg_o := $(o)disks/
ubuntu_dimgs :=

$(eval $(call include_rules,$(d)base/rules.mk))
$(eval $(call include_rules,$(d)hosts/rules.mk))

.PRECIOUS: $(ubuntu_dimgs)

ubuntu_vmlinux := $(o)vmlinux
ubuntu_bzImage := $(o)bzImage
ubuntu_initrd := $(o)initrd.img

$(ubuntu_vmlinux): $(ubuntu_base_dimg)
	mkdir -p $(@D)
	rm -f $@
	sudo $(virt_copy_out) -a $< /output/vmlinux $(@D)
	sudo chown $(shell id -u):$(shell id -g) $@
	touch $@

$(ubuntu_bzImage): $(ubuntu_base_dimg)
	mkdir -p $(@D)
	rm -f $@
	sudo $(virt_copy_out) -a $< /output/bzImage $(@D)
	sudo chown $(shell id -u):$(shell id -g) $@
	touch $@

$(ubuntu_initrd): $(ubuntu_base_dimg)
	mkdir -p $(@D)
	rm -f $@
	sudo $(virt_copy_out) -a $< /output/initrd.img $(@D)
	sudo chown $(shell id -u):$(shell id -g) $@
	touch $@

$(o)basetmp/disk.qcow2: $(ubuntu_base_dimg)
	mkdir -p $(@D)
	rm -f $@
	$(qemu_img) create -f qcow2 -o backing_file=$(realpath --relative-to=$(@D) $<) -F qcow2 $@
	
.PHONY: qemu-ubuntu-basetmp
qemu-ubuntu-basetmp: $(o)basetmp/disk.qcow2 $(ubuntu_vmlinux) $(ubuntu_initrd)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp $(shell echo $$((`nproc` / 2))) -m $(shell echo $$((`free -m | awk '/^Mem:/ {print $$4}'` / 2)))M  \
	-drive file=$(word 1,$^),media=disk,format=qcow2,if=ide,index=0 \
	-netdev user,id=user-net \
	-device virtio-net-pci,netdev=user-net \
	-boot c \
	-kernel $(word 2,$^) \
	-initrd $(word 3,$^) \
	-append "earlyprintk=ttyS0 console=ttyS0 root=/dev/sda1 init=/sbin/guestinit.sh rw" \
	-display none -serial mon:stdio
	