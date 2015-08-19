echo "
# Create an OSEv3 group that contains the masters and nodes groups
[OSEv3:children]
masters
nodes

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
# SSH user, this user should allow ssh based auth without requiring a password
ansible_ssh_user=root

# If ansible_ssh_user is not root, ansible_sudo must be set to true
#ansible_sudo=true

# To deploy origin, change deployment_type to origin
deployment_type=enterprise

# if you want the POD network to be on a different IP network range - (PODS  normally 10.1.0.0)
#osm_cluster_network_cidr=192.168.128.0/17

# if you want the kube network to be on a different IP network range - (Services normally 172.30.0.0)
#openshift_master_portal_net = 192.168.0.0/16

# set subdomain -- NEEDS TO BE TESTED
osm_default_subdomain=[{'subdomain': 'cloudapps.example.com'}]

# enable htpasswd authentication
# openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/openshift/openshift-passwd'}]
openshift_master_identity_providers=[{'name': 'any_password', 'login': 'true', 'challenge': 'true','kind': 'AllowAllPasswordIdentityProvider'}]

# host group for masters
[masters]
ose3-master.example.com 

# host group for nodes, includes region info
[nodes]
ose3-node2.example.com
ose3-node1.example.com 
ose3-master.example.com 
" > /etc/ansible/hosts

cd ~
git clone https://github.com/openshift/openshift-ansible
cd openshift-ansible

ansible-playbook ~/openshift-ansible/playbooks/byo/config.yml
