UBUNTU_IMAGE_URL := https://cloud-images.ubuntu.com/daily/server/jammy/20241217/jammy-server-cloudimg-amd64.img
UBUNTU_IMAGE_CKSUM_URL := https://cloud-images.ubuntu.com/daily/server/jammy/20241217/SHA256SUMS

UBUNTU_ROOT_DISK_SZ := 250G
UBUNTU_SECONDARY_DISK_SZ := 250G

ubuntu_seed_img := $(o)base/seed.raw
ubuntu_base_root_img := $(o)base/root/disk.qcow2
ubuntu_base_secondary_img := $(o)base/secondary/disk.qcow2
ubuntu_base_input_dir := $(b)base/input/
ubuntu_base_input_tar := $(b)base/input.tar
ubuntu_base_install_script := $(d)base_install.sh
ubuntu_extend_install_script := $(d)extend_install.sh

.PRECIOUS: $(ubuntu_base_root_img) $(ubuntu_base_secondary_img)
$(ubuntu_base_root_img): $(base_hcl) $(packer) $(ubuntu_seed_img) $(ubuntu_base_input_tar) $(ubuntu_base_install_script)
	rm -rf $(@D) 
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer) build \
	-var "cpus=`nproc`" \
	-var "disk_size=$(UBUNTU_ROOT_DISK_SZ)" \
	-var "iso_url=$(UBUNTU_IMAGE_URL)" \
	-var "iso_cksum_url=$(UBUNTU_IMAGE_CKSUM_URL)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "seedimg=$(ubuntu_seed_img)" \
	-var "input_tar_src=$(ubuntu_base_input_tar)" \
	-var "input_tar_dst=/tmp/input.tar" \
	-var "install_script=$(ubuntu_base_install_script)" \
	$(base_hcl)

$(ubuntu_base_secondary_img):
	mkdir -p $(@D)
	$(qemu_img) create -f qcow2 $@ $(UBUNTU_SECONDARY_DISK_SZ)

$(ubuntu_seed_img): $(d)user-data $(d)meta-data
	mkdir -p $(@D)
	rm -f $@
	$(MAKE) start-ubuntu-docker
	$(ubuntu_docker_exec) "cloud-localds $@ $^"
	$(MAKE) stop-ubuntu-docker

$(b)base/input.tar: $(d)input/base/ $(d)input/base/hosts  $(addprefix $(d)input/base/env/, passwdrc admin_openrc baize_openrc utils/sed_tpl.sh)
	rm -rf $(@D)/input	
	mkdir -p $(@D)/input
	cp -r $(word 1, $^)* $(@D)/input
	tar -C $< -cf $@ .

ubuntu_node_input := var netplan/90-baize-config.yaml chrony/chrony.conf

$(b)node_controller/input.tar: $(d)input/controller/special/install.sh $(addprefix $(d)input/controller/special/setup/, run.sh mysql/99-openstack.cnf etcd memcached.conf keystone.sh keystone.conf.tpl glance.sh glance-api.conf.tpl placement.sh placement.conf.tpl nova.sh nova.conf.tpl)

$(b)node_%/input.tar: $(d)input/%/ $(addprefix $(d)input/%/, $(ubuntu_node_input))
	rm -rf $(@D)/input
	mkdir -p $(@D)/input
	cp -r $(word 1, $^)* $(@D)/input
	tar -C $(@D)/input -cf $@ .

.PRECIOUS: $(o)node_%/root/disk.qcow2 $(o)node_%/secondary/disk.qcow2

$(o)node_%/root/disk.qcow2: $(ubuntu_base_root_img) $(b)node_%/input.tar $(extend_hcl) $(packer) $(ubuntu_extend_install_script)
	rm -rf $(@D)
	mkdir -p $(dir $(@D))
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer) build \
	-var "cpus=`nproc`" \
	-var "base_img=$(word 1, $^)" \
	-var "disk_size=$(UBUNTU_ROOT_DISK_SZ)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "input_tar_src=$(word 2, $^)" \
	-var "input_tar_dst=/tmp/input.tar" \
	-var "install_script=$(ubuntu_extend_install_script)" \
	$(extend_hcl)

$(o)node_%/secondary/disk.qcow2: $(ubuntu_base_secondary_img)
	mkdir -p $(@D)
	$(qemu_img) create -f qcow2 -F qcow2 -b $(shell realpath --relative-to=$(dir $@) $<) $@

.PHONY: qemu-ubuntu-%
qemu-ubuntu-%: $(o)node_%/root/disk.qcow2 $(o)node_%/secondary/disk.qcow2 $(ubuntu_config)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp 4 -m 16G \
	-drive file=$(word 1, $^),media=disk,format=qcow2,if=ide,index=0 \
	-drive file=$(word 2, $^),media=disk,format=qcow2,if=ide,index=1 \
	-netdev bridge,id=net-management,br=$(call confget_ubuntu,.network.management.bridge) \
	-device virtio-net-pci,netdev=net-management,mac=$(call confget_ubuntu,.network.management.nodes.$*.mac) \
	-netdev bridge,id=net-service,br=$(call confget_ubuntu,.network.service.bridge) \
	-device virtio-net-pci,netdev=net-service,mac=$(call confget_ubuntu,.network.service.nodes.$*.mac) \
	-boot c \
	-display none -serial mon:stdio
