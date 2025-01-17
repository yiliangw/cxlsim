YQ_VERSION := 4.44.5

yq := $(o)yq_v$(YQ_VERSION)

$(yq):
	mkdir -p $(@D)
	wget https://github.com/mikefarah/yq/releases/download/v$(YQ_VERSION)/yq_linux_amd64 -O $@
	chmod +x $@

ubuntu_config := $(d)ubuntu.yaml
ubuntu_sed := $(b)ubuntu.sed

instances_yaml := $(d)instances.yaml
instances_sed := $(b)instances.sed
instances_config := $(instances_yaml) $(instances_sed)

host_yaml := $(d)host.yaml
host_sed := $(b)host.sed
host_config := $(host_yaml) $(host_sed)

# $(1) - .yaml $(2) - .sed
define yaml2sed
sed 's/\//\\\//g' $(1) | $(yq) e '.. | select(. == "*") | "s/{{ ." + (path | join(".")) + " }}/" + . + "/g"' > $(2)
endef

$(b)%.sed: $(d)%.yaml $(yq)
	mkdir -p $(@D)
	$(call yaml2sed,$<,$@)

config_d := $(d)
config_b := $(b)

define confget
$(shell $(yq) 'explode(.) | $(2)' $(config_d)$(1).yaml)
endef

define confsed
sed -f $(config_b)$(1).sed $(2) > $(3)
endef

define confget_ubuntu
$(shell $(yq) 'explode(.) | $(1)' $(ubuntu_config))
endef
