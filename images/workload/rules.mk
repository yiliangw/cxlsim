workload_o := $(o)
workload_dimg_o := $(workload_o)disks/

$(workload_o)user-data: $(d)user-data
	@mkdir -p $(@D)
	@cp $< $@

workload_dimg_all := cirros ubuntu
workload_dimg_all := $(addprefix $(workload_dimg_o),$(workload_dimg_all))

.PRECIOUS: $(workload_dimg_all)

.PHONY: workload-dimg-all
workload-dimg-all: $(workload_dimg_all)

$(workload_dimg_o)cirros: $(workload_config_deps)
	@mkdir -p $(@D)
	wget -O $@ $(call conffget,workload,.cirros.iso_url) && touch $@

$(workload_dimg_o)ubuntu: $(workload_config_deps)
	@mkdir -p $(@D)
	wget -O $@ $(call conffget,workload,.ubuntu.iso_url) && touch $@


mysql_workload_deps := $(addprefix $(workload_o)mysql/,$(shell cd $(d)mysql && find . -type f | cut -c3-))
mysql_workload_deps += $(workload_dimg_o)ubuntu
mysql_workload_deps += $(workload_o)user-data

$(workload_o)mysql/%: $(d)mysql/%
	@mkdir -p $(@D)
	cp $< $@
