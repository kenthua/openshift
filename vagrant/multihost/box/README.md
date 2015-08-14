# Vagrant requirements
Networking Interface #1 must be NAT 
root / vagrant #ideal 
vagrant / vagrant 


# Inside your VM

- As root

- Set your environment variables

    export RHSM_USERNAME=
    export RHSM_PASSWORD=
    export RHSM_POOLID=

- Run the pre box script

    ./prep_box.sh

## Execute these commands manually

    visudo

- Comment out requiretty


    #Defaults requiretty

- Add the vagrant user


    vagrant ALL=(ALL) NOPASSWD: ALL

- As vagrant user


    su - vagrant
    ./vagrant_user.sh

# Package your box
- automated

    vagrant package --base <Virtualbox_VM_Name>

- manual

The vagrant file consists of the config.vm.base_mac

    tar -czf package.box Vagrantfile file.vmdk file.ovf metadata.json

- Add the box to your vagrant config

    vagrant box add <Box_Name> package.box
    
    
# Other notes / issues

If using the rhel-vagrant box image from the Red Hat Container Development Kit, if you remove/disable NetworkManager you need to add `HWADDR=08:00:27:7D:23:2E` to `/etc/sysconfig/network-scripts/ifcfg-eth0`
Otherwise the network interface won't come up anymore.

You will also need to add an additonal disk for the docker pool.  Once the disk is added you can run the following commands:

    pvcreate /dev/sdb
    vgextend VolGroup00  /dev/sdb
    lvextend -l 100%FREE /dev/VolGroup00/docker-pool

Otherwise the above configuration can be applied to this box.

