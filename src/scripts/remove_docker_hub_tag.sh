#!/bin/bash

set -eu

echo "IMAGE: '${IMAGE}'"
echo "TAG: '${TAG}'"

if [[ ${TAG} =~ ^date$ ]]; then
  TAG="$(date +'%Y-%m-%d')"
elif [[ ${TAG} =~ ^timestamp$ ]]; then
  TAG="$(date +'%Y-%m-%d_%H-%M-%S')"
fi

echo "TAG(resolved): '${TAG}'"

curl -H "Authorization: JWT ${DOCKER_HUB_TOKEN}" -X DELETE "https://hub.docker.com/v2/repositories/${DOCKER_USERNAME}/${IMAGE}/tags/${TAG}/"
