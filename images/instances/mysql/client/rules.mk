$(instances_dimg_o)mysql_client/disk.raw: $(d)install.sh $(b)input.tar $(instances_seed_image) $(packer) $(base_hcl) $(openstack_config_deps)
	rm -rf $(@D)
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer_run) build \
	-var "iso_url=$(call conffget,openstack,.instances.mysql.client.iso_url)" \
	-var "iso_cksum_url=$(call conffget,openstack,.instances.mysql.client.iso_cksum_url)" \
	-var "disk_size=$(call conffget,openstack,.instances.mysql.client.disk)G" \
	-var "disk_format=raw" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "seedimg=$(instances_seed_image)" \
	-var "install_script=$(word 1,$^)" \
	-var "input_tar_src=$(word 2,$^)" \
	-var "user_name=$(call conffget,openstack,.instances.user.name)" \
	-var "user_password=$(call conffget,openstack,.instances.user.password)" \
	$(base_hcl)

$(b)input.tar: $(b)input/run.sh $(b)input/prepare.sh 
	tar -C $(@D)/input -cf $@ .

INPUT_TAR_ALL += $(b)input.tar

$(b)input/%.sh: $(d)input/%.sh.tpl $(config_deps)
	mkdir -p $(@D)
	$(call confsed,$<,$@)
