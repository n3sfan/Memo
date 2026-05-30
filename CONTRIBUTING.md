# Contributing

For AI agents or teammates joining the project, start with `AGENTS.md`.

## Commit And PR Title Convention

Use Conventional Commits for local commits and pull request titles:

```text
<type>(<scope>): <message>
```

Examples:

```text
feat(api): add jwt auth guard
fix(mobile): handle expired session
chore(deps): update flutter packages
docs(contract): document auth error model
test(api): add authorization resolver specs
ci(github): add pr title validation
refactor(api): extract permission helpers
```

Allowed types:

- `feat`: new user-facing or developer-facing capability
- `fix`: bug fix
- `chore`: maintenance, tooling or repo housekeeping
- `docs`: documentation only
- `test`: tests only
- `refactor`: behavior-preserving code change
- `ci`: GitHub Actions or CI/CD changes
- `build`: build system, dependency or package changes
- `perf`: performance improvement
- `style`: formatting or style-only changes
- `revert`: revert a previous change

Recommended scopes:

```text
account, api, auth, ci, contract, db, deps, docs, duo, github, infra, maps,
media, mobile, pins, repo, share, timeline
```

Scopes are optional and are not restricted to this list. Use a clear free-form
scope when a change naturally belongs somewhere else, for example:

```text
feat(notification): add reminder preferences
fix(upload): handle large images
chore(jira): update sprint workflow
```

## Local Setup

Install dependencies with pnpm:

```bash
pnpm install
```

The root `prepare` script installs Husky. After that, the `commit-msg` hook runs
commitlint and rejects invalid commit messages before they are created.

Manual check for the latest commit:

```bash
pnpm commitlint:last
```

## Pull Requests

Use squash merge into `main`. The squash commit title comes from the PR title,
so the PR title must also follow Conventional Commits.

The `PR Title` GitHub Actions check validates this format on every pull request.

## Architecture

Follow the provider abstraction rules in `docs/architecture-guidelines.md`.
Feature code should depend on project-owned ports/interfaces, not concrete
third-party providers such as Mapbox, OpenStreetMap, R2, Google OAuth, Apple
OAuth, Prisma or Redis.
