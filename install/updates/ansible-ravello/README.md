OCP 3.4 ansible ravello scripts
---

* Based off Ravello blueprint

## Setup
0. Get private key: `sftp root@[workstation_ip]:.ssh/id_rsa ocp-ravello.pem`
  * Alternatively, you can add your public key to each VM
0. You can put your credentials in the `vars.yml` or use environment variables for credentials.
  * `GOOGLE_DDNS_USER`
  * `GOOGLE_DDNS_PASSWORD`
  * `RAVELLO_USER`
  * `RAVELLO_PASSWORD`

### Scripted Method - Initial Run
0. Prerequisite: ravello-sdk
  * `sudo pip install ravello-sdk`
0. Modify `vars.yml` accordingly with configuration
0. `ravello.sh`

### Scripted DDNS updates
0. `ravello.sh update`

### Manual Method - Initial Run
0. Modify `hosts` & `vars.yml` accordingly with IPs and configuration
0. `ansible-playbook --private-key=ocp-ravello.pem -i hosts ocp_ddns.yml`

### Manual Subsequent DDNS updates
0. Modify `hosts` with IPs
0. `ansible-playbook --private-key=ocp-ravello.pem -i hosts ocp_ddns.yml --tags "update_dns"`
  * This will just run the tasks to update the dns server with the new ips.
  
## Connecting CloudForms 4.1 to the OCP environment
0. From the workstation machine
  * `./oclogin.sh` - login as `admin`
  * `oc sa get-token -n management-infra management-admin` - to extract the token
0. On CloudForms 4.1, Compute > Containers > Providers > Configuration > Add a new Containers Providers
  * Default endpoint: Use the token from the previous command
  * Hawkular endpoint: `metrics.<ocp_wildcard>.<subdomain>.<domain>`
  * Validate each endpoint to ensure connectivity
0. Configure the CloudForms Management Engine to allow for all three Capacity & Utilization server roles, which are available under Configure → Configuration → Server → Server Control.[1]  

[1] [CloudForms documentation](https://access.redhat.com/documentation/en/red-hat-cloudforms/4.1/managing-providers/chapter-4-containers-providers)
  