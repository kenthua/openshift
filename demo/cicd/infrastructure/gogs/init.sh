#!/bin/bash

set -e

SCRIPT_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Login Information
OSE_CLI_USER="admin"
OSE_CLI_PASSWORD="admin"
OSE_CLI_HOST="https://10.1.2.2:8443"


OSE_CI_PROJECT="ci"
GOGS_ADMIN_USER="gogs"
GOGS_ADMIN_PASSWORD="osegogs"

TEMP_DIR=/tmp

SOURCE_APP=kitchensink
SOURCE_BINARY_APP=kitchensink-binary


cd $TEMP_DIR
git clone https://github.com/kenthua/$SOURCE_APP.git
mv $SOURCE_APP $SOURCE_BINARY_APP
cd $SOURCE_BINARY_APP
cp $TEMP_DIR/openshift/demo/cicd/infrastructure/jenkins/binary/Jenkinsfile .
rm -rf .git
cd $TEMP_DIR
git clone https://github.com/kenthua/$SOURCE_APP.git
cd $SOURCE_APP
cp $TEMP_DIR/openshift/demo/cicd/infrastructure/jenkins/source/Jenkinsfile .

GOGS_POD=$(oc get pods -n $OSE_CI_PROJECT -l=deploymentconfig=gogs --no-headers | awk '{ print $1 }')
GOGS_ROUTE=$(oc get routes -n $OSE_CI_PROJECT gogs --template='{{ .spec.host }}')

echo
echo "Setting up kitchensink git repository..."
echo
oc rsync -n $OSE_CI_PROJECT $TEMP_DIR/$SOURCE_APP $GOGS_POD:/tmp/ >/dev/null 2>&1
oc rsh -n $OSE_CI_PROJECT -t $GOGS_POD bash -c "cd /tmp/$SOURCE_APP && git init && git config --global user.email 'gogs@redhat.com' && git config --global user.name 'gogs' && git add . &&  git commit -m 'initial commit'" >/dev/null 2>&1
curl -H "Content-Type: application/json" -X POST -d '{"clone_addr": "/tmp/$SOURCE_APP","uid": 1,"repo_name": "$SOURCE_APP"}' --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/migrate >/dev/null 2>&1
curl -H "Content-Type: application/json" -X POST -d '{"type": "gogs","config": { "url": "http://admin:password@jenkins:8080/job/$SOURCE_APP-app-pipeline/build?delay=0", "content_type": "json" }, "active": true }' --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/gogs/$SOURCE_APP/hooks >/dev/null 2>&1

echo
echo "Setting up kitchensink binary git repository..."
echo
oc rsync -n $OSE_CI_PROJECT $TEMP_DIR/$SOURCE_BINARY_APP $GOGS_POD:/tmp/ >/dev/null 2>&1
oc rsh -n $OSE_CI_PROJECT -t $GOGS_POD bash -c "cd /tmp/$SOURCE_BINARY_APP && git init && git config --global user.email 'gogs@redhat.com' && git config --global user.name 'gogs' && git add . &&  git commit -m 'initial commit'" >/dev/null 2>&1
curl -H "Content-Type: application/json" -X POST -d '{"clone_addr": "/tmp/$SOURCE_BINARY_APP","uid": 1,"repo_name": "$SOURCE_BINARY_APP"}' --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/migrate >/dev/null 2>&1
curl -H "Content-Type: application/json" -X POST -d '{"type": "gogs","config": { "url": "http://admin:password@jenkins:8080/job/$SOURCE_BINARY_APP-app-pipeline/build?delay=0", "content_type": "json" }, "active": true }' --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/gogs/$SOURCE_BINARY_APP/hooks >/dev/null 2>&1
