# Repository Scripts

| Command | Purpose | Network |
| --- | --- | --- |
| `scripts/quality/check.sh` | Tools, Shell, Markdown, template integrity and offline regressions | None |
| `scripts/quality/check.sh --check-tools-only` | Required local tool versions | None |
| `scripts/quality/check.sh --pr PR --repo OWNER/REPO` | Local checks plus live PR contract | GitHub |
| `scripts/quality/check_template.sh` | Tracked files, local links, wiki ownership and CI entrypoint | None |
| `scripts/github/issue_status.sh` | Live contract/state checks and audited transitions | GitHub |
| `scripts/github/pr_contract.sh` | Live PR structure, branch and Issue association | GitHub |
| `scripts/github/review_convergence.sh RECORD.json` | Local review evidence structure | None |
| `scripts/quality/project_checks.sh` | Project-owned business checks; the template version checks nothing | Declared by the project |
| `scripts/quality/install_ci_tools.sh` | Explicit Linux x86_64 CI tool provisioning into runner temporary storage | Official downloads and npm |
| `scripts/quality/install_local_tools.sh [DIR]` | Linux x86_64 provisioning of the pinned lint tools into a new directory, `var/harness-tools` by default | Official downloads and npm |

The quality entrypoint invokes these tests once:

- `scripts/tests/test_issue_status.sh`
- `scripts/tests/test_pr_contract.sh`
- `scripts/tests/test_review_convergence.sh`
- `scripts/tests/test_quality.sh`
- `scripts/tests/test_template.sh`

Tests use disposable files and mocked GitHub clients. The template checker uses
its private Node.js implementation `scripts/quality/check_template.mjs`.
It checks local Markdown links and concrete repository path references outside
code fences, active wiki owners/source paths, necessary files and the CI entrypoint. The explicit `--source-audit` option
reads literal source markers from the provenance profile and scans extraction
residue; it is not a blanket restriction on downstream project vocabulary or assets. Template placeholders and external links are not fetched. Human review
still owns semantic correctness and external-link validity.

Installation is never part of the default read-only quality command. The CI
provisioner requires a CI environment; local setup follows the tool runbook.
The local installer verifies recorded digests, refuses an existing target and
accepts at most one relative or absolute directory. Unknown options and extra
arguments are rejected before downloads or writes. Installation is staged beside
the target, published only after success, and cleaned on failure. It does not
change `PATH`, system directories or the user's npm cache or global prefix;
prefix the directory's `bin` for the commands that need it. The quality entrypoint
does not automatically search the default `var/harness-tools` directory.

The quality entrypoint never runs `scripts/quality/project_checks.sh`. A project
puts its own regression commands there, CI runs it as a separate step, and the
file stays with the project when it adopts a harness update.
