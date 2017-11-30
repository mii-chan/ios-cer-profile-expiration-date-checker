#!/bin/bash

ROOT_PATH=`pwd`
DIR_PATH="$(cd $(dirname $0); pwd)"
TEMPLATES_PATH="$ROOT_PATH/templates"
RUBY_ENV_PATH="$ROOT_PATH/ruby-env"
FUNCTIONS_PATH="$ROOT_PATH/functions"

ZIPNAME='ios-cer-profile-expiration-checker.zip'

# main
(cd "${RUBY_ENV_PATH}"; zip -r9 $ZIPNAME ./ -x "*.DS_Store")

mv "${RUBY_ENV_PATH}/${ZIPNAME}" "${FUNCTIONS_PATH}"

(cd "${FUNCTIONS_PATH}"; zip -r9 $ZIPNAME ./ -x "*.DS_Store")

 mv "${FUNCTIONS_PATH}/${ZIPNAME}" "${ROOT_PATH}"