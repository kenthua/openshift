#!/bin/bash
export LOGFILE="/tmp/update.log"
export STARTDATE=`date`;
cat << EOF > /etc/motd
###############################################################################
###############################################################################
###############################################################################
Environment Provisioning In Progress : ${STARTDATE}
DO NOT USE THIS ENVIRONMENT AT THIS POINT
DISCONNECT AND TRY AGAIN 10 MINUTES FROM THE TIME ABOVE
###############################################################################
###############################################################################
If you want, you can check out the status of the installer by using:
tail -f /tmp/update.log
###############################################################################

EOF

hostname -s| awk -F"-" '{print $1}' 2>&1 | tee $LOGFILE
guid=`cat /usr/local/bin/configureIPA.sh | awk '{print $9}' | cut -c 19-22`
echo "GUID: $guid" 2>&1 | tee $LOGFILE
infraip=`host infra-$guid.oslab.opentlc.com ipa.opentlc.com  | grep $guid | awk '{ print $4 }'` 
echo "Infra IP: $infraip" 2>&1 | tee $LOGFILE

sed -i "s/{{guid}}/$guid/g" /etc/named.conf 
sed -i "s/{{guid}}/$guid/g" /var/named/zones/oslab.db
sed -i "s/{{infraip}}/$infraip/g" /var/named/zones/oslab.db

echo "Restart named" 2>&1 | tee -a $LOGFILE
systemctl restart named

cd /root
echo "Clone openshift" 2>&1 | tee -a $LOGFILE
git clone https://github.com/kenthua/openshift -b rhpds-cicd
cd /root/openshift/install/updates/ansible-ravello
echo "Change variables" 2>&1 | tee -a $LOGFILE
sed -i "s/^ose_wildcard: apps/ose_wildcard: cloudapps/g" vars.yml
sed -i "s/^subdomain: ose/subdomain: oslab/g" vars.yml
sed -i "s/^domain: techknowledgeshare.net/domain: opentlc.com/g" vars.yml
sed -i "s/^guid: /guid: -$guid/g" vars.yml
sed -i "s/^ci_enabled: false/ci_enabled: true/g" vars.yml
echo "[openshift_master]" > hosts
echo "10.0.0.2" >> hosts
echo "" >> hosts
echo "[vms]" >> hosts
echo "10.0.0.3" >> hosts
echo "10.0.0.4" >> hosts
echo "10.0.0.5" >> hosts
echo "10.0.0.100" >> hosts
echo "Run playbook" 2>&1 | tee -a $LOGFILE
ansible-playbook -i hosts ravello_ocp_master.yml 2>&1 | tee -a $LOGFILE
echo "###############################################################################
"
echo "Provisioning Complete" 2>&1 | tee -a $LOGFILE
echo "###############################################################################
"


export DATE=`date`;
cat << EOF > /etc/motd
###############################################################################
Environment Provisioning Started      : ${STARTDATE}
###############################################################################
###############################################################################
Environment Provisioning Is Completed : ${DATE}
###############################################################################
###############################################################################

EOF
