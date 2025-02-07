.PHONY: qemu-ubuntu-controller-bridge
qemu-ubuntu-controller-bridge: $(ubuntu_dimg_o)controller/disk.qcow2 $(config_deps)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp 4 -m 16G \
	-drive file=$(word 1, $^),media=disk,format=qcow2,if=ide,index=0 \
	-netdev bridge,id=net-management,br=$(call confget,.host.bridges.management.name) \
	-device virtio-net-pci,netdev=net-management,mac=$(call confget,.host.qemu_mac_list[0]) \
	-netdev bridge,id=net-provider,br=$(call confget,.host.bridges.provider.name) \
	-device virtio-net-pci,netdev=net-provider,mac=$(call confget,.host.qemu_mac_list[1]) \
	-boot c \
	-display none -serial mon:stdio

.PHONY: qemu-ubuntu-controller
qemu-ubuntu-controller: $(ubuntu_dimg_o)controller/disk.qcow2 $(config_deps)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp 4 -m 16G \
	-drive file=$(word 1, $^),media=disk,format=qcow2,if=ide,index=0 \
	-netdev user,id=user-net \
	-device virtio-net-pci,netdev=user-net \
	-boot c \
	-display none -serial mon:stdio

ubuntu_dimgs += $(ubuntu_dimg_o)controller/disk.qcow2
$(ubuntu_dimg_o)controller/disk.qcow2: $(ubuntu_dimg_o)controller_phase2/disk.qcow2
	mkdir -p $(@D)
	rm -f $@
	ln -s $(shell realpath --relative-to=$(dir $@) $<) $@

$(ubuntu_dimg_o)controller_phase2/disk.qcow2: $(ubuntu_dimg_o)controller_phase1/disk.qcow2 $(b)phase2/input.tar $(d)phase2/install.sh $(base_hcl) $(packer) $(config_deps)	
	rm -rf $(@D)
	mkdir -p $(dir $(@D))
	$(packer_run) build \
	-var "base_img=$(word 1, $^)" \
	-var "disk_size=$(call conffget,platform,.ubuntu.disk.size)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "user_name=root" \
	-var "user_password=$(call conffget,platform,.ubuntu.root.password)" \
	-var "input_tar_src=$(word 2,$^)" \
	-var "install_script=$(word 3,$^)" \
	$(extend_hcl)

.PRECIOUS: $(ubuntu_dimg_o)controller_phase1/disk.qcow2
$(ubuntu_dimg_o)controller_phase1/disk.qcow2: $(ubuntu_base_dimg) $(b)phase1/input.tar $(d)phase1/install.sh $(extend_hcl) $(packer) $(platform_config_deps)
	rm -rf $(@D)
	mkdir -p $(dir $(@D))
	$(packer_run) build \
	-var "base_img=$<" \
	-var "disk_size=$(call conffget,platform,.ubuntu.disk.size)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "user_name=root" \
	-var "user_password=$(call conffget,platform,.ubuntu.root.password)" \
	-var "input_tar_src=$(word 2,$^)" \
	-var "install_script=$(word 3,$^)" \
	$(extend_hcl)

$(b)phase1/input.tar:
	rm -rf $(@D)/input
	mkdir -p $(@D)/input
	tar -C $(@D)/input -cf $@ .

$(b)phase2/input.tar: $(addprefix $(b)phase2/input/, \
	$(ubuntu_phase2_common_input) \
	$(addprefix prepare/, run.sh chrony.conf mysql/99-openstack.cnf memcached.conf etcd keystone.sh keystone.conf \
	glance.sh glance-api.conf placement.sh placement.conf nova.sh nova.conf neutron.sh neutron/neutron.conf \
	neutron/ml2_conf.ini neutron/openvswitch_agent.ini neutron/dhcp_agent.ini neutron/l3_agent.ini neutron/metadata_agent.ini instances.sh) \
	$(addprefix run/, run.sh))
	tar -C $(@D)/input -cf $@ .

INPUT_TAR_ALL += $(b)phase2/input.tar

$(b)phase2/input/%: $(d)phase2/input/%
	mkdir -p $(@D)
	cp $< $@
$(b)phase2/input/%: $(d)../common/phase2/input/%
	mkdir -p $(@D)
	cp $< $@
$(b)phase2/input/%: $(b)controller.sed $(d)phase2/input/%.tpl
	mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@
$(b)phase2/input/%: $(b)controller.sed $(d)../common/phase2/input/%.tpl
	mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@

# Disk images
ubuntu_openstack_images := cirros.qcow2 mysql_server.qcow2 mysql_client.qcow2

p2_imgs_input_prefix := $(b)phase2/input/prepare/images/

$(b)phase2/input.tar: $(addprefix $(p2_imgs_input_prefix), $(ubuntu_openstack_images))

$(p2_imgs_input_prefix)cirros.qcow2:
	mkdir -p $(@D)
	wget -O $@ http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img 

$(p2_imgs_input_prefix)mysql_server.qcow2: $(mysql_server_disk_image)
	mkdir -p $(@D)
	cp $< $@

$(p2_imgs_input_prefix)mysql_client.qcow2: $(mysql_client_disk_image)
	mkdir -p $(@D)
	cp $< $@

$(o)controller.yaml: $(d)controller.yaml.tpl $(config_deps)
	mkdir -p $(@D)
	$(call confsed,$<,$@.tmp)
	$(yq) eval-all 'select(fileIndex == 0) * select(fileIndex == 1) | explode(.) ' $@.tmp $(config_yaml) > $@
	rm $@.tmp

$(b)controller.sed: $(o)controller.yaml $(yq)
	mkdir -p $(@D)
	$(call yaml2sed,$<,$@)
