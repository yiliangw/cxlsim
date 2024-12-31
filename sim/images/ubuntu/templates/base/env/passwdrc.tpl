ADMIN_PASS={{ .id.openstack.admin_pass }}
BAIZE_PASS={{ .id.openstack.user_pass }}
GLANCE_PASS=${{ .id.openstack.glance_pass }}
PLACEMENT_PASS={{ .id.openstack.placement_pass }}
NOVA_PASS={{ .id.openstack.nova_pass }}
NEUTRON_PASS={{ .id.openstack.neutron_pass }}
RABBIT_PASS={{ .id.openstack.rabbit_pass }}
METADATA_SECRET={{ .id.openstack.metadata_secret }}

KEYSTONE_DBPASS={{ .id.openstack.keystone_dbpass }}
GLANCE_DBPASS={{ .id.openstack.glance_dbpass }}
PLACEMENT_DBPASS={{ .id.openstack.placement_dbpass }}
NOVA_DBPASS={{ .id.openstack.nova_dbpass }}
NEUTRON_DBPASS={{ .id.openstack.neutron_dbpass }}
