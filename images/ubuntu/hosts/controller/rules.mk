ubuntu_dimgs += $(ubuntu_dimg_o)controller/disk.qcow2

.PRECIOUS: $(ubuntu_dimg_o)controller/disk.qcow2
$(ubuntu_dimg_o)controller/disk.qcow2: $(ubuntu_dimg_o)controller_base/disk.qcow2 | $(ubuntu_dimg_o)controller/
	@rm -rf $@
	@echo --relative-to=$(dir $@) $< 
	$(QEMU_IMG) create -f qcow2 -F qcow2 -b $(realpath --relative-to=$(@D) $<) $@

.PRECIOUS: $(ubuntu_dimg_o)controller_base/disk.qcow2
$(ubuntu_dimg_o)controller_base/disk.qcow2: $(ubuntu_base_dimg) $(b)phase1/input.tar $(d)phase1/install.sh $(extend_hcl) $(packer) $(platform_config_deps) | $(ubuntu_dimg_o)
	rm -rf $(@D)
	$(packer_run) build \
	-var "base_img=$<" \
	-var "disk_size=$(call conffget,platform,.ubuntu.disks.controller.size)" \
	-var "cpus=$(IMAGE_BUILD_CPUS)" \
	-var "memory=$(IMAGE_BUILD_MEMORY)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "user_name=root" \
	-var "user_password=$(call conffget,platform,.ubuntu.root.password)" \
	-var "input_tar_src=$(word 2,$^)" \
	-var "install_script=$(word 3,$^)" \
	-var "use_backing_file=false" \
	$(extend_hcl)

$(b)phase1/input.tar:
	rm -rf $(@D)/input
	mkdir -p $(@D)/input
	tar -C $(@D)/input -cf $@ .

inputd_ := $(b)phase2/input/

$(ubuntu_input_tar_o)controller_phase2.tar: $(b)phase2/input.tar | $(ubuntu_input_tar_o)
	@rm -f $@
	ln -s $(shell realpath --relative-to=$(dir $@) $<) $@

$(ubuntu_install_script_o)controller_phase2.sh: $(d)phase2/install.sh | $(ubuntu_install_script_o)
	@rm -f $@
	ln -s $(shell realpath --relative-to=$(dir $@) $<) $@

$(b)phase2/input.tar: $(addprefix $(inputd_), \
	$(ubuntu_phase2_common_input) \
	$(addprefix setup/, run.sh chrony.conf mysql/99-openstack.cnf memcached.conf etcd keystone.sh keystone.conf \
	glance.sh glance-api.conf placement.sh placement.conf nova.sh nova.conf neutron.sh neutron/neutron.conf \
	neutron/ml2_conf.ini neutron/openvswitch_agent.ini neutron/dhcp_agent.ini neutron/l3_agent.ini neutron/metadata_agent.ini misc.sh))
	tar -cf $@ -C $(@D)/input .

INPUT_TAR_ALL += $(b)phase2/input.tar

$(inputd_)%: $(d)phase2/input/%
	@mkdir -p $(@D)
	cp $< $@
$(inputd_)%: $(d)../common/phase2/input/%
	@mkdir -p $(@D)
	cp $< $@
$(inputd_)%: $(b)controller.sed $(d)phase2/input/%.tpl
	@mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@
$(inputd_)%: $(b)controller.sed $(d)../common/phase2/input/%.tpl
	@mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@

$(o)controller.yaml: $(d)controller.yaml.tpl $(config_deps) | $(o)
	$(call confsed,$<,$@.tmp)
	$(yq) eval-all 'select(fileIndex == 0) * select(fileIndex == 1) | explode(.) ' $@.tmp $(config_yaml) > $@
	rm $@.tmp

$(b)controller.sed: $(o)controller.yaml | $(b)
	$(call yaml2sed,$<,$@)
