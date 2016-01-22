# Core Scripts

## Prepare the machine
Sets up the Red Hat Subscription, repos, pre-reqs, and docker configs  

    1_prep_machine.sh
    
## Install OSE (advanced)
Performs advanced installation of OSE using the ansible host  

    2_ose_install_script.sh
    
## Configure base resources
Configures the registry, router, sets up user alice

    3_post_install_core.sh
    
# Additional Functions

## Configure OSE for CloudForms

    post_install_cf.sh
    
## Logging EFK stack

    post_install_logging.sh

## Metrics, Multitenant SDN, allow any docker image to run

    post_install_additions.sh
    
