#!/bin/bash

# setup subscription

subscription-manager register --username $RHSM_USERNAME --password $RHSM_PASSWORD
subscription-manager attach --pool=$RHSM_POOLID

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

# setup docker
yum -y install docker

# need this back for nmcli for vagrant/virtualbox
yum -y install NetworkManager

# Modify sshd config
sed -i -e '/^#UseDNS/a UseDNS no' /etc/ssh/sshd_config

# setup vagrant public key
su - vagrant
mkdir .ssh
chmod -R 0600 .ssh
cd .ssh
curl https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub > authorized_keys
chmod -R 0700 authorized_keys
exit
