#!/usr/bin/env bash
# Offline contract regression: isolated repositories, fake model CLIs and fake gh.
set -euo pipefail
repo_root=$(cd -- "${BASH_SOURCE[0]%/*}/../.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/agent-harness-debate.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
passed=0 failed=0

fixture() {
    case_root=$(mktemp -d "$test_root/case.XXXXXX")
    main=$case_root/main
    mkdir -p "$main/scripts" "$case_root/bin" "$case_root/mock-home"
    cp -R "$repo_root/scripts/debate" "$main/scripts/"
    printf 'var/\n.env\n' >"$main/.gitignore"
    printf 'fixture\n' >"$main/README.md"
    git -C "$main" init -q -b main
    git -C "$main" add .
    commit "$main" fixture
    d=$main/var/debates/session
    mkdir -p "$d"
    for who in claude codex; do
        for step in review smoke; do
            printf '请审查。\n' >"$d/prompt-$step-$who.md"
        done
    done
    cat >"$case_root/bin/fake-cli" <<'CLI'
#!/usr/bin/env bash
set -euo pipefail
printf 'called\n' >>"$TRACE.calls"
if [[ ${1:-} == --version ]]; then
    printf 'fake-cli 1.0\n'
    exit 0
fi
jq -n --arg cwd "$PWD" --arg bin "$0" --arg memory "${CLAUDE_CODE_DISABLE_AUTO_MEMORY:-}" \
    --args '{cwd:$cwd,bin:$bin,memory:$memory,args:$ARGS.positional}' -- "$@" >"$TRACE"
cat >"$TRACE.prompt"
if [[ -n ${WAIT_FIFO:-} ]]; then read -r _ <"$WAIT_FIFO"; fi
if [[ $1 == exec ]]; then
    printf '%s\n' '{"type":"thread.started","thread_id":"codex-offline-session"}'
    while (($#)); do
        if [[ $1 == -o ]]; then out=$2; break; fi
        shift
    done
    if [[ ${MODE:-} != empty ]]; then printf '审查输出\n' >"$out"; fi
    printf '%s\n' '{"type":"turn.completed","usage":{"input_tokens":7}}'
else
    jq -nc --arg mode "${MODE:-}" '{type:"result",subtype:"success",is_error:($mode=="error"),
      session_id:"claude-offline-session",result:(if $mode=="empty" then "" else "审查输出" end),
      usage:{input_tokens:7},num_turns:1,total_cost_usd:0}'
fi
if [[ ${MODE:-} == nonzero ]]; then exit 9; fi
CLI
    chmod +x "$case_root/bin/fake-cli"
    trace=$case_root/trace.json
    # Only fixture HOME and explicitly injected fake CLIs enter the child.
    run_env=(env -i PATH=/usr/bin:/bin HOME="$case_root/mock-home" TRACE="$trace"
        CODEX_BIN="$case_root/bin/fake-cli" CLAUDE_BIN="$case_root/bin/fake-cli")
    runner=$main/scripts/debate/run-b.sh
}
commit() { git -C "$1" -c user.name=Offline -c user.email=offline@example.invalid commit -qm "$2"; }
run_b() { "${run_env[@]}" "$runner" "$d" "${2:-review}" "${1:-codex}"; }
expect_rc() {
    local expected=$1 actual=0
    shift
    "$@" >"$case_root/stdout" 2>"$case_root/stderr" || actual=$?
    if [[ $actual != "$expected" ]]; then
        printf 'expected rc %s, got %s\n' "$expected" "$actual" >&2
        cat "$case_root/stdout" "$case_root/stderr" >&2
        return 1
    fi
}
no_launch() { [[ ! -e $trace.calls && ! -e $d/log.md ]]; }
args_match() { jq -e "$1" "$trace" >/dev/null; }
configure() {
    cat >"$main/scripts/debate/config.env" <<'CONFIG'
DEBATE_CLAUDE_MODEL=project-claude
DEBATE_CLAUDE_EFFORT=high
DEBATE_CODEX_MODEL=project-codex
DEBATE_CODEX_EFFORT=medium
DEBATE_CREDENTIAL_PATHS=(.env 'var/private/second key')
CONFIG
    git -C "$main" add scripts/debate/config.env
    commit "$main" config
}
placeholder() {
    printf '{{未填}}\n' >"$d/prompt-review-codex.md"
    expect_rc 2 run_b
    no_launch
}
existing() {
    printf 'previous' >"$d/review-codex.$1"
    expect_rc 2 run_b
    [[ $(cat "$d/review-codex.$1") == previous ]]
    no_launch
}
main_gate() {
    case $1 in
        branch) git -C "$main" switch -qc other ;;
        detached) git -C "$main" checkout -q --detach ;;
        dirty) printf change >"$main/README.md" ;;
        untracked) touch "$main/new.txt" ;;
    esac
    expect_rc 2 run_b
    grep -q '主检出' "$case_root/stderr"
    no_launch
}
directory_gate() {
    d=$case_root/outside
    mkdir "$d"
    printf test >"$d/prompt-review-codex.md"
    expect_rc 2 run_b
    no_launch
}
invalid_config() {
    configure
    case $1 in
        missing) rm "$main/scripts/debate/config.env" ;;
        model) sed -i 's/DEBATE_CLAUDE_MODEL=.*/DEBATE_CLAUDE_MODEL=/' "$main/scripts/debate/config.env" ;;
        effort) sed -i 's/DEBATE_CODEX_EFFORT=.*/DEBATE_CODEX_EFFORT=/' "$main/scripts/debate/config.env" ;;
        omitted) sed -i '/DEBATE_CODEX_MODEL=/d' "$main/scripts/debate/config.env" ;;
        absolute) printf '\nDEBATE_CREDENTIAL_PATHS=(/tmp/bait)\n' >>"$main/scripts/debate/config.env" ;;
        traversal) printf '\nDEBATE_CREDENTIAL_PATHS=(var/../bait)\n' >>"$main/scripts/debate/config.env" ;;
        empty) printf '\nDEBATE_CREDENTIAL_PATHS=()\n' >>"$main/scripts/debate/config.env" ;;
    esac
    git -C "$main" add -A
    commit "$main" invalid-config
    expect_rc 2 run_b
    no_launch
}
models() {
    local who=$1 step=$2
    configure
    run_env+=(CLAUDE_MODEL=smoke-claude CLAUDE_EFFORT=low CODEX_MODEL=smoke-codex CODEX_EFFORT=low)
    expect_rc 0 run_b "$who" "$step"
    if [[ $step == smoke ]]; then
        args_match '.args | any(. == "smoke-'"$who"'")'
        if [[ $who == claude ]]; then
            # shellcheck disable=SC2016 # jq variables, not Shell expansion.
            args_match '.args | index("--effort") as $i | $i != null and .[$i+1] == "low"'
        else
            args_match '.args | any(. == "model_reasoning_effort=\"low\"")'
        fi
    else
        args_match '.args | any(. == "project-'"$who"'")'
        args_match '.args | all(contains("smoke-") | not)'
        if [[ $who == claude ]]; then
            # shellcheck disable=SC2016 # jq variables, not Shell expansion.
            args_match '.args | index("--effort") as $i | .[$i+1] == "high"'
        else
            args_match '.args | any(. == "model_reasoning_effort=\"medium\"")'
        fi
    fi
}
codex_success() {
    local budget=$1
    if [[ $budget == yes ]]; then printf '{}' >"$d/fetch-budget.json"; fi
    expect_rc 0 run_b
    local sandbox=read-only cwd=$main
    if [[ $budget == yes ]]; then
        sandbox=workspace-write
        cwd=$d/evidence
    fi
    jq -e --arg sandbox "$sandbox" --arg cwd "$cwd" --argjson budget "$([[ $budget == yes ]] && echo true || echo false)" '
      .args | (index("-s") as $i | .[$i+1]==$sandbox) and
      (index("-C") as $i | .[$i+1]==$cwd) and
      (any(.=="sandbox_workspace_write.network_access=true")==$budget) and
      any(.=="web_search=\"live\"")' "$trace" >/dev/null
    [[ $(cat "$d/review-codex.rc") == 0 && -s $d/review-codex.md ]]
    [[ $(wc -l <"$d/log.md") == 3 ]]
    sed -n '1p' "$d/log.md" | grep -q 启动
    sed -n '2p' "$d/log.md" | grep -q 结束
    sed -n '3p' "$d/log.md" | grep -q 记录
    grep -q codex-offline-session "$d/log.md"
    grep -Fq "$(git -C "$main" rev-parse HEAD)" "$d/log.md"
    grep -Fq "$(sha256sum "$d/review-codex.md" | cut -c1-64)" "$d/log.md"
}
claude_permissions() {
    local budget=$1
    configure
    if [[ $budget == yes ]]; then printf '{}' >"$d/fetch-budget.json"; fi
    expect_rc 0 run_b claude
    jq -e --arg main "$main" --arg scripts "${runner%/run-b.sh}" \
        --argjson budget "$([[ $budget == yes ]] && echo true || echo false)" '
      .cwd==$main and .memory=="1" and
      (.args | (index("--tools") as $i | .[$i+1]=="Read,Grep,Glob,Bash,WebSearch,WebFetch") and
      any(.=="--restricted") and any(.=="--strict-mcp-config") and
      (any(.=="--mcp-config")|not) and
      (index("--permission-mode") as $i | .[$i+1]=="dontAsk") and
      (index("--permission-prompts") as $i | .[$i+1]=="none") and
      (.[index("--disallowedTools")+1:index("--strict-mcp-config")] ==
       ["Read(/"+$main+"/.env)","Read(/"+$main+"/var/private/second key)"]) and
      (.[index("--allowedTools")+1:index("--disallowedTools")] ==
       (["Read","Grep","Glob","WebSearch","WebFetch","Bash(scripts/debate/git-read.sh:*)",
         "Bash("+$scripts+"/git-read.sh:*)"] +
        if $budget then ["Bash(scripts/debate/fetch.sh:*)","Bash("+$scripts+"/fetch.sh:*)"] else [] end)))' "$trace" >/dev/null
    [[ $(cat "$d/review-claude.rc") == 0 && -s $d/review-claude.md ]]
}
failure_final() {
    local who=$1 mode=$2 expected=1
    [[ $mode != nonzero ]] || expected=9
    run_env+=(MODE="$mode")
    expect_rc "$expected" run_b "$who"
    [[ $(cat "$d/review-$who.rc") == "$expected" ]]
    if [[ $mode != nonzero ]]; then grep -q 没有输出 "$d/log.md"; fi
    cp "$d/log.md" "$case_root/before"
    [[ $(wc -l <"$trace.calls") == 2 ]]
    expect_rc 2 run_b "$who"
    [[ $(sha256sum <"$case_root/before") == "$(sha256sum <"$d/log.md")" ]]
    [[ $(wc -l <"$trace.calls") == 2 ]]
}
concurrent() {
    mkfifo "$case_root/release"
    run_env+=(WAIT_FIFO="$case_root/release")
    run_b codex review >"$case_root/first.out" 2>"$case_root/first.err" &
    local pid=$!
    trap 'kill "$pid" 2>/dev/null || true' EXIT
    local attempts=0
    until [[ -s $trace ]]; do
        sleep 0.01
        attempts=$((attempts + 1))
        [[ $attempts -lt 500 ]]
    done
    expect_rc 2 run_b
    grep -q '本步正在运行' "$case_root/stderr"
    printf 'finish\n' >"$case_root/release"
    wait "$pid"
    trap - EXIT
    [[ $(cat "$d/review-codex.rc") == 0 && $(wc -l <"$trace.calls") == 2 ]]
}
worktree() {
    configure
    git -C "$main" worktree add -qb implementation "$case_root/worktree"
    printf 'implementation dirty\n' >"$case_root/worktree/README.md"
    runner=$case_root/worktree/scripts/debate/run-b.sh
    # configure has already committed the exact fixture configuration.
    printf '{}' >"$d/fetch-budget.json"
    expect_rc 0 run_b claude
    jq -e --arg main "$main" --arg wt "$case_root/worktree" '
      .cwd==$main and (.args | any(.=="Read(/"+$main+"/.env)") and
      (any(.=="Read(/"+$wt+"/.env)")|not) and
      any(.=="Bash("+$wt+"/scripts/debate/git-read.sh:*)") and
      any(.=="Bash("+$wt+"/scripts/debate/fetch.sh:*)"))' "$trace" >/dev/null
    [[ ! -d $case_root/worktree/var ]]
    d=$case_root/worktree/var/debates/wrong
    mkdir -p "$d"
    printf test >"$d/prompt-review-codex.md"
    expect_rc 2 run_b
}
discovery() {
    local who=$1 layout=$2 suffix vendor extension expected
    if [[ $who == claude ]]; then
        vendor=anthropic.claude-code suffix=resources/native-binary/claude
    else
        vendor=openai.chatgpt suffix=bin/linux-x86_64/codex
    fi
    run_env=(env -i PATH="$case_root/bin:/usr/bin:/bin" HOME="$case_root/mock-home" TRACE="$trace")
    # A PATH candidate must not override either extension root.
    cp "$case_root/bin/fake-cli" "$case_root/bin/$who"
    expected=$case_root/bin/$who
    if [[ $layout != path && $layout != missing ]]; then
        for extension in .vscode .vscode-server; do
            local version=1.9
            [[ $extension != "$layout" ]] || version=1.10
            local dest=$case_root/mock-home/$extension/extensions/$vendor-$version-linux-x64/$suffix
            mkdir -p "${dest%/*}"
            cp "$case_root/bin/fake-cli" "$dest"
            if [[ $version == 1.10 ]]; then expected=$dest; fi
        done
    fi
    case $layout in
        explicit)
            run_env+=("${who^^}_BIN=$case_root/bin/fake-cli")
            expected=$case_root/bin/fake-cli
            ;;
        missing) rm "$case_root/bin/$who" ;;
    esac
    if [[ $layout == missing ]]; then
        expect_rc 2 run_b "$who"
        no_launch
        grep -q '找不到' "$case_root/stderr"
    else
        expect_rc 0 run_b "$who"
        jq -e --arg expected "$expected" '.bin==$expected' "$trace" >/dev/null
    fi
}
git_history() {
    local wt=$case_root/worktree head
    git -C "$main" worktree add -qb implementation "$wt"
    printf 'committed implementation\n' >"$wt/README.md"
    git -C "$wt" add README.md
    commit "$wt" implementation
    head=$(git -C "$wt" rev-parse HEAD)
    printf 'uncommitted material\n' >"$wt/README.md"
    for wrapper in "$main/scripts/debate/git-read.sh" "$wt/scripts/debate/git-read.sh"; do
        expect_rc 0 "$wrapper" log -n 1 -S fixture -- README.md
        grep -q fixture "$case_root/stdout"
        if grep -q implementation "$case_root/stdout"; then return 1; fi
        expect_rc 0 "$wrapper" show "$head:README.md"
        [[ $(cat "$case_root/stdout") == 'committed implementation' ]]
        (
            trap 'git -C "$main" restore -- README.md' EXIT
            printf 'uncommitted main material\n' >"$main/README.md"
            expect_rc 0 "$wrapper" blame -- README.md
            grep -q fixture "$case_root/stdout"
            if grep -q uncommitted "$case_root/stdout"; then exit 1; fi
        )
        [[ -z $(git -C "$main" status --porcelain) ]]
    done
}
git_rejects() {
    local head
    head=$(git -C "$main" rev-parse HEAD)
    local -a args
    for spec in output contents abbreviation cwd absolute traversal metadata shortened option short_sha symbolic_ref; do
        case $spec in
            output) args=(log --output=README.md) ;;
            contents) args=(blame --contents "$case_root/bait" -- README.md) ;;
            abbreviation) args=(lo) ;;
            cwd) args=(-C "$case_root" log) ;;
            absolute) args=(show "$head:/tmp/bait") ;;
            traversal) args=(log -- ../bait) ;;
            metadata) args=(blame -- .git/config) ;;
            shortened) args=(log --out=README.md) ;;
            option) args=(show --textconv HEAD:README.md) ;;
            short_sha) args=(show "${head:0:12}:README.md") ;;
            symbolic_ref) args=(show HEAD:README.md) ;;
        esac
        expect_rc 2 "$main/scripts/debate/git-read.sh" "${args[@]}"
    done
    [[ $(cat "$main/README.md") == fixture ]]
    [[ -z $(git -C "$main" status --porcelain) ]]
}
assemble() { "$main/scripts/debate/assemble-record.sh" "$d" "${1:-claude}" "${2:-codex}"; }
assembly_order() {
    local parts=(record-body body-revision brief proposal-claude draft-claude draft-codex
        review-codex review-claude disposition-claude followup-codex check-codex)
    local i=0
    for part in "${parts[@]}"; do
        printf 'unique-part-%s\n' "$i" >"$d/$part.md"
        i=$((i + 1))
    done
    expect_rc 0 assemble
    grep '^unique-part-' "$d/record.md" >"$case_root/actual"
    printf 'unique-part-%s\n' {0..10} >"$case_root/expected"
    [[ $(sha256sum <"$case_root/expected") == "$(sha256sum <"$case_root/actual")" ]]
    rm "$d/followup-codex.md"
    expect_rc 0 assemble
    ! grep -q unique-part-9 "$d/record.md"
}
assembly_validation() {
    case $1 in
        placeholder)
            printf '{{missing}}' >"$d/record-body.md"
            expect_rc 1 assemble
            ;;
        long)
            jq -nr '"字" * 65537' >"$d/record-body.md"
            expect_rc 1 assemble
            ;;
        boundary)
            jq -jn '"字" * 65535' >"$d/record-body.md"
            expect_rc 0 assemble
            grep -q 'chars 65536 / 65536' "$case_root/stdout"
            ;;
        path)
            printf '/Users/example/local.txt\n' >"$d/record-body.md"
            expect_rc 0 assemble
            grep -q 绝对路径 "$case_root/stdout"
            grep -Fq /Users/example/local.txt "$d/record.md"
            ;;
        same)
            printf '已确认的记录正文\n' >"$d/record-body.md"
            expect_rc 2 assemble codex codex
            grep -Fq 'A 与 B 不能相同' "$case_root/stderr"
            ;;
        unknown)
            printf '已确认的记录正文\n' >"$d/record-body.md"
            expect_rc 2 assemble other codex
            grep -Fq '参与方须为 claude 或 codex' "$case_root/stderr"
            ;;
    esac
}
snapshot() {
    cat >"$case_root/bin/gh" <<'GH'
#!/usr/bin/env bash
set -euo pipefail
[[ $* == *OWNER/REPO* ]]
if [[ $1 == issue ]]; then
    printf '%s\n' '{"body":"正文无额外换行"}'
else
    for i in 1 2; do
        jq -nc --arg i "$i" '[{user:{login:"author"},created_at:"2026-10-18T00:00:00Z",
          html_url:("https://example.invalid/comment-"+$i),body:"评论"}]'
    done
fi
GH
    chmod +x "$case_root/bin/gh"
    expect_rc 0 env -i PATH="$case_root/bin:/usr/bin:/bin" \
        "$main/scripts/debate/snapshot-issue.sh" 15 "$d/snapshot.md" OWNER/REPO
    grep -Fq "$(printf '正文无额外换行' | sha256sum | cut -c1-64)" "$case_root/stdout"
    grep -Fq '评论 2 条，末条 https://example.invalid/comment-2' "$case_root/stdout"
    grep -Fq '### author 2026-10-18T00:00:00Z（https://example.invalid/comment-1）' "$d/snapshot.md"
}
fetch_stub() {
    printf '{}' >"$d/fetch-budget.json"
    local before
    before=$(git -C "$main" status --porcelain --ignored)
    for arg in '' '--invalid' "$case_root/must-not-exist"; do
        expect_rc 2 "$main/scripts/debate/fetch.sh" "$arg" codex Q1 interface '{}' field
        [[ $(cat "$case_root/stdout" "$case_root/stderr") == 本项目未配置取数入口 ]]
        [[ $(wc -l <"$case_root/stderr") == 1 ]]
        [[ ! -e $case_root/must-not-exist ]]
    done
    [[ $(cat "$d/fetch-budget.json") == '{}' ]]
    [[ $(git -C "$main" status --porcelain --ignored) == "$before" ]]
    [[ $(find "$d" -type f | wc -l) == 5 ]]
}
run_test() {
    local label=$1 result
    shift
    set +e
    (
        set -e
        fixture
        "$@"
    ) >"$test_root/output" 2>&1
    result=$?
    set -e
    if ((result == 0)); then
        passed=$((passed + 1))
        printf 'PASS %s\n' "$label"
    else
        failed=$((failed + 1))
        printf 'FAIL %s\n' "$label" >&2
        cat "$test_root/output" >&2
    fi
}
run_test placeholder placeholder
for suffix in md events.jsonl stderr rc; do run_test "existing-$suffix" existing "$suffix"; done
for state in branch detached dirty untracked; do run_test "main-$state" main_gate "$state"; done
run_test directory directory_gate
for invalid in missing model effort omitted absolute traversal empty; do run_test "config-$invalid" invalid_config "$invalid"; done
for who in claude codex; do
    for step in review smoke; do run_test "model-$who-$step" models "$who" "$step"; done
    for layout in .vscode .vscode-server explicit path missing; do
        run_test "discovery-$who-$layout" discovery "$who" "$layout"
    done
    for mode in empty nonzero; do run_test "failure-$who-$mode" failure_final "$who" "$mode"; done
done
run_test failure-claude-is-error failure_final claude error
for budget in yes no; do
    run_test "codex-$budget" codex_success "$budget"
    run_test "claude-$budget" claude_permissions "$budget"
done
run_test concurrent concurrent
run_test worktree worktree
run_test git-history git_history
run_test git-rejects git_rejects
run_test assembly-order assembly_order
for variant in placeholder long boundary path same unknown; do run_test "assembly-$variant" assembly_validation "$variant"; done
run_test snapshot snapshot
run_test fetch-stub fetch_stub
printf 'debate tests: %s passed, %s failed\n' "$passed" "$failed"
((failed == 0))
