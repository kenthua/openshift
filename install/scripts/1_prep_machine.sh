#!/bin/bash

#export RHSM_USERNAME=
#export RHSM_PASSWORD=
#export RHSM_POOLID=
#rm -f ~/.bash_history

# add dns server if necessary
#echo "prepend domain-name-servers 172.16.118.132;" >> /etc/dhcp/dhclient.conf
#echo "append domain-name-servers 8.8.8.8;" >> /etc/dhcp/dhclient.conf

# setup subscription
subscription-manager register --username $RHSM_USERNAME --password $RHSM_PASSWORD
subscription-manager attach --pool=$RHSM_POOLID

subscription-manager repos --disable="*"
subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-3.1-rpms"

# setup prereq
yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion deltarpm
yum -y update
yum -y install atomic-openshift-utils

# setup docker
yum -y install docker

sed -i -e 's/^OPTIONS/#OPTIONS/' -e '/^#OPTIONS/a OPTIONS=--selinux-enabled --insecure-registry 172.30.0.0/16' /etc/sysconfig/docker

# clean repo
yum -y clean all

# generate ssh key on master if necessary
#ssh-keygen -N "" -f ~/.ssh/id_rsa

# replicate public key to all nodes
#for host in ose-master.example.com ose-node1.example.com \
#ose-node2.example.com; do ssh-copy-id -i ~/.ssh/id_rsa.pub \
#$host; done

# Modify sshd config (vagrant requirement)
sed -i -e '/^#UseDNS/a UseDNS no' /etc/ssh/sshd_config

