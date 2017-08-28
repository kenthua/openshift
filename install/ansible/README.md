OCP ansible scripts
---


# OCP Environment configuration / installation
Updated for OCP 3.6

* Set your RHSM credentials: `RHSM_USERNAME` / `RHSM_PASSWORD`
* Modify group_vars variables, openshift & custom_vms (if necessary)
* Update the `hosts` file to reflect your environment
* To setup/configure the OCP pre-reqs
  * Modify `ocp_pre_req.yml` (if necessary)
    * Set `config_network: true` - if networking configuration is needed
  * Run `ansible-playbook -i hosts ocp_pre_req.yml`
* To setup the nfs server (if necessary)
  * Run `ansible-playbook -i hosts ocp_infrastructure.yml` - to setup NFS server (if necessary)
* To install OCP (advanced install)
  * Modify `ocp_install.sh` accordingly
  * Run `./ocp_install.sh`

 
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