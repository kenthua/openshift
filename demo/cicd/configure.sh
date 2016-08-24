#!/bin/bash

ansible-playbook -i "localhost," init.yaml
ansible-playbook -i "localhost," ocp_project_prep.yaml

