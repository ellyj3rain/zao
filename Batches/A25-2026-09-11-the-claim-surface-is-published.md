# A25 - The claim surface is published

| Field | Record |
| --- | --- |
| Batch | `A25` |
| Date | 2026-09-11 |
| Name | The claim surface is published |
| Status | Closed append-only batch - implementation and records |
| Threads | [`T-001`](Batches/THREADS.md#t-001), [`T-002`](Batches/THREADS.md#t-002) |

## Record

ZAO now publishes a read-only query surface. Other mods can ask:

- `ZAO.owns(zombie)` — whether ZAO owns the body
- `ZAO.formOf(zombie)` — the body's current form
- `ZAO.performanceOf(zombie)` — the body's normalized form performance

This closes the reserved claim-surface fork with a plain Lua API.

## What changed

- `mod/42.20/media/lua/shared/ZAO_API.lua` publishes the query surface.
- `DECISION_REGISTRY.md` gains DR-024.
- `ROADMAP.md` closes the claim-surface fork.
- `SESSION_STATE.md` advances to this batch.
- `BATCH_LOG.md` gains the `[A25]` row.
- `tools/version_replay.py` classifies `[A25]`.

## Verification

The ZAO gate is clean.
