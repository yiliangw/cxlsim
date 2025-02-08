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
	-var "user_name=root" \
	-var "user_password=$(call conffget,platform,.ubuntu.root.password)" \
	-var "input_tar_src=$(word 1,$^)" \
	-var "install_script=$(word 3,$^)" \
	$(base_hcl)

$(b)input.tar: $(addprefix $(b)input/, linux/README simbricks-guestinit.sh simbricks-guestinit.service m5 \
	$(addprefix ssh/, id_rsa id_rsa.pub config)) | $(b)
	tar -C $(@D)/input -cf $@ .

$(b)input/linux/README: $(linux_dir)README | $(b)input/
	rm -rf $(@D)
	cp -r $(linux_dir) $(@D)
	$(MAKE) -C $(@D) mrproper

$(b)input/simbricks-guestinit.sh: $(d)input/simbricks-guestinit.sh | $(b)input/
	cp $< $@

$(b)input/simbricks-guestinit.service: $(d)input/simbricks-guestinit.service | $(b)input/
	cp $< $@

$(b)input/m5: $(simbricks_dir)images/m5 | $(b)input/
	@mkdir -p $(@D)
	cp $< $@

$(b)input/ssh/%: $(d)input/ssh/% | $(b)input/ssh/
	@mkdir -p $(@D)
	cp $< $@

$(ubuntu_base_secondary_img):
	@mkdir -p $(@D)
	$(qemu_img) create -f qcow2 $@ $(UBUNTU_SECONDARY_DISK_SZ)

$(b)user-data: $(d)user-data.tpl $(platform_config_deps) | $(b)
	$(call conffsed,platform,$<,$@)

$(b)meta-data: | $(b)
	tee $@ < /dev/null > /dev/null

$(b)seed.raw: $(b)user-data $(b)meta-data | $(b)
	cloud-localds $@ $^
