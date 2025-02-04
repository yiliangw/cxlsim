ubuntu_base_dimg := $(ubuntu_dimg_o)base/disk.qcow2
ubuntu_dimgs += $(ubuntu_base_dimg)
$(ubuntu_base_dimg): $(b)input.tar $(b)seed.raw $(d)install.sh $(platform_config_deps) $(base_hcl) $(packer)
	rm -rf $(@D)
	$(packer_run) build \
	-var "disk_size=$(call conffget,platform,.ubuntu.disk.size)" \
	-var "iso_url=$(call conffget,platform,.ubuntu.disk.iso_url)" \
	-var "iso_cksum_url=$(call conffget,platform,.ubuntu.disk.iso_cksum_url)" \
	-var "out_dir=$(@D)" \
	-var "out_name=$(@F)" \
	-var "cpus=$(shell echo $$((`nproc` / 2)))" \
	-var "memory=$(shell echo $$((`free -m | awk '/^Mem:/ {print $$4}'` / 2)))" \
	-var "seedimg=$(word 2,$^)" \
	-var "user_name=$(call conffget,platform,.ubuntu.user.name)" \
	-var "user_password=$(call conffget,platform,.ubuntu.user.password)" \
	-var "input_tar_src=$(word 1,$^)" \
	-var "install_script=$(word 3,$^)" \
	$(base_hcl)

$(b)input.tar: $(addprefix $(b)input/, linux/README guestinit.sh m5)
	tar -C $(@D)/input -cf $@ .

$(b)input/linux/README: $(linux_dir)README
	rm -rf $(@D)
	mkdir -p $(dirname $(@D))
	cp -r $(linux_dir) $(@D)
	$(MAKE) -C $(@D) mrproper

$(b)input/guestinit.sh: $(simbricks_dir)images/scripts/guestinit.sh
	mkdir -p $(@D)
	cp $< $@

$(b)input/m5: $(simbricks_dir)images/m5
	mkdir -p $(@D)
	cp $< $@

$(ubuntu_base_secondary_img):
	mkdir -p $(@D)
	$(qemu_img) create -f qcow2 $@ $(UBUNTU_SECONDARY_DISK_SZ)

$(b)user-data: $(d)user-data.tpl $(platform_config_deps)
	mkdir -p $(@D)
	$(call conffsed,platform,$<,$@)

$(b)meta-data:
	mkdir -p $(@D)
	tee $@ < /dev/null > /dev/null

$(b)seed.raw: $(b)user-data $(b)meta-data
	mkdir -p $(@D)
	rm -f $@
	cloud-localds $@ $^
