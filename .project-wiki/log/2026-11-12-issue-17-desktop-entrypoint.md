# 修正 Claude 当前 CLI 的桌面来源条件

按 2026-11-12 Issue #17 的确认变更
更新[架构主题](../architecture/agent-development-harness.md#contracts)：仅桌面入口采用 EXECPATH，
采用后版本不可读则拒绝，非桌面会话忽略它。完整判别与后备规则由
[工作流](../../.harness/workflows/decision-review.md#运行审查方)维护；
[Harness 日志](../../.harness/update-log/2026-11-12-issue-17-desktop-entrypoint.md)记录下游采用影响。
