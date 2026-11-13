# Codex B R1 整改

Issue #24 R1 的 F-001～F-003 修正 MCP 禁用机制、默认 TMPDIR 下失效的规范化断言，以及
与 ephemeral 矛盾的会话排查说明。完整机制及拒绝条件由
[决策审查工作流](../../.harness/workflows/decision-review.md#运行审查方)维护，
[采用日志](../../.harness/update-log/2026-11-13-issue-24-r1-corrections.md)记录兼容和回归注意事项。
架构分工与已确认的关闭范围不变；逐项禁用后的列表复查和真实 CLI 回环探针需与参数断言区分，
首次枚举可能发起 HTTP MCP 的 OAuth 元数据探测，不能以执行阶段禁用推导预检没有网络请求。
历史 smoke 仍绑定原 head，不能将旧结果当作整改后重新运行的证明。
