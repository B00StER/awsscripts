#!/bin/bash

### (c) Mike Syroezhko
# https://github.com/B00StER/awsscripts
#
### A helper script to test your AWS CodeDeploy deployments with.
# 
### Prerequisites
# - System: Bash, jq, AWS CLI installed and configured, /tmp exists and is writable
# - AWS: An infrastructure to deploy your app to (i.e., EC2 Autoscaling group), CodeDeploy Application and Deployment Group
# - Local directory with the application code (cloned git repo)
# - appspec.yml and this script must be in the root of the app directory
#

# echo "Pulling the latest version from git"
# git pull

count=0
pollingPeriod=5
TZ=UTC
region="us-east-1"
s3Bucket="s3-bucket-name"
appName="codedeploy-application-name"
deploymentGroupName="deployment-group-name"

### Start
#
GITHASH=`git rev-parse HEAD`
echo "Creating artifact bundle"
mkdir -p /tmp/$GITHASH
# lazy way to hide .git dir
mv .git /tmp/$GITHASH
bundleInfo=$(aws deploy push --region ${region} --output json --application-name ${appName} --s3-location s3://${s3Bucket}/${appName}/bundle.zip);


### Trigger new deployment
#
echo "Starting the deployment"
deploymentJSON=$(aws deploy create-deployment --region ${region} --output json --application-name ${appName} --deployment-group-name ${deploymentGroupName} --description "${appName} Git Hash ${GITHASH}" --s3-location bucket=${s3Bucket},key=${appName}/bundle.zip,bundleType=zip);

if (( $? != 0 )); then
   log "FAIL" "Failed when creating deployment in AWS CodeDeploy"
   exit 1
fi

deploymentId=$(echo "${deploymentJSON}" | jq -r .deploymentId);

echo "Waiting for the end of the Deployment (ID: ${deploymentId})"

finished=false;
failed=false;
sp="/-\|"
while [[ $finished == false ]]; do

  deploymentStatus=$(aws deploy get-deployment --output json --deployment-id ${deploymentId});
  status=$(echo "$deploymentStatus" | jq -r .deploymentInfo.status);
  statusSummary=$(echo "$deploymentStatus" | jq -r '.deploymentInfo.deploymentOverview | "Pending: " + (.Pending|tostring) + ", In Progress: " + (.InProgress|tostring) + ", Succeeded: " + (.Succeeded|tostring) + ", Failed: " + (.Failed|tostring)');

  if [[ $status == "Succeeded" ]]; then
    finished=true;
    seconds=$(($count * $pollingPeriod))
    timePeriod=$(echo $seconds | awk '{printf "%d:%02d:%02d", $1/3600, ($1/60)%60, $1%60}')
    echo "Deployment ${deploymentId} succeeded. It took ${timePeriod} to run";
    break;
  fi
  if [[ $status == "Stopped" ]]; then
    finished=true;
    failed=true;
    echo "Deployment ${deploymentId} stopped";
    break;
  fi
  if [[ $status == "Failed" ]]; then
    finished=true;
    failed=true;
    error=$(echo "$deploymentStatus" | jq -r .deploymentInfo.errorInformation.message);
    echo "Deployment ${deploymentId} failed";
    echo "Error: ${error}"
    break;
  fi

  sleep $pollingPeriod;
  printf "\b${sp:count++%${#sp}:1}"
#  ((count+=1));
done

mv /tmp/$GITHASH/.git .
rm -rf /tmp/$GITHASH
