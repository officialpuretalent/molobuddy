# MoloBuddy Development Workflow

- **Status:** Accepted
- **Owner:** Engineering
- **Last updated:** 22 August 2026

## Branch names

Every non-default branch uses exactly this pattern:

```text
<type>/<short-kebab-case-summary>
```

Allowed branch types are:

| Type       | Use                                                 |
| ---------- | --------------------------------------------------- |
| `feat`     | New product or engineering capability               |
| `fix`      | Defect correction                                   |
| `security` | Security correction or hardening                    |
| `refactor` | Internal structural change with unchanged behaviour |
| `docs`     | Documentation-only change                           |
| `test`     | Test-only change                                    |
| `build`    | Build, dependency or packaging change               |
| `ci`       | Continuous-integration or automation change         |
| `chore`    | Maintenance that fits none of the above             |
| `hotfix`   | Urgent production correction                        |
| `release`  | Release preparation or release branch               |

Examples: `feat/accounting-connector-foundation`,
`fix/oauth-state-replay`, `security/webhook-signature-validation`.

Tool, person, model and workstation prefixes are prohibited. Do not create
`codex/`, `claude/`, `chatgpt/`, user-name or machine-name branches. The branch
describes the work, not the tool that created it.

Use one coherent concern per branch. Follow-up work belongs on a new branch
when it changes the purpose, risk profile or review audience.

## Commits and handoff

Use Conventional Commit-style summaries:

```text
feat(connectors): add transactional lifecycle ledger
fix(auth): reject stale region routes
docs(workflow): define branch naming policy
```

Before pushing a branch, run the affected formatting, static checks and tests;
run the Firestore emulator suite for any persistence change. The handoff notes
must name the branch, commit(s), verification performed, migrations/indexes,
and any external release gates. Never commit credentials, provider payloads,
emulator logs or local environment files.
