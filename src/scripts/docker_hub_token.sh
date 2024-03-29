#!/bin/bash

set -eu

LOGIN_DATA="$(jq -n --arg user "${DOCKER_USERNAME}" --arg passwd "${DOCKER_PASSWORD}" '{ username: $user, password: $passwd }')"

TOKEN="$(curl -s -H "Content-Type: application/json" -X POST -d "${LOGIN_DATA}" "https://hub.docker.com/v2/users/login/" | jq -r .token)"

echo "export DOCKER_HUB_TOKEN='${TOKEN}'" >> "${BASH_ENV}"
