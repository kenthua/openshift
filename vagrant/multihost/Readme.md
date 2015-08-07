# OpenShift Enterprise 3 Vagrant Setup

Still a work in progress, issues with pod to pod communication across nodes 

credits to Brian Ashburn for the reference point
https://github.com/bashburn/ose3-vagrant

This project contains a Vagrant file creating multiple VMs for running and demoing OpenShift Enterprise v3.
The demo environment consists of one VM running dnsmasq as the DNS server, one OpenShift master, and two OpenShift
nodes.

## Table of Contents

[Architecture](#architecture)

[Preparation](#preparation)

[Running the System](#running-the-system)


## Architecture

The demo environment setup contains the following VMs:
- ose3-master.example.com - This is the OpenShift Master
- ose3-node[1|2].example.com - These are the nodes supporting the system.
- ose3-dns.example.com - The dnsmasq server with a wildcard DNS entry for cloudapps.example.com

## requirements

Vagrant 1.7.4+ (NetworkManager not required anymore)
