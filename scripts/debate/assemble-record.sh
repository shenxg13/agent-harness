#!/usr/bin/env bash
# 用法：scripts/debate/assemble-record.sh <辩论目录> <A：claude|codex> <B：claude|codex>
# 把 record-body.md（及用户确认后补写的 body-revision.md）与题目、提案、审查、答复等原文拼成 record.md（原文放进 <details>），并打印字符数。
# 超过 GitHub 评论上限（65,536 字符）时退出码为 1；含本机绝对路径时只提示，不改写原文（折叠区标注的哈希针对原文）。
set -euo pipefail
d=${1:?辩论目录}
a=${2:?A：claude 或 codex}
b=${3:?B：claude 或 codex}
declare -A name=([claude]=Claude [codex]=Codex)
for p in "$a" "$b"; do
    [[ -n ${name[$p]:-} ]] || {
        echo "参与方须为 claude 或 codex：$p" >&2
        exit 2
    }
done
[[ $a != "$b" ]] || {
    echo "A 与 B 不能相同" >&2
    exit 2
}
cd "$d"
[[ -f record-body.md ]] || {
    echo "缺少 record-body.md" >&2
    exit 2
}
A=${name[$a]} B=${name[$b]}
parts=(
    "brief.md|题目"
    "proposal-$a.md|提案 · $A"
    "draft-$a.md|独立稿 · $A"
    "draft-$b.md|独立稿 · $B"
    "review-$b.md|审查 · $B"
    "review-$a.md|审查 · $A"
    "disposition-$a.md|答复 · $A"
    "followup-$b.md|追加交锋 · $B"
    "check-$b.md|记录核对 · $B"
)
{
    cat record-body.md
    echo
    if [[ -f body-revision.md ]]; then
        cat body-revision.md
        echo
    fi
    for p in "${parts[@]}"; do
        f=${p%%|*} t=${p#*|}
        [[ -f $f ]] || continue
        echo "<details>"
        echo "<summary>$t（SHA-256 <code>$(sha256sum "$f" | cut -c1-12)</code>…）</summary>"
        echo
        cat "$f"
        echo
        echo "</details>"
        echo
    done
} >record.md
sha256sum record.md
# jq 的字符串 length 按 Unicode 字符计数，不按 UTF-8 字节或 Shell locale。
chars=$(jq -Rs 'length' record.md)
limit=65536
printf 'chars %s / %s\n' "$chars" "$limit"
if grep -q '{{' record.md; then
    echo '错误：仍有未填的占位符' >&2
    exit 1
fi
mapfile -t local_paths < <(grep -oE '/(home|Users)/[^][:space:])`>]+' record.md || true)
if ((${#local_paths[@]})); then
    printf '提示：含 %s 处本机绝对路径，在 GitHub 上打不开；请在过程记录中说明。首处：%s\n' \
        "${#local_paths[@]}" "${local_paths[0]}"
fi
if ((chars > limit)); then
    echo '错误：超过 GitHub 评论上限，需要精简记录正文或拆分' >&2
    exit 1
fi
