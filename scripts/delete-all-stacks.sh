#!/bin/bash

ROOT_PATH=`pwd`
DIR_PATH="$(cd $(dirname $0); pwd)"
PARAMETERS_PATH="$ROOT_PATH/parameters"

function error-exit {
  echo "Error exit"
  exit 1
}

stack_name=`cat "${PARAMETERS_PATH}/parameters.json" | grep -A 1 '"ParameterKey": "StackName"' | tr -d ' ' | grep '^"ParameterValue":' | sed -e 's/^"ParameterValue":"\(.*\)".*$/\1/'`
bucket_name=`aws cloudformation describe-stacks --stack-name "${stack_name}" | tr -d ' ' | grep -2 '"OutputKey":"S3BucketName"' | grep '^"OutputValue"' | sed -e 's/^"OutputValue":"\(.*\)".*$/\1/'`
stack_name_lambda=`cat "${PARAMETERS_PATH}/parameters.json" | grep -A 1 '"ParameterKey": "StackNameLambda"' | tr -d ' ' | grep '^"ParameterValue":' | sed -e 's/^"ParameterValue":"\(.*\)".*$/\1/'`


echo "##### Deleting All Objects in the S3Bucket... #####"

aws s3 rm "s3://${bucket_name}" --recursive || error-exit

echo "##### 1/3 All Objects Deleted #####"


echo "##### Deleting Lambda Stack... #####"

aws cloudformation delete-stack --stack-name "${stack_name_lambda}" || error-exit
aws cloudformation wait stack-delete-complete --stack-name "${stack_name_lambda}" || error-exit

echo "##### 2/3 Lambda Stack Deleted #####"


echo "##### Deleting Stack... #####"

aws cloudformation delete-stack --stack-name "${stack_name}" || error-exit
aws cloudformation wait stack-delete-complete --stack-name "${stack_name}" || error-exit

echo "##### 3/3 Stack Deleted #####"


echo "##### All Stacks Deleted! #####"