#!/bin/bash

SRC_DEV=src-dev
SRC_TEST=src-test
SRC_PROD=src-prod

BIN_DEV=bin-dev
BIN_TEST=bin-test
BIN_PROD=bin-prod

OSE_CI_PROJECT=ci

SRC_PROJECTS="$SRC_DEV $SRC_TEST $SRC_PROD"
BIN_PROJECTS="$BIN_DEV $BIN_TEST $BIN_PROD"
PROJECTS="$SRC_PROJECTS $BIN_PROJECTS"

for PROJECT in $PROJECTS;
    do
        oc delete project $PROJECT
    done

sleep 20

for PROJECT in $PROJECTS;
    do
        oc new-project $PROJECT
    done
    
# no longer recommended
# https://docs.openshift.com/enterprise/3.2/dev_guide/managing_images.html - Importing Images across projects - edit access (better?) or system:image-puller

for PROJECT in $SRC_PROJECTS;
    do
        oc policy add-role-to-user edit system:serviceaccount:$PROJECT:default -n $SRC_DEV
        oc policy add-role-to-user edit system:serviceaccount:$OSE_CI_PROJECT:default -n $PROJECT
    done

for PROJECT in $SRC_PROJECTS;
    do
        oc policy add-role-to-user edit system:serviceaccount:$PROJECT:default -n $BIN_DEV
        oc policy add-role-to-user edit system:serviceaccount:$OSE_CI_PROJECT:default -n $PROJECT
    done
