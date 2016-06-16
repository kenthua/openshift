OSE 3.2 ansible scripts
---

Updated for OSE 3.2  

# OSE Environment configuration
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
  
# DDNS update via google domains - initial run, based off ravello blueprint
0. Get private key: `sftp root@[workstation_ip]:.ssh/id_rsa ose-ravello.pem`
  * Alternatively, you can upload your public key to each VM

## Scripted Method - Initial Run
0. Prerequisite: python-lxml
  * `sudo pip install lxml`
0. Modify `ose_ddns_vars.yml` accordingly with configuration
0. `ravello.sh`

### Scripted DDNS updates
0. `ravello.sh update`


## Manual Method - Initial Run
0. Modify `hosts-rav` & `ose_ddns_vars.yml` accordingly with IPs and configuration
0. `ansible-playbook --private-key=ose-ravello.pem -i hosts-rav ose_ddns.yml`

### Manual Subsequent DDNS updates
0. Modify `hosts-rav` with IPs
0. `ansible-playbook --private-key=ose-ravello.pem -i hosts-rav ose_ddns.yml --tags "update_dns"`
  * This will just run the tasks to update the dns server with the new ips.
  