$(instances_dimg_o)mysql_server/disk.qcow2: $(d)install.sh $(b)input.tar $(instances_seed_image) $(packer) $(base_hcl) $(openstack_instances_config_deps)
	rm -rf $(@D)
	$(packer_run) build \
	-var "iso_url=$(call conffget,openstack,.instances.mysql.server.iso_url)" \
	-var "iso_cksum_url=$(call conffget,openstack,.instances.mysql.server.iso_cksum_url)" \
	-var "disk_size=$(call conffget,openstack,.instances.mysql.server.disk)G" \
	-var "disk_compression=true" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "seedimg=$(instances_seed_image)" \
	-var "install_script=$(word 1,$^)" \
	-var "input_tar_src=$(word 2,$^)" \
	-var "user_name=$(call conffget,openstack,.instances.user.name)" \
	-var "user_password=$(call conffget,openstack,.instances.user.password)" \
	$(base_hcl)

$(b)input.tar:
	rm -rf $(@D)/input
	mkdir -p $(@D)/input
	tar -C $(@D)/input -cf $@ .
