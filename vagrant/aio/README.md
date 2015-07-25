OpenShift Enterprise 3.0 Vagrant Install - All In One Image (Master/Node)
===

# Dependencies:  

* Red Hat OpenShift Enterprise 3.0 subscription
* Red Hat Container Development Kit CDK RHEL 7.1 vagrant-virtualbox image  
* Vagrant plugin: vagrant-registration
* Virtualbox installed
* Pre-configured DNS
	* bind-dns-config (ex: https://github.com/kenthua/bind-dns-config)
		* configured rhose.org (base domain)
		* configured *.cloudapps.rhose.org (wildcard domain) 
* Environment variables for Red Hat Subscription Manager information
	* SUB_USERNAME
	* SUB_PASSWORD

# Changes:

* update `scripts/update_network.sh` to reference your configured DNS server

# Command:

Add the vagrant-virtualbox image

	vagrant box add rhel-7.1 rhel-server-virtualbox-7.1-3.x86_64.box

	vagrant up
	vagrant ssh

# known issues:

* The vagrant virtualbox image has a known issue where if you shutdown then start, the en0 10.x address will no longer resolve
	* suspend instead (not yet tested)
	* you can always vagrant destroy then up again to rebuild

