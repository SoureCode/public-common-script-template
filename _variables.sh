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
PUBCST_PROJECT_DIRECTORY="$(dirname "$(dirname "${PUBCST_CURRENT_DIRECTORY}")")"
PUBCST_SCRIPT_DIRECTORY="${PUBCST_PROJECT_DIRECTORY}/scripts"

PUBCST_CURRENT_ID="$(id)"
PUBCST_CURRENT_WORKING_DIRECTORY="$(pwd)"
PUBCST_CURRENT_HOME="${HOME:-}"
PUBCST_CURRENT_SHELL="${SHELL:-}"
