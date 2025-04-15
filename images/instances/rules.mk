instances_seed_image := $(b)seed.img

instances_dimg_o := $(o)disks/

instances_dimg_all := mysql_server mysql_client 
instances_dimg_all := $(addprefix $(instances_dimg_o),$(instances_dimg_all))
instances_dimg_all := $(addsuffix /disk.qcow2,$(instances_dimg_all))

.PHONY: instances-dimg-all
instances-dimg-all: $(instances_dimg_all)

.PRECIOUS: $(instances_dimg_o)%/disk.qcow2 $(instances_dimg_o)%/disk.raw

$(instances_seed_image): $(b)user-data $(b)meta-data
	mkdir -p $(@D)
	rm -f $@
	cloud-localds $@ $^

$(b)user-data: $(d)user-data.tpl $(openstack_config_deps)
	mkdir -p $(@D)
	$(call conffsed,openstack,$<,$@)

$(b)meta-data:
	mkdir -p $(@D)
	tee $@ < /dev/null > /dev/null

$(instances_dimg_o)cirros/disk.qcow2: | $(instances_dimg_o)cirros/
	wget -O $@ http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img 

$(eval $(call include_rules,$(d)mysql/rules.mk))
