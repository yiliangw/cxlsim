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

ubuntu_test_secondary_img := $(o)test_secondary.qcow2
ubuntu_test_root_img := $(o)test_root.qcow2

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

$(ubuntu_test_root_img): $(ubuntu_root_img)
	$(qemu_img) create -f qcow2 -F qcow2 -b $(shell realpath --relative-to=$(dir $@) $<) $@

$(ubuntu_test_secondary_img): $(ubuntu_secondary_img)
	$(qemu_img) create -f qcow2 -F qcow2 -b $(shell realpath --relative-to=$(dir $@) $<) $@

.PHONY: qemu-ubuntu-test  
qemu-ubuntu-test: $(ubuntu_test_root_img) $(ubuntu_test_secondary_img)
	$(qemu) -machine q35,accel=kvm -cpu host -smp 4 -m 4G \
	-drive file=$(ubuntu_test_root_img),media=disk,format=qcow2,if=ide,index=0 \
	-drive file=$(ubuntu_test_secondary_img),media=disk,format=qcow2,if=ide,index=1 \
	-device virtio-net-pci,netdev=net0 -netdev user,id=net0 \
	-boot c \
	-display none -serial mon:stdio 
 