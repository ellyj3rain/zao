# A3 - Corrections across the seam

| Field | Record |
|---|---|
| Batch | `A3` |
| Date | 2026-08-29 |
| Name | Corrections across the seam |
| Status | Closed append-only batch - play verification pending (no play receipt) |
| Threads | [`T-001`](THREADS.md#t-001), [`T-002`](THREADS.md#t-002) |

## Record

The operator's corrections, and the sister's answer to the repair prompt.

First the corrections. The engine's per-body fields (F-005) are actuators
the design projects onto, not the axis set — the design axes are ZAO's own
and new, inverse/mirror axes included; the roadmap's mutation-axes fork
carries the ruling. The corpse-side hands-off posture quoted from SAO's
code was ruled a gap, not a principle: SAO owns death of the person
completely — record, corpse identity, arming the turn — and the audit was
reworded so no session inherits the doctrine framing. The repair prompt
carried seven items to SAO, widened on operator direction with population
grounding (the census precedent extended to the dead) and a general
hardening sweep, and ZAO held behind it.

Then the answer. SAO's hardening landed (its 1.11.2.0 tip) and its fresh
javap pass falsified two of this repository's findings. Both
falsifications were re-derived here by hand before anything moved:
`IsoDeadBody` has THREE `copyTable` sites, not two — the constructor
copies the dying character's modData onto the corpse unconditionally at
the join point every path reaches (F-007 supersedes F-002's "nothing
fills it" half; stamping the living body suffices); and the descriptor
copy in the constructor is unguarded — the `instanceof IsoSurvivor`
protects only a survivor-list removal, so every non-animal corpse carries
the full descriptor, players included (F-008 supersedes F-003's
corpse-side half; the zombie-side half stands — the risen body's
descriptor is fresh and nameless, and the shared player-zombie descriptor
path no-ops in single player). The [A2] errors were an unverified repeated
count and a truncated-context inference; the corrected entries say so.

Adopted on the ratified contract: DR-013 mirrors SAO's DR-016/DR-019 —
the division at the seam, the `SAOPersonId` key read verbatim, the
crowd-ledger and identity-bearing-predicate composition rules, the `:`
encoding caution for Knox ids. `ENGINE_CONTRACT.md` §1 was corrected in
place against F-007/F-008, §9a records the contract and the sister's
verified arming chain (adopted with SAO's receipts F-044..F-047;
signatures spot-checked here, the full chain not re-derived), and the G0
ledger's first row became the gate.

The gate, stated for the next session: ZAO's mechanics stay closed until
the turn has one live receipt — a bitten SAO survivor witnessed dying,
leaving a named corpse, rising with `SAOPersonId` intact, and being
recognized. The operator's current SAO play sessions are expected to
produce it. This batch is evidence-trail correction and contract adoption
only; no mod code.
