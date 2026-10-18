#!/usr/bin/env bash
# 参数白名单入口；读取主检出的 Git 历史，不接受任意 git 选项。
# 用法：git-read.sh log [-n 数量] [-S 文字] [-- 仓库相对路径...]
#       git-read.sh show <完整提交SHA>:<仓库相对路径>
#       git-read.sh blame [--] <主检出 HEAD 中的文件>
set -euo pipefail
# shellcheck source=common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

reject() {
    echo "git-read: 仅允许 log [-n 数量] [-S 文字] [-- 路径...]、show 完整SHA:路径、blame [--] 路径" >&2
    exit 2
}
relative_path() {
    [[ -n $1 && $1 != /* && $1 != -* ]] || reject
    case /$1/ in */../* | */./* | */.git/*) reject ;; esac
}

# 不启动 pager、外部 diff、textconv 或 fsmonitor；路径按字面匹配。
# 这里只约束本入口的参数，不替代 Claude 对其他 Bash 命令的权限判断。
export GIT_OPTIONAL_LOCKS=0 GIT_NO_LAZY_FETCH=1
git_cmd=(git --no-pager --literal-pathspecs -C "$main_root" -c core.fsmonitor=false)
sub=${1:-}
[[ $# -gt 0 ]] || reject
shift
case $sub in
    log)
        options=(-n 20)
        paths=()
        while (($#)); do
            case $1 in
                -n)
                    [[ $# -ge 2 && $2 =~ ^[1-9][0-9]*$ ]] || reject
                    options+=(-n "$2")
                    shift 2
                    ;;
                -S)
                    [[ $# -ge 2 ]] || reject
                    options+=("-S$2")
                    shift 2
                    ;;
                --)
                    shift
                    [[ $# -gt 0 ]] || reject
                    for path in "$@"; do
                        relative_path "$path"
                        paths+=("$path")
                    done
                    break
                    ;;
                *) reject ;;
            esac
        done
        exec "${git_cmd[@]}" log --no-ext-diff --no-textconv "${options[@]}" HEAD -- "${paths[@]}"
        ;;
    show)
        [[ $# -eq 1 && $1 =~ ^[0-9a-f]{40}:.+$ ]] || reject
        relative_path "${1#*:}"
        exec "${git_cmd[@]}" show --no-ext-diff --no-textconv "$1"
        ;;
    blame)
        if [[ ${1:-} == -- ]]; then shift; fi
        [[ $# -eq 1 ]] || reject
        relative_path "$1"
        # 固定 HEAD，避免读取工作区内容、未跟踪文件或其符号链接目标。
        exec "${git_cmd[@]}" blame --no-textconv HEAD -- "$1"
        ;;
    *) reject ;;
esac
