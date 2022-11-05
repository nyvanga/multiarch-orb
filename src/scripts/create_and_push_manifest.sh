#!/bin/bash

set -eu

function get_image_name() {
	local tag="${1}"; shift
	if [[ ${tag} =~ ^date$ ]]; then
		echo "${DOCKER_USERNAME}/${IMAGE}:$(date +'%Y-%m-%d')"
	elif [[ ${tag} =~ ^timestamp$ ]]; then
		echo "${DOCKER_USERNAME}/${IMAGE}:$(date +'%Y-%m-%d_%H-%M-%S')"
	else
		echo "${DOCKER_USERNAME}/${IMAGE}:${tag}"
	fi
}

for TAG in ${TAGS}; do
    MANIFEST="$(get_image_name "${TAG}")"
    docker manifest create "${MANIFEST}" \
      --amend "${DOCKER_USERNAME}/${IMAGE}:x86_64" \
      --amend "${DOCKER_USERNAME}/${IMAGE}:arm64"
    docker manifest push "${MANIFEST}"
done
