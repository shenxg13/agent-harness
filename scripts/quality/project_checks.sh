#!/usr/bin/env bash
# Project-owned entry for business checks. An adopting project replaces the
# body with its own commands and keeps this file when it takes a harness
# update. CI runs it after scripts/quality/check.sh, which never calls it.
set -euo pipefail

printf '%s\n' 'no project checks declared'
