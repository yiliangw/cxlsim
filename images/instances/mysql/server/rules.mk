mysql_server_disk_image := $(o)disk/disk.qcow2

$(b)input.tar:
	mkdir -p $(@D)
	touch $@

INPUT_TAR_ALL += $(b)input.tar

.PRECIOUS: $(mysql_server_disk_image)
$(mysql_server_disk_image): $(d)install.sh $(b)input.tar $(instances_seed_image) $(packer) $(base_hcl) $(openstack_config_deps)
	rm -rf $(@D)
	$(packer_run) build \
	-var "iso_url=$(call conffget,openstack,.instances.mysql.server.iso_url)" \
	-var "iso_cksum_url=$(call conffget,openstack,.instances.mysql.server.iso_cksum_url)" \
	-var "disk_size=$(call conffget,openstack,.instances.mysql.server.disk)G" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "seedimg=$(instances_seed_image)" \
	-var "install_script=$(word 1,$^)" \
	-var "input_tar_src=$(word 2,$^)" \
	-var "user_name=$(call conffget,openstack,.instances.user.name)" \
	-var "user_password=$(call conffget,openstack,.instances.user.password)" \
	$(base_hcl)
