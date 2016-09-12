#!/bin/bash
export GUID=`hostname -s | cut  -c 8-11`
sed -i -e "s/GUID/$GUID/" vars.yaml
ansible-playbook -i "localhost," init.yaml
ansible-playbook -i "localhost," ocp_project_prep.yaml

