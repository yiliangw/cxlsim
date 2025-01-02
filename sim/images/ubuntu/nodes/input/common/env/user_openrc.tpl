export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME={{ .id.openstack.user_project }}
export OS_USERNAME={{ .id.openstack.user }}
export OS_PASSWORD={{ .id.openstack.user_pass }}
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
