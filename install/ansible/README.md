OCP ansible scripts
---


# OCP Environment configuration
Updated for OCP 3.5 

* Modify group_vars content, hosts and ose_ddns_vars.yml (as necessary)
* `ocp_pre_req.yml` 
  * Network setup, ose prereqs
  * RHSM credentials: `SUB_USERNAME` / `SUB_PASSWORD`
  * Comment out network_prereq if not needed (this should be run on all vms)
* `ocp_infrastructure.yml` -- To setup nfs infrastructure
* Run `ocp_install.sh`
  * OSE advanced install
  * Modify accordingly
* `preload_images.yml` -- 
  * To preload docker images into your environment

 
# OCP Environment Configuration in EC2
Updated for OCP 3.3

* Modify variables defined in `roles/ec2/defaults/main.yml` or override them via command line / `ec2_create_instances.yml`
* `ec2_create_instances.yml`
  * Define security group
  * Create ec2 instances
  * Define r53 routes for master and wildcard dns
* `ansible-playbook -i "localhost," ec2_create_instances.yml`
* Take note of all your defined hosts, the playbook will output the specific external public DNS names of each ec2 instance and associated ocp node type.  Define this in your `hosts` file
* `ec2_setup_instances.yml`
  * Setup rhsm
  * This will prereqs prior to OCP installation.  Similar to `ose_pre_req.yml`
* `ansible-playbook -i hosts ec2_setup_instances.yml`
* Take the EC2 instance external public DNS names and apply them to the `ec2_ocp-ansible-hosts` file.  Make any other modifications necessary to the install.
* From your cloned `openshift-ansible` repository.  
  * Run `ansible-playbook -i <path>/ec2_ocp-ansible-hosts --become --become-user=ec2-user playbooks/byo/config.yml`