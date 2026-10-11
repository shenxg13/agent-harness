# 支持并发实施与评审

新知识日志和 Harness 更新日志按变更分文件；文件名由模板检查校验。下游采用时保留两份
原日志的全部条目，只在开头增加新位置说明，并同步工作流、方法页、检查单与检查器，见
[更新说明](../../docs/updating.md)。

[交付流程](../workflows/github-planning.md)和[评审流程](../workflows/review-sync.md)明确独立
工作树及清理责任；[运行时指南](../tooling-runtime.md)说明共享工具与项目本地资源边界。
合并后检查该次 `main` 推送的组合结果，失败时先回退或修复，恢复前不合并其他 PR。
来源为本仓库 [Issue #2 的确认记录](../../docs/provenance.md#并发协作需求)，非下游回流。
