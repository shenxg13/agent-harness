# 工作树复用主检出的检查工具

[架构契约](../architecture/agent-development-harness.md#contracts)在工作树本地资源一条中补充：
主检出默认位置的检查工具同样可以按绝对路径从它的各个链接工作树复用，独立克隆不适用；
定位方法由[运行时指南](../../.harness/tooling-runtime.md#worktrees-and-local-resources)维护。
确认依据为 [Issue #10 的确认记录](../../docs/provenance.md#工作树复用检查工具需求)；下游采用
方式见 [Harness 更新条目](../../.harness/update-log/2026-10-11-issue-10-worktree-tool-reuse.md)。
