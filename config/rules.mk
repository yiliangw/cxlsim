YQ_VERSION := 4.44.5

yq := $(o)yq_v$(YQ_VERSION)

$(yq):
	mkdir -p $(@D)
	wget https://github.com/mikefarah/yq/releases/download/v$(YQ_VERSION)/yq_linux_amd64 -O $@
	chmod +x $@

ubuntu_config := $(d)ubuntu.yaml
ubuntu_sed := $(b)ubuntu.sed

$(d)%.yaml: $(yq)

$(b)%.sed: $(d)%.yaml
	mkdir -p $(@D)
	yq e '.. | select(. == "*") | "s/{{ " + (path | join(".")) + " }}/" + . + "/g"' $< > $@

define confget_ubuntu
$(shell $(yq) '$(1)' $(ubuntu_config))
endef
