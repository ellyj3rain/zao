# Continuous integration

ZAO runs the same discipline as SAO and CAO, adapted to this repository's
Project Zomboid and governed-history contracts.

| Check | Contract |
|---|---|
| `ci-verify` | Checks committed diff hygiene and runs the full border gate (`tools/check.sh`). Border 15 receives the exact merged SAO C83 source tree; borders that require the installed game still report SKIPPED rather than passing. |
| `codeql-python` | Advisory code scanning over `tools/` on pull requests, `main`, and the weekly schedule. |

`ci-verify` is the required merge gate on `main` and is also the pre-commit
hook's content. CodeQL is an additional signal; a service delay in it does not
move the repository's deterministic merge boundary.

There is no dependency scan because there is no dependency graph to scan:
the mod ships Lua and, when it has one, a self-built Java jar, and `tools/`
runs on the Python standard library alone. If a dependency manifest ever
enters the tree, this note is wrong by construction and the workflow is added
with it.

CI never deploys into the operator's Project Zomboid installation, launches
the game, edits a save, or claims play acceptance.

## What this repository does not yet have that SAO does

Named so the gap is a decision rather than an oversight.

- **No `gate_reach_test.py`.** SAO's gate proves every mirror in `tools/` is
  wired into `check.sh`, because thirty-three of its mirrors once existed and
  eleven ran. ZAO currently names all fifteen borders in `check.sh` directly.
  The reachability border remains outstanding.
- **No `RECEIPTS.md`.** SAO carries one under DR-025 because its doc-pack was
  claiming perpetual untestedness. ZAO has no such claim to retire and no play
  evidence yet; the ledger arrives with the first observation.
