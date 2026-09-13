# A20 - The form registry and the pathogen roll

| Field | Record |
| --- | --- |
| Batch | `A20` |
| Date | 2026-09-11 |
| Name | The form registry and the pathogen roll |
| Status | Closed append-only batch - implementation and records |
| Threads | [`T-001`](Batches/THREADS.md#t-001), [`T-002`](Batches/THREADS.md#t-002) |

## Record

ZAO gains the form registry and the pathogen roll. The six source-port forms
are Puker, Husk, Skitter, Wrecker, Leaper, and Weeper. They are internal
candidate names, not player-facing copy.

The pathogen owns the roll. A body carries a form only when the pathogen has
already acted on it: infected, dead, or turned. A turned body has a 10
percent chance of taking one of the six forms, uniform across the candidates
by default and sandbox-configurable. Form performance is a normalized state
value between 0 and 1, not a gameplay number.

`ZAO_Forms.lua` implements the roll and the performance value.
`ZAO_State.lua` now consumes them, and `tools/state_dump.py` emits the same
state to the dataset side. `FORMS.md` is the canonical registry.

## What changed

- `FORMS.md` records the six forms, the 10 percent roll, and the normalized
  performance state.
- `mod/42.20/media/lua/shared/ZAO_Forms.lua` implements the form roll and
  performance value.
- `mod/42.20/media/lua/shared/ZAO_State.lua` consumes them.
- `tools/state_dump.py` emits the same state.
- `tools/state_dump_test.py` now checks a known form roll and a known
  performance value.
- `MEMORY.md` indexes `FORMS.md`.
- `SESSION_STATE.md` advances to this batch.
- `BATCH_LOG.md` gains the `[A20]` row.
- `tools/version_replay.py` classifies `[A20]`.

## Border

Border 3 still checks the state mapping and precedence. It now also checks
the known form roll for `sao-44` at hour 888 and the matching performance
value.

## Verification

`python tools/state_dump_test.py` passes, and `tools/check.sh` is clean.
