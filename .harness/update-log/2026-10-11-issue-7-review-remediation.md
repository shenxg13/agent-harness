# 评审整改、观察项与维护者认定

[评审协议](../workflows/review-sync.md#remediation-scope-and-observations)限定整改范围，
要求按条目列出文件并在接受交接前核对；观察项独立记录，纳入后按台账核验，未纳入项在
批准后由维护者逐条决定另开 Issue 或不处理。[完成规则](../workflows/github-planning.md#completion-rules)
要求记录处置。[维护者认定](../workflows/review-sync.md#maintainer-and-risk-owner)采用已确认
运行模型声明；没有声明时个人仓库由账号所有者承担，组织仓库没有默认人选。

下游采用时，以下四个文件必须一起更新：

- 评审协议 `.harness/workflows/review-sync.md`。
- 评论模板 `.github/review_convergence_comment.md`。
- 评审回归 `scripts/tests/test_review_convergence.sh`。
- 交付流程 `.harness/workflows/github-planning.md`。

组织仓库须先在已确认运行模型中声明维护者，才可接受风险或作出裁决。观察项和整改记录
不进入 JSON 校验，轮次、阻断判定和终验要求不变；不追溯已发出的评审记录。
来源为 2026-10-11 [Issue #7 的确认记录](../../docs/provenance.md#评审整改与维护者认定需求)。
