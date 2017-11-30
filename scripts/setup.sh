#!/bin/bash

ROOT_PATH=`pwd`
DIR_PATH="$(cd $(dirname $0); pwd)"
TEMPLATES_PATH="$ROOT_PATH/templates"
PARAMETERS_PATH="$ROOT_PATH/parameters"

function error-exit {
  echo "Error exit"
  rm -f tmp-file
  rm -f tmp-template.yaml
  exit 1
}

# 0. Input Apple ID, Password, Slack Webhook URL
read -p "AppleID: " id
read -sp "Password: " pass; echo
read -sp "WebhookURL: " url; echo

# 1. Create S3 bucket for Lambda by AWS CloudFormation
stack_name=`cat "${PARAMETERS_PATH}/parameters.json" | grep -A 1 '"ParameterKey": "StackName"' | tr -d ' ' | grep '^"ParameterValue":' | sed -e 's/^"ParameterValue":"\(.*\)".*$/\1/'`
aws cloudformation create-stack --stack-name "${stack_name}" --template-body "file://${TEMPLATES_PATH}/cf-template.yaml" --capabilities CAPABILITY_IAM || error-exit

echo "##### Creating Stack... #####"

aws cloudformation wait stack-create-complete --stack-name "${stack_name}" || error-exit

echo "##### 1/4 Create Stack Completed #####"


# 2. Create Zip file
echo "##### Creating Zip file... #####"

"${DIR_PATH}/create-zip.sh"

echo "##### 2/4 Deploy Package is Ready #####"


# 3. Upload Zip file to S3 
echo "##### 3/4 Uploading package to S3... #####"

aws cloudformation describe-stacks --stack-name "${stack_name}" > tmp-file
bucket_name=`cat tmp-file | tr -d ' ' | grep -2 '"OutputKey":"S3BucketName"' | grep '^"OutputValue"' | sed -e 's/^"OutputValue":"\(.*\)".*$/\1/'`
kms_key_arn=`cat tmp-file | tr -d ' ' | grep -2 '"OutputKey":"KmsKeyArn"' | grep '^"OutputValue"' | sed -e 's/^"OutputValue":"\(.*\)".*$/\1/'`
lambda_role_arn=`cat tmp-file | tr -d ' ' | grep -2 '"OutputKey":"LambdaRoleArn"' | grep '^"OutputValue"' | sed -e 's/^"OutputValue":"\(.*\)".*$/\1/'`

schedule_exp=`cat "${PARAMETERS_PATH}/schedule-expression" | grep "^ScheduleExpression:" | sed -e 's/^ScheduleExpression://' | sed -e 's/^[   ]*//' -e 's/[   ]*$//'`
encrypted_id=`aws kms encrypt --key-id "${kms_key_arn}" --plaintext "${id}" | tr -d ' ' | grep '"CiphertextBlob":' | sed -e 's/^"CiphertextBlob":"\(.*\)".*$/\1/'`
encrypted_pass=`aws kms encrypt --key-id "${kms_key_arn}" --plaintext "${pass}" | tr -d ' ' | grep '"CiphertextBlob":' | sed -e 's/^"CiphertextBlob":"\(.*\)".*$/\1/'`
url=`echo "${url}" | sed -e 's|^https://||'`
encrypted_url=`aws kms encrypt --key-id "${kms_key_arn}" --plaintext "${url}" | tr -d ' ' | grep '"CiphertextBlob":' | sed -e 's/^"CiphertextBlob":"\(.*\)".*$/\1/'`

cat "${TEMPLATES_PATH}/sam-template.yaml" | sed -e "s/###ScheduleExpression###/${schedule_exp}/" -e "s'###AppleID###'${encrypted_id}'" -e "s'###Password###'${encrypted_pass}'" -e "s'###WebhookURL###'${encrypted_url}'" > tmp-template.yaml

aws cloudformation package \
  --template-file tmp-template.yaml \
  --output-template-file "${TEMPLATES_PATH}/sam-template-output.yaml" \
  --s3-bucket "${bucket_name}" || error-exit

echo "##### 3/4 Uploaded package to S3 #####"


# 4. Deploy Lambda
echo "##### Deploying #####"
stack_name_lambda=`cat "${PARAMETERS_PATH}/parameters.json" | grep -A 1 '"ParameterKey": "StackNameLambda"' | tr -d ' ' | grep '^"ParameterValue":' | sed -e 's/^"ParameterValue":"\(.*\)".*$/\1/'`
cat "${PARAMETERS_PATH}/parameters.json" | tr -d ' ' | tr -d '\n' | sed  -e 's/^\[//' -e 's/\]$//' -e 's/"},{"/ /g' -e 's/ParameterKey":"//g' -e 's/","ParameterValue":"/=/g' -e 's/^{"//' -e 's/"}$//' |
aws cloudformation deploy \
   --template-file  "${TEMPLATES_PATH}/sam-template-output.yaml" \
   --stack-name "${stack_name_lambda}" \
   --capabilities CAPABILITY_IAM \
   --parameter-overrides `cat -` KmsKeyArn="${kms_key_arn}" LambdaRoleArn="${lambda_role_arn}" || error-exit

echo "##### 4/4 Deployed! #####"


rm -f tmp-file
rm -f tmp-template.yaml
exit 0