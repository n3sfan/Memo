# Agent Guide

This file is the first thing every AI agent or teammate should read before
working in this repository.

## Project Summary

Memo is a mobile-first memory map app. The repo is a monorepo with:

- `apps/api`: NestJS backend API.
- `apps/mobile`: Flutter mobile app.
- `contract`: API and mobile/backend contract docs.
- `docs`: architecture and project documentation.
- `deploy`: deployment notes and templates.

The MVP is being built in small vertical slices. Prefer narrow, tested changes
that unblock other team members.

For product direction, MVP boundaries and future-phase non-goals, use
`docs/product-context.md`.

## Read These First

Before coding, read these files in this order:

1. `README.md`: local setup, Docker, run/test commands.
2. `docs/product-context.md`: product intent, MVP scope and non-goals.
3. `CONTRIBUTING.md`: commit, PR title and team conventions.
4. `docs/architecture-guidelines.md`: OCP/DIP/provider abstraction rules.
5. `contract/api-contract.md`: API envelope, auth, errors and endpoints.
6. `contract/mobile-data-layer-usage.md`: mobile repository/provider usage.
7. `contract/backend-api-skeleton.md`: backend route/module skeleton notes.

If a Jira ticket or user request conflicts with these docs, stop and surface the
conflict before changing code.

## Hard Rules

- Do not read, print, commit or expose `.env` values.
- Do not push directly to `main`.
- Work on a feature branch and open a PR.
- Use `pnpm`, not `npm`.
- Do not bypass or weaken tests/CI to make a change pass.
- Do not introduce direct vendor coupling in feature code.
- Do not revert changes you did not make unless explicitly asked.

## Branch And Commit Rules

Use a branch per task:

```text
feature/scrum-20-contract-smoke-tests
feature/pin-editor-mvp
fix/api-auth-error-envelope
```

Use Conventional Commits:

```text
feat(api): implement pin creation
fix(mobile): handle expired session
test(api): add contract smoke tests
chore(repo): update agent guide
docs(contract): clarify media upload flow
```

PR titles must follow the same format because `main` uses squash merge.

## Architecture Rules

Follow OCP and DIP for third-party dependencies.

Feature code should depend on project-owned ports/interfaces, not concrete
providers.

Examples:

```text
Map View -> MapViewportController -> Mapbox/OpenStreetMap adapter
MediaService -> ObjectStoragePort -> R2 adapter
AuthService -> OAuthProviderClient -> Google/Apple adapter
AuthorizationService -> AccessControlRepository -> Prisma adapter
```

Backend services should not spread Prisma queries directly. Put database access
behind domain repositories such as:

```text
AccessControlRepository
PinRepository
MediaRepository
InvitationRepository
ShareLinkRepository
```

Mobile UI should not call HTTP directly. Use:

```text
ApiClient -> Repository -> Provider -> UI
```

Map provider is not locked. Keep map code behind `apps/mobile/lib/map`
ports/adapters, and add concrete provider packages only inside the adapter task
that needs them.

## Backend Notes

The API uses NestJS.

Important locations:

- `apps/api/src/common`: envelopes, API errors, filters, shared DTOs.
- `apps/api/src/modules`: feature modules.
- `apps/api/src/infra`: provider adapters and infrastructure boundaries.
- `apps/api/prisma`: Prisma schema and migrations.
- `apps/api/test`: unit and integration tests.

Protected routes use `JwtAuthGuard`.

Standard API responses:

```json
{ "data": {}, "requestId": "req_..." }
```

Standard API errors:

```json
{ "error": "unauthorized", "message": "...", "details": {}, "requestId": "req_..." }
```

When changing backend contracts, update:

- `contract/api-contract.md`
- DTOs in `apps/api/src/modules/**/dto`
- mobile DTOs in `apps/mobile/lib/data/models`
- relevant contract smoke tests

## Mobile Notes

The mobile app uses Flutter, Riverpod, Dio, local cache skeletons and repository
interfaces.

Important locations:

- `apps/mobile/lib/data/models`: DTOs.
- `apps/mobile/lib/data/repositories`: repository interfaces and API impls.
- `apps/mobile/lib/data/mock`: fake repositories for feature development.
- `apps/mobile/lib/data/repository_providers.dart`: fake/real provider swap.
- `apps/mobile/lib/map`: map provider ports/adapters.

Feature UI should depend on repositories/providers, not Dio or backend URLs.

## Verification

Run the smallest relevant checks first, then broaden if the change crosses
module boundaries.

Backend:

```bash
pnpm api:build
pnpm api:test
pnpm api:test:contract
```

Mobile:

```bash
cd apps/mobile
flutter analyze
flutter test
```

Repo/commit:

```bash
pnpm commitlint:last
```

If Flutter is not on `PATH` on this machine, use:

```powershell
& 'C:\Users\Admin\dev\flutter\bin\flutter.bat' analyze
& 'C:\Users\Admin\dev\flutter\bin\flutter.bat' test
```

## Definition Of Done

A task is done when:

- The implementation matches the ticket/request.
- Public contracts and docs are updated when behavior changes.
- Relevant unit/integration/contract tests pass.
- No secrets are committed.
- The branch has a Conventional Commit message.
- A PR is opened with a Conventional Commit title.
