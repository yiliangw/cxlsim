$(o)%.yaml: $(d)%.yaml.tpl $(ubuntu_sed) $(ubuntu_config) $(yq)
	mkdir -p $(@D)
	sed -f $(ubuntu_sed) $< > $@.tmp
	$(yq) eval-all 'select(fileIndex == 0) * select(fileIndex == 1) | explode(.) ' $@.tmp $(ubuntu_config) > $@
	rm $@.tmp

$(b)%.sed: $(o)%.yaml $(yq)
	mkdir -p $(@D)
	$(call yaml2sed,$<,$@)

.PRECIOUS: $(b)%/input.tar $(o)%/root/disk.qcow2 $(o)%/secondary/disk.qcow2

$(o)%/root/disk.qcow2: $(b)%/input.tar $(d)install.sh $(ubuntu_base_root_img) $(extend_hcl) $(packer)
	rm -rf $(@D)
	mkdir -p $(dir $(@D))
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer) build \
	-var "base_img=$(ubuntu_base_root_img)" \
	-var "disk_size=$(UBUNTU_ROOT_DISK_SZ)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "input_tar_src=$(word 1,$^)" \
	-var "input_tar_dst=/tmp/input.tar" \
	-var "install_script=$(word 2,$^)" \
	$(extend_hcl)

$(o)%/secondary/disk.qcow2: $(ubuntu_base_secondary_img)
	mkdir -p $(@D)
	$(qemu_img) create -f qcow2 -F qcow2 -b $(shell realpath --relative-to=$(dir $@) $<) $@

ubuntu_common_input := hostname hosts netplan.yaml \
	$(addprefix env/, admin_openrc passwdrc user_openrc)

$(eval $(call include_rules,$(d)controller.mk))
$(eval $(call include_rules,$(d)compute.mk))
