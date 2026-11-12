#!/usr/bin/env bash
# 只定位检出和 CLI；不读取凭据或机器本地配置。
script_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
common_dir=$(git -C "$script_root" rev-parse --path-format=absolute --git-common-dir) || exit 2
# Used by scripts that source this file.
# shellcheck disable=SC2034
main_root=$(dirname -- "$common_dir")

cli_version() {
    local output
    output=$("$1" --version 2>/dev/null) || return 1
    # Claude: 2.1.321 (Claude Code); Codex: codex-cli 0.167.0-alpha.4.1.
    [[ $output =~ (^|[[:space:]])([0-9]+\.[0-9]+(\.[0-9]+)*([-+][[:alnum:].-]+)?)($|[[:space:]]) ]] || return 1
    printf '%s\n' "${BASH_REMATCH[2]}"
}

select_cli() {
    local candidate=$1 source=$2 version=${3:-}
    [[ -f $candidate && -x $candidate ]] || return 1
    [[ -n $version ]] || version=$(cli_version "$candidate") || return 1
    # Keep selection metadata in the caller; do not invoke through $(find_cli ...).
    bin=$(realpath -s -e -- "$candidate") || return 1
    # Used by run-b.sh for the startup log.
    # shellcheck disable=SC2034
    cli_source=$source cli_selected_version=$version
}

newest_app_cli() {
    local source=$1 candidate version selected
    shift
    local -a candidates=()
    for candidate in "$@"; do
        [[ -f $candidate && -x $candidate ]] || continue
        version=$(cli_version "$candidate") || continue
        candidates+=("$version"$'\t'"$candidate")
    done
    ((${#candidates[@]})) || return 1
    selected=$(printf '%s\n' "${candidates[@]}" | LC_ALL=C sort -t $'\t' -k1,1Vr -k2,2 | sed -n '1p')
    select_cli "${selected#*$'\t'}" "$source" "${selected%%$'\t'*}"
}

windows_user_home() {
    # Linux hosts must not execute Windows interop commands just because they are on PATH.
    [[ -n ${WSL_INTEROP:-} || -n ${WSL_DISTRO_NAME:-} || $(uname -r) == *[Mm]icrosoft* ]] || return 1
    command -v cmd.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1 || return 1
    local profile
    profile=$(cmd.exe /d /c 'echo %USERPROFILE%' 2>/dev/null) || return 1
    profile=${profile//$'\r'/}
    [[ -n $profile && $profile != '%USERPROFILE%' && $profile != *$'\n'* ]] || return 1
    wslpath -u "$profile" 2>/dev/null
}

find_cli() {
    local vendor=$1 suffix=$2 extension version candidate windows_home
    local override='' command_name=${suffix##*/} app_source
    case $command_name in
        claude) override=${CLAUDE_BIN:-} app_source=claude-desktop ;;
        codex) override=${CODEX_BIN:-} app_source=codex-app ;;
    esac
    if [[ -n $override ]]; then
        select_cli "$override" explicit && return
        echo "找不到 $command_name 的可用 CLI；已检查来源：explicit（显式覆盖，不探测其他来源）" >&2
        return 2
    fi
    case $command_name in
        claude)
            # Every Claude CLI may export EXECPATH; only desktop entrypoints identify the app.
            if [[ (${CLAUDE_CODE_ENTRYPOINT:-} == claude-desktop || ${CLAUDE_CODE_ENTRYPOINT:-} == claude-desktop-3p) &&
                -f ${CLAUDE_CODE_EXECPATH:-} && -x ${CLAUDE_CODE_EXECPATH:-} ]]; then
                select_cli "$CLAUDE_CODE_EXECPATH" "$app_source" && return
                echo "Claude 当前 app CLI 无法读取版本；已检查来源：$app_source（CLAUDE_CODE_EXECPATH）" >&2
                return 2
            fi
            newest_app_cli "$app_source" "$HOME"/.claude/remote/ccd-cli/* && return
            ;;
        codex)
            if windows_home=$(windows_user_home); then
                newest_app_cli "$app_source" "$windows_home"/.codex/bin/wsl/*/codex && return
            fi
            ;;
    esac
    local -a candidates=()
    for extension in "$HOME"/.vscode-server/extensions/"$vendor"-*-linux-x64 \
        "$HOME"/.vscode/extensions/"$vendor"-*-linux-x64; do
        if [[ -f $extension/$suffix && -x $extension/$suffix ]]; then
            version=${extension##*/}
            version=${version#"$vendor"-}
            version=${version%-linux-x64}
            candidates+=("$version"$'\t'"$extension/$suffix")
        fi
    done
    if ((${#candidates[@]})); then
        # 保留扩展版本优先；同版本以路径字典序稳定选择。
        while IFS=$'\t' read -r version candidate; do
            select_cli "$candidate" vscode-extension && return
        done < <(printf '%s\n' "${candidates[@]}" | LC_ALL=C sort -t $'\t' -k1,1Vr -k2,2)
    fi
    candidate=$(command -v "$command_name") && select_cli "$candidate" path && return
    echo "找不到 $command_name 的可用 CLI；已检查来源：$app_source、vscode-extension、path" >&2
    return 2
}

isolate_b_environment() {
    local name
    # Names only: never enumerate or log inherited values. Run after discovery/smoke parsing.
    while IFS= read -r name; do
        case $name in
            CLAUDECODE* | CLAUDE_* | CODEX_* | ANTHROPIC_BASE_URL | USE_LOCAL_OAUTH | USE_STAGING_OAUTH | \
                API_TIMEOUT_MS | DISABLE_AUTOUPDATER | DISABLE_MICROCOMPACT | MCP_CONNECTION_NONBLOCKING | \
                MCP_SERVER_CONNECTION_BATCH_SIZE | AI_AGENT | LOG_FORMAT | RUST_LOG | \
                NODE_TLS_REJECT_UNAUTHORIZED | NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S)
                unset "$name"
                ;;
        esac
    done < <(compgen -e)
}

check_cli_capabilities() {
    local who=$1 help flag
    local -a flags
    case $who in
        claude)
            flags=(--restricted --permission-prompts --strict-mcp-config --disallowedTools)
            help=$("$bin" --help 2>/dev/null) || return 2
            ;;
        codex)
            flags=(--json -o -s -C)
            help=$("$bin" exec --help 2>/dev/null) || return 2
            ;;
    esac
    for flag in "${flags[@]}"; do
        if ! grep -Eq -- "(^|[[:space:],])${flag}([[:space:],=]|$)" <<<"$help"; then
            echo "$who CLI 缺少必需参数：$flag" >&2
            return 2
        fi
    done
}
