#!/usr/bin/env bash
# 用法：scripts/debate/snapshot-issue.sh <Issue 号> <输出文件> <OWNER/REPO>
# 把 Issue 正文和全部评论存成 Markdown 快照，评论标题写作者、时间和评论链接；
# 打印正文 SHA-256、评论条数、末条评论链接和快照 SHA-256，供登记到 log.md。需要联网。
set -euo pipefail
n=${1:?Issue 号}
out=${2:?输出文件}
repo=${3:?显式指定 OWNER/REPO，避免解析到上游仓库}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
gh issue view "$n" -R "$repo" --json body | jq -j .body >"$tmp/body"
gh api "repos/$repo/issues/$n/comments" --paginate | jq -s 'add // []' >"$tmp/comments.json"
body_sha=$(sha256sum <"$tmp/body" | cut -c1-64)
{
    echo "# Issue #$n 快照（$(date -u +%FT%TZ) 读取；正文 SHA-256 $body_sha）"
    echo
    echo "## 正文"
    echo
    cat "$tmp/body"
    echo
    echo
    echo "## 评论"
    jq -r '.[] | "\n### \(.user.login) \(.created_at)（\(.html_url)）\n\n\(.body)"' "$tmp/comments.json"
} >"$out"
echo "正文 SHA-256 $body_sha"
echo "评论 $(jq length "$tmp/comments.json") 条，末条 $(jq -r '.[-1].html_url // "无"' "$tmp/comments.json")"
sha256sum "$out"
