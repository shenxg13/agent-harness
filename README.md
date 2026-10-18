# Agent Development Harness

面向 AI Agent 协作开发的通用仓库模板，包含需求管理、实施、独立评审、
质量检查和项目知识维护流程。

## 开始使用

1. 阅读 [初始化说明](docs/getting-started.md)，确定本地阶段与远程协作阶段。
2. 从 [Agent 入口](AGENTS.md) 进入 [Harness](.harness/index.md)。
3. 按 [运行模型模板](.project-wiki/templates/operating-model.md) 声明项目边界。
4. 安装 [工具合同](docs/runbooks/issue-pr-quality-tooling.md) 中的依赖后运行：

```bash
scripts/quality/check.sh --check-tools-only
scripts/quality/check.sh
```

本地质量检查无需 GitHub 认证或业务服务。Issue 与 PR 测试使用模拟 `gh`，
不会请求真实仓库。实际远程协作使用 GitHub CLI 或已连接的 GitHub 工具。

Linux x86_64 可用 `scripts/quality/install_local_tools.sh` 把固定工具装到默认的
`var/harness-tools`，再临时设置 `PATH="$PWD/var/harness-tools/bin:$PATH"` 运行检查。
项目将业务检查写入自己的 `scripts/quality/project_checks.sh`，CI 在通用检查之后
单独调用；通用检查入口不调用它。安装边界及参数见上述工具合同。

## 目录职责

| 路径 | 职责 |
| --- | --- |
| `.harness/` | 任务路由、流程、规则和交接 |
| `.project-wiki/` | 有来源的持久知识与实体模板 |
| `.github/` | 需求、PR、评审模板与质量 CI |
| `scripts/debate/` | 可选的双模型决策审查：项目配置、启动、只读历史入口、快照及记录模板 |
| `scripts/github/` | 状态机、PR 契约与评审证据校验 |
| `scripts/quality/` | 工具合同与本地安装、离线质量、模板检查及项目检查入口 |
| `scripts/tests/` | 流程与质量入口回归 |
| `docs/` | 初始化、更新、来源及验证记录 |

默认协作语言为中文，默认分支为 `main`。首版工具环境为 Linux／WSL、
Bash 和 GNU 工具链，业务语言、服务和验证命令由采用模板的项目声明。

## 维护

- [架构与知识边界](.project-wiki/architecture/agent-development-harness.md)
- [工程原则](.project-wiki/decisions/engineering-principles.md)
- [知识维护方法](.project-wiki/methods/knowledge-maintenance.md)
- [人工更新与回流方法](docs/updating.md)
- [来源与提取清单](docs/provenance.md)
- [首次验证记录](docs/reports/initial-validation.md)

许可证尚未确定，首次发布不添加 `LICENSE` 文件。
