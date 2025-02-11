# Default lease settings
default-lease-time 600;
max-lease-time 7200;

# DHCP for provider network 
subnet {{ .openstack.network.provider.subnet }} netmask {{ .openstack.network.provider.netmask }} {
  range {{ .openstack.network.provider.ip_pool.start }} {{ .openstack.network.provider.ip_pool.end }};
  option routers {{ .openstack.network.provider.gateway }};
  option domain-name-servers {{ .openstack.network.provider.nameserver }};
}
