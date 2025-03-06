set -xe

mysql_server_ip={{ .openstack.instances.mysql.server.ip }}
mysql_client_ip={{ .openstack.instances.mysql.client.ip }}
user={{ .openstack.instances.user.name }}
password={{ .openstack.instances.user.password }}

sshpass -p${password} ssh ${user}@${mysql_client_ip} 'bash ~/input/run.sh'
