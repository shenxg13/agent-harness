# Agent Entry

Explicit user authorization defines the current task. Keep confirmed
requirements, pending proposals and implemented behavior distinguishable.

## Read By Task

- Copy or string edit: read the target file and its direct constraints.
- Non-trivial development or process change: read `.harness/index.md` and
  `.harness/rules.md`, use `.harness/catalog.md` to select the applicable
  workflow, and inspect the relevant source before editing.
- Work that touches project requirements: select topics from
  `.project-wiki/index.md`; follow cross-topic links only where the task
  touches them.
- Before running repository tools or diagnosing the environment: read
  `.harness/tooling-runtime.md`.
- Knowledge updates: follow `.harness/workflows/wiki-update.md` and
  `.project-wiki/methods/knowledge-maintenance.md`, and edit the topic that
  owns the rule.

Reuse instructions already read while they still apply. This entry and the wiki
index hold routes; detailed requirements are not repeated here.

## Lifecycle

Before the first GitHub remote exists, follow
`.harness/workflows/local-bootstrap.md`: confirm scope, plan and test cases,
then implement and record local verification. Connect the remote only when
its owner, name, visibility and publication scope are authorized.

After connection, requirements, Issue implementation, review and handoff follow
`.harness/workflows/github-planning.md`. `status:*` labels own execution state.
Start unclaimed work only from `status:planned`; resume `status:in-progress`
only with an explicit handoff and no concurrent owner. Use
`scripts/github/issue_status.sh` for transitions and checks. A temporarily
unreachable or removed remote does not reset an existing Issue lifecycle.

Issue titles, bodies, workflow comments and PR bodies default to Chinese.
Requirements work permits clarification and bounded read-only investigation;
implementation and independent review own changes and full acceptance checks.
Confirmed scope changes must update the live Issue contract before implementation.
The workflow defines reopening, follow-up and completion rules.

## Tool And Network Boundaries

Use the current session's filesystem, network and approval policy. When a
network-restricted sandbox blocks GitHub, use a narrowly scoped authorized
outside-sandbox invocation. A network error is not evidence of a bad token;
follow the diagnostic sequence in `.harness/tooling-runtime.md`.

## Quality And Knowledge

`scripts/quality/check.sh` runs offline harness checks. The `--pr` mode reads
GitHub and requires separately authorized network access. Project-specific
checks are declared in project knowledge, run through the project-owned
`scripts/quality/project_checks.sh` entry, and are added explicitly to
delivery plans.

When a durable requirement or workflow changes, update the owning topic and
leave a summary with a link in the log. Change the wiki index only for
navigation and this entry only for agent-wide rules.
