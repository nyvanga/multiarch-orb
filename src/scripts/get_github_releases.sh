#!/bin/bash

set -euo pipefail

shopt -s extglob

MAJOR_VERSIONS=()
UNIQ_MAJOR_VERSIONS=()
VERSIONS=()
STABLE_VERSIONS=()
PRE_RELEASE_VERSIONS=()
IS_PRE_RELEASE=()

function env_message() {
	local env_name="${1}"; shift
	local env_message="${1}"; shift
	if [[ "${!env_name:-}" == "" ]]; then
		echo "Env variable '${env_name}' needs to be set to ${env_message}."
		exit 1
	fi
}

function usage() {
	echo "Usage: $(basename "${0}")"
	env_message "OWNER" "a Github owner"
	# shellcheck disable=SC2153
	env_message "REPO" "a Github repo of owner '${OWNER}'"
	env_message "COMMAND" "one of: all, major, stable, latest, pre-release or major version"
	echo "All:"
	echo "  Lists all versions."
	echo "Major:"
	echo "  Lists latest of each major version."
	if [[ ${#STABLE_VERSIONS[@]} -gt 0 ]]; then
		echo "Stable is:"
		echo "  ${STABLE_VERSIONS[0]}"
	fi
	if [[ ${#VERSIONS[@]} -gt 0 ]]; then
		echo "Latest is:"
		echo "  ${VERSIONS[0]}"
	fi
	if [[ ${#PRE_RELEASE_VERSIONS[@]} -gt 0 ]]; then
		echo "Pre-release is:"
		echo "  ${PRE_RELEASE_VERSIONS[0]}"
	fi
	if [[ ${#UNIQ_MAJOR_VERSIONS[@]} -gt 0 ]]; then
		echo "Major version one of:"
		echo "  $(echo "${VERSION_PATTERN}" | sed -r 's/\|/, /g')"
	fi
	exit 1
}

function parse_github_releases() {
	local owner="${1}"; shift
	local repo="${1}"; shift
	local releases_path="${owner}/${repo}/releases"
	local tag_regex=".*href=\"/${releases_path}/tag/([^\"]+)\".*"
	local pre_release_regex='Pre-release'
	local release_tag=''
	local pre_release=''
	local line
	while read -r line; do
		if [[ "${line}" =~ ${tag_regex} ]]; then
			if [[ "${release_tag}" != "" ]]; then
				echo "${release_tag} pre-release=${pre_release}"
			fi
			release_tag="$(echo "${line}" | sed -r "s|${tag_regex}|\1|")"
			pre_release='No'
		elif [[ "${line}" =~ ${pre_release_regex} ]]; then
			pre_release='Yes'
		fi
	done < <(curl -sS "https://github.com/${releases_path}" | grep -E "${tag_regex}|${pre_release_regex}")
	if [[ "${release_tag}" != "" ]]; then
		echo "${release_tag} pre-release=${pre_release}"
	fi
}

function parse_versions() {
	local previous_major_version=""
	local index
	for index in "${!VERSIONS[@]}"; do
		local major_version
		major_version=$(echo "${VERSIONS[index]}" | sed -r 's/^([0-9]+\.[0-9]+).*$/\1/')
		MAJOR_VERSIONS+=("${major_version}")
		if [[ "${major_version}" != "${previous_major_version}" ]]; then
			previous_major_version=${major_version}
			UNIQ_MAJOR_VERSIONS+=("${major_version}")
		fi
		if [[ ${IS_PRE_RELEASE[index]} =~ No ]]; then
			if [[ ! ${VERSIONS[index]} =~ (alpha|beta|oci|rc) ]]; then
				STABLE_VERSIONS+=("${VERSIONS[index]}")
			else
				PRE_RELEASE_VERSIONS+=("${VERSIONS[index]}")
			fi
		else
			PRE_RELEASE_VERSIONS+=("${VERSIONS[index]}")
		fi
	done
	# shellcheck disable=SC2001
	VERSION_PATTERN="$(echo "${UNIQ_MAJOR_VERSIONS[@]}" | sed 's/ /\|/g')"
}

function get_github_releases_versions() {
	local owner="${1}"; shift
	local repo="${1}"; shift
	local tag_line_regex="^(.+) pre-release=(.+)$"
	while read -r release_tag; do
		VERSIONS+=("$(echo "${release_tag}" | sed -r "s/${tag_line_regex}/\1/" | sed -r "s/^v?([0-9]+\.[0-9]+\.[0-9]+)/\1/")")
		IS_PRE_RELEASE+=("$(echo "${release_tag}" | sed -r "s/${tag_line_regex}/\2/")")
	done < <(parse_github_releases "${owner}" "${repo}" | sort --reverse)
	parse_versions
}

if [[ "${OWNER:-}" != "" ]] && [[ "${REPO:-}" != "" ]]; then
	get_github_releases_versions "${OWNER}" "${REPO}"
else
	usage
fi

function get_version() {
	local index="${1}"; shift
	local extra_tags=""
	if [[ "${VERSIONS[index]}" == "${STABLE_VERSIONS[0]}" ]]; then
		extra_tags="${extra_tags} stable"
	fi
	if [[ "${VERSIONS[index]}" == "${VERSIONS[0]}" ]]; then
		extra_tags="${extra_tags} latest"
	fi
	if [[ ${PRE_RELEASE_VERSIONS[0]} =~ ${VERSIONS[index]} ]]; then
		extra_tags="${extra_tags} pre-release"
	fi
	echo "${MAJOR_VERSIONS[index]} ${VERSIONS[index]}${extra_tags}"
}

function get_major_version() {
	local major_version="${1}"; shift
	local index
	for index in "${!MAJOR_VERSIONS[@]}"; do
		if [[ "${major_version}" == "${MAJOR_VERSIONS[index]}" ]]; then
			get_version "${index}"
			return
		fi
	done
}

function get_all_major_versions() {
	local index	
	for index in "${!UNIQ_MAJOR_VERSIONS[@]}"; do
		get_major_version "${UNIQ_MAJOR_VERSIONS[index]}"
	done
}

function get_all_versions() {
	local index
	for index in "${!VERSIONS[@]}"; do
		get_version "${index}"
	done
}

function get_major_version_from_version() {
	local version="${1}"; shift
	local index
	for index in "${!VERSIONS[@]}"; do
		if [[ "${VERSIONS[index]}" == "${version}" ]]; then
			echo "${MAJOR_VERSIONS[index]}"
		fi
	done
}

function create_version_json() {
	local name="${1}"; shift
	local major_version="${1}"; shift
	local minor_version="${1}"; shift
	local name_prefix
	name_prefix="$(echo "${OWNER,,}_${REPO,,}_${name}" | sed -r 's/[^a-z0-9_]//')"
	if [[ "${name_prefix}" =~ ^${FILTER} ]]; then
		local json
		json="$(jq --null-input \
			--arg name1 "${name_prefix}_major" --arg value1 "${major_version}" \
			--arg name2 "${name_prefix}_minor" --arg value2 "${minor_version}" \
			'{ ($name1): $value1, ($name2): $value2 }')"
		JSON+=("${json}")
	fi
}

function get_old_version_json() {
	local name="${1}"; shift
	local major_version="${1}"; shift
	local index
	for index in "${!MAJOR_VERSIONS[@]}"; do
		if [[ "${major_version}" == "${MAJOR_VERSIONS[index]}" ]]; then
			create_version_json "${name}" "${MAJOR_VERSIONS[index]}" "${VERSIONS[index]}"
			return
		fi
	done
}

function get_versions_json() {
	local major_version=''
	if [[ ${#STABLE_VERSIONS[@]} -gt 0 ]]; then
		major_version="$(get_major_version_from_version "${STABLE_VERSIONS[0]}")"
		create_version_json "stable" "${major_version}" "${STABLE_VERSIONS[0]}"
	else
		create_version_json "stable" "--" "--"
	fi
	local major_pre_release=''
	if [[ ${#PRE_RELEASE_VERSIONS[@]} -gt 0 ]]; then
		major_pre_release="$(get_major_version_from_version "${PRE_RELEASE_VERSIONS[0]}")"
		create_version_json "prerelease" "${major_pre_release}" "${PRE_RELEASE_VERSIONS[0]}"
	else
		create_version_json "prerelease" "--" "--"
	fi
	local old_major_version
	local old_index=1
	local index
	for index in "${!UNIQ_MAJOR_VERSIONS[@]}"; do
		old_major_version="${UNIQ_MAJOR_VERSIONS[index]}"
		if [[ "${old_major_version}" != "${major_version}" ]] && [[ "${old_major_version}" != "${major_pre_release}" ]]; then
			get_old_version_json "old${old_index}" "${old_major_version}"
			old_index=$((old_index + 1))
		fi
	done
	if [[ ${#JSON[@]} -gt 0 ]]; then
		if [[ "${JSONFILE:-}" == "" ]]; then
			echo "${JSON[@]}" | jq --slurp add
		else
			if [[ -f "${JSONFILE}" ]]; then
				JSON+=("$(cat "${JSONFILE}")")
			fi
			echo "${JSON[@]}" | jq --slurp add | tee "${JSONFILE}" | jq '.'
		fi
	else
		echo "Empty JSON. Maybe FILTER isn't set correctly?"
	fi
}

case "${COMMAND:-}" in
	all)
		get_all_versions
		;;

	major)
		get_all_major_versions
		;;

	stable)
		echo "${STABLE_VERSIONS[0]}"
		;;

	latest)
		echo "${VERSIONS[0]}"
		;;

	pre-release)
		echo "${PRE_RELEASE_VERSIONS[0]}"
		;;

	@($VERSION_PATTERN))
		get_major_version "${COMMAND}"
		;;

	json)
		JSON=()
		get_versions_json
		;;

	*)
		usage
		;;
esac
