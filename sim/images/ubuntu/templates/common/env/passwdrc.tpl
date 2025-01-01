export ADMIN_PASS={{ .id.openstack.admin_pass }}
export BAIZE_PASS={{ .id.openstack.user_pass }}
export GLANCE_PASS={{ .id.openstack.glance_pass }}
export PLACEMENT_PASS={{ .id.openstack.placement_pass }}
export NOVA_PASS={{ .id.openstack.nova_pass }}
export NEUTRON_PASS={{ .id.openstack.neutron_pass }}
export RABBIT_PASS={{ .id.openstack.rabbit_pass }}
export METADATA_SECRET={{ .id.openstack.metadata_secret }}

export KEYSTONE_DBPASS={{ .id.openstack.keystone_dbpass }}
export GLANCE_DBPASS={{ .id.openstack.glance_dbpass }}
export PLACEMENT_DBPASS={{ .id.openstack.placement_dbpass }}
export NOVA_DBPASS={{ .id.openstack.nova_dbpass }}
export NEUTRON_DBPASS={{ .id.openstack.neutron_dbpass }}
