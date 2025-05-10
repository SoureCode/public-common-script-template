#!/usr/bin/env bash
###############################################################################
# DO NOT MODIFY THIS FILE
#
# This file is maintained by the template.
# Any changes you make here will be automatically overwritten.
#
# If modifications are necessary, please update the template instead.
###############################################################################

set -euo pipefail

PUBCST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "${PUBCST_CURRENT_DIRECTORY}/_variables.sh"

#<editor-fold desc="base functions">
_PUBCST_CONTEXT_PRINTED=false
function _pubcst_print_context() {
    if [ "$_PUBCST_CONTEXT_PRINTED" = true ]; then
        return
    fi

    echo "========== CONTEXT =========="
    echo "CURRENT_ID: ${PUBCST_CURRENT_ID}"
    echo "CURRENT_WORKING_DIRECTORY: ${PUBCST_CURRENT_WORKING_DIRECTORY}"
    echo "CURRENT_HOME: ${PUBCST_CURRENT_HOME}"
    echo "CURRENT_SHELL: ${PUBCST_CURRENT_SHELL}"
    echo "SCRIPT_DIRECTORY: ${PUBCST_SCRIPT_DIRECTORY}"
    echo "PROJECT_DIRECTORY: ${PUBCST_PROJECT_DIRECTORY}"
    echo "PHP: $(_pubcst_php -v)"
    echo "COMPOSER: $(_pubcst_composer -V)"
    echo "============================="

    _PUBCST_CONTEXT_PRINTED=true
}

function _pubcst_call_hook() {
    local HOOK_NAME="${1:-}"

    shift

    if [ -z "$HOOK_NAME" ]; then
        echo "Missing required parameter: HOOK_NAME"
        exit 1
    fi

    local HOOK_FILE="${PUBCST_SCRIPT_DIRECTORY}/hooks/${HOOK_NAME}.sh"

    if [ -f "$HOOK_FILE" ]; then
        source "${HOOK_FILE}" "$@"
    fi

    local LOCAL_HOOK_FILE="${PUBCST_SCRIPT_DIRECTORY}/hooks/${HOOK_NAME}.local.sh"

    if [ -f "$LOCAL_HOOK_FILE" ]; then
        source "${LOCAL_HOOK_FILE}" "$@"
    fi
}
function _pubcst_resolve_binary() {
    local BINARY_NAME="${1:-}"
    local IS_REQUIRED="${2:-true}"

    if [ -z "$BINARY_NAME" ]; then
        echo "Missing required parameter: BINARY_NAME"
        exit 1
    fi

    local ALIAS_OUTPUT
    local BINARY_PATH

    ALIAS_OUTPUT="$(alias "$BINARY_NAME" 2>/dev/null)"

    if [ -n "$ALIAS_OUTPUT" ]; then
        ALIAS_OUTPUT=${ALIAS_OUTPUT#alias } # Remove "alias " prefix
        ALIAS_OUTPUT=${ALIAS_OUTPUT#*=}     # Remove everything before "="
        ALIAS_OUTPUT=${ALIAS_OUTPUT//\'/}   # Remove single quotes

        echo "$ALIAS_OUTPUT"
        return 0
    fi

    BINARY_PATH="$(command -v "$BINARY_NAME" 2>/dev/null)"

    if [ -n "$BINARY_PATH" ]; then
        echo "$BINARY_PATH"
        return 0
    fi

    if [ "$IS_REQUIRED" = "true" ]; then
        echo "Missing binary: $BINARY_NAME"
        exit 1
    fi

    echo "MISSING BINARY '$BINARY_NAME'"
    return 1
}
#</editor-fold>

#<editor-fold desc="binary functions">
_PUBCST_DOCKER_BINARY_CACHE=""
_PUBCST_HAS_DOCKER=false
function _pubcst_docker() {
    if [ -z "$_PUBCST_DOCKER_BINARY_CACHE" ]; then
        _PUBCST_DOCKER_BINARY_CACHE="$(_pubcst_resolve_binary "docker")"
        _PUBCST_HAS_DOCKER=true
    fi

    "$_PUBCST_DOCKER_BINARY_CACHE" "$@"
}
_PUBCST_SYMFONY_BINARY_CACHE=""
_PUBCST_HAS_SYMFONY=false
function _pubcst_symfony() {
    if [ -z "$_PUBCST_SYMFONY_BINARY_CACHE" ]; then
        _PUBCST_SYMFONY_BINARY_CACHE="$(_pubcst_resolve_binary "symfony")"
        _PUBCST_HAS_SYMFONY=true
    fi

    "$_PUBCST_SYMFONY_BINARY_CACHE" "$@"
}
_PUBCST_PHP_BINARY_CACHE=""
_PUBCST_HAS_PHP=false
function _pubcst_php() {
    if [ "$_PUBCST_HAS_SYMFONY" = "true" ]; then
        _pubcst_symfony php "$@"
    else
        if [ -z "$_PUBCST_PHP_BINARY_CACHE" ]; then
            _PUBCST_PHP_BINARY_CACHE="$(_pubcst_resolve_binary "php")"
            _PUBCST_HAS_PHP=true
        fi

        "$_PUBCST_PHP_BINARY_CACHE" "$@"
    fi
}
_PUBCST_COMPOSER_BINARY_CACHE=""
_PUBCST_HAS_COMPOSER=false
function _pubcst_composer() {
    if [ "$_PUBCST_HAS_SYMFONY" = "true" ]; then
        _pubcst_symfony composer "$@"
    else
        if [ -z "$_PUBCST_COMPOSER_BINARY_CACHE" ]; then
            _PUBCST_COMPOSER_BINARY_CACHE="$(_pubcst_resolve_binary "composer")"
            _PUBCST_HAS_COMPOSER=true
        fi

        "$_PUBCST_COMPOSER_BINARY_CACHE" "$@"
    fi
}
function _pubcst_binary_warmup() {
    # pre-check for symfony binary to make calls for php and composer with symfony
    if _pubcst_resolve_binary "symfony" "false"; then
        _PUBCST_HAS_SYMFONY=true
    fi
}

_pubcst_binary_warmup >/dev/null 2>&1
#</editor-fold>

#<editor-fold desc="load php env">
if [ -f "${PUBCST_PROJECT_DIRECTORY}/.env.local.php" ]; then
    eval "$(php -r "\$entries = include '${PUBCST_PROJECT_DIRECTORY}/.env.local.php'; foreach (\$entries as \$key => \$value) { echo \"\$key=\$value\".PHP_EOL; }")"
fi
#</editor-fold>

#<editor-fold desc="env functions">
function _pubcst_is_prod() {
    [ "${APP_ENV:-dev}" == "prod" ]
}

function _pubcst_is_dev() {
    [ "${APP_ENV:-dev}" == "dev" ]
}
#</editor-fold>

#<editor-fold desc="git functions">
function _pubcst_git_update_template() {
    local REMOTE_BRANCH="${1:-}"
    local REMOTE_URL="${2:-}"
    local TARGET_DIRECTORY="${3:-}"

    if [ -z "${REMOTE_BRANCH}" ] || [ -z "${REMOTE_URL}" ] || [ -z "${TARGET_DIRECTORY}" ]; then
        echo "Missing required parameters: REMOTE_BRANCH, REMOTE_URL, TARGET_DIRECTORY"
        exit 1
    fi

    local ABSOLUTE_TARGET_DIRECTORY
    ABSOLUTE_TARGET_DIRECTORY="${PUBCST_PROJECT_DIRECTORY}/${TARGET_DIRECTORY}"

    if [[ "${ABSOLUTE_TARGET_DIRECTORY}" != "${PUBCST_SCRIPT_DIRECTORY}"* ]]; then
        echo "Invalid target directory. Expected to be within: ${PUBCST_SCRIPT_DIRECTORY}"
        exit 1
    fi

    if [ -d "${TARGET_DIRECTORY}" ]; then
        echo "Removing old target directory at '${TARGET_DIRECTORY}'..."
        rm -rf "${TARGET_DIRECTORY:?}" 2>/dev/null
    fi

    echo "Cloning repository '${REMOTE_URL}' (branch: '${REMOTE_BRANCH}') into '${TARGET_DIRECTORY}'..."
    git clone --depth 1 --branch "${REMOTE_BRANCH}" "${REMOTE_URL}" "${TARGET_DIRECTORY}" 2>/dev/null

    local CLEANUP_SCRIPT_PATH="${ABSOLUTE_TARGET_DIRECTORY}/___cleanup.sh"

    if [ -f "${CLEANUP_SCRIPT_PATH}" ]; then
        bash "${CLEANUP_SCRIPT_PATH}"
    else
        if [ -d "${TARGET_DIRECTORY}/.git" ]; then
            echo "Removing folder '${TARGET_DIRECTORY}/.git'..."
            rm -rf "${TARGET_DIRECTORY:?}/.git" 2>/dev/null
        fi
    fi
}

function _pubcst_git_has_changes() {
    if [ -n "$(git status --porcelain)" ]; then
        return 0
    else
        return 1
    fi
}

function _pubcst_git_has_remote_template() {
    local REMOTE_URLS

    REMOTE_URLS=$(git remote -v | awk '{print $2}' | sort | uniq)

    if echo "${REMOTE_URLS}" | grep -q "^https"; then
        echo "What are you doing with https remotes?" >&2
        echo "I'm not going to help you with that." >&2
        echo "Is that even a thing?" >&2
        exit 1
    fi

    for REMOTE_URL in $REMOTE_URLS; do
        local REMOTE_ORGANIZATION
        local REMOTE_REPOSITORY

        REMOTE_ORGANIZATION="$(echo "${REMOTE_URL}" | awk -F ':' '{print $2}' | awk -F '/' '{print $1}')"

        if [ "${REMOTE_ORGANIZATION}" != "SoureCode" ]; then
            continue
        fi

        REMOTE_REPOSITORY="$(echo "${REMOTE_URL}" | awk -F ':' '{print $2}' | awk -F '/' '{print $2}' | awk -F '.' '{print $1}')"

        if [[ "${REMOTE_REPOSITORY}" == *script-template ]]; then
            return 0
        fi
    done

    return 1
}

function _pubcst_git_commit() {
    local MESSAGE="${1:-}"

    if [ -z "${MESSAGE}" ]; then
        echo "Missing required parameter: MESSAGE"
        exit 1
    fi

    git add -A
    git commit -m "${MESSAGE}"
}
#</editor-fold>

#<editor-fold desc="version functions">
function _pubcst_version_create() {
    local VERSION="${1:-}"

    if [ -z "${VERSION}" ]; then
        echo "Missing required parameter: VERSION"
        exit 1
    fi

    if ! [[ "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid version format. Expected: <digit>.<digit>.<digit>"
        exit 1
    fi

    if _pubcst_git_has_remote_template; then
        echo "# !!! Template repository detected !!!"
        echo ""
        echo "Release of script-template is not allowed; script-templates are versioned by git branch and commit."
        echo ""

        exit 1
    fi

    local TAG_NAME="v${VERSION}"

    _pubcst_call_hook "pubcst_pre_version" "${VERSION}" "${TAG_NAME}"

    if _pubcst_git_has_changes; then
        _pubcst_git_commit "Release $VERSION"
    fi

    git tag "${TAG_NAME}" -m "Release ${TAG_NAME}"

    _pubcst_call_hook "pubcst_post_version" "${VERSION}" "${TAG_NAME}"
}
#</editor-fold>

#<editor-fold desc="composer functions">
_PUBCST_COMPOSER_DEPENDENCIES_CACHE=""

function _pubcst_composer_has_package() {
    local PACKAGE="${1:-}"
    if [ -z "${PACKAGE}" ]; then
        echo "Missing required parameter: PACKAGE"
        exit 1
    fi

    if [ -f "${PUBCST_PROJECT_DIRECTORY}/composer.json" ]; then
        if [ -z "${_PUBCST_COMPOSER_DEPENDENCIES_CACHE}" ]; then
            _PUBCST_COMPOSER_DEPENDENCIES_CACHE=$(composer show --no-dev --format=text | awk '{print $1}')
        fi

        local COMPOSER_DEPENDENCIES="${_PUBCST_COMPOSER_DEPENDENCIES_CACHE}"

        if echo "${COMPOSER_DEPENDENCIES}" | grep -q "^${PACKAGE}$"; then
            return 0
        fi
    fi

    return 1
}

_PUBCST_COMPOSER_DEV_DEPENDENCIES_CACHE=""

function _pubcst_composer_has_dev_package() {
    local PACKAGE="${1:-}"
    if [ -z "${PACKAGE}" ]; then
        echo "Missing required parameter: PACKAGE"
        exit 1
    fi

    if [ -f "${PUBCST_PROJECT_DIRECTORY}/composer.json" ]; then
        if [ -z "${_PUBCST_COMPOSER_DEV_DEPENDENCIES_CACHE}" ]; then
            local PROD_PACKAGES
            local ALL_PACKAGES

            PROD_PACKAGES="$(composer show --no-dev --format=text | awk '{print $1}')"
            ALL_PACKAGES="$(composer show --format=text | awk '{print $1}')"

            _PUBCST_COMPOSER_DEV_DEPENDENCIES_CACHE=$(echo "${ALL_PACKAGES}" | grep -v -F "${PROD_PACKAGES}")
        fi

        local COMPOSER_DEV_DEPENDENCIES="${_PUBCST_COMPOSER_DEV_DEPENDENCIES_CACHE}"

        if echo "${COMPOSER_DEV_DEPENDENCIES}" | grep -q "^${PACKAGE}$"; then
            return 0
        fi
    fi

    return 1
}
#</editor-fold>

#<editor-fold desc="tools functions">
function _pubcst_tools_ensure_directory() {
    if [ ! -d "${PUBCST_TOOLS_DIRECTORY}" ]; then
        mkdir -p "${PUBCST_TOOLS_DIRECTORY}"
    fi
}

function _pubcst_tools_install() {
    local NAME="${1:-}"
    local URL="${2:-}"
    local TOOL_FILE="${PUBCST_TOOLS_DIRECTORY}/${NAME}"

    _pubcst_tools_ensure_directory

    if [ ! -f "${TOOL_FILE}" ]; then
        wget "${URL}" -O "${TOOL_FILE}" 2>/dev/null
        chmod +x "${TOOL_FILE}"
    fi
}
#</editor-fold>
