instances_seed_image := $(b)seed.img

$(instances_seed_image): $(b)user-data $(b)meta-data
	mkdir -p $(@D)
	rm -f $@
	cloud-localds $@ $^

$(b)user-data: $(d)user-data.tpl $(instances_config)
	mkdir -p $(@D)
	$(call confsed,instances,$<,$@)

$(b)meta-data:
	mkdir -p $(@D)
	tee $@ < /dev/null > /dev/null

$(eval $(call include_rules,$(d)mysql/rules.mk))
