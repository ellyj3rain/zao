| Document | Zombie Awareness Overhaul Decision Registry |
|---|---|
| Version | `0.3.1.1-pre-alpha` |
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

---

## DR-014 — The project is the ontology other mods become coherent inside

**Date** 2026-09-09
**Status** RATIFIED (operator-directed)

**Decision.** This project is not assembled out of other mods and does
not import them. The Workshop already answers narrow questions well -
what a special infected does, how a hostile fights, how an infection
course runs, how a companion takes an order - and each answer ships
with its own small world-model: its own way of marking a body, its own
taxonomy, its own reason a population exists at all. Run four of them
together and a county holds four unrelated ontologies.

What is built here is the county those answers can be true inside at
once: one identity per person, one owner per body, one causal account
of how somebody came to be the way they are. Complementary work becomes
an EXPRESSION on this project's own people rather than a second
population beside them.

**A taxonomy is the cheapest part of a mod and an implementation is
the most expensive part.** Names, categories and the reasons a mod
gives for why a body is the way it is are all discardable, and
discarding them costs nothing. Working code that makes a body leap a
fence, charge in a line, resist a bullet or cry where it sits is
months of somebody's craft. This project keeps the second and is
indifferent to the first: a capability is renamed, recombined and
re-caused freely, and what decides which body has it is always this
project's own account of who that person was and what happened to
them.

**Rationale.** The value is not in the acquiring. Copying another
mod's systems produces a worse copy of that mod; what does not exist
anywhere is the substrate that makes disparate good work cohere while
this project's own systems carry the causation. That substrate is the
new thing, and it is the only part nobody else is building. The point
of it is a better game than anyone is currently providing.

**Consequences.** Compatibility is a first-class outcome rather than a
courtesy, so the claim-and-release surface (F-012, F-013) is load
bearing rather than a nicety. Nothing here derives a population from
another mod. Where another author's work is genuinely used, it is named
in `CREDITS.md` entry by entry with its own terms and its own
integration status, and most entries take nothing. An entry in
`CREDITS.md` is an acknowledgement of work this project is built to sit
with, not evidence that any of it is in this tree.

---

## DR-015 — A hostile is an outcome; a mod that produces hostiles is a compatibility target

**Date** 2026-09-09
**Status** RATIFIED (operator-directed)

**Decision.** This project does not take its hostile population from
another mod and does not place hostiles of its own. What it wants is
the conditions under which somebody becomes hostile - who they are,
what they are short of, what has been done to them - so that a bandit
is something the county produced rather than something spawned into it.

Bandits (Slayer, `Bandits2`) is a compatibility target: a mod many
players run, which should work alongside this project rather than
underneath it. Its shapes are prior art and are read as such. Its
deterministic production of hostiles is not adopted.

**Rationale.** A mod that reliably manufactures bandits answers a
different question from the one this project asks. The moment a hostile
is placed, the only measurement there is - what these people did on
their own - is destroyed. It is the sister's DR-037 applied to
hostility instead of to houses, and DR-014's general rule at its
sharpest case.

**Consequences.** No spawn table, no hostility roster, no faction
placed at world generation. Hostility is a state a person reaches
through the model that already governs standing and scarcity, and it is
reversible by the same model. Where Bandits is loaded, its bodies are
its own and this project does not claim them (DR-004); its published
surfaces are readable where useful and never required (DR-005).

The half of this that belongs to the living county rather than the
turned is the sister's, under its own DR-037. This entry fixes the
posture toward placement and toward the mod; it does not design the
mechanism.

---

## DR-016 — ZAO work does not wait for a watched turn

**Date** 2026-09-11
**Status** RATIFIED (operator-directed)

**Decision.** No rule blocks ZAO's mechanics until a watched turn exists.
The rule that said so was written by an assistant at `[A3]`, carried into
DR-013's consequences and `ENGINE_CONTRACT.md` §10.1, and presented as
the operator's. The operator ruled on 2026-09-11 that they never made it.
A watched turn — a bitten SAO survivor dying, leaving a named corpse,
rising with `SAOPersonId` intact, and being recognized — is wanted
evidence for the identity handoff.

**Rationale.** The rule blocked itself. ZAO has no game code, so a
watched turn inside ZAO cannot happen yet, and work that waits for it
can never start. The rule also attributed a ruling to the operator that
they never made.

**Consequences.** This entry supersedes the gate sentence in DR-013's
consequences; the rest of DR-013 stands. ZAO work does not wait for the
watched turn. Play is still later, one project at a time, when the
operator says. Closed batch records keep their text; this entry is the
correction.

---

## DR-017 — The mutants source port supplies the forms of the gradient

**Date** 2026-09-11
**Status** RATIFIED (operator-directed)

**Decision.** The mutants mod's forms and animations are usable through a
source port and are raw material for the mutation gradient. Attributes
and forms are distinct but linked: a bruiser can look the part and be the
part, and attributes and animations can also be conferred
non-physiognomically. A mutant-form body can come back as one of the
afflicted, and a returned mutant diversifies how the afflicted present and
the capabilities they carry forward.

**Rationale.** The middle outcomes of the gradient are defined in
substance by forms that already exist, rather than by a separate list of
strain names.

**Consequences.** Ported capabilities are re-caused under this project's
own ontology (DR-014) and attributed in `CREDITS.md` when source is used.
`MUTATION.md` carries the port and the returned-mutant ruling.

---

## DR-018 — The gradient's contents are enumerated from what is possible

**Date** 2026-09-11
**Status** RATIFIED (operator-directed)

**Decision.** The contents of the gradient are enumerated from what can be
made possible, using the mutants and the suggested concepts as the basis
for variety among the currently known types and for expanding beyond them.

**Rationale.** The count and contents of the gradient follow from
enumerating the possible, not from picking a number first.

**Consequences.** The enumeration of the gradient's contents is named work:
what can be made possible, from the ported forms and the suggested
concepts. `MUTATION.md` carries the direction.

---

## DR-019 — The dial numbers extrapolate from the operator's suggested numbers

**Date** 2026-09-11
**Status** RATIFIED (operator-directed)

**Decision.** The numbers behind the dial table are extrapolated from
numbers the operator has already suggested, to produce default-level
configurations.

**Rationale.** The defaults come from the operator's own suggestions rather
than from values an assistant invents.

**Consequences.** Extracting the suggested numbers into the tree is named
work; no dial value is authored by the assistant. `MUTATION.md` names the
source of the dial numbers.

---

## DR-020 — Afflicted memory is fractured at the turn, not necessarily decaying after it

**Date** 2026-09-11
**Status** RATIFIED (operator-directed)

**Decision.** Not every afflicted body loses memory over time. The original
premise is that memory was already fractured or disorganized by the
turning process and the return. Further loss is possible for some bodies
and is episodic where it occurs, governed by the existing dials and
genuinely random beyond them.

**Rationale.** The identity-decay premise had drifted from what was already
established; the correction grounds it in the turning and the return.

**Consequences.** `MUTATION.md`'s identity-decay section is corrected: the
fracture is at the turn, further loss is not universal, and the episodic
dials apply where further loss occurs.

---

## DR-021 — Necessity holds an afflicted settlement

**Date** 2026-09-11
**Status** RATIFIED (operator-directed)

**Decision.** What holds a cast-out afflicted settlement together is
necessity. Success stays unencoded: a settlement is what these people
did, or it does not exist.

**Rationale.** The holding principle follows what the members need, and the
mechanics of holding follow from that need.

**Consequences.** `MUTATION.md` states the holding principle beside the
never-encoded law. The mechanics of holding remain work that follows from
the principle.

---

## DR-022 — The pathogen owns the mutation roll, and forms feed the branching graph

**Date** 2026-09-11
**Status** RATIFIED (operator-directed)

**Decision.** The pathogen owns the mutation roll and the roll for form
performance. The default roll is uniform across the gradient, and sandbox
settings may weight it. Crossed is a terminal pathogen state: a crossed
body does not mutate further and does not organize around forms. Retained
form traits are state, not new branches. Capability forms and attribute
mutations stack. Forms are visible facts that enter Perception and change
pressure inside the living branching graph.

**Rationale.** The six integration questions were answered together because
they describe one seam: how ZAO's pathogen state meets SAO's branching
graph.

**Consequences.** `MUTATION.md` carries the integration section. The
cross-module row contract in Speakeasy is proposed against this ruling.

---

## DR-023 — The stable mod id is ZombieAwareness

**Date** 2026-09-11
**Status** RATIFIED (operator-directed)

**Decision.** The stable mod id is `ZombieAwareness`.

**Rationale.** The mod's name and repository make the id unambiguous, and a
development suffix would leave the loadout unclear.

**Consequences.** Both `mod.info` files use the id, and the deploy path is
`Zomboid/mods/ZombieAwareness`.

---

## DR-024 — ZAO publishes a read-only claim surface

**Date** 2026-09-11
**Status** RATIFIED (operator-directed)

**Decision.** ZAO publishes `ZAO.owns(zombie)`, `ZAO.formOf(zombie)`, and
`ZAO.performanceOf(zombie)` as a read-only query surface.

**Rationale.** Other mods need a stable way to ask who owns a body and what
form it carries without reaching into ZAO's private state.

**Consequences.** `ZAO_API.lua` is the public surface, and the claim-surface
fork is closed.

---

## DR-025 — ZAO's playable defaults are chosen

**Date** 2026-09-11
**Status** RATIFIED (operator-directed)

**Decision.** The playable defaults are: forms on, 10% mutation odds, runtime
controller on, world-space overlay on, and the state panel bound to **O**.

**Rationale.** These are the defaults the current runtime ships with, and they
make the new pathogen surface visible and playable without configuration.

**Consequences.** The enable-defaults fork is closed.

---

## DR-026 — Pathogen state and mutation knowledge are event-driven

**Date** 2026-09-12
**Status** RATIFIED (operator-directed)

**Decision.** A body's pathogen state and a survivor's mutation knowledge
come from simulated events: infection, death, turn, daily advancement,
carrier exposure, encounter, and testimony. No form, performance value,
attribute mutation, or knowledge is derived from a person id, a clock, or a
hash at read time.

**Rationale.** World generation is emergent. Precomputing a later world's
pathogen history would replace the simulation with a deterministic table.

**Consequences.** `ZAO_Pathogen.lua` owns event creation and daily
advancement. `SAO_PathogenEvents.lua` emits SAO's infection, death, and turn
events and derives knowledge only from proximity or testimony. The
Speakeasy state producer reads event-derived state and reports absence
honestly for rows that predate it.
