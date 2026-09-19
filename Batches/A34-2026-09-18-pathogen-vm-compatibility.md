# A34 - Pathogen VM compatibility

| Field | Record |
| --- | --- |
| Batch | `A34` |
| Date | 2026-09-18 |
| Name | Pathogen VM compatibility |
| Status | Closed implementation batch; play receipts pending |
| Threads | [`T-001`](THREADS.md#t-001), [`T-002`](THREADS.md#t-002) |

## Record

The recovery audit found an unfinished correction in `ZAO_Pathogen.lua`.
The installed Build 42.20 Kahlua environment supplies `pairs` and has no
global `next`. The original emptiness check failed during pathogen begin;
SAO's protected call could swallow that failure and leave a joint simulation
without the pathogen state it claimed to measure.

The existing correction is retained: a local table walk detects entries.
Border 5 loads the actual StateStore, Forms and Pathogen modules into the
installed VM. It verifies an empty mutation table, repeated begin without
rerolling an existing attribute, persistence, malformed legacy attributes,
and the crossed terminal form. Replacing the correction with the original
`next` call causes the VM to fail with its missing-call error.

The integrated scheduler probe also found full-day pathogen growth at the
initial fraction of day zero. `begin` now advances an existing state through
its accrued prior day before applying the new event, then stamps that event's
day. `advance` refuses repeated or backward days. A legacy state with no date
establishes its first known day without inventing elapsed progression. The VM
probe verifies begin-day, next-day, repeat, backward, transition and legacy
cases; disconnecting the clock guard fails the same-day observation.

The live controller's State projection now carries both clock fields through
its store write. Missing calendar days replay the existing nonlinear daily
body, including reversion and identity-decay draws, in chronological order.
Crossed remains terminal when SAO emits later infection, death, turn or
recovery events; the external event stays in history without rerolling the
pathogen or restarting the bridge course.

## Verification

`python tools/pathogen_vm_test.py` passes on the installed engine and rejects
the original code. The gate includes this check and reports an explicit skip
on machines without the engine and JDK. The complete native Git Bash gate passes with the installed engine and JDK:
all 15 Lua structural checks and all five borders, including actual Java build
and actual VM execution. No checks skipped. Five named controls reject missing
`next`, repeated same-day growth, lost projected clocks, skipped day replay,
and crossed-state overwrite. The local integration probe loads the real SAO
PathogenEvents emitter; a standalone checkout explicitly skips only that
additional sibling assertion.

## Operator boundary

These checks verify pathogen state in the engine's Lua VM. They do not claim
an observed in-game turn, body return, combat interaction or balanced outbreak.
