# Codex B 多代理关闭与 smoke 判断修正

Issue #24 的[运行审查方](../workflows/decision-review.md#运行审查方)在原十项关闭参数之外，
补充 `agents.enabled=false`。CLI `0.167.0-alpha.4.1` 仅将 `multi_agent` 功能位置为 false 仍暴露协作工具；
无推理请求对照确认补充配置可以移除它们并保留原生搜索。两种预算模式均增加独立参数回归。

下游采用时一并更新入口和工作流。smoke 使用当前实际原生搜索入口；code mode 的入口为
`functions.exec` 中的 `tools.web__run`。具体 MCP／应用连接器、通用 MCP 资源接口和多代理工具
分别核验，工具自述和单独的 prompt-input 渲染不能替代实际请求／运行证据。
原失败产物保留，后续获授权的 smoke 使用独立场次；无推理请求捕获不代表真实搜索已经通过。
诊断依据、版本对照与本轮运行结果保存在 Issue #24 的交付 PR。
