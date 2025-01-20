ubuntu_phase2_common_input := hostname hosts netplan.yaml \
	$(addprefix env/, openstackrc admin_openrc user_openrc) \
	$(addprefix ssh/, config id_rsa id_rsa.pub)
