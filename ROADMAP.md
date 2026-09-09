| Document | Zombie Awareness Overhaul Roadmap |
|---|---|
| Version | `0.1.1.7-pre-alpha` |
| Author | ellyj3rain |
| Repository | `ROADMAP.md` |
| Status | CANONICAL - gate order and the open-fork ledger. |

# Roadmap

## Gate order

Each gate is narrow enough that a failure is attributable to one subsystem. A
gate is not passed on code presence; it is passed on observed behavior.

### G0 — Verification

The turn surface is established from the installed build with file-and-line
evidence: how the engine turns a character (infection course, death,
reanimation), what survives onto the reanimated object, the zombie update
and AI seams, the sandbox zombie-lore options, and what the loaded recovery
mods actually expose. Nothing proceeds on remembered API behavior. Findings
land in `FINDINGS.md` from F-001.

### G1 — One brain per body

A tracked person turns. With ZAO enabled, ZAO takes the body; with ZAO
disabled, vanilla takes it; in both cases exactly one controller runs it,
proven by observation, and Knox Survivors in the load order changes nothing
about who owns the infected.

### G2 — The record rides the body

The person's record reaches the turned body with provenance intact and
begins to rot. Inspection shows what remains and what has gone. A turned
body never acts on a fact its person did not hold.

### G3 — Retention in action

Early post-turn verbs through engine paths — a door, a window, whatever was
in the hand — falling off at per-body speeds. Some bodies dump fast into an
ordinary shambler; some keep more for longer. Retention only ever subtracts.

### G4 — The course

Decay and mutation as their own substrate: both Knox ledgers live
(epidemiological routes, epistemological visibility), recovery-mod state
honored as input where loaded, ZAO's own course where not, outcomes held
distinct per DR-008.

### G5 — Settlement formation

Rare, whole, watchable: a group of the turned takes and keeps a new place —
path, group, claim, tools, occupancy — robust enough to watch for as long as
it stands.

Gate content past G0 depends on forks below; a gate is refined when its fork
closes, never widened silently.

## Open forks — reserved to the operator

The standing ledger of decisions the operator has reserved or left open.
Asked before they are needed; never authored into prose. Ratification lands
in `DECISION_REGISTRY.md` and the fork is struck here.

| Fork | What it decides | Status |
|---|---|---|
| Mutation axes | The gradients and branches mutation moves on (DR-008 consequence). Operator direction of 2026-08-29: think in spectrums and gradients, branches that are not binaries, spectrums along each branch, variation at every level; decay can come back via mutation; end states can pass human strength and speed; hybridization on the table, both directions, good and bad; nothing gimmicky, no example names (the comics, the ghoul parallel) promoted into spec. Corrected by the operator after [A2]: the engine's per-body fields (F-005) are ACTUATORS the axes project onto, not the axis set — the design axes are ZAO's own and new, and the direction includes inverse/mirror axes. Neo drafts the interrelation of Knox, decay, and mutation; the operator ratifies. | OPEN — draft owed; gated behind the live turn receipt (SESSION_STATE, the gate) |
| Strain names | Names for whatever the axes yield, and for the recognizable regions of the outcome space. | OPEN — operator names them |
| Rarity | Numbers for the spread's tails, settlement frequency included. | OPEN |
| Enable defaults | Sandbox defaults: what ships on, what ships off. | OPEN |
| Player on the axes | ~~Whether the player walks the same mutation axes as NPCs.~~ RATIFIED as a rule (DR-012): per outcome, where the gameplay loop supports it; some outcomes NPC-only by design. Each shipped outcome still states its player-side answer at its own batch. | CLOSED to a per-outcome call |
| SAO posture | ~~Whether ZAO requires SAO.~~ RATIFIED (DR-010): standalone and an integrated sister, both — read where present, derive where absent, one record shape. | CLOSED |
| Preexisting zombies | ~~Derived records or vanilla.~~ RATIFIED (DR-011): the ambient dead carry derived thin records, world-origin precedent. | CLOSED |
| The claim surface | Whether ZAO publishes a query letting another mod ask whether it owns a body, and how ZAO reads the same question of others. F-012: `The Mutants` publishes `PZTheMutants.API` with a contract version, and separately reverse-engineers Bandits through three fallback routes because Bandits publishes nothing - the same mod carrying both patterns at once. F-011 left open whether naming a mod in code is acceptable when the only door in is a named one; `PZM_ForeignOwnership` is a shipped precedent for the shape - one constant in one dedicated file, presence a type test on a global, every read `pcall`-wrapped, absence returning false. Both halves are public-contract decisions and both are cheap only while no mod code exists. | OPEN - operator decides; raised at [A7] |
| Mod id | The stable id, before the mod tree ships; changing it later breaks saves. | OPEN — operator names it |
| Publication | Whether and when this repository gets a public remote. | OPEN — local-first until directed |

## Deferred

Deferred items are recorded so the gates are not widened to accommodate
them; they are not scheduled.

- Playtesting of any kind: play is later, one project at a time, when the
  operator says. ZAO and SAO are not tested in the same window.
- Any UI beyond what existing moodle art and diagnostic output provide.
