#!/usr/bin/env bash

set -euo pipefail

PUBCST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if git remote -v | grep -qe "-script-template"; then
    echo "Do not run this script inside a script-template repository."
    echo "It is only meant to be used inside a library or project to cleanup files which shouldn't be used."
    exit 1
fi

rm -rf "${PUBCST_CURRENT_DIRECTORY:?}/.git"
rm -f "${PUBCST_CURRENT_DIRECTORY:?}/.gitignore"

if [ -d "${PUBCST_CURRENT_DIRECTORY:?}" ]; then
    find "${PUBCST_CURRENT_DIRECTORY:?}" -maxdepth 1 -type f -name "__*" -exec rm -f {} \;
fi
