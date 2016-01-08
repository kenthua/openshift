# enable hawkular metrics
# deployed in this project - since this is where pods will look natively
oadm new-project openshift-infra
oc project openshift-infra
# create the metrics deployer SA
oc create -f - <<API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-deployer
secrets:
- name: metrics-deployer
API
# metrics-deploy SA granted edit permission to openshift-infra
oadm policy add-role-to-user edit system:serviceaccount:openshift-infra:metrics-deployer
# heapster service account, access to list nodes and access stats
oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:openshift-infra:heapster
# chose to generate self signed cert, will require browser to accept cert
oc secrets new metrics-deployer nothing=/dev/null
# install metrics components
oc process -f /usr/share/ansible/openshift-ansible/roles/openshift_examples/files/examples/infrastructure-templates/enterprise/metrics-deployer.yaml -v \
IMAGE_PREFIX=openshift3/,\
IMAGE_VERSION=latest,\
HAWKULAR_METRICS_HOSTNAME=hawkular-metrics.cloudapps.example.com,\
USE_PERSISTENT_STORAGE=false \
| oc create -f -
# modify the master config to point to the correct metric URL
sed -i -e '/publicURL:/a\  metricsPublicURL: "https:\/\/hawkular-metrics.cloudapps.example.com/hawkular/metrics"' /etc/origin/master/master-config.yaml
systemctl restart atomic-openshift-master
systemctl restart atomic-openshift-node


# enable multitenant SDN
ssh root@ose-master.example.com 'sed -i -e "s/openshift-ovs-subnet/openshift-ovs-multitenant/" /etc/origin/master/master-config.yaml'
ssh root@ose-master.example.com 'sed -i -e "s/openshift-ovs-subnet/openshift-ovs-multitenant/" /etc/origin/node/node-config.yaml'
ssh root@ose-node1.example.com 'sed -i -e "s/openshift-ovs-subnet/openshift-ovs-multitenant/" /etc/origin/node/node-config.yaml'
ssh root@ose-node2.example.com 'sed -i -e "s/openshift-ovs-subnet/openshift-ovs-multitenant/" /etc/origin/node/node-config.yaml'
# can't just restart service, need to **REBOOT** each server for networking to properly function
# this seems to be the way until better instructions are provided
##ssh root@ose-master.example.com 'systemctl restart atomic-openshift-master'
##ssh root@ose-master.example.com 'systemctl restart atomic-openshift-node'
##ssh root@ose-node1.example.com 'systemctl restart atomic-openshift-node'
##ssh root@ose-node2.example.com 'systemctl restart atomic-openshift-node'
# once enabled to join pod networks 'oadm pod-network join-projects --to=<project 1> <project 2>'
# to make a project network global  'oadm pod-network make projects-global <project1> <project2>'


# allow external docker images (Dockerfile) with USER requirements to run
oc get scc restricted -o yaml > scc-restricted.yaml
sed -i -e "s/type: MustRunAsRange/type: RunAsAny/" scc-restricted.yaml
oc replace -f scc-restricted.yaml


# oclogin script example
oc login https://ose-master.example.com:8443 --certificate-authority=/etc/origin/master/ca.crt -u alice -p anything
