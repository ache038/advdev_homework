#!/bin/bash
# Setup Development Project

echo "Setting up Tasks Development Environment in project tasks-dev"

# Set up Dev Project
oc policy add-role-to-user edit system:serviceaccount:cicd-admin:jenkins -n tasks-dev

# Set up Dev Application
oc new-build --binary=true --name="tasks" --image-stream=openshift/jboss-eap72-openshift:latest -n tasks-dev
oc new-app tasks-dev/tasks:0.0-0 --name=tasks --allow-missing-imagestream-tags=true -n tasks-dev
oc set triggers dc/tasks --remove-all -n tasks-dev
oc expose dc tasks --port 8080 -n tasks-dev
oc expose svc tasks -n tasks-dev
oc create configmap tasks-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n tasks-dev
oc set volume dc/tasks --add --name=jboss-config --mount-path=/opt/eap/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-config -n tasks-dev
oc set volume dc/tasks --add --name=jboss-config1 --mount-path=/opt/eap/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=tasks-config -n tasks-dev
oc set probe dc/tasks --readiness --get-url=http://:8080/ --initial-delay-seconds=50 --timeout-seconds=1 -n tasks-dev
oc set probe dc/tasks --liveness --get-url=http://:8080/ --initial-delay-seconds=50 --timeout-seconds=1 -n tasks-dev

# Setting 'wrong' VERSION. This will need to be updated in the pipeline
oc set env dc/tasks VERSION='0.0 (tasks-dev)' -n tasks-dev
