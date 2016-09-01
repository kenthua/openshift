OCP 3.2 ansible scripts
---

Updated for OSE 3.2  

# OCP Environment configuration
0. Modify group_vars content, hosts and ose_ddns_vars.yml (as necessary)
0. `ose_pre_req.yml` 
  * Network setup, RHSM, ose prereqs
  * Comment out network_prereq if not needed (this should be run on all vms)
0. Run openshift/install/scripts/`2_ose_install_script.sh`
  * OSE advanced install
  * Modify accordingly
0. `ose_infrastructure.yml`
  * `ose_infrastructure_local.yml` for a local environment
0. `preload_images.yml`
  * To preload docker images into your environment
 
# OCP Environment Configuration in EC2
0. Modify variables defined in `roles/ec2/defaults/main.yml` or override them via command line / `ec2_create_instances.yml`
0. `ec2_create_instances.yml`
  * Define security group
  * Create ec2 instances
  * Define r53 routes for master and wildcard dns
0. `ansible-playbook -i "localhost," ec2_create_instances.yml`
0. Take note of all your defined hosts, the playbook will output the specific external public DNS names of each ec2 instance and associated ocp node type.  Define this in your `hosts` file
0. `ec2_setup_instances.yml`
  * Setup rhsm
  * This will prereqs prior to OCP installation.  Similar to `ose_pre_req.yml`
0. `ansible-playbook -i hosts ec2_setup_instances.yml`
0. Take the EC2 instance external public DNS names and apply them to the `ec2_ocp-ansible-hosts` file.  Make any other modifications necessary to the install.
0. From your cloned `openshift-ansible` repository.  
  * Run `ansible-playbook -i <path>/ec2_ocp-ansible-hosts --sudo --sudo-user=ec2-user playbooks/byo/config.yml`