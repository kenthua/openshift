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

JENKINS_SOURCE_PIPELINE=$SOURCE_APP-app-pipeline
JENKINS_BINARY_PIPELINE=$SOURCE_BINARY_APP-app-pipeline

OPENSHIFT_PWD=`pwd`

# Login to OSE
oc login -u ${OSE_CLI_USER} -p ${OSE_CLI_PASSWORD} ${OSE_CLI_HOST} --insecure-skip-tls-verify=true >/dev/null 2>&1

GOGS_POD=$(oc get pods -n $OSE_CI_PROJECT -l=deploymentconfig=gogs --no-headers | awk '{ print $1 }')
echo "GOGS_POD: $GOGS_POD"
GOGS_ROUTE=$(oc get routes -n $OSE_CI_PROJECT gogs --template='{{ .spec.host }}')
echo "GOGS_ROUTE: $GOGS_ROUTE"
JENKINS_ROUTE=$(oc get routes -n $OSE_CI_PROJECT jenkins --template='{{ .spec.host }}')
echo "JENKINS_ROUTE: $JENKINS_ROUTE"

echo "Clone test apps"
cd $TEMP_DIR
git clone https://github.com/kenthua/$SOURCE_APP.git
mv $SOURCE_APP $SOURCE_BINARY_APP
cd $SOURCE_BINARY_APP
cp $OPENSHIFT_PWD/infrastructure/jenkins/binary/Jenkinsfile .
rm -rf .git
cd $TEMP_DIR
git clone https://github.com/kenthua/$SOURCE_APP.git
sed -i -e 's/^def sourceURL =/#def sourceURL =/' -e '/^#def sourceURL =/a def sourceURL = "'"http://$GOGS_ROUTE/gogs/kitchensink"'"
' $OPENSHIFT_PWD/infrastructure/jenkins/source/Jenkinsfile
cd $SOURCE_APP
cp $OPENSHIFT_PWD/infrastructure/jenkins/source/Jenkinsfile .
rm -rf .git

echo "Find Jenkins PV Path and Owner"
JENKINS_PV=`oc get pvc jenkins -n $OSE_CI_PROJECT --template '{{ .spec.volumeName }}'`
JENKINS_NFS_VOLUME_PATH=`oc get pv $JENKINS_PV --template '{{ .spec.nfs.path }}'`
JENKINS_STAT_USER=`stat -c "%u" $JENKINS_NFS_VOLUME_PATH/jobs/custom-base-image-pipeline/config.xml`
JENKINS_STAT_GROUP=`stat -c "%g" $JENKINS_NFS_VOLUME_PATH/jobs/custom-base-image-pipeline/config.xml`

echo "Copy Jenkinsfile Source"
sudo mkdir -p $JENKINS_NFS_VOLUME_PATH/jobs/$JENKINS_SOURCE_PIPELINE
sudo cp $OPENSHIFT_PWD/infrastructure/jenkins/source/config.xml $JENKINS_NFS_VOLUME_PATH/jobs/$JENKINS_SOURCE_PIPELINE
sudo chown -R $JENKINS_STAT_USER:$JENKINS_STAT_GROUP $JENKINS_NFS_VOLUME_PATH/jobs/$JENKINS_SOURCE_PIPELINE

echo "Copy Jenkinsfile Binary"
sudo mkdir -p $JENKINS_NFS_VOLUME_PATH/jobs/$JENKINS_BINARY_PIPELINE
sudo cp $OPENSHIFT_PWD/infrastructure/jenkins/binary/config.xml $JENKINS_NFS_VOLUME_PATH/jobs/$JENKINS_BINARY_PIPELINE
sudo chown -R $JENKINS_STAT_USER:$JENKINS_STAT_GROUP $JENKINS_NFS_VOLUME_PATH/jobs/$JENKINS_BINARY_PIPELINE

echo "Reload Jenkins Config"
curl -X POST -u admin:password http://$JENKINS_ROUTE/reload

echo
echo "Setting up kitchensink git repository..."
echo
oc rsync -n $OSE_CI_PROJECT $TEMP_DIR/$SOURCE_APP $GOGS_POD:/tmp/ >/dev/null 2>&1
oc rsh -n $OSE_CI_PROJECT -t $GOGS_POD bash -c "cd /tmp/$SOURCE_APP && git init && git config --global user.email 'gogs@redhat.com' && git config --global user.name 'gogs' && git add . &&  git commit -m 'initial commit'" >/dev/null 2>&1
curl -H "Content-Type: application/json" -X POST -d '{"clone_addr": "'"/tmp/$SOURCE_APP"'","uid": 1,"repo_name": "'"$SOURCE_APP"'"}' --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/migrate >/dev/null 2>&1
curl -H "Content-Type: application/json" -X POST -d '{"type": "gogs","config": { "url": "'"http://admin:password@jenkins:8080/job/$JENKINS_SOURCE_PIPELINE/build?delay=0"'", "content_type": "json" }, "active": true }' --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/gogs/$SOURCE_APP/hooks >/dev/null 2>&1

echo
echo "Setting up kitchensink binary git repository..."
echo
oc rsync -n $OSE_CI_PROJECT $TEMP_DIR/$SOURCE_BINARY_APP $GOGS_POD:/tmp/ >/dev/null 2>&1
oc rsh -n $OSE_CI_PROJECT -t $GOGS_POD bash -c "cd /tmp/$SOURCE_BINARY_APP && git init && git config --global user.email 'gogs@redhat.com' && git config --global user.name 'gogs' && git add . &&  git commit -m 'initial commit'" >/dev/null 2>&1
curl -H "Content-Type: application/json" -X POST -d '{"clone_addr": "'"/tmp/$SOURCE_BINARY_APP"'","uid": 1,"repo_name": "'"$SOURCE_BINARY_APP"'"}' --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/migrate >/dev/null 2>&1
curl -H "Content-Type: application/json" -X POST -d '{"type": "gogs","config": { "url": "'"http://admin:password@jenkins:8080/job/$JENKINS_BINARY_PIPELINE/build?delay=0"'", "content_type": "json" }, "active": true }' --user $GOGS_ADMIN_USER:$GOGS_ADMIN_PASSWORD http://$GOGS_ROUTE/api/v1/repos/gogs/$SOURCE_BINARY_APP/hooks >/dev/null 2>&1

echo "Finished."
