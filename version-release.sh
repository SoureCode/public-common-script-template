#!/usr/bin/env bash

set -euo pipefail

PUBCST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "${PUBCST_CURRENT_DIRECTORY}/_variables.sh"
source "${PUBCST_CURRENT_DIRECTORY}/_functions.sh"

#<editor-fold desc="options">
OPTIONS=$(getopt --options= --longoptions=help -- "$@")

if [ $? != 0 ]; then
    echo "Failed to parse options." >&2
    exit 1
fi

eval set -- "${OPTIONS}"

while [ $# -gt 0 ]; do
    case "${1}" in
    --help)
        echo "Usage: $0 [--help] version" 1>&2
        exit 0
        ;;
    --)
        shift
        break
        ;;
    -*)
        echo "$0: error - unrecognized option $1" 1>&2
        exit 1
        ;;
    *) break ;;
    esac
done
#</editor-fold>

#<editor-fold desc="arguments">
ARGUMENT_VERSION="${1:-}"
#</editor-fold>

#<editor-fold desc="main">
pushd "${PUBCST_PROJECT_DIRECTORY}" >/dev/null 2>&1

_pubcst_version_create "${ARGUMENT_VERSION}"

popd >/dev/null 2>&1
#</editor-fold>
