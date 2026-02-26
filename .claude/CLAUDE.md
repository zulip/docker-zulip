# CLAUDE.md - Guidelines for AI Contributions to docker-zulip

This file provides guidance to Claude (and other AI coding assistants)
for contributing to the docker-zulip codebase.

## Philosophy

**Focus on making the codebase easy to understand and difficult to
make dangerous mistakes.** Every change should make the codebase more
maintainable and easier to read.

Before writing any code, understand:

1. What the existing code does and why, including relevant documentation.
2. What problem you're solving, in its full scope.
3. Why your approach is the right solution, and available alternatives.
4. How you will verify correctness and avoid plausible regressions.

## Key Technologies

- **Shell (bash)**: Primary language. Scripts use `set -eux` and
  `set -o pipefail`. Linted by **shellcheck**.
- **Docker**: Multi-stage `Dockerfile`. Linted by **hadolint**.
- **Docker Compose**: Service orchestration (`compose.yaml`).
- **Helm**: Kubernetes deployment chart with Bitnami subcharts.
- **Sphinx/MyST**: Documentation in Markdown, hosted on ReadTheDocs.
- **YAML**: 2-space indent per `.editorconfig`.
- **Markdown**: Formatted by **prettier**, spell-checked by **typos**.
- GitHub Actions security: **zizmor**.

## Repository Structure

```
Dockerfile              # Multi-stage Docker image build
entrypoint.sh           # Runtime entrypoint (~750 lines); the core of this repo
compose.yaml            # Docker Compose: Zulip + PostgreSQL, Memcached, RabbitMQ, Redis
compose.override.yaml   # Development/customization overrides
manage.py               # Wrapper for Zulip's Django manage.py
upgrade-postgresql      # PostgreSQL major-version upgrade helper
docs/                   # Sphinx/MyST documentation source (ReadTheDocs)
docs/conf.py            # Sphinx config; extracts versions from compose.yaml + Chart.yaml
ci/                     # Integration tests (bash + curl against running containers)
ci/test-common.sh       # Shared end-to-end test functions sourced by ci/*/test.sh
helm/zulip/             # Helm chart for Kubernetes deployment
helm/zulip/ci/          # Values files for Helm lint/test scenarios
helm/zulip/tests/       # helm-unittest suites (one per template)
.github/workflows/      # CI: Docker build, shellcheck, prettier, typos, zizmor
```

## Configuration System (entrypoint.sh)

The entrypoint supports three configuration modes:

1. **Environment variables** (default): Prefixed variables are applied
   automatically.
2. **Manual configuration** (`MANUAL_CONFIGURATION=True`): The
   entrypoint skips automatic config; you manage files directly.
3. **Linked settings** (`LINK_SETTINGS_TO_DATA=True`): Settings files
   are symlinked into `/data` for persistence across rebuilds.

### Environment variable prefixes

- `SETTING_*` → written to Zulip's `settings.py` (with type
  inference: bool, int, list, string).
- `CONFIG_<section>__<key>` → set via `crudini` in config files.
- `SECRET_*` → written to Zulip's `zulip-secrets.conf`.

### Other entrypoint features

- **Docker secrets**: Read from `/run/secrets/zulip__*`.
- **Boolean normalization**: Accepts true/false, yes/no, 1/0,
  enabled/disabled.
- **Certificate modes**: manual, certbot/Let's Encrypt, self-signed,
  or HTTP-only (`DISABLE_HTTPS`).
- **App commands**: `app:run`, `app:init`, `app:managepy`,
  `app:backup`, `app:restore`, `app:certs`, `app:help`.

## Testing

### Docker Compose integration tests

- Each `ci/<scenario>/` directory has a `compose.yaml` and `test.sh`.
- `ci/test-common.sh` contains shared end-to-end checks: realm
  creation, authentication, message posting, event queue verification.
- CI runs a matrix over all `ci/*/` directories.

### Helm chart tests

- **Unit tests** use [helm-unittest](https://github.com/helm-unittest/helm-unittest).
  Test suites live in `helm/zulip/tests/`, one file per template.
  Each suite loads values from `helm/zulip/ci/*-values.yaml` and
  uses structural assertions (`equal`, `contains`, `matchRegex`,
  `hasDocuments`) to verify rendered output at specific paths.
  Run locally with `helm unittest helm/zulip/`.
- **Schema validation** uses kubeconform against all values
  scenarios.
- **Functional tests** deploy into a KIND cluster via
  `helm/zulip/ci/test.sh`.

## Workflow

Follow: **understand → propose → implement → verify**.

### 1. Understand Before Coding

```bash
# Read relevant documentation
cat docs/how-to/<relevant-area>.md

# Search for patterns in the codebase
git grep "functionName"
git log --oneline -20 -- entrypoint.sh
```

- Read the docker-zulip docs in `docs/` and at
  https://zulip.readthedocs.io/projects/docker/
- Use `git grep` to find similar patterns before proposing changes.

### 2. Propose an Approach

Before writing code, explain:

- Your understanding of the problem
- What changes are needed and why
- How changes fit existing patterns
- What could break and how to prevent regressions
- Always start by rebasing onto the latest `main`.
- Do a pre-mortem: how might this break existing behavior, or need
  to be reverted?

### 3. Implement in Minimal, Coherent Commits

Each commit should be self-contained, reviewable via
`git show --color-moved`, and pass lint/tests independently. If
extracting new files or moving code, do that in a separate commit.

### Code Style

- **Be consistent with existing code.** Look at surrounding code and
  follow the same patterns.
- **Use clear, greppable names.** Future developers will `git grep`
  to find relevant code.
- Prefer readable code over clever code with explanatory comments.
  Comments should explain "why", not "what".

## Commit Discipline

Each commit is a **minimal coherent idea**. This is non-negotiable.

### Each Commit Must:

1. **Be coherent**: One logical change, completely and atomically.
2. **Pass tests**: Include test updates in the same commit as code
   changes.
3. **Not introduce regressions**: Work is ordered so no commit makes
   things worse.
4. **Be minimal and reviewable**: Don't combine moving code with
   changing it; use small prep commits for no-op refactoring.

### Never:

- Mix multiple separable changes in a single commit.
- Create a commit that "fixes" a mistake from an earlier commit in
  the same PR; instead, use the rebasing techniques below to amend
  the original commit.
- Include debugging code, commented-out code, or temporary TODOs.
- Use "Also" in a commit message — it hints the commit should be
  split.

### Commit Message Format

```
subsystem: Summary in 72 characters or less.

The body explains why and how. Include context that helps reviewers
understand your reasoning and verification, without repeating details
visible in the diff metadata.

Line-wrap at 68-70 characters, except URLs and verbatim content.

Fixes #123.
```

**Subsystem prefix:** lower-case, before the colon. End summary with
a period.

- Good: `ci: Use GHCR registry cache for main branch Docker builds.`
- Good: `helm: Allow for adding annotations to the service.`
- Good: `entrypoint: Add support for AUTH_LDAP_* settings.`
- Bad: `Fix bug`, `Update code`, `gather_subscriptions was broken`

**Linking issues:**

- `Fixes #123.` — automatically closes the issue.
- `Fixes part of #123.` — does not close (for partial fixes).
- Never: `Partially fixes #123.` (GitHub ignores "partially").

### Rebasing Commits (Non-Interactive)

Since `git rebase -i` requires an interactive editor, use
`GIT_SEQUENCE_EDITOR` to supply the todo list via a script:

1. **Squashing fixups:** `git commit --fixup=<target-hash>`, then:

   ```bash
   GIT_SEQUENCE_EDITOR=/path/to/todo-script.sh git rebase -i <base>
   ```

   Note: `--autosquash` alone without `-i` does **not** reorder or
   squash anything.

2. **Rewording messages:** In the todo script, use `exec` lines:

   ```
   pick <hash> Original message
   exec GIT_EDITOR=/path/to/new-msg-script.sh git commit --amend
   ```

## Self-Review Checklist

- [ ] PR addresses all points in the issue
- [ ] Code follows existing patterns
- [ ] Names are clear and greppable
- [ ] Each commit is a minimal coherent idea
- [ ] Commit messages and PR description are well done
- [ ] No debugging code or unnecessary comments remain
- [ ] No secrets or credentials in environment variable defaults
- [ ] Documentation updated if behavior changes
- [ ] Refactoring is complete (`git grep` for remaining occurrences)

Always output a recommended PR summary+description following the
guidelines below.

## Pull Request Guidelines

### PR Description Should:

Output the PR description in a markdown code block so formatting
copy-pastes correctly into GitHub.

1. Start with a `Fixes: #...` line linking the issue.
2. Explain **why** the change is needed, not just what changed.
3. Link to relevant issues or discussions.
4. Call out open questions or decisions you're uncertain about.

### PR Description Should Not:

- Regurgitate information visible from the diff.
- Make claims you haven't verified.

## When to Pause and Discuss

- The approach involves security-sensitive code
- The change affects many files (>10)
- The feature design isn't fully specified
- Existing tests are failing for unclear reasons

## Key Documentation Links

- Commit discipline: https://zulip.readthedocs.io/en/latest/contributing/commit-discipline.html
- Docker environment variables: https://zulip.readthedocs.io/projects/docker/en/latest/reference/environment-vars.html
- Docker Compose guide: https://zulip.readthedocs.io/projects/docker/en/latest/how-to/compose-index.html
- Helm chart: `helm/zulip/README.md`
