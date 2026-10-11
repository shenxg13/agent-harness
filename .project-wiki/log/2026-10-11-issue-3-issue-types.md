# Issue 类型与准入边界

[架构](../architecture/agent-development-harness.md)记录类型与执行状态的职责，
完整类型规则由 [Issue 工作流](../../.harness/workflows/github-planning.md#issue-types) 维护。
类型只在 planned 准入处由脚本校验，其他状态不追溯，所有转换保留类型。
确认依据为 [Issue #3 的确认记录](../../docs/provenance.md#issue-类型需求)；
下游须先建标签、补齐未关闭 Issue 类型，再采用新脚本，见
[Harness 更新条目](../../.harness/update-log/2026-10-11-issue-3-issue-types.md)。
