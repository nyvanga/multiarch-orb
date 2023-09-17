#!/bin/bash

set -eu

echo "IMAGE: '${IMAGE}'"
echo "TAG_ENV: '${TAG_ENV}'"
echo "${TAG_ENV}: '${!TAG_ENV}'"

curl -H "Authorization: JWT ${DOCKER_HUB_TOKEN}" -X DELETE "https://hub.docker.com/v2/repositories/${DOCKER_USERNAME}/${IMAGE}/tags/${!TAG_ENV}/"
