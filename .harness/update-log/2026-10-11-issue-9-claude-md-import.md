# CLAUDE.md 以导入方式加载入口

`CLAUDE.md` 的全部内容改为一行 `@AGENTS.md`。Claude Code 在 `CLAUDE.md` 与 `AGENTS.md` 并存时
默认只加载前者；原来的路由句只有在 Agent 自行打开 `AGENTS.md` 时才生效，导入则在启动时
与 `CLAUDE.md` 一起展开。入口规则仍只在 `AGENTS.md` 维护，`AGENTS.md`、`CODEX.md` 和模板
检查的必需文件清单不变；契约见[架构页](../../.project-wiki/architecture/agent-development-harness.md#contracts)。

下游采用时按自己的 `CLAUDE.md` 属于哪种情形处理：

- 只有指向 `AGENTS.md` 的路由句：整体替换为一行 `@AGENTS.md`，以换行结尾。
- 另有 Claude Code 专用内容：把 `@AGENTS.md` 放在首行，专用内容保留在其后，只删除原来的
  路由句。

模板检查不解析导入。采用后在新开的 Claude Code 会话里确认启动上下文已包含 `AGENTS.md`
的正文；上下文压缩后是否重新展开未经验证。Codex 直接读取 `AGENTS.md`，不受影响。
回滚时还原该文件即可。来源为 2026-10-11 [Issue #9 的确认记录](../../docs/provenance.md#入口加载需求)；
本次不修改下游仓库。
