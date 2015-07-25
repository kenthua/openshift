# $1 hostname
# $2 domain
# $3 ip_master
# $4 dns
# $5 dns_server

echo ">> Script argument: $1, $2, $3, $4, $5"

# install ansible
yum -y install \
    http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
yum -y --enablerepo=epel install ansible

#cp /home/vagrant/sync/scripts/hosts /etc/ansible/hosts
echo "
[OSEv3:children]
masters
nodes

[OSEv3:vars]
ansible_ssh_user=root
deployment_type=enterprise

# enable htpasswd authentication
openshift_master_identity_providers=[{'name': 'any_password', 'login': 'true', 'challenge': 'true','kind': 'AllowAllPasswordIdentityProvider'}]

[masters]
$1.$2 openshift_ip=$3 openshift_public_ip=$3 openshift_hostname=$1.$2 openshift_public_hostname=$1.$2

[nodes]
$1.$2 openshift_ip=$3 openshift_public_ip=$3 openshift_hostname=$1.$2 openshift_public_hostname=$1.$2 openshift_scheduleable=True
" > /etc/ansible/hosts


cd ~
git clone https://github.com/openshift/openshift-ansible
cd openshift-ansible

ansible-playbook ~/openshift-ansible/playbooks/byo/config.yml

# update dns server
if [[ $4 == 'true' ]]
then
	sed -i -e "0,/.*nameserver.*/s/.*nameserver.*/nameserver ${5}\n&/" /etc/resolv.conf
else
	echo "DNS Server Not Set/Updated"
fi

# setup service account for docker-registry
echo \
    '{"kind":"ServiceAccount","apiVersion":"v1","metadata":{"name":"registry"}}' \
     | oc create -f -

cd ~
oc get scc privileged -o yaml > scc-privileged.yaml
echo "- system:serviceaccount:default:registry" >> scc-privileged.yaml
oc update -f scc-privileged.yaml

mkdir -p /mnt/docker

# install docker-registry
oadm registry --service-account=registry \
--config=/etc/openshift/master/admin.kubeconfig \
--credentials=/etc/openshift/master/openshift-registry.kubeconfig \
--mount-host=/mnt/docker \
--images='registry.access.redhat.com/openshift3/ose-${component}:${version}'

# prepare generic certificate for openshift endpoints which don't provide their own certs
CA=/etc/openshift/master
oadm create-server-cert --signer-cert=$CA/ca.crt \
      --signer-key=$CA/ca.key --signer-serial=$CA/ca.serial.txt \
      --hostnames='*.cloudapps.$2' \
      --cert=cloudapps.crt --key=cloudapps.key

cat cloudapps.crt cloudapps.key $CA/ca.crt > cloudapps.router.pem

# install router
oadm router router --replicas=1 \
    --credentials='/etc/openshift/master/openshift-router.kubeconfig' \
    --images='registry.access.redhat.com/openshift3/ose-${component}:${version}' \
    --default-cert=cloudapps.router.pem

# add routing config so new projects wil leverage specified subdomain
echo "routingConfig:" >> /etc/openshift/master/master-config.yaml
echo "  subdomain: cloudapps.$2" >> /etc/openshift/master/master-config.yaml

# setup so that openshift doesn't authenticate passwords (any password is fine) - moved to ansible/hosts
#sed -i -e "s/- name: deny_all/- name: anypassword/" /etc/openshift/master/master-config.yaml
#sed -i -e "s/kind: DenyAllPasswordIdentityProvider/kind: AllowAllPasswordIdentityProvider/" /etc/openshift/master/master-config.yaml

# restart openshift-master from all the config changes above
systemctl restart openshift-master

# allow external docker images (Dockerfile) with USER requirements to run
oc get scc restricted -o yaml > scc-restricted.yaml
sed -i -e "s/type: MustRunAsRange/type: RunAsAny/" scc-restricted.yaml
oc update -f scc-restricted.yaml

# add users - with AllowAllPasswordIdentityProvider, oc login using any id / password
#useradd alice
