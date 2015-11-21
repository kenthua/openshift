#!/bin/bash

# label the nodes because the ansible installer script doesn't work
#oc label --overwrite node ose3-master.example.com region=infra zone=default
#oc label --overwrite node ose3-node1.example.com region=primary zone=east
#oc label --overwrite node ose3-node2.example.com region=primary zone=west

# make the master node schedulable
oadm manage-node ose-master.example.com --schedulable=true

# add users - with AllowAllPasswordIdentityProvider, oc login using any id / password
useradd alice

# add user so they can access the local docker-registry
oadm policy add-role-to-user system:registry alice

# setup service account for docker-registry
echo \
    '{"kind":"ServiceAccount","apiVersion":"v1","metadata":{"name":"registry"}}' \
     | oc create -f -

cd ~
oc get scc privileged -o yaml > scc-privileged.yaml
echo "- system:serviceaccount:default:registry" >> scc-privileged.yaml
oc replace -f scc-privileged.yaml

mkdir -p /mnt/docker

# install docker-registry
oadm registry --config=/etc/origin/master/admin.kubeconfig \
    --credentials=/etc/origin/master/openshift-registry.kubeconfig \
    --images='registry.access.redhat.com/openshift3/ose-${component}:${version}' \
    --selector='region=infra' \
    --mount-host=/mnt/docker \
    --service-account=registry 


# install router
# prepare generic certificate for openshift endpoints which don't provide their own certs
CA=/etc/origin/master
oadm ca create-server-cert --signer-cert=$CA/ca.crt \
      --signer-key=$CA/ca.key --signer-serial=$CA/ca.serial.txt \
      --hostnames='*.cloudapps.example.com' \
      --cert=cloudapps.crt --key=cloudapps.key

cat cloudapps.crt cloudapps.key $CA/ca.crt > cloudapps.router.pem

# setup service account for router
echo \
  '{"kind":"ServiceAccount","apiVersion":"v1","metadata":{"name":"router"}}' \
  | oc create -f -

cd ~
oc get scc privileged -o yaml > scc-privileged.yaml
sed -i -e "s/allowHostNetwork: false/allowHostNetwork: true/" scc-privileged.yaml
sed -i -e "s/allowHostPorts: false/allowHostPorts: true/" scc-privileged.yaml
echo "- system:serviceaccount:default:router" >> scc-privileged.yaml
oc replace -f scc-privileged.yaml

oadm router router --replicas=1 \
    --credentials='/etc/origin/master/openshift-router.kubeconfig' \
    --images='registry.access.redhat.com/openshift3/ose-${component}:${version}' \
    --default-cert=cloudapps.router.pem \
    --selector='region=infra' \
    --stats-user='admin' \
    --stats-password='redhat' \
    --service-account=router

# add routing config so new projects wil leverage specified subdomain 
# not needed if ansible/hosts has this config already
#echo "routingConfig:" >> /etc/openshift/master/master-config.yaml
#echo "  subdomain: cloudapps.example.com" >> /etc/openshift/master/master-config.yaml

# setup so that openshift doesn't authenticate passwords (any password is fine) - moved to ansible/hosts
#sed -i -e "s/- name: deny_all/- name: anypassword/" /etc/openshift/master/master-config.yaml
#sed -i -e "s/kind: DenyAllPasswordIdentityProvider/kind: AllowAllPasswordIdentityProvider/" /etc/openshift/master/master-config.yaml

# restart openshift-master from all the config changes above
#systemctl restart openshift-master

# allow external docker images (Dockerfile) with USER requirements to run
#oc get scc restricted -o yaml > scc-restricted.yaml
#sed -i -e "s/type: MustRunAsRange/type: RunAsAny/" scc-restricted.yaml
#oc replace -f scc-restricted.yaml

# oclogin script example
#oc login https://ose-master.example.com:8443 --certificate-authority=/etc/origin/master/ca.crt -u alice -p anything


