#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "${BASH_SOURCE[0]%/*}" && pwd)
repo_root=$(cd -- "$script_dir/../.." && pwd)
# shellcheck source=tool-versions.env
source "$script_dir/tool-versions.env"

usage() {
    cat <<'EOF'
Usage: scripts/quality/install_local_tools.sh [DIR]

Download the pinned ShellCheck, shfmt and Node.js artifacts, verify their
recorded SHA-256 digests, and install them together with the pinned npm and
markdownlint-cli2 into DIR. DIR defaults to var/harness-tools in this
repository and must not exist yet; nothing outside its parent directory is
written. Linux x86_64 only; needs network access to the official downloads.
EOF
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

[[ $# -le 1 ]] || die 'at most one target directory is accepted'
case ${1:-} in
    -h | --help)
        usage
        exit 0
        ;;
    -*)
        die "unknown option: $1"
        ;;
esac
target=${1:-$repo_root/var/harness-tools}
[[ ! -e $target && ! -L $target ]] || die "target already exists, remove it first: $target"
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] ||
    die 'recorded artifact hashes cover Linux x86_64 only'
for tool in curl tar xz sha256sum install; do
    command -v "$tool" >/dev/null 2>&1 || die "missing required tool: $tool"
done

fetch() {
    local url=$1
    local sha256=$2
    local output=$3
    curl -fsSL --retry 3 -o "$output" "$url"
    printf '%s  %s\n' "$sha256" "$output" | sha256sum --check --strict
}

parent=$(dirname -- "$target")
mkdir -p "$parent"
# The staged tools are used through PATH, which needs an absolute location.
parent=$(cd -- "$parent" && pwd)
target=$parent/$(basename -- "$target")
stage=$(mktemp -d "$parent/.harness-tools.XXXXXX")
trap 'rm -rf -- "$stage"' EXIT
mkdir -p "$stage/downloads" "$stage/tools"

fetch "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    "$NODE_LINUX_X64_SHA256" "$stage/downloads/node.tar.xz"
tar -xJf "$stage/downloads/node.tar.xz" -C "$stage/tools" --strip-components=1

fetch "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" \
    "$SHELLCHECK_LINUX_X64_SHA256" "$stage/downloads/shellcheck.tar.xz"
tar -xJf "$stage/downloads/shellcheck.tar.xz" -C "$stage/downloads"
install -m 0755 "$stage/downloads/shellcheck-v${SHELLCHECK_VERSION}/shellcheck" \
    "$stage/tools/bin/shellcheck"

fetch "https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_amd64" \
    "$SHFMT_LINUX_X64_SHA256" "$stage/downloads/shfmt"
install -m 0755 "$stage/downloads/shfmt" "$stage/tools/bin/shfmt"

# Keep npm's cache inside the staging directory so the user's own cache and
# global prefix stay untouched.
PATH="$stage/tools/bin:$PATH" npm_config_cache="$stage/npm-cache" \
    npm_config_update_notifier=false \
    npm install --global --prefix "$stage/tools" \
    "npm@$NPM_VERSION" "markdownlint-cli2@$MARKDOWNLINT_CLI2_VERSION"

PATH="$stage/tools/bin:$PATH" "$script_dir/check.sh" --check-tools-only
mv -- "$stage/tools" "$target"
printf 'installed pinned quality tools into %s\n' "$target"
printf "run checks with: PATH=\"%s/bin:\$PATH\" scripts/quality/check.sh\n" "$target"
