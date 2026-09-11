# A14 - The invented gate is removed

| Field | Record |
| --- | --- |
| Batch | `A14` |
| Date | 2026-09-11 |
| Name | The invented gate is removed |
| Status | Closed append-only batch - records correction; no mod code |
| Threads | [`T-001`](THREADS.md#t-001), [`T-002`](THREADS.md#t-002) |

## Record

A rule in this repository said ZAO's mechanics stay closed until one
watched turn exists: a bitten SAO survivor dying, leaving a named corpse,
rising with `SAOPersonId` intact, and being recognized. The rule was
written by an assistant at `[A3]`, carried into DR-013's consequences and
`ENGINE_CONTRACT.md` §10.1, and presented as the operator's.

The operator ruled on 2026-09-11 that they never made the rule and that
it blocks itself: ZAO has no game code, so a watched turn inside ZAO
cannot happen yet, and work that waits for it can never start. This batch
removes the rule from the living records. DR-016 records the ruling.

## What changed

- `SESSION_STATE.md` - the gate section is replaced by a plain statement
  of the wanted evidence; the line that said no mod code exists by
  design of the gate is corrected; the open-items line no longer says
  "behind the gate".
- `ENGINE_CONTRACT.md` §10.1 - the watched turn is a named, unverified
  observation. The claim that it gates all ZAO mechanics is gone, and so
  is the expectation that the operator's current play sessions produce
  it.
- `DECISION_REGISTRY.md` - DR-016 records the ruling and supersedes the
  gate sentence in DR-013's consequences.
- `Batches/THREADS.md` - T-002 no longer says the watched turn gates
  ZAO's mechanics. The batch lists had stopped at `A6`; they now carry
  every batch through `A14`.

## What did not change

The watched turn is still wanted evidence for the identity handoff. The
gate ladder in `ROADMAP.md` stands. Play is still later, one project at a
time, when the operator says. Closed batch records keep their text,
including `[A3]`'s; this record is the correction.

## No new border

A records correction in documents the doc-currency border already covers.
No mod code, no engine surface.
