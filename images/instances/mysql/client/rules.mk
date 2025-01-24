mysql_client_disk_image := $(o)disk/disk.qcow2

.PRECIOUS: $(mysql_client_disk_image)
$(mysql_client_disk_image): $(d)install.sh $(b)input.tar $(instances_seed_image) $(packer) $(base_hcl) $(config_deps)
	rm -rf $(@D)
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer) build \
	-var "iso_url=$(call confget,.openstack.instances.mysql.client.iso_url)" \
	-var "iso_cksum_url=$(call confget,.openstack.instances.mysql.client.iso_cksum_url)" \
	-var "disk_size=$(call confget,.openstack.instances.mysql.client.disk)G" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "seedimg=$(instances_seed_image)" \
	-var "install_script=$(word 1,$^)" \
	-var "input_tar_src=$(word 2,$^)" \
	-var "user_name=$(call confget,.openstack.instances.user.name)" \
	-var "user_password=$(call confget,.openstack.instances.user.password)" \
	$(base_hcl)

$(b)input.tar: $(b)input/run.sh 
	tar -C $(@D)/input -cf $@ .

INPUT_TAR_ALL += $(b)input.tar

$(b)input/run.sh: $(d)input/run.sh.tpl $(config_deps)
	mkdir -p $(@D)
	$(call confsed,$<,$@)
