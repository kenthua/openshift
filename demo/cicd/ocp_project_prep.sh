#!/bin/bash

oc delete project dev test prod

sleep 20

oc new-project dev
oc new-project test
oc new-project prod

# no longer recommended
# https://docs.openshift.com/enterprise/3.2/dev_guide/managing_images.html - Importing Images across projects - edit access (better?) or system:image-puller
oc policy add-role-to-user edit system:serviceaccount:test:default -n dev
oc policy add-role-to-user edit system:serviceaccount:uat:default -n dev
oc policy add-role-to-user edit system:serviceaccount:prod:default -n dev

oc policy add-role-to-user edit system:serviceaccount:ci:default -n dev
oc policy add-role-to-user edit system:serviceaccount:ci:default -n test
oc policy add-role-to-user edit system:serviceaccount:ci:default -n prod

`
