#!/bin/bash

set -eu

echo "IMAGE: '${IMAGE}'"
echo "TAG_PREFIX: '${TAG_PREFIX}'"
echo "ARCHITECTURE: '${ARCHITECTURE}'"
echo "BUILD_CONTEXT: '${BUILD_CONTEXT}'"
echo "BUILD_ARGS: '${BUILD_ARGS}'"
echo "BUILD_ARGS_ENV_NAME: '${BUILD_ARGS_ENV_NAME}'"

TAG="${DOCKER_USERNAME}/${IMAGE}:${TAG_PREFIX}${ARCHITECTURE}"

if [[ "${BUILD_ARGS_ENV_NAME}" != "" ]]; then
	BUILD_ARGS="${BUILD_ARGS} ${!BUILD_ARGS_ENV_NAME}"
fi

# shellcheck disable=SC2086
docker build ${BUILD_ARGS} --quiet --tag "${TAG}" "${BUILD_CONTEXT}"

docker push "${TAG}"
