OSE 3.2 ansible ravello scripts
---

* Based off Ravello blueprint

## Setup
0. Get private key: `sftp root@[workstation_ip]:.ssh/id_rsa ose-ravello.pem`
  * Alternatively, you can add your public key to each VM
0. You can put your credentials in the `vars.yml` or use environment variables for credentials.
  * `GOOGLE_DDNS_USER`
  * `GOOGLE_DDNS_PASSWORD`
  * `RAVELLO_USER`
  * `RAVELLO_PASSWORD`

### Scripted Method - Initial Run
0. Prerequisite: python-lxml
  * `sudo pip install lxml`
0. Different way to clone to pull the ansible-xml project as well
  * `git clone --recursive https://github.com/kenthua/openshift`
0. Modify `vars.yml` accordingly with configuration
0. `ravello.sh`

### Scripted DDNS updates
0. `ravello.sh update`

### Manual Method - Initial Run
0. Modify `hosts` & `vars.yml` accordingly with IPs and configuration
0. `ansible-playbook --private-key=ose-ravello.pem -i hosts-rav ose_ddns.yml`

### Manual Subsequent DDNS updates
0. Modify `hosts` with IPs
0. `ansible-playbook --private-key=ose-ravello.pem -i hosts-rav ose_ddns.yml --tags "update_dns"`
  * This will just run the tasks to update the dns server with the new ips.
  
## Connecting CloudForms 4.1 to the OCP environment
0. From the workstation machine
  * `./oclogin.sh` - login as `admin`
  * `oc sa get-token -n management-infra management-admin` - to extract the token
0. On CloudForms 4.1, Compute > Containers > Providers > Configuration > Add a new Containers Providers
  * Default endpoint: Use the token from the previous command
  * Hawkular endpoint: `metrics.<ose_wildcard>.<subdomain>.<domain>`
  * Validate each endpoint to ensure connectivity
  
  