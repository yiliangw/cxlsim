YQ_VERSION := 4.44.5

yq := $(o)yq_v$(YQ_VERSION)

$(yq):
	mkdir -p $(@D)
	wget https://github.com/mikefarah/yq/releases/download/v$(YQ_VERSION)/yq_linux_amd64 -O $@
	chmod +x $@

config_yaml := $(d)config.yaml
config_sed := $(b)config.sed

config_deps := $(yq) $(config_yaml) $(config_sed)

# $(1) - .yaml $(2) - .sed
define yaml2sed
sed 's/\//\\\//g' $(1) | $(yq) e 'explode(.) | .. | select(. == "*") | "s/{{ ." + (path | join(".")) + " }}/" + . + "/g"' > $(2)
endef

$(b)%.sed: $(d)%.yaml $(yq)
	mkdir -p $(@D)
	$(call yaml2sed,$<,$@)

define confget
$(shell $(yq) 'explode(.) | $(1)' $(config_yaml))
endef

define confsed
sed -f $(config_sed) $(1) > $(2)
endef
