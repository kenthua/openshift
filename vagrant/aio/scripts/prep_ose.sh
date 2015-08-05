#!/bin/bash

# $1 hostname
# $2 domain

echo ">> Script argument: $1, $2"

# setup subscription
subscription-manager repos --disable="*"
subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-optional-rpms" \
    --enable="rhel-7-server-ose-3.0-rpms"

# setup prereq
yum -y remove NetworkManager
yum -y install wget git net-tools bind-utils iptables-services bridge-utils deltarpm
yum -y update

# leverage disk2 created by vagrant - to extend docker pool, default vagrant vbox rhel-7 image is about 250MB or 160MB
pvcreate /dev/sdb
vgextend VolGroup00  /dev/sdb
lvextend -l 100%FREE /dev/VolGroup00/docker-pool

yum -y install docker

# no need if have local file
#ssh-keygen -N "" -f ~/.ssh/id_rsa

# copy local public key info for ansible openshift setup so the host can ssh into itself
cd ~/.
mkdir .ssh
chmod 700 ~/.ssh
cp /home/vagrant/sync/scripts/id_rsa ~/.ssh
chmod 600 ~/.ssh/id_rsa
cp /home/vagrant/sync/scripts/id_rsa.pub ~/.ssh
chmod 644 ~/.ssh/id_rsa.pub
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

for host in $1.$2; do ssh-copy-id -i ~/.ssh/id_rsa.pub -o "StrictHostKeyChecking=no" $host; done
