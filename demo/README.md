# Login to OpenShift 

	oc login https://ose-aio.example.com:8443 --certificate-authority=ca.crt

# Docker project with WAR
b6m

	oc new-project k-docker
	oc new-app https://github.com/kenthua/kitchensink-docker.git
	oc get pods -w

You will get an error like this because the image hasn't been pulled down yet

	NAME                         READY     REASON                                                     RESTARTS   AGE
	kitchensink-docker-1-build   1/1       Running                                                    0          1m
	kitchensink-docker-1-e2so4   0/1       Error: image library/kitchensink-docker:latest not found   0          1m

Watch the docker build

	oc logs -f kitchensink-docker-1-build
	
	I0717 18:11:44.001404       1 docker.go:91] Successfully pushed 172.30.56.67:5000/k-docker/kitchensink-docker	

Expose the service

	oc get service
	oc expose service kitchensink-docker
	browser (http://kitchensink-docker.k-docker.cloudapps.example.com)	

# Kitchensink with just WAR file
b5m

	oc new-project k-war

Browser - Create (Project View) -> Select Image

	https://github.com/kenthua/kitchensink-war.git
	jboss-eap6-openshift:latest

or command line  

	oc new-app --template=eap6-basic-sti --param=GIT_URI=https://github.com/kenthua/kitchensink-war.git --param=GIT_REF=master --param=GIT_CONTEXT_DIR=""

	oc get pod
	oc logs -f kitchensink-war-1-build

Browser - Browse -> Services -> Routes:

OR command line

	oc get route

URL

	http://kitchensink-war.k-war.cloudapps.example.com	


# Kitchensink standalone S2I - H2 database - builder image
b6m

	oc new-project kitchensink

Browser - Create (Project View)

	https://github.com/kenthua/kitchensink.git
	EAP:latest or eap6-basic

or command line

	oc new-app --template=eap6-basic-sti --param=GIT_URI=https://github.com/kenthua/kitchensink.git --param=GIT_REF=master --param=GIT_CONTEXT_DIR="" --param=APPLICATION_NAME=kitchensink

Watch the build when it starts

	oc get build -w
	NAME            TYPE      STATUS    POD
	kitchensink-1   Source    New       kitchensink-1-build
	kitchensink-1   Source    Pending   kitchensink-1-build
	kitchensink-1   Source    Running   kitchensink-1-build

Watch builds from the build option or builder pod (pom.xml in src, maven build is exected)

	oc build-logs kitchensink-1
	oc logs -f kitchensink-1-build

Browser

	http://kitchensink.kitchensink.cloudapps.example.com


# Kitchensink S2I - postgres - builder image
b8m

Browser - Create Project (Home View) (Click OpenShift Enterprise text to get to Project screen)

	k-postgres

Add EAP keystore secret

	oc project k-postgres
	oc create -f eap-app-secret.json
 
Browser - Create (Project View)-> Browse all templates -> eap6-postgresql-sti -> Select template -> edit parameters

	GIT_URI=https://github.com/kenthua/kitchensink-postgres.git
	DB_JNDI=java:jboss/datasources/PostgreSQLDS

Browser - Browse -> Builds -> wait for build eap-app-1 to start

Check out the pods (notice the postgres pod as well)

	oc get pod
	NAME                         READY     REASON    RESTARTS   AGE
	eap-app-1-build              1/1       Running   0          3m
	eap-app-postgresql-1-8wzae   1/1       Running   0          3m

Let's manually scale

	oc get rc
	CONTROLLER             CONTAINER(S)         IMAGE(S)                                                                                                       SELECTOR                                                                                                  REPLICAS
	eap-app-1              eap-app              172.30.56.67:5000/k-postgres/eap-app@sha256:b9830468ff16d7c6a880bc50da2b6890ff05732c1bc5e5833f687be5c010c6d3   deployment=eap-app-1,deploymentConfig=eap-app,deploymentconfig=eap-app                                    1
	eap-app-postgresql-1   eap-app-postgresql   registry.access.redhat.com/openshift3/postgresql-92-rhel7:latest                                               deployment=eap-app-postgresql-1,deploymentConfig=eap-app-postgresql,deploymentconfig=eap-app-postgresql   1
	
	oc scale --replicas=2 rc/eap-app-1
	
	oc get pod
	NAME                         READY     REASON       RESTARTS   AGE
	eap-app-1-build              0/1       ExitCode:0   0          26m
	eap-app-1-ig8y1              1/1       Running      0          1m
	eap-app-1-iwwe0              1/1       Running      0          19m
	eap-app-postgresql-1-8wzae   1/1       Running      0          26m
	
	oc get service eap-app
	
	oc describe service eap-app
	Name:			eap-app
	Labels:			application=eap-app,template=eap6-postgresql-sti
	Selector:		deploymentConfig=eap-app
	Type:			ClusterIP
	IP:			172.30.35.161
	Port:			<unnamed>	8080/TCP
	Endpoints:		10.1.0.22:8080,10.1.0.25:8080
	Session Affinity:	None
	No events.
	
# Ruby hello-world 
(b6m) / 25m

Browser - Create (Home View)

	ruby	

Browser - Create (Project View) 

	https://github.com/kenthua/ruby-hello-world.git
	ruby:2.0

Edit Deployment Configuration

	MYSQL_USER=root
	MYSQL_PASSWORD=redhat
	MYSQL_DATABASE=mydb

Browser - Browse -> Services -> Navigate to URL

	http://ruby-hello-world.ruby.cloudapps.example.com

Browser - Create (Project View) -> browse all templates

	mysql-empemeral

Edit parameters

	DATABASE_SERVICE_NAME=database
	POSTGRESQL_USER=root
	POSTGRESQL_PASSWORD=redhat
	POSTGRESQL_DATABASE=mydb

Verify database-1 and ruby-hello-world-1 pods are running

	oc get pod
	NAME                       READY     REASON       RESTARTS   AGE
	database-1-aytfl           1/1       Running      0          20s
	ruby-hello-world-1-build   0/1       ExitCode:0   0          10m
	ruby-hello-world-1-jc1jg   1/1       Running      0          4m

Browser - app still broken  
Need to force a rebuild with of the POD, because the original frontend environment didn't have DATABASE_SERVICE_HOST environemnt variable

	oc delete pod `oc get pod | grep -e "hello-world-[0-9]" | grep -v build | awk '{print $1}'`

Old pod is deleted and a new pod is spawned to meet the desired state of replica size = 1
Refresh app again

Make a change to the application

Now we need to get the generic webhook url

	oc describe bc ruby-hello-world
	
	Name:			ruby-hello-world
	...
	Webhook Generic:	https://ose-aio.example.com:8443/oapi/v1/namespaces/ruby/buildconfigs/ruby-hello-world/webhooks/1f4a60ac41f59d9b/generic
	...
	Builds:
	  Name			Status		Duration	Creation Time
	  ruby-hello-world-1 	complete 	6m6s 		2015-07-17 19:20:23 -0400 EDT
	 
Trigger a new build manually via webhook

	curl -i -H "Accept: application/json" \
	-H "X-HTTP-Method-Override: PUT" -X POST -k \
	https://ose-aio.example.com:8443/oapi/v1/namespaces/ruby/buildconfigs/ruby-hello-world/webhooks/1f4a60ac41f59d9b/generic
	
	HTTP/1.1 200 OK
	Cache-Control: no-store
	Date: Fri, 17 Jul 2015 23:40:50 GMT
	Content-Length: 0
	Content-Type: text/plain; charset=utf-8

Check out a new build

	oc get build
	NAME                 TYPE      STATUS     POD
	ruby-hello-world-1   Source    Complete   ruby-hello-world-1-build
	ruby-hello-world-2   Source    Running    ruby-hello-world-2-build

Once ready, check out the new changes

Rollback to the original
	
	oc rollback ruby-hello-world-1
	
Rollback to the changes if desired

	oc rollback ruby-hello-world-2
	
Check out how many rc's we have

	oc get rc
	CONTROLLER           CONTAINER(S)       IMAGE(S)                                                                                                          SELECTOR                                                          REPLICAS
	database-1           mysql              registry.access.redhat.com/openshift3/mysql-55-rhel7:latest                                                       deployment=database-1,deploymentconfig=database,name=database     1
	ruby-hello-world-1   ruby-hello-world   172.30.56.67:5000/ruby/ruby-hello-world@sha256:84b3c3a091f9bc7fb5530c126add792df93a29b779fb7abcc26291ba79a339d9   deployment=ruby-hello-world-1,deploymentconfig=ruby-hello-world   0
	ruby-hello-world-2   ruby-hello-world   172.30.56.67:5000/ruby/ruby-hello-world@sha256:a6a81a82cd4305e9b50cb189875d4cc7f1dd5a9c42c6b956db36726a14bd8e5a   deployment=ruby-hello-world-2,deploymentconfig=ruby-hello-world   0
	ruby-hello-world-3   ruby-hello-world   172.30.56.67:5000/ruby/ruby-hello-world@sha256:84b3c3a091f9bc7fb5530c126add792df93a29b779fb7abcc26291ba79a339d9   deployment=ruby-hello-world-3,deploymentconfig=ruby-hello-world   0
	ruby-hello-world-4   ruby-hello-world   172.30.56.67:5000/ruby/ruby-hello-world@sha256:a6a81a82cd4305e9b50cb189875d4cc7f1dd5a9c42c6b956db36726a14bd8e5a   deployment=ruby-hello-world-4,deploymentconfig=ruby-hello-world   1

# PHP, persistent volumes 
(b4m) / 20m

If you don't have a persistent volume already created by root, reference this repo for a quick NFS & PV setup:  
https://github.com/kenthua/openshift-configs/tree/master/root

Browser - Create (Home view)

	php

Browser - Create (Project view)

	https://github.com/kenthua/openshift-php-upload-demo.git
	php:5.5
	Name: openshift-php-upload
	
Create a claim on a volume

	oc create -f pvc.json

	oc get pvc
	NAME       LABELS    STATUS    VOLUME
	phpclaim   map[]     Bound     phpvolume

Need to edit the deployment config to leverage the volume

First, directly under the `template spec:` line, add this YAML (indented from the `spec:` line):

		volumes:
      - name: php-upload-volume
        persistentVolumeClaim:
          claimName: phpclaim

Then to have the container mount this, add this YAML after the `terminationMessagePath:` line:

        volumeMounts:
        - mountPath: /opt/openshift/src/uploaded
          name: php-upload-volume

Automatically triggers a new deploy

Browser - navigate to

	http://openshift-php-upload.php.cloudapps.example.com/form.html

Scale the php upload app

	oc get rc
	CONTROLLER               CONTAINER(S)           IMAGE(S)                                                                                                             SELECTOR                                                                  REPLICAS
	openshift-php-upload-1   openshift-php-upload   172.30.56.67:5000/php/openshift-php-upload@sha256:cf64adfa53b74a3548ad9fd6104fdf481015c9d74316d7da75625640dbc7fa7f   deployment=openshift-php-upload-1,deploymentconfig=openshift-php-upload   0
	openshift-php-upload-2   openshift-php-upload   172.30.56.67:5000/php/openshift-php-upload@sha256:cf64adfa53b74a3548ad9fd6104fdf481015c9d74316d7da75625640dbc7fa7f   deployment=openshift-php-upload-2,deploymentconfig=openshift-php-upload   1
	
	oc scale --replicas=3 rc/openshift-php-upload-2
	
	oc get pod
	NAME                           READY     REASON       RESTARTS   AGE
	openshift-php-upload-1-build   0/1       ExitCode:0   0          24m
	openshift-php-upload-2-31eng   1/1       Running      0          6m
	openshift-php-upload-2-53f4z   1/1       Running      0          24s
	openshift-php-upload-2-oc0g5   1/1       Running      0          24s

Check for persistent volume saving, also round robin service
ose-aio machine 
	
	ls /var/export/vol1
	
	oc get service -n php
	
	curl http://172.30.117.104:8080/test.php
	openshift-php-upload-2-oc0g5
	curl http://172.30.117.104:8080/test.php
	openshift-php-upload-2-31eng
	curl http://172.30.117.104:8080/test.php
	openshift-php-upload-2-53f4z
	curl http://172.30.117.104:8080/test.php
	openshift-php-upload-2-oc0g5
	curl http://172.30.117.104:8080/test.php
	openshift-php-upload-2-31eng
	curl http://172.30.117.104:8080/test.php
	openshift-php-upload-2-53f4z
	curl http://172.30.117.104:8080/test.php 

# Ruby hello-world with db different project

Browser - Create (Home View)

	data	

Browser - Create (Project View) - browse all templates 

	mysql-ephemeral

Edit Deployment Configuration - Create

	DATABASE_SERVICE_NAME=mysql
	MYSQL_USER=root
	MYSQL_PASSWORD=redhat
	MYSQL_DATABASE=mydb

Verify mysql-1 pod is running

	oc project data
	
	oc get pod
	NAME            READY     REASON    RESTARTS   AGE
	mysql-1-dppdz   1/1       Running   0          1m
	
	oc get service
	NAME      LABELS                              SELECTOR     IP(S)           PORT(S)
	mysql     template=mysql-ephemeral-template   name=mysql   172.30.237.51   3306/TCP
	
	curl 172.30.237.51:3306
	5.5.41exO_r>}{��qHP9j.DK,9yxmysql_native_password!��#08S01Got packets out of order	

Browser - Create (Home View)

	frontend	

Browser - Create (Project View) 

	http://github.com/kenthua/ruby-hello-world.git
	ruby:2.0

Edit Deployment Configuration by adding some environment variables

	DATABASE_SERVICE_HOST=mysql.data.svc.cluster.local
	DATABASE_SERVICE_PORT=3306
	MYSQL_USER=root
	MYSQL_PASSWORD=redhat
	MYSQL_DATABASE=mydb

Check that the frontend pod is running

	oc project frontend
	
	oc get pod 
	NAME                       READY     REASON       RESTARTS   AGE
	ruby-hello-world-1-build   0/1       ExitCode:0   0          2m
	ruby-hello-world-1-trpn3   1/1       Running      0          1m

Browser - Navigate to:

	http://ruby-hello-world.frontend.cloudapps.example.com

# PHP Upload Application Template - Instant App

As admin/root user

	oc create -f php-upload.json -n openshift

Browser - Create (Home View)

	template-test

Browser - Create (Project View) -> Select Template -> Create

	template: php-upload-template

Browser - Browse -> Builds -> Start build

Browser - navigate to:

	http://php-upload.template-test.cloudapps.example.com/form.html	

# PHP Upload Application - Instant App

	oc new-project newapp-test
	oc new-app php-upload.json
	oc start-build php-upload

Browser - navigate to:

	http://php-upload.newapp-test.cloudapps.example.com/form.html



