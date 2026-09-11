# A15 - The remaining gate claims are removed

| Field | Record |
| --- | --- |
| Batch | `A15` |
| Date | 2026-09-11 |
| Name | The remaining gate claims are removed |
| Status | Closed append-only batch - records correction; no mod code |
| Threads | [`T-001`](THREADS.md#t-001), [`T-002`](THREADS.md#t-002) |

## Record

`[A14]` removed the rule that blocked ZAO's mechanics until a watched
turn exists. Three sentences in the living records still presented the
absence of code as something the process requires:

- the README said no mod code exists because the gate order asks for it;
- the engine contract's header said live receipts close G0, which closed
  at `[A6]` on structural evidence;
- the session state's retelling of `[A6]` carried the same no-code claim.

The gate ladder does not require the absence of code. G1 is passed on
observed behavior, and observing ZAO take a body needs ZAO code. This
batch corrects the three sentences to state facts: no mod code exists
yet, and `ENGINE_CONTRACT.md` section 10 lists what remains unverified.

## What changed

- `README.md` - the status line states the fact and drops the claim.
- `ENGINE_CONTRACT.md` - the header states what section 10 does.
- `SESSION_STATE.md` - the `[A6]` retelling states the fact and drops the
  claim; this batch is the new tip.
- The sister's `PROJECTS.md` carried the same claim in its ZAO row. It
  moves in the same turn, in the sister's repository.

## What did not change

The watched turn is still wanted evidence for the identity handoff. The
gate ladder stands. Play is still later, one project at a time, when the
operator says. Append-only records keep their text, including the `[A3]`
and `[A6]` originals; this record is the correction.

## No new border

A records correction in documents the doc-currency border already covers.
No mod code, no engine surface.
