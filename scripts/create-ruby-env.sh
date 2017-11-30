#!/bin/bash

ROOT_PATH=`pwd`
DIR_PATH="$(cd $(dirname $0); pwd)"
TEMPLATES_PATH="$ROOT_PATH/templates"

# Create a docker image
docker build -t mii-chan/lambda-ruby-env:1.0 "${TEMPLATES_PATH}"

# Run it
docker run --rm -it -v "$(pwd)/ruby-env":/app mii-chan/lambda-ruby-env:1.0

# After getting into the container, execute the following commands
# bash-4.2# cp -rp * .[^\.]* /app
# bash-4.2# exit

# Now, Ruby Execution Environment is ready under `ruby-env` directory