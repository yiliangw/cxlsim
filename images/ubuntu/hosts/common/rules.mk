ubuntu_phase2_common_input := hostname hosts netplan.yaml ovs-iface-up.service \
	$(addprefix env/, openstackrc admin_openrc user_openrc)
