# THIS TOOL IS NO LONGER MAINTAINED. YOU SHOULD NOT USE THIS IN PRODUCTION

## iOS certificates and provisioning profiles expiration dates checker
`ios-cer-profile-expiration-date-checker` is a tool for checking the expiration dates of iOS certificates and provisioning profiles and post the days left to Slack, by using AWS Lambda and fastlane/spaceship.

[Qiita article (in Japanese)](https://qiita.com/mii-chan/items/3a9d9f45b2c370372d45)

## How to use
### 1. Set up the environment to execute AWS CLI command
 1. Install AWS CLI if you haven't
 2. Set up the credentials on your local machine

### 2. Create Ruby execution environment in `ruby-env` directory
 1. Install Docker if you haven't
 2. Make sure you're in the project root, then execute the script below in terminal. Automatically create docker image and get into the container
    - `$ ./scripts/create-ruby-env.sh`

### 3. After Running the script, make sure you're in the docker container, then execute the script below in the container
* `bash-4.2# cp -a . /app`
* `bash-4.2# exit`

### 4. Modify parameters.json and schedule-expression files in parameters directory

#### parameters.json

Parameter Key | Parameter Value Example | Description
---|:---:|---
StackName| `"iOS-cer-profile-expiration-date-check"` | A name for CloudFormation Stack created ahead of deploying the Lambda function (**only alphanumeric characters and hyphens**). It creates S3 Bucket, KMS and Execution Role for Lambda. For more information, see [cf-template.yaml](/templates/cf-template.yaml) in `templates` directory.
StackNameLambda| `"iOS-cer-profile-expiration-date-check-lambda"` | A name for CloudFormation Stack for deploying the Lambda function(**only alphanumeric characters and hyphens**). For more information, see [sam-template.yaml](/templates/sam-template.yaml) in `templates` directory.
CHANNEL|`"#general"`| Slack Channel to post message to
USERNAME|`"iOS Monthly Bot"`| Name of this Bot (displayed in Slack)
ICON|`":iphone:"`| Icon of this Bot (displayed in Slack)
WARNINGDAY|`"60"`| If an expiration day is less than the day, the Slack attachment color will be orange
DANGERDAY|`"30"`| If an expiration day is less than the day, the Slack attachment color will be red

#### schedule-expression
Specify a Schedule Expression for CloudWatch Event to invoke the Lambda function on a regular schedule. Please specify like `ScheduleExpression: <Rate or Cron expression>` as written in line 5. For more information on Schedule Expressions, see AWS official Document, [Schedule Expressions Using Rate or Cron](http://docs.aws.amazon.com/ja_jp/lambda/latest/dg/tutorial-scheduled-events-schedule-expressions.html).

### 5. Make sure you're in the project root, then execute the script below in terminal. Automatically create CloudFormation stacks and deploy Lambda in your AWS Account!
- `$ ./scripts/setup.sh`
- Please input the following values (will be encrypted by AWS KMS and set as Environment Variables in the Lambda function)
  * `AppleID:` Your Apple ID to login to the Apple Deeloper Portal
  * `Password:` Your Password to login to the Apple Deeloper Portal
  * `WebhookURL:` You Slack Incoming Webhook URL
    - if error occured, fix the issues and rerun the script.
      * you might be better to delete the stacks before rerunning.
      * If you'd like to delete all the stacks, please execute `$ ./scripts/delete-all-stacks.sh` in your project root

## Libraries
This depends on the following libraries.Thanks :)
### JavaScript
 - [aws/aws-sdk-js](https://github.com/aws/aws-sdk-js)
   * [Apache License 2.0](https://github.com/aws/aws-sdk-js/blob/master/LICENSE.txt)

### Ruby
 - [phusion/traveling-ruby](https://github.com/phusion/traveling-ruby)
   * [MIT License](https://github.com/phusion/traveling-ruby/blob/master/LICENSE.md)
 - [fastlane/fastlane/spaceship](https://github.com/fastlane/fastlane/tree/master/spaceship)
   * [MIT License](https://github.com/fastlane/fastlane/blob/master/LICENSE)
 - [shoyan/slack-incoming-webhooks](https://github.com/shoyan/slack-incoming-webhooks)
   * [MIT License](https://github.com/shoyan/slack-incoming-webhooks/blob/master/LICENSE.txt)

### Deploy
 - [aws/aws-cli](https://github.com/aws/aws-cli)
   * [Apache License 2.0](https://github.com/aws/aws-cli/blob/develop/LICENSE.txt)

## License
MIT License, see [LICENSE](/LICENSE).
