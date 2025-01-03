$(b)controller/input.tar: $(addprefix $(b)controller/input/, $(ubuntu_common_input) install.sh chrony.conf \
	$(addprefix setup/, run.sh mysql/99-openstack.cnf memcached.conf etcd keystone.sh keystone.conf \
	glance.sh glance-api.conf placement.sh placement.conf nova.sh nova.conf neutron.sh neutron/neutron.conf \
	neutron/ml2_conf.ini neutron/openvswitch_agent.ini neutron/dhcp_agent.ini neutron/l3_agent.ini neutron/metadata_agent.ini))
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

ubuntu_openstack_images := cirros

$(b)controller/input.tar: $(addprefix $(b)controller/input/images/, $(ubuntu_openstack_images))

$(b)controller/input/images/cirros:
	mkdir -p $(@D)
	wget -O $@ http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img 
