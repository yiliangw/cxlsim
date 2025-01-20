export ADMIN_PASS={{ .openstack.id.admin_pass }}
export USER_PASS={{ .openstack.id.user_pass }}
export GLANCE_PASS={{ .openstack.id.glance_pass }}
export PLACEMENT_PASS={{ .openstack.id.placement_pass }}
export NOVA_PASS={{ .openstack.id.nova_pass }}
export NEUTRON_PASS={{ .openstack.id.neutron_pass }}
export RABBIT_PASS={{ .openstack.id.rabbit_pass }}
export METADATA_SECRET={{ .openstack.id.metadata_secret }}

export KEYSTONE_DBPASS={{ .openstack.id.keystone_dbpass }}
export GLANCE_DBPASS={{ .openstack.id.glance_dbpass }}
export PLACEMENT_DBPASS={{ .openstack.id.placement_dbpass }}
export NOVA_DBPASS={{ .openstack.id.nova_dbpass }}
export NEUTRON_DBPASS={{ .openstack.id.neutron_dbpass }}

export USER_PROJECT={{ .openstack.id.user_project }}
export USER_NAME={{ .openstack.id.user }}
