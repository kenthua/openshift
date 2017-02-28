export ANSIBLE_HOST_KEY_CHECKING=False

#ansible-playbook -i "localhost," -c local get_ravello_ips.yml # connection now local defined in the playbook
ansible-playbook -i "localhost," get_ravello_hosts.yml

if [ "$1" != "update" ]
then
    ansible-playbook -i hosts ocp_ddns.yml --skip-tags=logging
else
    ansible-playbook -i hosts ocp_ddns.yml --tags "update_dns" --skip-tags=logging
fi 
