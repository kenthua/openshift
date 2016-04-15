oadm new-project logging 
oc project logging
#https://github.com/openshift/origin-aggregated-logging/tree/master/deployment
oc secrets new logging-deployer nothing=/dev/null

oc create -f - <<API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: logging-deployer
secrets:
- name: logging-deployer
API

oc policy add-role-to-user edit \
            system:serviceaccount:logging:logging-deployer

#oc edit scc/privileged
#- system:serviceaccount:logging:aggregated-logging-fluentd
oadm policy add-scc-to-user privileged system:serviceaccount:logging:aggregated-logging-fluentd

oadm policy add-cluster-role-to-user cluster-reader \
              system:serviceaccount:logging:aggregated-logging-fluentd

oc create -n openshift -f /usr/share/openshift/examples/infrastructure-templates/enterprise/logging-deployer.yaml

oc process logging-deployer-template -n openshift \
          -v KIBANA_OPS_HOSTNAME=kibana-ops.cloudapps.example.com,KIBANA_HOSTNAME=kibana-logging.cloudapps.example.com,ES_CLUSTER_SIZE=1,PUBLIC_MASTER_URL=https://ose-master.example.com:8443 \
          | oc create -f -

oc process logging-support-template | oc create -f -

oc edit scc/privileged
#- system:serviceaccount:logging:aggregated-logging-elasticsearch

mkdir -p /mnt/logging

oc get dc
#retrieve logging-es-XXXX

# does this work? needed to manually modify oc edit dc/logging-es- and change elasticsearch-storage to /mnt/logging
oc volume dc/logging-es- \
          --add --overwrite --name=elasticsearch-storage \
          --type=hostPath --path=/mnt/logging
          
oc edit dc/logging-es-

# add nodeselector
apiVersion: v1
kind: DeploymentConfig
spec:
  template:
    spec:
      nodeSelector:
        region: infra

oc scale dc/logging-fluentd --replicas=2
oc scale dc/logging-kibana --replicas=2