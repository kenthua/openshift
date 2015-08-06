#!/bin/bash

# Set the proper DNS resolver
sed -i -e "s/^nameserver.*/nameserver 192.168.100.150/" /etc/resolv.conf

# copy local public key info for ansible openshift setup so the host can ssh into itself
cd ~/.
mkdir .ssh
chmod 700 ~/.ssh
cp /home/vagrant/sync/id_rsa ~/.ssh
chmod 600 ~/.ssh/id_rsa
cp /home/vagrant/sync/id_rsa.pub ~/.ssh
chmod 644 ~/.ssh/id_rsa.pub
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
