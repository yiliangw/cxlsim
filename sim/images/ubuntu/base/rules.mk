UBUNTU_IMAGE_URL := https://cloud-images.ubuntu.com/daily/server/jammy/20241217/jammy-server-cloudimg-amd64.img
UBUNTU_IMAGE_CKSUM_URL := https://cloud-images.ubuntu.com/daily/server/jammy/20241217/SHA256SUMS

ubuntu_base_root_img := $(o)root/disk.qcow2
ubuntu_base_secondary_img := $(o)secondary/disk.qcow2

$(b)input.tar: $(addprefix $(b)input/, ssh/config ssh/id_rsa ssh/id_rsa.pub)
	tar -C $(@D)/input -cf $@ .

INPUT_ALL += $(b)input.tar

$(b)input/%: $(d)input/%
	mkdir -p $(@D)
	cp $< $@
$(b)input/%: $(d)input/%.tpl $(config_deps)
	mkdir -p $(@D)
	$(call confsed,$<,$@)

.PRECIOUS: $(ubuntu_base_root_img) $(ubuntu_base_secondary_img)

$(ubuntu_base_root_img): $(b)input.tar $(b)seed.raw $(d)install.sh $(base_hcl) $(packer)
	rm -rf $(@D) 
	PACKER_CACHE_DIR=$(packer_cache_dir) \
	$(packer) build \
	-var "disk_size=$(UBUNTU_ROOT_DISK_SZ)" \
	-var "iso_url=$(UBUNTU_IMAGE_URL)" \
	-var "iso_cksum_url=$(UBUNTU_IMAGE_CKSUM_URL)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "seedimg=$(word 2,$^)" \
	-var "input_tar_src=$(word 1,$^)" \
	-var "input_tar_dst=/tmp/input.tar" \
	-var "install_script=$(word 3,$^)" \
	$(base_hcl)

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
