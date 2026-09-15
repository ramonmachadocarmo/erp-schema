# erp-schema

Shared wire-contract schemas for the ERP system, codegen'd to Go, TypeScript, and Dart.

## What this is — and isn't

This repo defines the **JSON shape that crosses the wire** for a small, deliberately curated
set of entities — not each service's internal domain model. A service's
`internal/domain/*.go` structs stay private to that service and are never replaced by
anything generated here; generated types are consumed only at the HTTP (de)serialization
boundary, mapped to/from the internal domain type by a small handler-local function.

Most entities in the system are **intentionally not shared** here (`Product`, `Person`,
`OrderItem`/`QuoteLine`-style line items, etc.) because each service shapes them differently
for its own bounded context, and that's correct microservices design — not something to
"fix" by force-unifying. Only add a schema here when a shape is **genuinely identical**
across 2+ consumers (like `Address`, duplicated byte-for-byte between sales-service and
config-service before this repo existed) or when an entity has already caused a real
cross-language drift bug (like `Quote`, whose mobile representation silently fell out of
sync with the web/backend one).

## Layout

```
schemas/            JSON Schema (2020-12) source of truth, one file per entity
  common/           Shapes genuinely shared by 2+ consumers (e.g. Address)
  purchasing/       Entities scoped to one service, still worth generating for 3 languages
generated/
  go/               module erp-schema — plain structs, json tags, one flat `model` package
  ts/               @erp/schema — TypeScript interfaces/enums
  dart/             erp_schema — Dart classes with fromJson/toJson
```

## Regenerating

```
npm install        # once, for quicktype + typescript
make generate       # regenerates all three targets from schemas/
make verify          # go build+vet, tsc --noEmit, dart analyze
```

Never hand-edit anything under `generated/` — it's overwritten on every `make generate`.
`go-jsonschema` (Go target) is a separate binary, not an npm dep:
`go install github.com/atombender/go-jsonschema@latest`.

## Adding a new entity

1. Confirm it's actually shared (see "What this is" above) or has already caused drift.
2. Write `schemas/<area>/<entity>.schema.json`. Use `$defs` + `"title"` for nested/enum
   types so codegen names them sensibly instead of inferring a generic name. Mark
   server-computed fields (id, status, computed totals, created_at) as not `required` so
   one type can serve both request and response shapes.
3. Add the new file to `SCHEMAS` in the `Makefile`, `make generate && make verify`.
4. Bump the version in `generated/{go,ts,dart}`'s manifest and add a `CHANGELOG.md` entry —
   call out breaking field changes explicitly, since three independently-deployed
   ecosystems consume this.

## Consuming this repo locally (no remote git host yet)

This repo is nested **inside** the main `erp` checkout, at `erp/schema` — its own independent
git history (not a submodule, `erp`'s `.gitignore` excludes it from that repo's tracking), just
physically co-located for workspace convenience and so relative-path dependencies resolve inside
every Docker build context. `erp/mobile` (the Flutter app, also its own nested repo) lives at the
same level, so `schema` and `mobile` are siblings of each other under `erp/`.

- **Go**: `erp/go.work` has `use ./schema/generated/go`. Each consuming service's `go.mod` needs
  a plain `require erp-schema v0.0.0-00010101000000-000000000000` line — no `replace` needed
  while the workspace `use` is active.
- **TypeScript**: in `erp/apps/web/packages/shared/package.json`:
  `"@erp/schema": "file:../../../../schema/generated/ts"` (4 levels — the package.json lives 4
  directories under `erp/`: `apps/web/packages/shared/`). Because `schema/` now lives inside
  `erp/`, it's included in every Docker build context by default (`.dockerignore` doesn't
  exclude it) — the previous hard blocker, where `apps/web`'s `Dockerfile.dev` couldn't see a
  sibling checkout outside `erp/` at image-build time, is resolved by this move, not by needing
  a remote git host. `npm install` still needs to be re-run once after this path changes to
  refresh the `file:` copy/symlink.
- **Dart**: in `erp/mobile/pubspec.yaml`:
  ```yaml
  dependencies:
    erp_schema:
      path: ../schema/generated/dart
  ```
  (1 level — `mobile/` and `schema/` are both direct children of `erp/`.)

Once this repo has a remote: Go → tag + `go get erp-schema@vX.Y.Z` (drop the `use` line);
npm → `"@erp/schema": "git+https://.../erp-schema.git#vX.Y.Z"`; Dart →
`git: {url: ..., path: generated/dart, ref: vX.Y.Z}`.
