$(o)%/secondary/disk.qcow2: $(ubuntu_base_secondary_img)
	mkdir -p $(@D)
	$(qemu_img) create -f qcow2 -F qcow2 -b $(shell realpath --relative-to=$(dir $@) $<) $@

# Disk images
ubuntu_instance_dimgs := cirros mysql_server mysql_client

ubuntu_instance_dimgs_d := $(b)instance_dimgs/
ubuntu_instance_dimgs_tar := $(b)instance_dimgs.tar

.PRECIOUS: $(ubuntu_instance_dimgs_tar)
$(ubuntu_instance_dimgs_tar): $(addprefix $(ubuntu_instance_dimgs_d),$(addsuffix .raw,$(ubuntu_instance_dimgs)))
	@rm -f $@
	tar -cf $@ -C $(ubuntu_instance_dimgs_d) .

$(ubuntu_instance_dimgs_d)%.raw: $(instances_dimg_o)%/disk.raw | $(ubuntu_instance_dimgs_d)
	cp $< $@

$(eval $(call include_rules,$(d)common/rules.mk))
$(eval $(call include_rules,$(d)controller/rules.mk))
$(eval $(call include_rules,$(d)compute/rules.mk))
