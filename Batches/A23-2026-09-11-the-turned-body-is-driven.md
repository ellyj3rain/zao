# A23 - The turned body is driven

| Field | Record |
| --- | --- |
| Batch | `A23` |
| Date | 2026-09-11 |
| Name | The turned body is driven |
| Status | Closed append-only batch - implementation and records |
| Threads | [`T-001`](Batches/THREADS.md#t-001), [`T-002`](Batches/THREADS.md#t-002) |

## Record

ZAO now drives the turned body.

`ZAO_Controller.lua` claims every zombie that carries `SAOPersonId`, writes
the ZAO ownership mark into its modData, and drives that body from the pathogen
state:

- a `Puker` holds range and moves to a firing tile;
- a `Husk`, `Wrecker`, `Leaper`, or `Weeper` closes on the target;
- a `Skitter` flanks before closing.

The controller writes `ZAOForm` and `ZAOFormPerformance` into the body's
modData, so the sister's Perception scanner can read the same facts a survivor
can see.

## What changed

- `mod/42.20/media/lua/client/ZAO_Controller.lua` owns and drives the body.
- `FORMS.md` now states that forms drive movement.
- `SESSION_STATE.md` advances to this batch.
- `BATCH_LOG.md` gains the `[A23]` row.
- `tools/version_replay.py` classifies `[A23]`.

## Verification

`bash tools/check.sh` is clean.
