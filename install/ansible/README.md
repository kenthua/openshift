OSE 3.x ansible scripts
---

Updated for OSE 3.2  

# OSE Environment configuration
0. Modify group_vars content, hosts and ose_ddns_vars.yml (as necessary)
0. `ose_pre_req.yml` 
  * Network setup, RHSM, ose prereqs
  * comment out network_prereq if not needed (this should be run on all vms)
0. Run openshift/install/scripts/`2_ose_install_script.sh`
  * OSE advanced install
  * modify accordingly
0. `ose_infrastructure.yml`
  * `ose_infrastructure_local.yml` for a local environment
0. `preload_images.yml`
  * to preload docker images into your environment
  
# DDNS update via google domains
0. based off a ravello blueprint
0. `git clone https://github.com/kenthua/openshift`
0. modify `hosts-rav` & `ose_ddns_vars.yml` accordingly with IPs and names above
0. get the key private key: `sftp root@[workstation_ip]:.ssh/id_rsa ose-ravello.pem`
0. `ansible-playbook --private-key=ose-ravello.pem -i hosts-rav ose_ddns.yml`
