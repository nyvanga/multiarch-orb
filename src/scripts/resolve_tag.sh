#!/bin/bash

set -eu

TAG_ENV="RESOLVED_${TAG}"

echo "TAG: '${TAG}'"
echo "TAG_ENV: '${TAG_ENV}'"

if [[ ${TAG} =~ ^date$ ]]; then
	TAG="$(date +'%Y-%m-%d')"
elif [[ ${TAG} =~ ^timestamp$ ]]; then
	TAG="$(date +'%Y-%m-%d_%H-%M-%S')"
fi

echo "${TAG_ENV}: '${TAG}'"

echo "export ${TAG_ENV}='${TAG}'" >> "${BASH_ENV}"
