# OpenShift Enterprise 3 Vagrant Setup

Status:  
AIO - Working  
Multihost - Working 

credits to Brian Ashburn for the reference point
https://github.com/bashburn/ose3-vagrant

This project contains a Vagrant file creating multiple VMs for running and demoing OpenShift Enterprise v3.
The demo environment consists of one VM running dnsmasq as the DNS server, one OpenShift master, and two OpenShift
nodes.

## Architecture

The demo environment setup contains the following VMs:
- ose3-master.example.com - This is the OpenShift Master
- ose3-node[1|2].example.com - These are the nodes supporting the system.
- ose3-dns.example.com - The dnsmasq server with a wildcard DNS entry for cloudapps.example.com

## Requirements

Vagrant 1.7.4+ (NetworkManager not required anymore)

## Box Creation

The box folder contains instructions for creating your very own box.  

Scripts and commands provided

## Issues Observed

* Vagrant 1.7.3 and earlier required nmcli, which required NetworkManager

* Master Node to NodeX communication issues 

    - Resolution being worked on: https://github.com/openshift/openshift-sdn/issues/84  

    Why did this happen?  Likely because my base vagrant box is doing something when vagrant messes with networking.

    Resolution for now: 

    - Clear out existing hosts entry 
    
    Why?
    
    - Install script has the master node assigned at 127.0.0.1, resulting in lbr0 having issues communicating across master/nodes
    - lbr0 - can't ping across master & nodeX on 10.x.x.x IP 
    - Based on current box image, original `/etc/hosts` is `127.0.0.1 ose3-master.example.com ose3-master localhost ....`
    - This can probably be fixed by not allowing vagrant to update hosts file - `/etc/sysconfig/network-scripts` somewhere
