# 决策审查的桌面来源与子进程环境

按 Issue #17 的已确认契约更新[架构主题](../architecture/agent-development-harness.md#contracts)：
CLI 发现优先桌面 app，启动前检查参数并清除 A 会话 app 环境，日志记录实际来源、版本与路径。
采用时须将四个旧 smoke 变量迁移到 `DEBATE_SMOKE_*`，并单独验证清除配置目录覆盖后的默认登录。
完整规则与兼容边界见[工作流](../../.harness/workflows/decision-review.md#运行审查方)，
[下游采用说明](../../.harness/update-log/2026-11-12-issue-17-desktop-cli.md)记录不兼容变化。
离线证据不代表实机登录或隔离验收完成。
