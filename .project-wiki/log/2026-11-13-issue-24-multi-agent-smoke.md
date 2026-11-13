# Codex B 运行时边界与 smoke 判断

Issue #24 修复多代理功能位关闭后仍暴露协作工具的问题；具体参数和 smoke 核验方法由
[决策审查工作流](../../.harness/workflows/decision-review.md#运行审查方)维护。
原生搜索按实际工具模式调用，具体连接器与通用资源接口分别记录；历史失败记录不覆盖。
[采用日志](../../.harness/update-log/2026-11-13-issue-24-multi-agent-smoke.md)说明修正与证据边界。
架构职责未变，继续链接工作流，不复制启动参数；实际运行结果留在交付 PR。
