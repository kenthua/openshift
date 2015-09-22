# Login to OpenShift 

	oc login https://ose-aio.example.com:8443 --certificate-authority=ca.crt

# Docker project with WAR
Last Tested: 3.0.1 
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
Last Tested: 3.0.0 
b5m

	oc new-project k-war

Browser - Add to Project -> Select Image

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
Last Tested: 3.0.1 
b6m

	oc new-project kitchensink

Browser - Add to Project

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
Last Tested: 3.0.0 
b8m

Browser - New Project (Click OpenShift Enterprise text to get to Project screen)

	k-postgres

Add EAP keystore secret

	oc project k-postgres
	oc create -f eap-app-secret.json
 
Browser - Add to Project -> Browse all templates -> eap6-postgresql-sti -> Select template -> edit parameters

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
Last Tested: 3.0.0 
(b6m) / 25m

Browser - New Project

	ruby	

Browser - Add to Project

	https://github.com/kenthua/ruby-hello-world.git
	ruby:2.0

Edit Deployment Configuration

	MYSQL_USER=root
	MYSQL_PASSWORD=redhat
	MYSQL_DATABASE=mydb

Browser - Browse -> Services -> Navigate to URL

	http://ruby-hello-world.ruby.cloudapps.example.com

Browser - Add to Project -> browse all templates

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

# AB Deployment Testing
Last Tested: 3.0.1  
Added: 2015-09-22  

Reference, thanks to Veer for the example on the OpenShift blog: https://blog.openshift.com/openshift-3-demo-part-11-ab-deployments/

Browser - New Project

	ab-example
	
Browser - Add to Project  
NOTE: We do not want to create a route because we will be creating a new service and a new route based on the service

	https://github.com/kenthua/ab-example.git
	php:5.5
	Name: a-example
	Routing: Create a route to the application: No
	Labels: abgroup=true
	
Edit DC and create a new service based on edited DC  
We will be replacing the default deploymentconfig=a-example selector with abgroup=true  
NOTE: One could also edit the existing service a-example and replace deploymentconfig=a-example with abgroup=true, but we will edit the DC in this example

	oc get dc/a-example -o yaml > dc-a-example.yaml
	sed -i -e '/selector:/!b;n;c\   \ abgroup: "true"' dc-a-example.yaml
	oc replace -f dc-a-example.yaml
	
Then we will expose the DC as a service call ab-service with a selector of abgroup=true	
	
	oc expose dc/a-example --name=ab-service --selector=abgroup=true --generator=service/v1
	
Expose the service as a route
	
	oc expose service ab-service
	
Increase the replicas to 4

	oc scale --replicas=4 rc/a-example-1

Run a test of the scaled application

	for i in {1..10}; do curl ab-service.ab-example.cloudapps.example.com; echo " "; done
	
	Application VERSION 1 -- Pod IP: 10.1.0.12
	Application VERSION 1 -- Pod IP: 10.1.0.13
	Application VERSION 1 -- Pod IP: 10.1.1.18
	Application VERSION 1 -- Pod IP: 10.1.1.19
	Application VERSION 1 -- Pod IP: 10.1.0.12
	Application VERSION 1 -- Pod IP: 10.1.0.13
	Application VERSION 1 -- Pod IP: 10.1.1.18
	Application VERSION 1 -- Pod IP: 10.1.1.19
	Application VERSION 1 -- Pod IP: 10.1.0.12
	Application VERSION 1 -- Pod IP: 10.1.0.13

Edit php index.php on github, i.e. increment app version

Browser - Add to Project

	https://github.com/kenthua/ab-example.git
	php:5.5
	Name: b-example
	Routing: Create a route to the application: No
	Labels: abgroup=true

Run a test of the same route with the newly added project, with the label abgroup=true 
Notice that VERSION 2 is now in the load balancing scheme

	for i in {1..10}; do curl ab-service.ab-example.cloudapps.example.com; echo " "; done
	
	Application VERSION 1 -- Pod IP: 10.1.0.12
	Application VERSION 1 -- Pod IP: 10.1.0.13
	Application VERSION 2 -- Pod IP: 10.1.0.14
	Application VERSION 1 -- Pod IP: 10.1.1.18
	Application VERSION 1 -- Pod IP: 10.1.1.19
	Application VERSION 1 -- Pod IP: 10.1.0.12
	Application VERSION 1 -- Pod IP: 10.1.0.13
	Application VERSION 2 -- Pod IP: 10.1.0.14
	Application VERSION 1 -- Pod IP: 10.1.1.18
	Application VERSION 1 -- Pod IP: 10.1.1.19
	
Scale down VERSION 1 and Scale up VERSION 2

	oc scale --replicas=2 rc/a-example-1
	oc scale --replicas=2 rc/b-example-1
	
Run another test

	for i in {1..10}; do curl ab-service.ab-example.cloudapps.example.com; echo " "; done
	
	Application VERSION 1 -- Pod IP: 10.1.0.12
	Application VERSION 1 -- Pod IP: 10.1.0.13
	Application VERSION 2 -- Pod IP: 10.1.0.14
	Application VERSION 2 -- Pod IP: 10.1.1.21
	Application VERSION 1 -- Pod IP: 10.1.0.12
	Application VERSION 1 -- Pod IP: 10.1.0.13
	Application VERSION 2 -- Pod IP: 10.1.0.14
	Application VERSION 2 -- Pod IP: 10.1.1.21
	Application VERSION 1 -- Pod IP: 10.1.0.12
	Application VERSION 1 -- Pod IP: 10.1.0.13
	
Scale up VERSION 2 and Scale down VERSION 1

	oc scale --replicas=4 rc/b-example-1
	oc scale --replicas=0 rc/a-example-1	
	
Last test

	for i in {1..10}; do curl ab-service.ab-example.cloudapps.example.com; echo " "; done

	Application VERSION 2 -- Pod IP: 10.1.0.14
	Application VERSION 2 -- Pod IP: 10.1.0.17
	Application VERSION 2 -- Pod IP: 10.1.1.21
	Application VERSION 2 -- Pod IP: 10.1.1.24
	Application VERSION 2 -- Pod IP: 10.1.0.14
	Application VERSION 2 -- Pod IP: 10.1.0.17
	Application VERSION 2 -- Pod IP: 10.1.1.21
	Application VERSION 2 -- Pod IP: 10.1.1.24
	Application VERSION 2 -- Pod IP: 10.1.0.14
	Application VERSION 2 -- Pod IP: 10.1.0.17

# PHP, persistent volumes 
Last Tested: 3.0.0 
(b4m) / 20m

If you don't have a persistent volume already created by root, reference this repo for a quick NFS & PV setup:  
https://github.com/kenthua/openshift-configs/tree/master/root

Browser - New Project (Home view)

	php

Browser - Add to Project

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


# Ruby hello-world with db different project - Ruby Instant App
Last Tested: 3.0.0 

Browser - New Project (Home View)

	data	

Browser - Add to Project - browse all templates 

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

Add Instant App (as system:admin - root user)

	oc create -f ruby-hello-world-template.json -n openshift

Browser - New Project (Home View)

	frontend	

Browser - Add to Project - Create Using a Template 

	ruby-hello-world-template

Click Create - (note parameters already entered) 

Check that the frontend pod is running

	oc project frontend
	
	oc get pod 
	NAME                       READY     REASON       RESTARTS   AGE
	ruby-hello-world-1-build   0/1       ExitCode:0   0          2m
	ruby-hello-world-1-trpn3   1/1       Running      0          1m

Browser - Navigate to:

	http://ruby-hello-world.frontend.cloudapps.example.com


# Ruby hello-world with db different project
Last Tested: 3.0.0 

Browser - New Project (Home View)

	data	

Browser - Add to Project - browse all templates 

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

Browser - New Project (Home View)

	frontend	

Browser - Add to Project

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
Last Tested: 3.0.0 

As admin/root user

	oc create -f php-upload.json -n openshift

Browser - New Project (Home View)

	template-test

Browser - Add to Project -> Select Template -> Create

	template: php-upload-template

Browser - Browse -> Builds -> Start build

Browser - navigate to:

	http://php-upload.template-test.cloudapps.example.com/form.html	

# PHP Upload Application - Instant App
Last Tested: 3.0.0 

	oc new-project newapp-test
	oc new-app php-upload.json
	oc start-build php-upload

Browser - navigate to:

	http://php-upload.newapp-test.cloudapps.example.com/form.html



---


# References
https://github.com/openshift/training 

