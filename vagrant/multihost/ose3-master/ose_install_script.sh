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

# enable htpasswd authentication
# openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/openshift/openshift-passwd'}]
openshift_master_identity_providers=[{'name': 'any_password', 'login': 'true', 'challenge': 'true','kind': 'AllowAllPasswordIdentityProvider'}]

# host group for masters
[masters]
ose3-master.example.com  openshift_ip=192.168.100.100 openshift_public_ip=192.168.100.100 openshift_hostname=ose3-master.example.com openshift_public_hostname=ose3-master.example.com

# host group for nodes, includes region info
[nodes]
ose3-node2.example.com  openshift_ip=192.168.100.201 openshift_public_ip=192.168.100.201 openshift_hostname=ose3-node2.example.com openshift_public_hostname=ose3-node2.example.com
ose3-node1.example.com  openshift_ip=192.168.100.200 openshift_public_ip=192.168.100.200 openshift_hostname=ose3-node1.example.com openshift_public_hostname=ose3-node1.example.com
ose3-master.example.com  openshift_ip=192.168.100.100 openshift_public_ip=192.168.100.100 openshift_hostname=ose3-master.example.com openshift_public_hostname=ose3-master.example.com openshift_scheduleable=True
" > /etc/ansible/hosts

cd ~
git clone https://github.com/openshift/openshift-ansible
cd openshift-ansible

ansible-playbook ~/openshift-ansible/playbooks/byo/config.yml
