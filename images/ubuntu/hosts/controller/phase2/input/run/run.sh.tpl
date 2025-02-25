set -xe

mysql_server_ip={{ .openstack.instances.mysql.server.ip }}
mysql_client_ip={{ .openstack.instances.mysql.client.ip }}
user={{ .openstack.instances.user.name }}
password={{ .openstack.instances.user.password }}

while ! sshpass -p${password} ssh ${user}@${mysql_server_ip} uptime; do
    echo "Waiting for ssh connection to the server."
done
while ! sshpass -p${password} ssh ${user}@${mysql_client_ip} uptime; do
    echo "Waiting for ssh connection to the client."
done

sshpass -p${password} ssh ${user}@${mysql_client_ip} 'bash ~/input/run.sh'
