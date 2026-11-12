# Codex B 边界与环境认证影响

Issue #24 的已确认规则由[决策审查工作流](../../.harness/workflows/decision-review.md#运行审查方)
维护：Codex B 清空 MCP 表、关闭十项扩展功能并不持久化会话，仍读取用户的其他配置。
前缀清除会影响环境认证和服务方选择，采用项目须准备 CLI 默认位置的登录，并按版本核对功能名。
[下游采用说明](../../.harness/update-log/2026-11-12-issue-24-codex-b-boundaries.md)记录兼容与排查注意事项。

[架构主题](../architecture/agent-development-harness.md#contracts)已将启动参数、清除名单和实际隔离
限度交由工作流维护；本次沿用该分工，不复制关闭名单。离线参数回归与 TMPDIR 规范化断言只证明
脚本合同，实际 MCP／应用连接及记忆目录变化仍需单独授权 smoke 验证，证据留在交付 PR。
