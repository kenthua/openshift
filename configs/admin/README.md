OpenShift root access configurations
===

# Resource Quotas / limits

Quota resource limits for CPU and Memory require the Pods to have resource limits defined.  Otherwise by default they are unbounded and the quotas will deny creation of new pods.

Memory  
1Mi ~ 1024K bytes  
250Mi ~ 250MB  
1Gi ~ 1024M bytes  

CPU  
200m ~ .20 Core  
500m ~ .50 Core  
1 ~ 1 Core  


# Persistent Volumes

In order to run the `persistentvolume.json` a local NFS must be set up for the script to point to.  Of course this is for a POC/prototype, in production you would have an NFS infrastructure configured.

This one must be run on the master and all the nodes so that they have the correct mount NFS type

	yum -y install nfs-utils

The rest of the commands are run on the master, the NFS host providing the volume

	mkdir -p /var/export/vol1
	chown nfsnobody:nfsnobody /var/export/vol1
	chmod 700 /var/export/vol1

Edit /etc/exports

Manual

	/var/export/vol1 *(rw,sync,all_squash)

Scripted

	echo "/var/export/vol1 *(rw,sync,all_squash)" >> /etc/exports

	systemctl enable rpcbind nfs-server
	systemctl start rpcbind nfs-server nfs-lock 
	systemctl start nfs-idmap

iptables rules

	iptables -I OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 111 -j ACCEPT
	iptables -I OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 2049 -j ACCEPT
	iptables -I OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 20048 -j ACCEPT
	iptables -I OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 50825 -j ACCEPT
	iptables -I OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 53248 -j ACCEPT

edit /etc/sysconfig/iptables - above the first OS_FIREWALL_ALLOW command

	-A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 53248 -j ACCEPT
	-A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 50825 -j ACCEPT
	-A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 20048 -j ACCEPT
	-A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 2049 -j ACCEPT
	-A OS_FIREWALL_ALLOW -p tcp -m state --state NEW -m tcp --dport 111 -j ACCEPT

edit /etc/sysconfig/nfs

	RPCMOUNTDOPTS="-p 20048"
	STATDARG="-p 50825"
	
	sed -i.bak -e 's/^RPCMOUNTDOPTS/#RPCMOUNTDOPTS/' -e '/^#RPCMOUNTDOPTS/a RPCMOUNTDOPTS=\"-p 20048\"' /etc/sysconfig/nfs	
	sed -i.bak -e 's/^STATDARG/#STATDARG/' -e '/^#STATDARG/a STATDARG=\"-p 50825\"' /etc/sysconfig/nfs	

edit /etc/sysctl.conf

	fs.nfs.nlm_tcpport=53248
	fs.nfs.nlm_udpport=53248
	
	echo "fs.nfs.nlm_tcpport=53248" >> /etc/sysctl.conf
	echo "fs.nfs.nlm_udpport=53248" >> /etc/sysctl.conf

run commands

	sysctl -p
	systemctl restart nfs

allow containers to write to nfs mounted directories

	setsebool -P virt_use_nfs=true