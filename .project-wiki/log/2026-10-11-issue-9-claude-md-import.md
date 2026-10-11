# 入口加载方式

[架构契约](../architecture/agent-development-harness.md#contracts)新增一条：`CLAUDE.md` 以
`@AGENTS.md` 导入在 Claude Code 启动时加载入口，入口规则只在 `AGENTS.md` 维护；`CODEX.md`
是保留的短路由，Codex 直接读取 `AGENTS.md`。确认依据为
[Issue #9 的确认记录](../../docs/provenance.md#入口加载需求)；下游两种情形的采用方式见
[Harness 更新条目](../../.harness/update-log/2026-10-11-issue-9-claude-md-import.md)。
