| Document | Zombie Awareness Overhaul Memory |
|---|---|
| Version | `0.1.1.14-pre-alpha` |
| Author | ellyj3rain |
| Repository | `MEMORY.md` |
| Status | ACTIVE - index of every root document and its standing. |

# Memory

Index of every document at the repository root, with what it is and whether
it is current. Nothing at the root is unclassified.

## Status vocabulary

| Status | Meaning |
|---|---|
| CANONICAL | Current truth. Edit in place when superseded. |
| CANONICAL, APPEND-ONLY | Current, extended through new entries; prior substance is fixed. |
| REGULATORY | Active index. May be corrected without rewriting what it organizes. |
| SHIM | Pointer file. |

## Canonical doc-pack

| File | Status | Role |
|---|---|---|
| `README.md` | CANONICAL | Human entry point. |
| `MEMORY.md` | CANONICAL | This index. |
| `CORE.md` | CANONICAL | Project identity, the two mechanisms, governing constraints. |
| `ARCHITECTURE.md` | CANONICAL | Ratified framework shape; the ownership seam; what is not ratified. |
| `GOVERNANCE.md` | CANONICAL | Operating discipline and judgement rules. |
| `DECISION_REGISTRY.md` | CANONICAL, APPEND-ONLY | Ratified decisions from DR-001. |
| `FINDINGS.md` | CANONICAL, APPEND-ONLY | Verified engine findings from F-001; empty by design until G0. |
| `BATCH_LOG.md` | REGULATORY | Chronological index for the batch sequence. |
| `VERSION_MAP.md` | REGULATORY | The version machine's rendering over the closed chronology. |
| `ROADMAP.md` | CANONICAL | Gate order and the open-fork ledger. |
| `SESSION_STATE.md` | CANONICAL | Where the work actually stands. |
| `ENGINE_CONTRACT.md` | CANONICAL, INCOMPLETE | The verified engine mechanics the turned require; live-unverified throughout. |
| `SAO_SEAM_AUDIT.md` | CANONICAL | Reference audit of the sister at the turn; collision points and precedents. |
| `VERSION` | CANONICAL | The machine's output. Every root header's `Version` cell reads this and nothing else. |
| `LICENSE` | CANONICAL | GPL-3.0. |
| `CREDITS.md` | CANONICAL | Attribution and integration status per source; every entry states what was taken and what was not. |
| `MUTATION.md` | CANONICAL | The mutation system as the operator defined it: what the pathogen does to a body and what that body becomes, with every dial named. |

## Instruction surface

| File | Status | Role |
|---|---|---|
| `NEO.md` | CANONICAL | The instruction surface. Read first. |
| `CLAUDE.md` | SHIM | Autoload pointer to `NEO.md`. |
| `AGENTS.md` | SHIM | Autoload pointer to `NEO.md`. |

## Directories

| Path | Role |
|---|---|
| `Batches/` | One alphanumeric batch sequence; one record per closed batch; the thread index. |
| `tools/` | The evidence apparatus: the borders, `check.sh`, the version machine, the pre-commit hook. |
