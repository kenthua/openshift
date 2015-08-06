#!/bin/bash
yum install -y dnsmasq

echo "
strict-order
domain-needed
local=/example.com/
bind-dynamic
resolv-file=/etc/resolv.conf.upstream
address=/.cloudapps.example.com/192.168.100.100
server=8.8.8.8
log-queries
" > /etc/dnsmasq.d/openshift.conf

systemctl enable dnsmasq; systemctl start dnsmasq

iptables -A IN_public_allow -p udp --dport 53 -j ACCEPT
iptables -A IN_public_allow -p tcp --dport 53 -j ACCEPT

# Set the proper DNS resolver
sed -i -e "s/^nameserver.*/nameserver 192.168.100.150/" /etc/resolv.conf
