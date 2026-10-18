# 可选双模型决策审查

新增[工作流](../workflows/decision-review.md)、启动与记录脚本、提示模板和离线 Shell 回归，
来源与取舍见[来源记录](../../docs/provenance.md#2026-10-18可选双模型决策审查)。
执行会话为 A，默认 Claude／Codex；项目自行声明授权、相持及材料边界，未声明时交维护者决定。

采用时保留项目所有的 `scripts/debate/config.env` 和 `scripts/debate/fetch.sh`。
配置文件不自动跟随模板默认值；正式模型与档位只读配置，环境覆盖只用于已授权 smoke。
CLI 查找增加 PATH 后备；配置非法会在 CLI 和日志之前拒绝。模板取数入口不实现取数。
质量入口新增假 CLI 回归和 util-linux flock 检查，不调用真实模型；真实冒烟仍需单独授权。
