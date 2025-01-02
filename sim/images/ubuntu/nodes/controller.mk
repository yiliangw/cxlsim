$(b)controller/input.tar: $(addprefix $(b)controller/input/, $(ubuntu_common_input) install.sh chrony.conf\
	$(addprefix setup/, run.sh mysql/99-openstack.cnf memcached.conf etcd keystone.sh keystone.conf \
	glance.sh glance-api.conf placement.sh placement.conf nova.sh nova.conf))
	mkdir -p $(@D)
	tar -C $(@D)/input -cf $@ .

$(b)controller/input/%: $(d)input/controller/%
	mkdir -p $(@D)
	cp $< $@
$(b)controller/input/%: $(d)input/common/%
	mkdir -p $(@D)
	cp $< $@
$(b)controller/input/%: $(b)controller.sed $(d)input/controller/%.tpl
	mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@
$(b)controller/input/%: $(b)controller.sed $(d)input/common/%.tpl
	mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@
