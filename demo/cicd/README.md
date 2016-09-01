OCP 3.2 CI/CD
===

Tested on: OCP 3.2 & on cdk 2.1

## Description
Examples of OpenShift Container Platform CI/CD, leveraging Jenkins, gogs, sonarqube and nexus.

* Source, use the openshift builder image to build from Source
* Binary, build within Jenkins and use OCP's binary build to add your app

## Prerequisites
Deployment of this [example](https://github.com/kenthua/summit2016-ose-cicd) is required.  As it depends on the infrastructure installed.  

## Instructions 
0. Login to your environment
  * cdk: `vagrant ssh` into your environment
0. Clone this repo
0. Modify `ocp_*` variables in `vars.yaml`
0. Run the `configure.sh` to add the repos to gogs, setup the jenkins pipelines, and install sonarqube.  The second playbook will initialize the projects.
0. Ensure that sonarqube is started and running, otherwise this step in the binary pipeline will fail
0. Navigate to jenkins and fire off the pipelines or make a change to the gogs applications