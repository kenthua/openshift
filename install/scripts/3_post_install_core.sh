#!/bin/bash

# make the default namespace accept region=infra 
# new untested method with "oc patch"
oc patch namespace/default -p '{"metadata":{"annotations":{"openshift.io/node-selector":"region=infra"}}}'

#oc get namespace default -o yaml > namespace.default.yaml
#sed -i  '/annotations/ a \ \ \ \ openshift.io/node-selector: region=infra' namespace.default.yaml
#oc replace -f namespace.default.yaml

# make the master node schedulable
oadm manage-node ose-master.example.com --schedulable=true

# add users - with AllowAllPasswordIdentityProvider, oc login using any id / password
useradd alice

# add oclogin command for user alice
echo "oc login https://ose-master.example.com:8443 -u alice -p password --insecure-skip-tls-verify=true" > /home/alice/oclogin.sh
chown alice:alice /home/alice/oclogin.sh
chmod 755 /home/alice/oclogin.sh

# add user so they can access the local docker-registry
oadm policy add-role-to-user system:registry alice

mkdir -p /mnt/docker
# this is needed for the 3.1.1.6+ registry
chmod -R 777 /mnt/docker

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

# setup router
oadm router router --replicas=1 \
    --credentials='/etc/origin/master/openshift-router.kubeconfig' \
    --images='registry.access.redhat.com/openshift3/ose-${component}:${version}' \
    --default-cert=cloudapps.router.pem \
    --selector='region=infra' \
    --stats-user='admin' \
    --stats-password='redhat' \
    --service-account=router

# MOVED TO ansible/hosts add routing config so new projects wil leverage specified subdomain 
##echo "routingConfig:" >> /etc/openshift/master/master-config.yaml
##echo "  subdomain: cloudapps.example.com" >> /etc/openshift/master/master-config.yaml

# MOVED TO ansible/hosts setup so that openshift doesn't authenticate passwords (any password is fine)
##sed -i -e "s/- name: deny_all/- name: anypassword/" /etc/openshift/master/master-config.yaml
##sed -i -e "s/kind: DenyAllPasswordIdentityProvider/kind: AllowAllPasswordIdentityProvider/" /etc/openshift/master/master-config.yaml
