# Issue 类型与 planned 准入

需求模板的标题直接描述工作，通过恰好一个 `type:*` 标签按主要交付物分类；默认五类、
Harness 产品边界和更正规则见 [Issue 类型](../workflows/github-planning.md#issue-types)。
状态脚本在现有 planned 准入检查中验证类型数量，缺少或重复时在任何写入前拒绝，
`repair` 和 `--force` 不能绕过。只认前缀、不自动改类型、不追溯其他状态，转换保留类型。

下游采用顺序：先按 [初始化说明](../../docs/getting-started.md#接入-github) 创建类型标签，
给所有未关闭的 Issue 补上恰好一个类型，再采用新脚本及配套回归、模板和流程文档。
已有标题和已关闭 Issue 不补改，回滚脚本时类型标签可保留。

来源为本仓库 [Issue #3 的确认记录](../../docs/provenance.md#issue-类型需求)，于 2026-10-11
确认的需求；本次不修改下游仓库。
