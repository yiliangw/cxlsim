set -xe

mysql_server_ip={{ .openstack.instances.mysql.server.ip }}
mysql_client_ip={{ .openstack.instances.mysql.client.ip }}
user={{ .openstack.instances.user.name }}
password={{ .openstack.instances.user.password }}

while ! sshpass -p${password} ssh ${user}@${mysql_server_ip} uptime; do
    sleep 1
done
while ! sshpass -p${password} ssh ${user}@${mysql_client_ip} uptime; do
    sleep 1
done

sshpass -p${password} ssh ${user}@${mysql_client_ip} 'bash ~/input/run.sh'

. ~/env/user_openrc

openstack console log show mysql.server
openstack console log show mysql.client
