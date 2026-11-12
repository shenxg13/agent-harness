# 决策审查的桌面 CLI 与环境隔离

[决策审查工作流](../workflows/decision-review.md#运行审查方)按 Issue #17 的确认契约，
增加桌面 app 优先发现、实际版本比较、来源日志、必需参数检查与统一的 A 会话环境清除。
显式覆盖仍最高优先级；无桌面候选时保留扩展优先、PATH 后备。内部 app 目录不承诺稳定。

下游采用时注意：桌面 app 即使版本较低也优先于 VS Code 扩展；四个 smoke 覆盖变量已从
`CLAUDE_MODEL`／`CLAUDE_EFFORT`／`CODEX_MODEL`／`CODEX_EFFORT` 改成对应 `DEBATE_SMOKE_` 前缀，
旧名忽略且仅 smoke 提示一次，没有兼容期。B 不继承自设的 `CLAUDE_CONFIG_DIR`／`CODEX_HOME`，
需单独授权验证默认位置的登录凭据；不改变项目所有的配置与取数入口。
离线回归使用假 CLI 和模拟目录，不调用真实模型；实机 smoke 证据由交付 PR 保存。
