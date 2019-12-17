#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/redhat-gpte-devopsautomation/advdev_homework_template.git na311.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project cicd-admin from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Set up Jenkins with sufficient resources
# TBD

oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi --param DISABLE_ADMINISTRATIVE_MONITORS=true  -n cicd-admin
oc set resources dc jenkins --limits=memory=2Gi,cpu=2 --requests=memory=1Gi,cpu=200m  -n cicd-admin

oc expose svc/jenkins  -n cicd-admin


# Create custom agent container image with skopeo
# TBD
oc new-build -D $'FROM registry.example.com:8443/openshift3/jenkins-agent-maven-35-rhel7
USER root
RUN yum -y install skopeo --disablerepo=* --enablerepo=rhel-7-server-extras-rpms,rhel-7-server-rpms && yum clean all
USER 1001' --name=jenkins-agent-appdev -n cicd-admin


# Create pipeline build config pointing to the ${REPO} with contextDir `openshift-tasks`
# TBD
echo "apiVersion: v1
items:
- kind: 'BuildConfig'
  apiVersion: 'v1'
  metadata:
    name: 'demo-pipeline'
  spec:
    source:
      contextDir: openshift-tasks
      type: 'git'
      git:
        uri: 'http://gogs.cicd-admin.svc:3000/gogs/advdev_homework.git'
    strategy:
      type: 'JenkinsPipeline'
      jenkinsPipelineStrategy:
        env:
        - name: GUID
          value: ${GUID}
        jenkinsfilePath: Jenkinsfile
kind: List
metadata: []" | oc apply -f - -n cicd-admin

# Make sure that Jenkins is fully up and running before proceeding!
while : ; do
  echo "Checking if Jenkins is Ready..."
  AVAILABLE_REPLICAS=$(oc get dc jenkins -n cicd-admin -o=jsonpath='{.status.availableReplicas}')
  if [[ "$AVAILABLE_REPLICAS" == "1" ]]; then
    echo "...Yes. Jenkins is ready."
    break
  fi
  echo "...no. Sleeping 10 seconds."
  sleep 10
done