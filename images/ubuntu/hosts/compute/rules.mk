.PHONY: qemu-ubuntu-compute1
qemu-ubuntu-compute1: $(ubuntu_dimg_o)compute1/disk.qcow2 $(config_deps)
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp 4 -m 16G \
	-drive file=$(word 1, $^),media=disk,format=qcow2,if=ide,index=0 \
	-netdev bridge,id=net-management,br=$(call confget,.host.bridges.management.name) \
	-device virtio-net-pci,netdev=net-management,mac=$(call confget,.host.qemu_mac_list[3]) \
	-netdev bridge,id=net-provider,br=$(call confget,.host.bridges.provider.name) \
	-device virtio-net-pci,netdev=net-provider,mac=$(call confget,.host.qemu_mac_list[4]) \
	-boot c \
	-display none -serial mon:stdio

.PRECIOUS: $(ubuntu_dimg_o)compute%/disk.qcow2
$(ubuntu_dimg_o)compute%/disk.qcow2: $(ubuntu_dimg_o)compute%_phase2/disk.qcow2
	mkdir -p $(@D)
	rm -f $@
	ln -s $(shell realpath --relative-to=$(dir $@) $<) $@

$(ubuntu_dimg_o)compute%_phase2/disk.qcow2: $(ubuntu_dimg_o)compute%_phase1/disk.qcow2 $(b)compute%/phase2/input.tar $(d)phase2/install.sh $(extend_hcl) $(packer)
	rm -rf $(@D)
	mkdir -p $(dir $(@D))
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer) build \
	-var "base_img=$(word 1,$^)" \
	-var "disk_size=$(UBUNTU_ROOT_DISK_SZ)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "input_tar_src=$(word 2,$^)" \
	-var "install_script=$(word 3,$^)" \
	$(extend_hcl)

.PRECIOUS: $(ubuntu_dimg_o)compute%_phase1/disk.qcow2
$(ubuntu_dimg_o)compute%_phase1/disk.qcow2: $(ubuntu_base_dimg) $(b)compute%/phase1/input.tar $(d)phase1/install.sh $(extend_hcl) $(packer) 
	rm -rf $(@D)
	mkdir -p $(dir $(@D))
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer) build \
	-var "base_img=$(word 1,$^)" \
	-var "disk_size=$(UBUNTU_ROOT_DISK_SZ)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "input_tar_src=$(word 2,$^)" \
	-var "install_script=$(word 3,$^)" \
	$(extend_hcl)

$(b)compute%/phase1/input.tar:
	rm -rf $(@D)/input
	mkdir -p $(@D)/input
	tar -C $(@D)/input -cf $@ .

$(b)compute%/phase2/input.tar: $(addprefix $(b)compute%/phase2/input/, \
	$(ubuntu_phase2_common_input) \
	$(addprefix setup/, run.sh chrony.conf nova.sh nova.conf neutron.sh neutron/neutron.conf neutron/openvswitch_agent.ini))
	mkdir -p $(@D)
	tar -C $(@D)/input -cf $@ .

INPUT_TAR_ALL += $(b)compute1/phase2/input.tar

$(o)compute%.yaml: $(d)compute%.yaml.tpl $(config_deps)
	mkdir -p $(@D)
	$(call confsed,$<,$@.tmp)
	$(yq) eval-all 'select(fileIndex == 0) * select(fileIndex == 1) | explode(.) ' $@.tmp $(config_yaml) > $@
	rm $@.tmp

$(b)compute%.sed: $(o)compute%.yaml $(yq)
	mkdir -p $(@D)
	$(call yaml2sed,$<,$@)


$(b)compute1/phase2/input/%: $(d)phase2/input/%
	mkdir -p $(@D)
	cp $< $@
$(b)compute1/phase2/input/%: $(d)../common/phase2/input/%
	mkdir -p $(@D)
	cp $< $@
$(b)compute1/phase2/input/%: $(b)compute1.sed $(d)phase2/input/%.tpl
	mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@
$(b)compute1/phase2/input/%: $(b)compute1.sed $(d)../common/phase2/input/%.tpl
	mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@

