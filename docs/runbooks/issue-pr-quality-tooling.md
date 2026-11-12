# 质量工具安装与运行

## 工具合同

唯一机器可读版本来源是 `scripts/quality/tool-versions.env`。

| 工具 | 版本 | 用途 |
| --- | --- | --- |
| Bash | 最低 5.1.0 | Shell 入口 |
| Git | 最低 2.39.0 | 枚举文件与版本控制 |
| jq | 最低 1.6.0 | JSON 与流程校验 |
| flock（util-linux） | 最低 2.36.0 | 决策审查启动锁与离线并发回归 |
| GNU coreutils | 最低 8.32.0 | base64 和基础文件工具 |
| ShellCheck | 固定 0.10.0 | Shell 静态检查 |
| shfmt | 固定 3.13.1 | Shell 格式检查 |
| Node.js | 固定 24.19.0 | Markdown 与模板校验 |
| npm | 固定 11.17.0 | 安装 Markdown 检查器 |
| markdownlint-cli2 | 固定 0.23.2 | Markdown 校验 |
| GitHub CLI | 最低 2.45.0，仅真实远程操作需要 | Issue／PR 与 GitHub |

首版支持 Linux／WSL 与 GNU 工具链。本地离线入口无需真实 `gh`；模拟客户端由
测试提供。现有合规工具可以继续使用；升级版本应同步合同、说明及回归结果。

## 本地安装

Bash、Git、jq、util-linux（flock）和 coreutils 从所用 Linux 发行版的受信任软件源安装。
版本须满足上述下限，使用 `command -v` 和工具的版本命令核对。

Linux x86_64 上，五个固定版本的工具可以用安装脚本一次装好；安装前应取得相应授权：

```bash
scripts/quality/install_local_tools.sh
PATH="$PWD/var/harness-tools/bin:$PATH" scripts/quality/check.sh --check-tools-only
```

脚本从官方地址下载 ShellCheck、shfmt 和 Node.js，按工具合同记录的摘要核对，再用这份
Node.js 安装固定版本的 npm 与 markdownlint-cli2，最后运行一次工具版本检查。默认目录是
仓库内已被 Git 忽略的 `var/harness-tools`，也可以把相对或绝对目标目录作为唯一参数传入。
目标已存在、末段为 `.` 或 `..`、未知选项或多于一个参数时，脚本在下载和写入前拒绝执行。下载和安装先在目标旁
的临时目录完成，全部成功后才出现目标目录；失败时不留下目标目录，临时目录也会清理。脚本不修改
`PATH`、系统目录、用户的 npm 缓存或全局前缀，运行检查时按上面的写法临时加上 `bin` 目录。
安装命令通过命令行参数固定 npm 缓存和前缀，覆盖用户导出的同名配置；安装与版本检查期间
禁用 Node 编译缓存。若发布时目标已出现，脚本失败并清理自身暂存，保留已有目标。
辅助工具为 curl、tar、xz、sha256sum 和 install。

装在主检出默认位置的工具可以从它的各个工作树复用；定位主检出和在工作树里安装的写法见
[运行时指南](../../.harness/tooling-runtime.md#worktrees-and-local-resources)。

不使用脚本或在其他架构上，按以下方式手工安装。ShellCheck 从 [官方发行](https://github.com/koalaman/shellcheck/releases/tag/v0.10.0)
获取，shfmt 从 [官方发行](https://github.com/mvdan/sh/releases/tag/v3.13.1)
获取。工具合同记录 Linux x86_64 资产摘要；其他架构应选官方对应资产，
核对来源并记录摘要，不能复用 x86_64 摘要。

Node.js 从 [官方目录](https://nodejs.org/dist/v24.19.0/) 安装，核对该目录的
SHASUMS256.txt，或使用能提供精确版本的已有版本管理器。使用用户拥有的安装
目录，不对系统 npm 执行 `sudo npm install`。

下面假设 Node/npm 安装前缀可由当前用户写入；安装前应取得相应授权：

```bash
source scripts/quality/tool-versions.env
npm install --global "npm@$NPM_VERSION" "markdownlint-cli2@$MARKDOWNLINT_CLI2_VERSION"
scripts/quality/check.sh --check-tools-only
```

运行真实 GitHub 操作时，另从 [官方 GitHub CLI](https://cli.github.com/)
安装 `gh`，按运行时指南完成网络与身份验证。

## CI 安装

`.github/workflows/quality.yml` 固定 Actions 提交，读取同一版本合同，由
`scripts/quality/install_ci_tools.sh` 下载并核对 ShellCheck、shfmt 摘要，安装
固定 npm 与 Markdown 工具，随后调用统一检查入口。
CI 辅助工具为 curl、tar、xz、sha256sum 和 install，工作目录位于 runner 临时目录。
安装脚本不修改业务依赖或凭据；本地入口不会自动调用它。

统一检查入口之后，CI 另有一步调用 `scripts/quality/project_checks.sh`。该文件归项目
所有：项目把自己的业务检查命令写在里面，不必改动工作流文件；模板自带的版本不做任何
检查。统一检查入口不调用它，因此始终可以单独验证 harness。需要额外运行时或服务的
项目检查，可以另建项目自己的工作流文件。

## 运行与排障

```bash
scripts/quality/check.sh
```

缺少工具或版本不符会明确失败。先核对来源、版本与 PATH；不得降低门禁或把
不可运行检查描述为成功。缺失 GitHub 登录只影响真实远程操作。

`--check-tools-only` 也检查 `flock` 存在及版本，缺失会明确报错。真实 Claude／Codex CLI
不是通用质量入口的依赖；决策审查离线回归只用假 CLI。真实 CLI 的安装、项目配置与授权
见[可选能力启用说明](../getting-started.md#可选启用双模型决策审查)。

决策审查启动时按“显式覆盖 → 桌面 app → VS Code 扩展 → PATH”发现 CLI；Codex app 发现
需要 WSL 的 `cmd.exe` 和 `wslpath`，互操作不可用时跳过。用单场日志中的来源、版本和完整路径
核对实际选择；内部目录改变时用 `CLAUDE_BIN`／`CODEX_BIN` 固定 CLI。帮助输出缺少必需参数
会在模型调用和日志之前拒绝，需维护者选用兼容版本，不降低检查。
smoke 覆盖已改名为 `DEBATE_SMOKE_*`；旧名忽略且只提示一次。B 清除 A 的 app 环境后使用
CLI 默认位置的登录，原有 `CLAUDE_CONFIG_DIR`／`CODEX_HOME` 不再传递；前缀匹配的认证与服务方
选择变量也被清除，依赖它们的项目须先在默认位置登录。Codex 两种模式在 B 的工作目录先用
`mcp list --json` 枚举服务器，逐项追加 `enabled=false` 覆盖并复查全部禁用，之后才写启动日志和调用模型。
命令失败、列表结构不符、名称不匹配 `^[A-Za-z0-9_-]+$` 或仍有启用项时退出 2；该机制依赖 CLI
列表输出与名称寻址规则。CLI `0.167.0-alpha.4.1` 首次枚举会对 HTTP MCP 做 OAuth 元数据 GET 探测；
逐项禁用后的复查与执行在回环探针中没有连接，不能把预检称为全程无网络请求。
另关闭工作流列出的扩展及多代理工具并使用 `--ephemeral`；
保留用户提供方、代理和网络配置，不修改用户配置或更换配置目录。
smoke 按实际工具模式调用原生搜索，并分别检查具体连接器、通用资源接口和多代理工具，避免混淆。
定位、清除名单、功能关闭项和 [smoke 新旧变量对照](../../.harness/workflows/decision-review.md#运行审查方)
由工作流维护；登录可用性、实际连接边界和记忆目录是否变化需要另行授权实机验证。
功能名可能随 CLI 版本变化，离线检查只证明脚本合同，帮助检查不能证明功能名仍有效。
