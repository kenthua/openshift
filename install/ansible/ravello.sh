ansible-playbook -i "localhost," -c local get_ravello_ips.yml

if [ "$1" != "update" ]
then
    ansible-playbook -i hosts-rav ose_ddns.yml
else
    ansible-playbook -i hosts-rav ose_ddns.yml --tags "update_dns"
fi 
