'use strict';

// modules
const exec = require('child_process').exec;
const AWS = require('aws-sdk');
const KMS = new AWS.KMS();

// environment variables
const channel = process.env['CHANNEL'];
const username = process.env['USERNAME'];
const icon = process.env['ICON'];
const warningDay = process.env['WARNINGDAY'];
const dangerDay = process.env['DANGERDAY'];
const encryptedParams = [
  process.env['WEBHOOKURL'],
  process.env['ID'],
  process.env['PASS']
];
const decryptedParams = {};

// functions
const execRubyScript = (event, context, callback) => {
  process.env['HOME'] = '/tmp';

  const child = exec(`./list_expiration_dates.rb '${channel}' '${username}' '${icon}' '${warningDay}' '${dangerDay}' '${decryptedParams.webhookurl}' '${decryptedParams.id}' '${decryptedParams.pass}'`,
  { env: process.env },
  result => {
    callback(null, result);
  });
  
  // Display Logs for development (make sure not to display your password!)
  // child.stdout.on('data', console.log);
  // child.stderr.on('data', console.error);
};

const decryptEnvVar = encryptedParam => KMS.decrypt({ CiphertextBlob: new Buffer(encryptedParam, 'base64') })
                                         .promise()
                                         .then(data => data.Plaintext.toString('ascii'));

// main
exports.handler = (event, context, callback) => {
  if (decryptedParams.webhookurl && decryptedParams.id && decryptedParams.pass) {
    execRubyScript(event, context, callback);
  } else {
    Promise.all(encryptedParams.map( encryptedParam => decryptEnvVar(encryptedParam) ))
    .then(params => {
      decryptedParams.webhookurl = params[0];
      decryptedParams.id = params[1];
      decryptedParams.pass = params[2];
      
      execRubyScript(event, context, callback);
    })
    .catch(err => {
      console.log('Decrypt error:', err);
      callback(err);
    });
  }
};