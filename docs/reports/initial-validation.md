# 首次验证记录

## 验证范围

2026-09-21，初始提取的 60 个跟踪文件、40 个 Markdown 文件及两份有效 Wiki 实体。
来源提交、继承方式与新增文件见 [来源记录](../provenance.md)。

## 已执行结果

| 命令或核对 | 结果 |
| --- | --- |
| `scripts/quality/check.sh` | PASS：工具合同、Bash 语法、ShellCheck、shfmt、Markdown、模板完整性及五组回归 |
| `scripts/quality/check_template.sh --source-audit` | PASS：来源记录之外无声明的来源标识残留 |
| `git diff --cached --check` | PASS：暂存内容无空白错误 |
| GitHub 契约实现逐字节比对 | PASS：三个 Shell 入口与 jq 校验器均与固定来源一致 |

## 回归覆盖

- Issue：未确认或占位需求、非法状态、审计字段、错误对象、写入失败、并发覆盖与读回不一致。
- PR：必要章节、真实关联模拟、分支、验收映射与执行状态边界。
- Review：R0–R3、未完成责任、晚发现来源、阻塞与裁决、协议不一致拒绝。
- Quality：缺失工具、精确与最低版本错误、失败传播、缺少 gh 时拒绝真实 PR 模式。
- Template：必要文件缺失、断链、逃逸路径、未跟踪引用、未知 Wiki 关联、CI 入口缺失、
  未固定 Action，以及显式来源审计。普通检查允许采用项目加入自己的业务词汇和二进制资源。

## 修复记录

首次检查发现来源链接的 Markdown 格式问题，已修正。
Node 子进程枚举在受限执行环境返回 EPERM；改为 Shell 枚举并通过管道传给 Node，
管道保持失败传播，Node 只负责文件解析。后续完整检查通过。

## 干净检出与发布读回

初始提交为 `5f79ff84eba1261d5eeaa0381f7e270593d5a9f7`。

- 从正式本地仓库以 `git clone --no-local` 建立独立克隆。
- 取消 GH_TOKEN、GITHUB_TOKEN、GH_ENTERPRISE_TOKEN，并使用空 GH_CONFIG_DIR；
  完整质量入口和显式来源审计均 PASS，工作区保持干净。
- `git show --format= --check HEAD` PASS。
- 首次远程 main 与本地初始提交一致；公开可见、模板设置及六个状态标签已读回。
- GitHub 连接器读取仓库元数据与固定初始提交的 README 成功。
- 首次 push 触发的 Harness quality，run ID `35616802625`，状态 completed／success。
- 远程地址和证据链接集中记录在 [来源及发布读回](../provenance.md#首次发布读回)。

以上结果绑定初始提交；本次补记仅修改验证文档，最终提交的 CI 结果由交接时实时读回。

## 证据边界

本报告记录实施自检，不代表独立 R1–R3 评审。GitHub 操作回归使用模拟客户端，
不证明真实远程权限。上述干净克隆、真实连接器访问和远程 CI 已分别验证。
本次未通过创建真实 Issue／PR 来演练完整交付生命周期；这部分证据来自离线回归。
