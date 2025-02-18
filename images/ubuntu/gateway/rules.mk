$(ubuntu_dimg_o)gateway/disk.qcow2: $(ubuntu_dimg_o)gateway_phase2/disk.qcow2 | $(ubuntu_dimg_o)gateway/
	@rm -f $@
	ln -s $(shell realpath --relative-to=$(dir $@) $<) $@

$(ubuntu_dimg_o)gateway_phase2/disk.qcow2: $(ubuntu_dimg_o)gateway_phase1/disk.qcow2 $(b)phase2/input.tar $(d)phase2/install.sh $(base_hcl) $(packer) $(config_deps) | $(ubuntu_dimg_o)
	rm -rf $(@D)
	$(packer_run) build \
	-var "base_img=$(word 1, $^)" \
	-var "disk_size=$(call conffget,platform,.ubuntu.disks.gateway.size)" \
	-var "cpus=$(IMAGE_BUILD_CPUS)" \
	-var "memory=$(IMAGE_BUILD_MEMORY)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "user_name=root" \
	-var "user_password=$(call conffget,platform,.ubuntu.root.password)" \
	-var "input_tar_src=$(word 2,$^)" \
	-var "install_script=$(word 3,$^)" \
	$(extend_hcl)

$(ubuntu_dimg_o)gateway_phase1/disk.qcow2: $(ubuntu_base_dimg) $(b)phase1/input.tar $(d)phase1/install.sh $(extend_hcl) $(packer) $(platform_config_deps) | $(ubuntu_dimg_o)
	rm -rf $(@D)
	$(packer_run) build \
	-var "base_img=$<" \
	-var "disk_size=$(call conffget,platform,.ubuntu.disks.gateway.size)" \
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

$(ubuntu_input_tar_o)gateway_phase2.tar: $(b)phase2/input.tar | $(ubuntu_input_tar_o)
	@rm -f $@
	ln -s $(shell realpath --relative-to=$(dir $@) $<) $@

$(ubuntu_install_script_o)gateway_phase2.sh: $(d)phase2/install.sh | $(ubuntu_install_script_o)
	@rm -f $@
	ln -s $(shell realpath --relative-to=$(dir $@) $<) $@

inputd_ := $(b)phase2/input/

$(b)phase2/input.tar: $(addprefix $(inputd_), dhcpd.conf isc-dhcp-server netplan.yaml)
	tar -C $(@D)/input -cf $@ .

$(inputd_)%: $(d)phase2/input/%
	@mkdir -p $(@D)
	cp $< $@
$(inputd_)%: $(b)gateway.sed $(d)phase2/input/%.tpl
	@mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@

$(o)gateway.yaml: $(d)local.yaml.tpl $(config_deps) | $(o)
	$(call confsed,$<,$@.tmp)
	$(yq) eval-all 'select(fileIndex == 0) * select(fileIndex == 1) | explode(.) ' $@.tmp $(config_yaml) > $@
	rm $@.tmp

.PHONY: yaml
yaml: $(o)gateway.yaml

$(b)gateway.sed: $(o)gateway.yaml | $(b)
	$(call yaml2sed,$<,$@)
