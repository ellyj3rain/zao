# A19 - The state surface

| Field | Record |
| --- | --- |
| Batch | `A19` |
| Date | 2026-09-11 |
| Name | The state surface |
| Status | Closed append-only batch - implementation and records |
| Threads | [`T-001`](Batches/THREADS.md#t-001), [`T-002`](Batches/THREADS.md#t-002) |

## Record

ZAO gains its first runtime state surface. `ZAO_State.lua` defines the
pathogen state ZAO can honestly produce from the facts SAO already records:
terminal state, current form, form performance, decay state, and visible
forms.

A body with no assigned form is in the `none` form, and its performance is
zero. This is not an invented mutation; it is the state ZAO can produce
before form assignment exists.

`tools/state_dump.py` emits the same mapping to the dataset side, and
`tools/state_dump_test.py` is the border that checks the mapping and its
precedence.

## What changed

- `mod/42.20/media/lua/shared/ZAO_State.lua` defines the state surface.
- `tools/state_dump.py` emits the same state from SAO rows.
- `tools/state_dump_test.py` checks the mapping and its precedence.
- `tools/check.sh` runs the new border.
- `ARCHITECTURE.md` names the state surface.
- `SESSION_STATE.md` advances to this batch.
- `BATCH_LOG.md` gains the `[A19]` row.
- `tools/version_replay.py` classifies `[A19]`.

## Border

Border 3 checks the state producer’s mapping and precedence. Its controls
are contradictory facts: turned overrides dead, and dead overrides infected.

## Verification

`python tools/state_dump_test.py` passes, and `tools/check.sh` is clean.
