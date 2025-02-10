$(ubuntu_dimg_o)compute%/disk.qcow2: $(ubuntu_dimg_o)compute%_phase2/disk.qcow2 | $(ubuntu_dimg_o)compute%/
	@rm -f $@
	ln -s $(shell realpath --relative-to=$(dir $@) $<) $@

.PRECIOUS: $(ubuntu_dimg_o)compute%_phase2/disk.qcow2
$(ubuntu_dimg_o)compute%_phase2/disk.qcow2: $(ubuntu_dimg_o)compute%_phase1/disk.qcow2 $(b)compute%/phase2/input.tar $(d)phase2/install.sh $(extend_hcl) $(packer) $(platform_config_deps) | $(ubuntu_dimg_o)
	rm -rf $(@D)
	$(packer_run) build \
	-var "base_img=$(word 1,$^)" \
	-var "disk_size=$(call conffget,platform,.ubuntu.disk.size)" \
	-var "cpus=$(IMAGE_BUILD_CPUS)" \
	-var "memory=$(IMAGE_BUILD_MEMORY)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "user_name=root" \
	-var "user_password=$(call conffget,platform,.ubuntu.root.password)" \
	-var "input_tar_src=$(word 2,$^)" \
	-var "install_script=$(word 3,$^)" \
	$(extend_hcl)

.PRECIOUS: $(ubuntu_dimg_o)compute%_phase1/disk.qcow2
$(ubuntu_dimg_o)compute%_phase1/disk.qcow2: $(ubuntu_base_dimg) $(b)compute%/phase1/input.tar $(d)phase1/install.sh $(extend_hcl) $(packer) | $(ubuntu_dimg_o)
	rm -rf $(@D)
	$(packer_run) build \
	-var "base_img=$(word 1,$^)" \
	-var "disk_size=$(call conffget,platform,.ubuntu.disk.size)" \
	-var "cpus=$(IMAGE_BUILD_CPUS)" \
	-var "memory=$(IMAGE_BUILD_MEMORY)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "user_name=root" \
	-var "user_password=$(call conffget,platform,.ubuntu.root.password)" \
	-var "input_tar_src=$(word 2,$^)" \
	-var "install_script=$(word 3,$^)" \
	$(extend_hcl)

$(b)compute%/phase1/input.tar:
	rm -rf $(@D)/input
	mkdir -p $(@D)/input
	tar -C $(@D)/input -cf $@ .

$(b)compute1/phase2/input.tar: $(addprefix $(b)compute1/phase2/input/, \
	$(ubuntu_phase2_common_input) \
	$(addprefix prepare/, run.sh chrony.conf nova.sh nova.conf neutron.sh neutron/neutron.conf neutron/openvswitch_agent.ini)) | $(b)compute1/phase2/
	tar -C $(@D)/input -cf $@ .

INPUT_TAR_ALL += $(b)compute1/phase2/input.tar

$(o)compute%.yaml: $(d)compute%.yaml.tpl $(config_deps) | $(o)
	$(call confsed,$<,$@.tmp)
	$(yq) eval-all 'select(fileIndex == 0) * select(fileIndex == 1) | explode(.) ' $@.tmp $(config_yaml) > $@
	rm $@.tmp

$(b)compute%.sed: $(o)compute%.yaml $(yq) | $(b)
	$(call yaml2sed,$<,$@)

inputd_ := $(b)compute1/phase2/input/

$(inputd_)%: $(d)phase2/input/%
	@mkdir -p $(@D)
	cp $< $@
$(inputd_)%: $(d)../common/phase2/input/%
	@mkdir -p $(@D)
	cp $< $@
$(inputd_)%: $(b)compute1.sed $(d)phase2/input/%.tpl
	@mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@
$(inputd_)%: $(b)compute1.sed $(d)../common/phase2/input/%.tpl
	@mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@
