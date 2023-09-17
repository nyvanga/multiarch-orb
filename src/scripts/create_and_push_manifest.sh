#!/bin/bash

set -eu

echo "IMAGE: '${IMAGE}'"
echo "TAG_PREFIX: '${TAG_PREFIX}'"
echo "TAG_ENV: '${TAG_ENV}'"
echo "${TAG_ENV}: '${!TAG_ENV}'"

MANIFEST="${DOCKER_USERNAME}/${IMAGE}:${!TAG_ENV}"

docker manifest create "${MANIFEST}" \
  --amend "${DOCKER_USERNAME}/${IMAGE}:${TAG_PREFIX}x86_64" \
  --amend "${DOCKER_USERNAME}/${IMAGE}:${TAG_PREFIX}arm64"

docker manifest push "${MANIFEST}"
