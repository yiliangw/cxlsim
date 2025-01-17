mysql_server_disk_image := $(o)disk/disk.qcow2

$(b)input.tar:
	mkdir -p $(@D)
	touch $@

$(mysql_server_disk_image): $(d)install.sh $(b)input.tar $(instances_config) $(instances_seed_image) $(packer) $(base_hcl)
	rm -rf $(@D)
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer) build \
	-var "iso_url=$(call confget,instances,.instances.mysql.server.iso_url)" \
	-var "iso_cksum_url=$(call confget,instances,.instances.mysql.server.iso_cksum_url)" \
	-var "disk_size=$(call confget,instances,.instances.mysql.server.disk)G" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "seedimg=$(instances_seed_image)" \
	-var "install_script=$(word 1,$^)" \
	-var "input_tar_src=$(word 2,$^)" \
	-var "input_tar_dst=/tmp/input.tar" \
	-var "user_name=$(call confget,instances,.instances.user.name)" \
	-var "user_password=$(call confget,instances,.instances.user.password)" \
	$(base_hcl)
