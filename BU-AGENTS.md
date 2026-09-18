# BU fork rules

`bu-ist/bu-mcp-gateway-registry` is a fork of
[agentic-community/mcp-gateway-registry](https://github.com/agentic-community/mcp-gateway-registry).
BU builds all four gateway images from it because upstream never publishes
`metrics-service`. Decisions and history live in the notes
(`bu/projects/bu-mcp-gateway-registry/`), not here.

## Branches

- `main` mirrors upstream `main`. Never commit to it.
- `bu` is the build branch: an upstream release tag plus BU commits on top.
  On a new upstream release, rebase `bu` onto the new tag; BU commits stay a
  short, readable stack (`git log <tag>..bu`).

## What BU owns

Only these paths. Do not edit upstream files, workflows or instruction files;
that is what keeps the rebase clean.

- `.github/workflows/bu-*.yml` and `.github/bu/`
- `BU-*.md`
- Deliberate source patches, one commit each, with the reason in the message.

## Images and tags

Four images, upstream's names: `auth-server`, `registry` (nginx lives inside
it), `mcpgw`, `metrics-service`. Published tags are `<upstream tag>-bu.<n>`,
e.g. `1.30.0-bu.1`, and immutable, because the bytes are no longer upstream's.
