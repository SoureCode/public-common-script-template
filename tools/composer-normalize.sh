#!/usr/bin/env bash

set -euo pipefail

PUBCST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "${PUBCST_CURRENT_DIRECTORY}/../_variables.sh"
source "${PUBCST_CURRENT_DIRECTORY}/_functions.sh"

function _main() {
    pushd "${PUBCST_PROJECT_DIRECTORY}" >/dev/null 2>&1

    _pubcst_tools_install "composer-normalize" "https://github.com/ergebnis/composer-normalize/releases/latest/download/composer-normalize.phar"
    _pubcst_php "${PUBCST_TOOLS_DIRECTORY}/composer-normalize" "$@"

    popd >/dev/null 2>&1
}

_main "$@"
