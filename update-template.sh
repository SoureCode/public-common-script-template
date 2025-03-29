#!/usr/bin/env bash

set -euo pipefail

PUBCST_CURRENT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "${PUBCST_CURRENT_DIRECTORY}/_variables.sh"
source "${PUBCST_CURRENT_DIRECTORY}/_functions.sh"

#<editor-fold desc="main">
pushd "${PUBCST_PROJECT_DIRECTORY}" >/dev/null 2>&1

_pubcst_git_update_template "master" "git@github.com:SoureCode/public-common-script-template.git" "scripts/public-common"

popd >/dev/null 2>&1
#</editor-fold>
