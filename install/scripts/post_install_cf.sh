# CF for ose-master
# https://access.redhat.com/documentation/en/red-hat-cloudforms/4.0/managing-providers/chapter-3-containers-providers

# enable the correct service account for CF to connect to openshift
oadm new-project management-infra --description="Management Infrastructure"

oc create -n management-infra -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: management-admin
EOF

oc create -f - <<EOF
apiVersion: v1
kind: ClusterRole
metadata:
  name: management-infra-admin
rules:
- resources:
  - pods/proxy
  verbs:
  - '*'
EOF

oadm policy add-role-to-user -n management-infra admin -z management-admin
oadm policy add-role-to-user -n management-infra management-infra-admin -z management-admin
oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:management-infra:management-admin
oadm policy add-scc-to-user privileged system:serviceaccount:management-infra:management-admin

# grab the token for CF 

###

# enable hawkular metrics
# deployed in this project - since this is where pods will look natively

HAWKULAR_METRICS_HOSTNAME=ose-master.example.com


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
# choose to generate self signed cert, will require browser to accept cert
#oc secrets new metrics-deployer nothing=/dev/null

# Setup a key -- testing
CA=/etc/origin/master
oadm ca create-server-cert --signer-cert=$CA/ca.crt   --signer-key=$CA/ca.key --signer-serial=$CA/ca.serial.txt \
  --hostnames='hawkular-metrics' --cert=metrics.crt --key=metrics.key
cat metrics.crt metrics.key > metrics.pem
oc secrets new metrics-deployer \
   hawkular-metrics.pem=metrics.pem \
   hawkular-metrics-ca.cert=/etc/origin/master/ca.crt


# install metrics components
oc process -f /usr/share/ansible/openshift-ansible/roles/openshift_examples/files/examples/v1.1/infrastructure-templates/enterprise/metrics-deployer.yaml -v \
IMAGE_PREFIX=openshift3/,\
IMAGE_VERSION=latest,\
HAWKULAR_METRICS_HOSTNAME=$HAWKULAR_METRICS_HOSTNAME,\
USE_PERSISTENT_STORAGE=false \
| oc create -f -
# modify the master config to point to the correct metric URL
sed -i -e "/publicURL:/a\  metricsPublicURL: \"https:\/\/$HAWKULAR_METRICS_HOSTNAME/hawkular/metrics\"" /etc/origin/master/master-config.yaml
systemctl restart atomic-openshift-master
systemctl restart atomic-openshift-node

### 

# metrics router for CF
# hostname could be the hostname or the IP of the master node
MASTER_HOSTNAME=xyz

oadm router management-metrics \
-n default \
--credentials=/etc/origin/master/openshift-router.kubeconfig \
--service-account=router --ports='443:5000' \
--selector="kubernetes.io/hostname=$MASTER_HOSTNAME"
--stats-port=1937 \
--host-network=false
