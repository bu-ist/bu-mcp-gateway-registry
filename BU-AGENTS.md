# BU fork rules

`bu-ist/bu-mcp-gateway-registry` is a fork of
[agentic-community/mcp-gateway-registry](https://github.com/agentic-community/mcp-gateway-registry).
BU builds all four gateway images from it because upstream never publishes
`metrics-service`. Decisions and history live in the notes
(`bu/projects/arm64-migration/gateway-images.md`), not here.

## Branches

- `main` mirrors upstream `main`. Fast-forward only, never commit to it. It
  is a reference, not a build input.
- `bu` is the build branch and the repository default (GitHub only dispatches
  workflows that exist on the default branch). It is never rebased or
  force-pushed: Actions runs and image labels point at `bu` shas.
- New upstream release: `git fetch upstream --tags`, fast-forward `main`,
  then `git merge <tag>` into `bu` (the tag, not `main`, which carries
  unreleased commits). Resolve conflicts in BU-patched files by hand, dispatch
  the build, tag the result `<tag>-bu.1`. BU changes remain visible with
  `git log --first-parent upstream/main..bu` or by diffing against the tag.

## What BU owns

Only these paths. Do not edit upstream files, workflows or instruction files;
that is what keeps the merges clean.

- `.github/workflows/bu-*.yml` and `.github/bu/`
- `BU-*.md`
- Deliberate source patches, one commit each, with the reason in the message.

Upstream workflows that run on a schedule fire here too, because `bu` is the
default branch. Do not edit them; disable them in the repository's Actions
settings (`gh workflow disable <file>`). Disabled so far: `dependency-update.yml`
(2026-09-21, it pushed a lockfile branch and failed on a missing label).

## Images and tags

Four images, upstream's names: `auth-server`, `registry` (nginx lives inside
it), `mcpgw`, `metrics-service`. Published tags are `<upstream tag>-bu.<n>`,
e.g. `1.30.0-bu.1`, and immutable, because the bytes are no longer upstream's.
