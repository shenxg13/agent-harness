# 来源与提取清单

## 固定来源

- 来源仓库：`sologovision/tm-lab`。
- 来源提交：`4ce838031aef3881005c01562d6ee5c96b85b551`。
- 来源链接：[固定提交](https://github.com/sologovision/tm-lab/commit/4ce838031aef3881005c01562d6ee5c96b85b551)
- 原本地工作目录：`/home/sfmon/code/tm-lab`，仅作来源标识，不是运行依赖。
- 新仓库：`shenxg13/agent-harness`，用户确认公开发布，首次不添加 LICENSE。
- 采用全新 Git 历史；来源仓库的提交、Issue、PR 和业务状态不迁移为新仓库状态。

## 提取残留检查配置

仅在显式执行 `scripts/quality/check_template.sh --source-audit` 时应用以下来源标识。
下游项目按自己的来源调整该配置；普通完整性检查允许项目业务词汇与二进制资产。

```json
{"source_markers": ["tm-lab", "tm_lab", "tm-agent", "sologovision", "shenxg13", "CNIPA", "trademark", "/home/sfmon", "127.0.0.1:7890", "TM_LAB"]}
```

## 继承文件

以下文件均从固定提交读取，记录的是初始化提取方式。后续变化以新仓库 Git 历史为准。

| 路径 | 处理 |
| --- | --- |
| `AGENTS.md` | 通用化改写或重建 |
| `CLAUDE.md` | 原样保留 |
| `CODEX.md` | 原样保留 |
| `README.md` | 通用化改写或重建 |
| `.gitignore` | 通用化改写或重建 |
| `.shellcheckrc` | 原样保留 |
| `.markdownlint-cli2.yaml` | 原样保留 |
| `.harness/index.md` | 通用化改写或重建 |
| `.harness/catalog.md` | 通用化改写或重建 |
| `.harness/rules.md` | 通用化改写或重建 |
| `.harness/tooling-runtime.md` | 通用化改写或重建 |
| `.harness/sync-status.json` | 原样保留 |
| `.harness/update-log.md` | 通用化改写或重建 |
| `.harness/checklists/doc-sync.md` | 原样保留 |
| `.harness/workflows/small-change.md` | 原样保留 |
| `.harness/workflows/large-change.md` | 原样保留 |
| `.harness/workflows/github-planning.md` | 通用化改写或重建 |
| `.harness/workflows/review-sync.md` | 通用化改写或重建 |
| `.harness/workflows/knowledge-sync.md` | 原样保留 |
| `.harness/workflows/wiki-update.md` | 原样保留 |
| `.project-wiki/schema.md` | 原样保留 |
| `.project-wiki/index.md` | 通用化改写或重建 |
| `.project-wiki/log.md` | 通用化改写或重建 |
| `.project-wiki/templates/architecture.md` | 原样保留 |
| `.project-wiki/templates/module.md` | 原样保留 |
| `.project-wiki/templates/feature.md` | 原样保留 |
| `.project-wiki/templates/contract.md` | 原样保留 |
| `.project-wiki/templates/decision.md` | 原样保留 |
| `.project-wiki/templates/method.md` | 原样保留 |
| `.github/ISSUE_TEMPLATE/requirement.md` | 原样保留 |
| `.github/ISSUE_TEMPLATE/config.yml` | 原样保留 |
| `.github/pull_request_template.md` | 原样保留 |
| `.github/review_convergence_comment.md` | 原样保留 |
| `scripts/README.md` | 通用化改写或重建 |
| `scripts/github/issue_status.sh` | 原样保留 |
| `scripts/github/pr_contract.sh` | 原样保留 |
| `scripts/github/review_convergence.sh` | 原样保留 |
| `scripts/github/review_convergence.jq` | 原样保留 |
| `scripts/quality/check.sh` | 通用化改写或重建 |
| `scripts/quality/tool-versions.env` | 通用化改写或重建 |
| `scripts/tests/test_issue_status.sh` | 通用化改写或重建 |
| `scripts/tests/test_pr_contract.sh` | 通用化改写或重建 |
| `scripts/tests/test_review_convergence.sh` | 通用化改写或重建 |
| `scripts/tests/test_quality.sh` | 通用化改写或重建 |
| `docs/runbooks/issue-pr-quality-tooling.md` | 通用化改写或重建 |

工程原则另从 `.project-wiki/decisions/trusted-single-maintainer-performance.md`
提取通用部分，项目模型被改为可选示例。

## 新增文件

- `.github/workflows/quality.yml`
- `.harness/plans/initial-extraction.md`
- `.harness/workflows/local-bootstrap.md`
- `.project-wiki/architecture/agent-development-harness.md`
- `.project-wiki/decisions/engineering-principles.md`
- `.project-wiki/templates/operating-model.md`
- `docs/examples/single-maintainer.md`
- `docs/getting-started.md`
- `docs/reports/initial-validation.md`
- `docs/updating.md`
- `scripts/quality/check_template.mjs`
- `scripts/quality/check_template.sh`
- `scripts/quality/install_ci_tools.sh`
- `scripts/tests/test_template.sh`
- `docs/provenance.md`

## 排除范围

业务代码、数据库、依赖文件、原始资料、搜索/OCR/CNIPA 契约与资源、业务测试、
历史报告、原业务 Wiki 实体、业务计划和 Python 业务 CI 均未提取。
`.harness/workflows/search-weak-word-review.md` 属于业务工作流，不纳入通用模板。
原 `.env.example` 和仅服务业务证据字节保护的 `.gitattributes` 不提取。

只有本来源记录允许保留来源仓库名、业务标识和历史绝对路径。
这些标识用于追溯，不提供运行配置或跨仓库同步。

## 首次发布读回

- 远程仓库：[shenxg13/agent-harness](https://github.com/shenxg13/agent-harness)。
- 可见性 public，默认分支 main，is_template=true；首次不添加 LICENSE。
- 初始本地提交与远程 main：`5f79ff84eba1261d5eeaa0381f7e270593d5a9f7`。
- 首次 [Harness quality CI](https://github.com/shenxg13/agent-harness/actions/runs/35616802625) 为 completed／success，绑定上述提交。
- GitHub 连接器成功读取仓库元数据和同一提交的 README。
- status:triage、status:planned、status:in-progress、status:blocked、status:needs-review、status:done 六个标签已读回。
- 本条记录为实施发布证据，不是独立评审结论。后续任务按 GitHub 工作流执行。
