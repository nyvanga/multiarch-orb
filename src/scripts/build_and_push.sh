#!/bin/bash

set -eu

TAG="${DOCKER_USERNAME}/${IMAGE}:${TAG_PREFIX}${ARCHITECTURE}"

if [[ "${BUILD_ARGS_ENV_NAME}" != "" ]]; then
	BUILD_ARGS="${BUILD_ARGS} ${!BUILD_ARGS_ENV_NAME}"
fi

# shellcheck disable=SC2086
docker build ${BUILD_ARGS} --quiet --tag "${TAG}" "${BUILD_CONTEXT}"

docker push "${TAG}"
