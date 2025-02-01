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

$(b)input.tar: $(linux_dir)README
	rm -rf $(@D)/input
	mkdir -p $(@D)/input
	cp -r $(linux_dir) $(@D)/input/linux
	$(MAKE) -C $(@D)/input/linux mrproper
	tar -C $(@D)/input -cf $@ .

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

$(o)basetmp/disk.qcow2: $(ubuntu_base_dimg)
	mkdir -p $(@D)
	rm -f $@
	$(qemu_img) create -f qcow2 -o backing_file=$(realpath --relative-to=$(@D) $<) -F qcow2 $@
	
.PHONY: qemu-ubuntu-basetmp
qemu-ubuntu-basetmp: $(o)basetmp/disk.qcow2
	sudo -E $(qemu) -machine q35,accel=kvm -cpu host -smp $(shell echo $$((`nproc` / 2))) -m $(shell echo $$((`free -m | awk '/^Mem:/ {print $$4}'` / 2)))M  \
	-drive file=$(word 1, $^),media=disk,format=qcow2,if=ide,index=0 \
	-netdev user,id=user-net \
	-device virtio-net-pci,netdev=user-net \
	-boot c \
	-display none -serial mon:stdio
