OCP 3.2 CI/CD
===

Tested: OCP 3.2 (cdk 2.1)

## Description

Examples of OpenShift Container Platform CI/CD, leveraging Jenkins, gogs, and nexus.

0. Source, use the openshift builder image to build from Source
0. Binary, build within Jenkins and use OCP's binary build to add your app

## Prerequisites
Deployment of this [example](https://github.com/kenthua/summit2016-ose-cicd) is required.  As it depends on this infrastructure.  

## Instructions 
How to Run on CDK:

0. `vagrant ssh` into your environment
0. Clone this repo
0. Run the `init.sh` to add the repos to gogs and setup the jenkins pipelines
0. Run the `ocp_project_prep.sh` to initialize the projects
0. Navigate to jenkins and fire off the pipelines or make a change to the gogs applications