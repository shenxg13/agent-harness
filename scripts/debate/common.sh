#!/usr/bin/env bash
# 只定位检出和 CLI；不读取凭据或机器本地配置。
script_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
common_dir=$(git -C "$script_root" rev-parse --path-format=absolute --git-common-dir) || exit 2
# Used by scripts that source this file.
# shellcheck disable=SC2034
main_root=$(dirname -- "$common_dir")

find_cli() {
    local vendor=$1 suffix=$2 extension version
    local override='' command_name=${suffix##*/}
    case $command_name in
        claude) override=${CLAUDE_BIN:-} ;;
        codex) override=${CODEX_BIN:-} ;;
    esac
    if [[ -n $override ]]; then
        printf '%s\n' "$override"
        return
    fi
    local -a candidates=()
    for extension in "$HOME"/.vscode-server/extensions/"$vendor"-*-linux-x64 \
        "$HOME"/.vscode/extensions/"$vendor"-*-linux-x64; do
        if [[ -x $extension/$suffix ]]; then
            version=${extension##*/}
            version=${version#"$vendor"-}
            version=${version%-linux-x64}
            candidates+=("$version"$'\t'"$extension/$suffix")
        fi
    done
    if ((${#candidates[@]})); then
        # 只比较扩展版本；主目录前缀不能覆盖版本顺序。
        printf '%s\n' "${candidates[@]}" | sort -t $'\t' -k1,1V | tail -1 | cut -f2-
    else
        command -v "$command_name" || true
    fi
}
