PACKER_VERSION := 1.9.0

UBUNTU_IMAGE_URL := https://cloud-images.ubuntu.com/daily/server/jammy/20241217/jammy-server-cloudimg-amd64.img
UBUNTU_IMAGE_CKSUM_URL := https://cloud-images.ubuntu.com/daily/server/jammy/20241217/SHA256SUMS
UBUNTU_IMAGE_SZ_MB := 256000

qemu := qemu-system-x86_64
qemu_img := qemu-img

packer := $(b)packer
packer_hcl := $(d)disk.pkr.hcl
packer_cache_dir := $(b).packer_cache

ubuntu_seed_img := $(o)ubuntu_seed.img
ubuntu_disk_img := $(o)ubuntu.qcow2
ubuntu_input_dir := $(b)ubuntu_input
ubuntu_input_tar := $(ubuntu_input_dir).tar
ubuntu_install_script := $(d)ubuntu/install.sh

ubuntu_test_disk_img := $(o)ubuntu_test.qcow2

$(ubuntu_disk_img): $(eval packer_output_dir := $(b)packer_output.ubuntu)
$(ubuntu_disk_img): $(packer_hcl) $(packer) $(ubuntu_seed_img) $(ubuntu_input_tar)
	rm -rf $(packer_output_dir)
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer) build \
	-var "cpus=`nproc`" \
	-var "disk_sz=$(UBUNTU_IMAGE_SZ_MB)" \
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

$(packer): packer_zip := $(b)packer_$(PACKER_VERSION)_linux_amd64.zip
$(packer):
	mkdir -p $(dir $(packer_zip))
	wget -O $(packer_zip) https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_linux_amd64.zip
	unzip -o -d $(@D) $(packer_zip)
	touch $@

$(ubuntu_seed_img): $(d)ubuntu/user-data $(d)ubuntu/meta-data
	mkdir -p $(@D)
	rm -f $@
	cloud-localds $@ $^

$(ubuntu_input_tar): $(d)guestinit.sh   
	rm -rf $(ubuntu_input_dir)
	mkdir -p $(ubuntu_input_dir)
	cp $^ $(ubuntu_input_dir)
	tar -cf $@ -C $(ubuntu_input_dir) .

$(ubuntu_test_disk_img): $(ubuntu_disk_img)
	$(qemu_img) create -f qcow2 -F qcow2 -b $(shell realpath --relative-to=$(dir $@) $<) $@

.PHONY: qemu-ubuntu-test  
qemu-ubuntu-test: $(ubuntu_test_disk_img)
	$(qemu) -machine q35,accel=kvm -cpu host -smp 4 -m 4G \
	-drive file=$<,media=disk,format=qcow2,if=ide,index=0 \
	-device virtio-net-pci,netdev=net0 -netdev user,id=net0 \
	-boot c \
	-display none -serial mon:stdio 
