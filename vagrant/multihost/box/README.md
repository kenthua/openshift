# Vagrant requirements
Networking Interface #1 must be NAT
root / vagrant #ideal
vagrant / vagrant


# Inside your VM

## Set your environment variables

  export RHSM_USERNAME=
  export RHSM_PASSWORD=
  export RHSM_POOLID=

## Run the pre box script

  ./prep_box.sh

## Execute commands manually

  visudo

## Comment out requiretty
#Defaults requiretty

## Add the vagrant user
vagrant ALL=(ALL) NOPASSWD: ALL


# Package your box
## automated

  vagrant package --base <Virtualbox_VM_Name>

## manual

The vagrant file consists of the config.vm.base_mac

  tar -czf package.box Vagrantfile file.vmdk file.ovf metadata.json

# Add the box to your vagrant config

  vagrant box add <Box_Name> package.box
