#!/usr/bin/env bash
# 用法：scripts/debate/run-b.sh <辩论目录> <review|followup|check|draft|smoke> <codex|claude>
# 启动参与方 B（decision-review 工作流）：读 <目录>/prompt-<步骤>-<B>.md，最终回答写到 <目录>/<步骤>-<B>.md，
# 事件流和 stderr 写到同名的 .events.jsonl、.stderr；在 <目录>/log.md 追加启动、结束、记录三行；
# 最后把退出码写进 <目录>/<步骤>-<B>.rc。执行会话看到 .rc 才算结束，不重复启动。
# B 一律可以联网搜索、读网页；<目录>/fetch-budget.json 存在时，还可以用 fetch.sh 在预算内取数。B 不得改仓库，实际工具边界见下方 Claude 注释及工作流。
# 正式模型与档位读取项目所有的 config.env；CODEX_MODEL、CODEX_EFFORT、CLAUDE_MODEL、CLAUDE_EFFORT 只用于冒烟测试。
set -uo pipefail
d=${1:?辩论目录}
r=${2:?步骤：review、followup、check、draft 或 smoke}
b=${3:?B：codex 或 claude}
# shellcheck source=common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
# 清空配置变量，避免文件漏项时从进程环境继承正式配置。
DEBATE_CLAUDE_MODEL='' DEBATE_CLAUDE_EFFORT='' DEBATE_CODEX_MODEL='' DEBATE_CODEX_EFFORT=''
DEBATE_CREDENTIAL_PATHS=()
config=$script_root/scripts/debate/config.env
[[ -f $config ]] || {
    echo "缺少项目配置 config.env" >&2
    exit 2
}
# shellcheck source=config.env
source "$config" || exit 2
for value in "$DEBATE_CLAUDE_MODEL" "$DEBATE_CLAUDE_EFFORT" "$DEBATE_CODEX_MODEL" "$DEBATE_CODEX_EFFORT"; do
    [[ -n ${value//[[:space:]]/} ]] || {
        echo "配置中的模型和档位不能为空" >&2
        exit 2
    }
done
((${#DEBATE_CREDENTIAL_PATHS[@]})) || {
    echo "配置须声明凭据相对路径" >&2
    exit 2
}
denied=()
for credential_path in "${DEBATE_CREDENTIAL_PATHS[@]}"; do
    [[ -n ${credential_path//[[:space:]]/} && $credential_path != /* && $credential_path != *..* ]] || {
        echo "凭据路径须为非空仓库相对路径，不能含 .." >&2
        exit 2
    }
    denied+=("Read(/$main_root/$credential_path)")
done
repo=$main_root
d=$(realpath -e -- "$d") || exit 2
case $d/ in
    "$main_root/var/debates/"?*/) ;;
    *)
        echo "辩论目录须是主检出 var/debates/ 下已有的场次目录" >&2
        exit 2
        ;;
esac
case $r in
    review) label="B 审查" ;;
    followup) label="B 追加交锋" ;;
    check) label="B 记录核对" ;;
    draft) label="B 独立稿" ;;
    smoke) label="B 冒烟测试" ;;
    *)
        echo "步骤须为 review、followup、check、draft 或 smoke" >&2
        exit 2
        ;;
esac
prompt=$d/prompt-$r-$b.md
out=$d/$r-$b.md
ev=$d/$r-$b.events.jsonl
err=$d/$r-$b.stderr
rcf=$d/$r-$b.rc
[[ -f $prompt ]] || {
    echo "缺少 $prompt" >&2
    exit 2
}
if grep -q '{{' "$prompt"; then
    echo "$prompt 仍有未填的占位符" >&2
    exit 2
fi
# 持有锁直至 CLI 退出，防止两个启动者同时通过文件检查。
exec 9>"$d/.$r-$b.launch.lock"
flock -n 9 || {
    echo "本步正在运行，不重复启动" >&2
    exit 2
}
for f in "$out" "$ev" "$rcf" "$err"; do
    if [[ -e $f ]]; then
        echo "$f 已存在：这一步可能已运行或仍在运行。不重复启动，先问用户" >&2
        exit 2
    fi
done
[[ $(git -C "$repo" symbolic-ref --quiet --short HEAD) == main ]] || {
    echo "主检出须在 main 分支；当前分支不符或为 detached HEAD" >&2
    exit 2
}
[[ -z $(git -C "$repo" status --porcelain --untracked-files=all) ]] || {
    echo "主检出工作区不干净（忽略文件除外），拒绝启动" >&2
    exit 2
}
main_head=$(git -C "$repo" rev-parse HEAD) || exit 2
fetch=no
[[ -f $d/fetch-budget.json ]] && fetch=yes

case $b in
    codex)
        bin=$(find_cli openai.chatgpt bin/linux-x86_64/codex)
        model=$DEBATE_CODEX_MODEL
        effort=$DEBATE_CODEX_EFFORT
        if [[ $r == smoke ]]; then
            model=${CODEX_MODEL:-$model}
            effort=${CODEX_EFFORT:-$effort}
        fi
        ;;
    claude)
        bin=$(find_cli anthropic.claude-code resources/native-binary/claude)
        model=$DEBATE_CLAUDE_MODEL
        effort=$DEBATE_CLAUDE_EFFORT
        if [[ $r == smoke ]]; then
            model=${CLAUDE_MODEL:-$model}
            effort=${CLAUDE_EFFORT:-$effort}
        fi
        ;;
    *)
        echo "B 须为 codex 或 claude" >&2
        exit 2
        ;;
esac
[[ -x $bin ]] || {
    echo "找不到 $b 的可执行文件：$bin" >&2
    exit 2
}

log() { echo "| $(date -u +%FT%TZ) | $label $1 | $2 |" >>"$d/log.md"; }
log 启动 "$("$bin" --version 2>/dev/null | head -1)，$model，$effort；主检出 HEAD $main_head；联网搜索开，取数 $fetch；prompt SHA-256 \`$(sha256sum "$prompt" | cut -c1-64)\`"
start=$(date +%s)
case $b in
    codex)
        # 联网搜索走 Codex 原生 web_search（模型侧执行，不需要沙箱联网）。
        # 取数要在沙箱里联网：改用 workspace-write 并打开网络，工作根目录设为本场 evidence/，
        # 可写范围因此只有 evidence/（及系统临时目录），仓库其余部分仍只读。
        if [[ $fetch == yes ]]; then
            mkdir -p "$d/evidence"
            sandbox=(-s workspace-write -c sandbox_workspace_write.network_access=true -C "$d/evidence")
        else
            sandbox=(-s read-only -C "$repo")
        fi
        "$bin" exec -m "$model" -c "model_reasoning_effort=\"$effort\"" -c 'web_search="live"' "${sandbox[@]}" \
            --json -o "$out" - <"$prompt" >"$ev" 2>"$err"
        rc=$?
        ;;
    claude)
        # Bash 显式放行参数受限的 git-read.sh 和有预算时的 fetch.sh，不放行裸 git 前缀。
        # dontAsk 仍自动运行内置只读命令；Read 拒绝规则覆盖文件工具、可识别文件命令及重定向，
        # 不覆盖间接读取的子进程：这些命令对凭据及仓库外文件的读取仍只靠指令约束。
        # 不加载自动记忆或 MCP。官方依据见工作流“运行审查方”，不能把允许列表当作全部 Bash 边界。
        # Claude 的绝对路径规则以 // 开头；repo 已以 / 开头，因此再加一个 /。
        allowed=(Read Grep Glob WebSearch WebFetch)
        allowed+=("Bash(scripts/debate/git-read.sh:*)" "Bash($script_root/scripts/debate/git-read.sh:*)")
        if [[ $fetch == yes ]]; then
            allowed+=("Bash(scripts/debate/fetch.sh:*)" "Bash($script_root/scripts/debate/fetch.sh:*)")
        fi
        (cd "$repo" && CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 "$bin" -p --model "$model" --effort "$effort" \
            --restricted --tools "Read,Grep,Glob,Bash,WebSearch,WebFetch" \
            --allowedTools "${allowed[@]}" \
            --disallowedTools "${denied[@]}" --strict-mcp-config \
            --permission-mode dontAsk --permission-prompts none \
            --output-format stream-json --verbose <"$prompt" >"$ev" 2>"$err")
        rc=$?
        if [[ $(jq -r 'select(.type=="result") | .subtype=="success" and .is_error==false' "$ev" 2>/dev/null) == true ]]; then
            jq -j 'select(.type=="result") | .result' "$ev" >"$out"
        elif [[ $rc -eq 0 ]]; then
            rc=1
        fi
        ;;
esac
if [[ ! -s $out && $rc -eq 0 ]]; then rc=1; fi
log 结束 "退出码 $rc，耗时 $(($(date +%s) - start)) 秒"

if [[ -s $out ]]; then
    case $b in
        codex)
            id=$(jq -r 'select(.type=="thread.started") | .thread_id' "$ev")
            usage=$(jq -c 'select(.type=="turn.completed") | .usage' "$ev" | tail -1)
            calls=$(jq -s '[.[] | select(.type=="item.completed" and (.item.type=="command_execution" or .item.type=="web_search"))] | length' "$ev")
            ;;
        claude)
            id=$(jq -r 'select(.type=="result") | .session_id' "$ev")
            usage=$(jq -c 'select(.type=="result") | {input_tokens: .usage.input_tokens, cache_read_input_tokens: .usage.cache_read_input_tokens, cache_creation_input_tokens: .usage.cache_creation_input_tokens, output_tokens: .usage.output_tokens, num_turns, total_cost_usd}' "$ev")
            calls=$(jq -s '[.[] | select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")] | length' "$ev")
            ;;
    esac
    log 记录 "会话 ID \`$id\`；$(basename "$out") SHA-256 \`$(sha256sum "$out" | cut -c1-64)\`；用量 $usage；工具调用 $calls 次"
else
    log 记录 "没有输出：$(basename "$out") 为空或不存在，见 $(basename "$err") 和事件流"
    [[ $rc -ne 0 ]] || rc=1
fi
echo "$rc" >"$rcf"
exit "$rc"
