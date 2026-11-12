#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd -- "${BASH_SOURCE[0]%/*}" && pwd)
filter="$script_dir/review_convergence.jq"

usage() {
    cat <<'EOF'
Usage: scripts/github/review_convergence.sh RECORD.json

Validate a local Review Convergence Protocol evidence record. The command is
read-only and does not contact or modify GitHub.
EOF
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    usage
    exit 0
fi

[[ $# == 1 ]] || die 'exactly one JSON record is required'
record=$1
[[ -f $record ]] || die "record does not exist: $record"
[[ -r $record ]] || die "record is not readable: $record"

# Slurping emits one array even for empty input, so -e always sees a boolean.
single_object='length == 1 and (.[0] | type == "object")'
if ! jq -s -e "$single_object" "$record" >/dev/null; then
    die "review convergence record is invalid: $record (expected exactly one JSON object)"
fi

# Check the output explicitly; jq versions disagree on -e with no output.
if ! jq -f "$filter" "$record" | jq -s -e "$single_object" >/dev/null; then
    die "review convergence record is invalid: $record (rules must produce exactly one JSON object)"
fi

printf 'OK: %s satisfies the Review Convergence Protocol\n' "$record"
