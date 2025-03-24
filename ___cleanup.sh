#!/usr/bin/env bash

set -euo pipefail

PUBCST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PUBCST_GIT_ROOT_DIRECTORY="$(git rev-parse --show-toplevel)"

if git remote -v | grep -qe "-script-template" && [ "${PUBCST_CURRENT_DIRECTORY:?}" == "${PUBCST_GIT_ROOT_DIRECTORY:?}" ]; then
    echo "Do not run this script inside a script-template repository."
    echo "It is only meant to be used inside a library or project to cleanup files which shouldn't be used."
    exit 1
fi

GIT_DIRECTORY="${PUBCST_CURRENT_DIRECTORY:?}/.git)"
GIT_IGNORE_FILE="${PUBCST_CURRENT_DIRECTORY:?}/.gitignore"

if [ -d "${GIT_DIRECTORY:?}"  ]; then
    rm -rf "${GIT_DIRECTORY:?}"
fi

if [ -f "${GIT_IGNORE_FILE:?}" ]; then
    rm -f "${GIT_IGNORE_FILE:?}"
fi

if [ -d "${PUBCST_CURRENT_DIRECTORY:?}" ]; then
    find "${PUBCST_CURRENT_DIRECTORY:?}" -maxdepth 1 -type f -name "__*" -exec rm -f {} \;
fi
