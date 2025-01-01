YQ_VERSION := 4.44.5

yq := $(o)yq_v$(YQ_VERSION)

$(yq):
	mkdir -p $(@D)
	wget https://github.com/mikefarah/yq/releases/download/v$(YQ_VERSION)/yq_linux_amd64 -O $@
	chmod +x $@

ubuntu_config := $(d)ubuntu.yaml
ubuntu_sed := $(b)ubuntu.sed

define yaml2sed
$(yq) e '.. | select(. == "*") | "s/{{ ." + (path | join(".")) + " }}/" + . + "/g"' $(1) > $(2)
endef

$(b)%.sed: $(d)%.yaml $(yq)
	mkdir -p $(@D)
	$(call yaml2sed,$<,$@)

define confget_ubuntu
$(shell $(yq) '$(1)' $(ubuntu_config))
endef
