#!/bin/bash

set -eu

echo "IMAGE: '${IMAGE}'"
echo "TAG_PREFIX: '${TAG_PREFIX}'"
echo "TAG: '${TAG}'"

if [[ ${TAG} =~ ^date$ ]]; then
  TAG="$(date +'%Y-%m-%d')"
elif [[ ${TAG} =~ ^timestamp$ ]]; then
  TAG="$(date +'%Y-%m-%d_%H-%M-%S')"
fi

echo "TAG(resolved): '${TAG}'"

MANIFEST="${DOCKER_USERNAME}/${IMAGE}:${TAG}"

docker manifest create "${MANIFEST}" \
  --amend "${DOCKER_USERNAME}/${IMAGE}:${TAG_PREFIX}x86_64" \
  --amend "${DOCKER_USERNAME}/${IMAGE}:${TAG_PREFIX}arm64"

docker manifest push "${MANIFEST}"
