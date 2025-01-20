$(b)controller/input.tar: $(addprefix $(b)controller/input/, $(ubuntu_common_input) install.sh chrony.conf \
	$(addprefix setup/, run.sh mysql/99-openstack.cnf memcached.conf etcd keystone.sh keystone.conf \
	glance.sh glance-api.conf placement.sh placement.conf nova.sh nova.conf neutron.sh neutron/neutron.conf \
	neutron/ml2_conf.ini neutron/openvswitch_agent.ini neutron/dhcp_agent.ini neutron/l3_agent.ini neutron/metadata_agent.ini))
	mkdir -p $(@D)
	tar -C $(@D)/input -cf $@ .

INPUT_ALL += $(b)controller/input.tar

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

# Disk images

# ubuntu_openstack_images := cirros.qcow2 mysql_server.qcow2 mysql_client.qcow2
ubuntu_openstack_images := cirros.qcow2

$(b)controller/input.tar: $(addprefix $(b)controller/input/images/, $(ubuntu_openstack_images))

$(b)controller/input/images/cirros.qcow2:
	mkdir -p $(@D)
	wget -O $@ http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img 

$(b)controller/input/images/mysql_server.qcow2: $(mysql_server_disk_image)
	mkdir -p $(@D)
	cp $< $@

$(b)controller/input/images/mysql_client.qcow2: $(mysql_client_disk_image)
	mkdir -p $(@D)
	cp $< $@
