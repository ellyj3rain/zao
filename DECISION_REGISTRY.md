| Document | Zombie Awareness Overhaul Decision Registry |
|---|---|
| Version | `0.1.1.3-pre-alpha` |
| Author | ellyj3rain |
| Repository | `DECISION_REGISTRY.md` |
| Status | CANONICAL, APPEND-ONLY - ratified decisions. |

# Decision registry

Append-only. A superseding decision references what it supersedes; prior
entries are never rewritten. Every entry below is ratified from operator
direction of 2026-08-29 at project genesis; the operator's words are the
source, restated without the ideation prose around them.

---

## DR-001 — Two mechanisms in one county, litigated separately

**Date** 2026-08-29 08:15 UTC / 2026-08-29 01:15 PDT
**Status** RATIFIED (operator-directed)

**Decision.** ZAO is two mechanisms: zombie intelligence (modeled decay and
neurodegeneration of the turned mind) and decay/mutation (the pathogen's own
mechanics). They sit in the same county, cross-integrate, and are never the
same mechanic.

**Rationale.** Litigating them separately lets the pathogen hook other mods
without ZAO pretending those mods do not exist and without requiring them,
and keeps "the zombies got smarter" distinct from "this body recovered" or
"this body mutated" — events that are not the same and must not read as one.

**Consequences.** No spec, sandbox surface, or code path may merge the two to
look clean. A change to retention speaks to mechanism one; a change to
routes, courses, or mutation speaks to mechanism two.

---

## DR-002 — The rotting mind is the record

**Date** 2026-08-29 08:15 UTC / 2026-08-29 01:15 PDT
**Status** RATIFIED (operator-directed)

**Decision.** What a turned body knows and does is the SAO person's own
record decaying — what they had already perceived, what they could still do,
how they moved, whether they could hold a tool. The composition is SAO's
four pillars with decay operating on each pillar's record; ZAO adds no fifth
pillar and no second planner.

**Rationale.** A new species brain pasted onto a walker reproduces the exact
failure SAO exists to kill: a decision function omniscient about geometry
and oblivious about the person. Extending SAO's law — identity is a record;
the engine object is a temporary body — across death is what makes ZAO a
sibling rather than a monster generator.

**Consequences.** Early post-turn tool use is retention of verbs the person
carried in, never addition. No map omniscience. A turned body with no
surviving record has nothing to act from beyond what the engine's own zombie
senses grant. Retention only subtracts over time.

---

## DR-003 — Zombification is a spread of outcomes

**Date** 2026-08-29 08:15 UTC / 2026-08-29 01:15 PDT
**Status** RATIFIED (operator-directed)

**Decision.** Zombification is not one outcome. The Knox mutation is one
default in the spread, not the only landing. Verbs and record fall off at
different speeds on different bodies: some dump fast into an ordinary
shambler, some keep more of the record for longer.

**Rationale.** Variability is required by direction; one uniform decay curve
is the species-brain failure wearing a different coat.

**Consequences.** Per-body variation is a first-class input to mechanism
one's rates, drawn from mechanism two's course. Rarity numbers and enable
defaults for the spread's tails are reserved to the operator (`ROADMAP.md`).

---

## DR-004 — One brain per body; the turn is the ownership seam

**Date** 2026-08-29 08:15 UTC / 2026-08-29 01:15 PDT
**Status** RATIFIED (operator-directed)

**Decision.** Living people are SAO's until the turn. After the turn, if ZAO
is on, ZAO owns that body; if ZAO is off, vanilla handles the corpse. Knox
Survivors may be in the load order; it does not own the infected. Never two
brains on one corpse.

**Rationale.** Double ownership is the classic NPC-mod collision: two
controllers correcting each other produces behavior neither authored.

**Consequences.** ZAO's enable state is a hard gate on every code path that
touches a body. The handoff at the turn is a designed surface, verified at
G1 (`ROADMAP.md`), not an emergent property.

---

## DR-005 — Recovery mods are inputs, never dependencies

**Date** 2026-08-29 08:15 UTC / 2026-08-29 01:15 PDT
**Status** RATIFIED (operator-directed)

**Decision.** ZAO does not depend on Antibodies or its cousins (They Knew,
The Only Cure). Where loaded, their antibody, recovery, cure, and
repeat-infection state — including the modifiers and moodles they already
put on screen — are inputs to ZAO. Where not loaded, ZAO runs a course of
its own.

**Rationale.** Awareness of the ecosystem without dependence on it: the
county should get richer when those mods are present and remain whole when
they are absent.

**Consequences.** Integration reads their state; it never writes their
internals and never requires their presence. A character coming out immune
to Knox, or staying a person with function, are events on mechanism two,
distinct from anything mechanism one does.

---

## DR-006 — Settlement formation by the turned: real, rare, whole

**Date** 2026-08-29 08:15 UTC / 2026-08-29 01:15 PDT
**Status** RATIFIED (operator-directed)

**Decision.** A group of the turned can sometimes form a settlement the way
living survivors form one: a new place, kept, occupied, grouped. It is rare
on purpose. It ships whole — path, group, claim, tools, occupancy — or not
at all.

**Rationale.** This is the mechanic that makes ZAO a genuine parallel
project rather than an ambience layer: the fun and the difficulty. Not a
pile at a car alarm; not only standing in the house they already had.

**Consequences.** Rarity is a tuning fact and never a licence to stub any
member of the mechanic. The behavior must be robust enough to watch. Rarity
numbers themselves are reserved to the operator.

---

## DR-007 — Knox is defined on two ledgers

**Date** 2026-08-29 08:15 UTC / 2026-08-29 01:15 PDT
**Status** RATIFIED (operator-directed)

**Decision.** Knox is defined epidemiologically — what the pathogen does to
bodies and through which routes — and epistemologically — what anyone in the
county is permitted to know: moodles, rumor, what SAO already permits a
person to perceive. Never a percentage on the forehead.

**Rationale.** A pathogen whose ground truth leaks to every observer is the
omniscience defect applied to disease; the county's knowledge of Knox must
travel the same channels as every other fact.

**Consequences.** Mechanism two carries both ledgers from the start. Player-
facing readability uses existing moodle art where it already reads.

---

## DR-008 — Outcomes are distinct and sit on separate axes

**Date** 2026-08-29 08:15 UTC / 2026-08-29 01:15 PDT
**Status** RATIFIED (operator-directed)

**Decision.** Mutation moves on separate axes, and its outcomes are
distinct: a body can go past ordinary zombie; a still-human, bloodlusted
type is its own outcome and not a grade of anything else; a mutant is past
that and is a third thing. These are never flattened into one type.

**Rationale.** The axes are the gameplay deviation — beyond "smarter walker"
and beyond "still looks like a person and wants blood." Flattening them
forfeits exactly what makes the mechanism worth building.

**Consequences.** The axes themselves are **unratified** and reserved to the
operator, with one operator-proposed candidate on the table: hybridization
as a form of mutation, able to move both directions, good and bad — and
distinct from the still-human bloodlusted type, which is not a hybridization
grade. Strain names are the operator's. Whether the player walks the same
axes as NPCs is the operator's. All live in `ROADMAP.md`'s fork ledger until
ratified here.

---

## DR-009 — The version is a machine (CAO's model, adopted)

**Date** 2026-08-29 08:15 UTC / 2026-08-29 01:15 PDT
**Status** RATIFIED (house standard)

**Decision.** The version coordinate is the output of
`tools/version_replay.py`: CAO's model (`major.minor.kohai.patch-maturity`,
caps 12/16/24, cap movements roll the tier above, maturity moves only on
play receipts), adopted whole as SAO adopted it at its DR-013. One unit per
closed batch; the tier table in that file is the only input; names, dates,
and threads derive from `BATCH_LOG.md`.

**Rationale.** Nobody picks the number. Classify the work; the replay emits
the coordinate.

**Consequences.** On every batch close: add the batch's row to `UNITS` with
its tier and argument, run `python tools/version_replay.py --write`, and
restamp the doc headers. `VERSION` and `VERSION_MAP.md` are never edited by
hand. The gate holds every stated version to the replay.

---

## DR-010 — Standalone and an integrated sister, both

**Date** 2026-08-29 09:10 UTC / 2026-08-29 02:10 PDT
**Status** RATIFIED (operator-directed: "it can both be standalone and a fully integrated sister")

**Decision.** ZAO reads SAO's record at the turn where SAO is present, and
derives a thin record for a turned body where SAO is absent. It never
requires SAO, and it never ignores SAO where SAO is loaded.

**Rationale.** The same posture DR-005 takes toward the recovery mods,
applied to the sister: richer beside her, whole without her. A person SAO
tracked for weeks must not turn into a stranger.

**Consequences.** The record layer has one shape with two sources — read or
derived — and everything downstream of it is source-blind. No ZAO feature
may branch on "is SAO installed" beyond the record source itself.

---

## DR-011 — The ambient dead carry derived records

**Date** 2026-08-29 09:10 UTC / 2026-08-29 02:10 PDT
**Status** RATIFIED (operator-selected)

**Decision.** The county's preexisting zombies — turned before anyone was
watching, with no tracked person behind them — draw a decayed thin record
from where they stand, on SAO's world-origin precedent: a body in a house
was plausibly its occupant.

**Rationale.** Without this, the county's millions stay ordinary shamblers
forever and settlement formation (DR-006) could only ever involve the
recently dead. Mechanism one must cover the whole county.

**Consequences.** Derivation is a record source under DR-010's one-shape
rule. What a derived record may plausibly contain is bounded by where the
body is and what it wears and carries — never by what the encounter would
find convenient.

---

## DR-012 — The player walks an axis where the loop supports it

**Date** 2026-08-29 09:10 UTC / 2026-08-29 02:10 PDT
**Status** RATIFIED (operator-directed: "wherever it makes sense in the gameplay loop; by design some things only make sense because they are NPCs")

**Decision.** Whether the player experiences a given mutation outcome is
decided per outcome by whether the gameplay loop supports it — not by a
blanket yes or no. Some outcomes exist only for NPCs, by design, because
they only make sense uncontrolled by a human.

**Rationale.** The operator's rule verbatim. A spread built for watching
the county is not automatically a spread built for playing, and forcing
symmetry either way is the flattening DR-008 forbids.

**Consequences.** Every outcome region that ships states its player-side
answer at the batch that builds it, with NPC-only as the default until
stated. Player-facing outcomes must close their loop (agency, feedback,
an ending) before shipping as playable.

---

## DR-013 — The identity contract at the seam, adopted from the sister

**Date** 2026-08-29 (after SAO's ontology hardening, its 1.11.2.0 tip)
**Status** RATIFIED (mirrors SAO DR-016 and DR-019, operator-ratified
there 2026-08-29; extends DR-004 and DR-010)

**Decision.** The division at the seam, as ratified on the SAO side: SAO
owns death of the person completely — the record, the corpse's identity,
and arming the turn under the game's own rules. ZAO owns the risen brain
when installed and on; one brain per body (DR-004 unchanged). The identity
key is SAO's **`SAOPersonId`**, stamped on the living body's modData and
carried by the engine through corpse and reanimation (F-007); ZAO reads
exactly that string and never mints a parallel key for people SAO tracks.

**Rationale.** One key, one accounting, one owner per fact. The engine
performs the whole relay itself; a second channel would be drift waiting
to happen.

**Consequences.** ZAO's derived records for the ambient dead (DR-011) use
ZAO's own keying only where no `SAOPersonId` exists, and yield to it where
one does. Knox ids contain `:`, so ZAO wire protocols that separate on `:`
encode the id. If ZAO ever counts or moves the crowd, it reads SAO's
`"SurvivorAwareness_CrowdLedger"` rather than keeping a second ledger; any
ZAO consumer of the zombie list mirrors SAO's identity-bearing predicate
shape, failing closed. ZAO mechanics stay gated until the turn has one
live receipt (`ENGINE_CONTRACT.md` §10.1).
