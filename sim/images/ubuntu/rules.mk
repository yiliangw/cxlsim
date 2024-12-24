UBUNTU_IMAGE_URL := https://cloud-images.ubuntu.com/daily/server/jammy/20241217/jammy-server-cloudimg-amd64.img
UBUNTU_IMAGE_CKSUM_URL := https://cloud-images.ubuntu.com/daily/server/jammy/20241217/SHA256SUMS

UBUNTU_ROOT_DISK_SZ_MB := 256000
UBUNTU_SECONDARY_DISK_SZ_MB := 256000

ubuntu_seed_img := $(o)seed.img
ubuntu_root_img := $(o)root.qcow2
ubuntu_secondary_img := $(o)secondary.qcow2
ubuntu_input_dir := $(b)input/
ubuntu_input_tar := $(ubuntu_input_dir).tar
ubuntu_install_script := $(d)install.sh

$(ubuntu_root_img): $(eval packer_output_dir := $(b)packer_output)
$(ubuntu_root_img): $(packer_hcl) $(packer) $(ubuntu_seed_img) $(ubuntu_input_tar) $(ubuntu_install_script)
	rm -rf $(packer_output_dir)
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer) build \
	-var "cpus=`nproc`" \
	-var "disk_sz=$(UBUNTU_ROOT_DISK_SZ_MB)" \
	-var "iso_url=$(UBUNTU_IMAGE_URL)" \
	-var "iso_cksum_url=$(UBUNTU_IMAGE_CKSUM_URL)" \
	-var "out_dir="$(packer_output_dir) \
	-var "out_name=$(@F)" \
	-var "seedimg=$(ubuntu_seed_img)" \
	-var "input_tar=$(ubuntu_input_tar)" \
	-var "install_script=$(ubuntu_install_script)" \
	$(packer_hcl)
	mkdir -p $(@D)
	mv $(packer_output_dir)/$(@F) $@

$(ubuntu_secondary_img):
	$(qemu_img) create -f qcow2 $@ $(UBUNTU_SECONDARY_DISK_SZ_MB)M

$(ubuntu_seed_img): $(d)user-data $(d)meta-data
	mkdir -p $(@D)
	rm -f $@
	cloud-localds $@ $^

$(ubuntu_input_tar): $(ubuntu_input_dir)
	tar -cf $@ -C $< .

$(ubuntu_input_dir): $(devstack_dir)
	rm -rf $@
	mkdir -p $@
	cp -r $(devstack_dir) $@

.PRECIOUS: $(o)vm%_root.qcow2
$(o)vm%_root.qcow2: $(ubuntu_root_img)
	$(qemu_img) create -f qcow2 -F qcow2 -b $(shell realpath --relative-to=$(dir $@) $<) $@

.PRECIOUS: $(o)vm%_secondary.qcow2
$(o)vm%_secondary.qcow2: $(ubuntu_secondary_img)
	$(qemu_img) create -f qcow2 -F qcow2 -b $(shell realpath --relative-to=$(dir $@) $<) $@

qemu-ubuntu-vm%: $(o)vm%_root.qcow2 $(o)vm%_secondary.qcow2
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp 4 -m 4G \
	-drive file=$(word 1, $^),media=disk,format=qcow2,if=ide,index=0 \
	-drive file=$(word 2, $^),media=disk,format=qcow2,if=ide,index=1 \
	-netdev bridge,id=net0,br=$(BRIDGE_IF) \
	-device virtio-net-pci,netdev=net0,mac=$(shell printf 00:11:22:33:44:%02x $*) \
	-boot c \
	-display none -serial mon:stdio
