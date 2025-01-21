ubuntu_base_dimg := $(ubuntu_dimg_o)base/disk.qcow2
ubuntu_dimgs += $(ubuntu_base_dimg)
$(ubuntu_base_dimg): $(b)input.tar $(b)seed.raw $(d)install.sh $(base_hcl) $(packer)
	rm -rf $(@D) 
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer) build \
	-var "disk_size=$(UBUNTU_ROOT_DISK_SZ)" \
	-var "iso_url=$(UBUNTU_ISO_URL)" \
	-var "iso_cksum_url=$(UBUNTU_ISO_CKSUM_URL)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "seedimg=$(word 2,$^)" \
	-var "input_tar_src=$(word 1,$^)" \
	-var "input_tar_dst=/tmp/input.tar" \
	-var "install_script=$(word 3,$^)" \
	$(base_hcl)

$(b)input.tar:
	rm -rf $(@D)/input
	mkdir -p $(@D)/input
	tar -C $(@D)/input -cf $@ .

$(ubuntu_base_secondary_img):
	mkdir -p $(@D)
	$(qemu_img) create -f qcow2 $@ $(UBUNTU_SECONDARY_DISK_SZ)

$(b)user-data: $(d)user-data.tpl $(config_deps)
	mkdir -p $(@D)
	$(call confsed,$<,$@)

$(b)meta-data:
	mkdir -p $(@D)
	tee $@ < /dev/null > /dev/null

$(b)seed.raw: $(b)user-data $(b)meta-data
	mkdir -p $(@D)
	rm -f $@
	cloud-localds $@ $^
