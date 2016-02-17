User Configs
============

# NodePort Example
Tested 3.1.1.6  
* This example is for exposing A-MQ's TCP 61616 port outside of OSE
* The current HAProxy router in OSE 3.1 and lower only supports HTTP/HTTPS traffic
* Acceptable nodePort range is 30000-32767, specify 0 to have OSE select a port
* Change the selector accordingly to your specified deploymentConfig
* Change the name/description 
* Documentation on [Integrating External Services](https://docs.openshift.com/enterprise/3.1/dev_guide/integrating_external_services.html)

# Application Template Examples
* php-upload - complete php upload application template
* php-upload-persistent - complete php upload with persistent volume application template (requires creation of PV at admin level)

Create the app like this:

	oc new-app php-upload.json
	oc new-app php-upload-persistent.json

	oc start-build php-upload

# Generic Pod
* pod.yaml

Generic pod that'll create a container that pings

# PVC Claim in the App DC
The part we will need to edit is the pod dc template. We will need to add two
parts: 

    oc edit dc/openshift-php-upload

* a definition of the volume
* where to mount it inside the container

First, directly under the `template` `spec:` line, add this YAML (indented from the `spec:` line):

          volumes:
          - name: php-upload-volume
            persistentVolumeClaim:
              claimName: phpclaim

Then to have the container mount this, add this YAML after the
`terminationMessagePath:` line:

            volumeMounts:
            - mountPath: /opt/openshift/src/uploaded
              name: php-upload-volume

Remember that YAML is sensitive to indentation
