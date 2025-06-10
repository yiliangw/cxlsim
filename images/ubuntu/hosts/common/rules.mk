ubuntu_phase2_common_input := hostname hosts netplan.yaml \
	$(addprefix setup/, services/ovs-iface-up.service services/provider-veth-up.service \
		sbin/setup-ovs-iface.sh sbin/setup-provider-veth.sh ) \
	$(addprefix env/, openstackrc admin_openrc user_openrc)
