历史更新日志已冻结，以下已有条目原样保留，不再追加。新条目见 [update-log/](update-log/)，一次变更一个文件，按文件名排序阅读。

# Harness Update Log

| Date | Commit | Summary |
| --- | --- | --- |
| 2026-09-21 | Initial extraction; see Git history | 通用流程、离线质量、初始化与更新说明；来源见 `docs/provenance.md` |
| 2026-10-11 | See Git history | 以下三行取自下游项目的使用经验，来源与取舍见[来源记录](../docs/provenance.md)。评审收敛：R1～R3 任一轮在无当前阻断且已核对全部验收标准与不可豁免门禁时可直接 `approve`，停用 `pass_to_R3`；规则见[评审收敛协议](workflows/review-sync.md#review-convergence-protocol)。下游须同时更新规则正文、评论模板、校验脚本和回归 |
| 2026-10-11 | See Git history | 按任务读取与知识单处维护：入口和索引只保留路由，完整规则留在所属主题页；新增[知识维护方法](../.project-wiki/methods/knowledge-maintenance.md)；原始资料目录改为 `.project-wiki/raw/`。下游已在根目录 `raw/` 存放知识快照的，采用时自行决定是否迁移 |
| 2026-10-11 | See Git history | 新增项目检查入口 `scripts/quality/project_checks.sh`（项目所有，CI 单独调用，采用更新时保留项目自己的版本）和本地安装脚本 `scripts/quality/install_local_tools.sh`。模板检查、CI 步骤和入口文件须一起采用，否则模板检查失败；下游在工作流文件里自行添加过项目检查步骤的，采用时把命令移入该入口。安装的缓存隔离与目标拒绝边界见[工具手册](../docs/runbooks/issue-pr-quality-tooling.md#本地安装) |
