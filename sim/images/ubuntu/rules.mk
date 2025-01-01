UBUNTU_IMAGE_URL := https://cloud-images.ubuntu.com/daily/server/jammy/20241217/jammy-server-cloudimg-amd64.img
UBUNTU_IMAGE_CKSUM_URL := https://cloud-images.ubuntu.com/daily/server/jammy/20241217/SHA256SUMS

UBUNTU_ROOT_DISK_SZ := 250G
UBUNTU_SECONDARY_DISK_SZ := 250G

ubuntu_seed_img := $(o)base/seed.raw
ubuntu_base_root_img := $(o)base/root/disk.qcow2
ubuntu_base_secondary_img := $(o)base/secondary/disk.qcow2
ubuntu_base_install_script := $(d)base_install.sh
ubuntu_extend_install_script := $(d)extend_install.sh

.PRECIOUS: $(ubuntu_base_root_img) $(ubuntu_base_secondary_img)

$(ubuntu_base_root_img): $(b)base/input.tar $(base_hcl) $(packer) $(ubuntu_seed_img) $(ubuntu_base_install_script)
	rm -rf $(@D) 
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer) build \
	-var "disk_size=$(UBUNTU_ROOT_DISK_SZ)" \
	-var "iso_url=$(UBUNTU_IMAGE_URL)" \
	-var "iso_cksum_url=$(UBUNTU_IMAGE_CKSUM_URL)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "seedimg=$(ubuntu_seed_img)" \
	-var "input_tar_src=$(word 1, $^)" \
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

$(b)base/input.tar: $(b)base/input/
	rm -rf $(@D)/input	
	mkdir -p $(@D)/input
	cp -r $(word 1, $^)* $(@D)/input
	tar -C $< -cf $@ .

$(b)base/input/:
	mkdir -p $@

$(o)nodes/%.yaml: $(d)templates/%.yaml.tpl $(ubuntu_sed) $(ubuntu_config) $(yq)
	mkdir -p $(@D)
	sed -f $(ubuntu_sed) $< > $@.tmp
	$(yq) eval-all 'select(fileIndex == 0) * select(fileIndex == 1) | explode(.) ' $@.tmp $(ubuntu_config) > $@
	rm $@.tmp

$(b)nodes/%.sed: $(o)nodes/%.yaml $(yq)
	mkdir -p $(@D)
	$(call yaml2sed,$<,$@)

ubuntu_common_input := hostname hosts netplan.yaml \
	$(addprefix env/, admin_openrc passwdrc user_openrc)

$(b)nodes/controller/input/: $(addprefix $(b)nodes/controller/input/, $(ubuntu_common_input) install.sh chrony.conf\
	$(addprefix setup/, run.sh mysql/99-openstack.cnf memcached.conf etcd keystone.sh keystone.conf \
	glance.sh glance-api.conf placement.sh placement.conf nova.sh nova.conf))

$(b)nodes/controller/input/%: $(d)templates/controller/%
	mkdir -p $(@D)
	cp $< $@
$(b)nodes/controller/input/%: $(d)templates/common/%
	mkdir -p $(@D)
	cp $< $@
$(b)nodes/controller/input/%: $(b)nodes/controller.sed $(d)templates/controller/%.tpl
	mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@
$(b)nodes/controller/input/%: $(b)nodes/controller.sed $(d)templates/common/%.tpl
	mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@

.PRECIOUS: $(b)nodes/%/input.tar

$(b)nodes/%/input.tar: $(b)nodes/%/input/
	tar -C $< -cf $@ .

.PRECIOUS: $(o)nodes/%/root/disk.qcow2 $(o)nodes/%/secondary/disk.qcow2

$(o)nodes/%/root/disk.qcow2: $(ubuntu_base_root_img) $(b)nodes/%/input.tar $(extend_hcl) $(packer) $(ubuntu_extend_install_script)
	rm -rf $(@D)
	mkdir -p $(dir $(@D))
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer) build \
	-var "base_img=$(word 1, $^)" \
	-var "disk_size=$(UBUNTU_ROOT_DISK_SZ)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "input_tar_src=$(word 2, $^)" \
	-var "input_tar_dst=/tmp/input.tar" \
	-var "install_script=$(ubuntu_extend_install_script)" \
	$(extend_hcl)

$(o)nodes/%/secondary/disk.qcow2: $(ubuntu_base_secondary_img)
	mkdir -p $(@D)
	$(qemu_img) create -f qcow2 -F qcow2 -b $(shell realpath --relative-to=$(dir $@) $<) $@

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
