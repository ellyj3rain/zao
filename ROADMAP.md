| Document | Zombie Awareness Overhaul Roadmap |
|---|---|
| Version | `0.1.0.0-pre-alpha` |
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
| Mutation axes | The separate axes mutation moves on (DR-008 consequence). Operator-proposed candidate on the table: hybridization as a form of mutation, both directions, good and bad; the still-human bloodlusted type is distinct from it, not a grade of it. | OPEN — operator direction of 2026-08-29 recorded; axes not ratified |
| Strain names | Names for whatever the axes yield. | OPEN — operator names them |
| Rarity | Numbers for the spread's tails, settlement frequency included. | OPEN |
| Enable defaults | Sandbox defaults: what ships on, what ships off. | OPEN |
| Player on the axes | Whether the player walks the same mutation axes as NPCs. | OPEN |
| SAO posture | Whether ZAO requires SAO, or runs beside vanilla with records derived some other way. | OPEN |
| Preexisting zombies | Whether the county's ambient zombies (no SAO record) get derived thin records — SAO's world-origin precedent — or stay vanilla, ZAO applying only to tracked turns. | OPEN |
| Mod id | The stable id, before the mod tree ships; changing it later breaks saves. | OPEN — operator names it |
| Publication | Whether and when this repository gets a public remote. | OPEN — local-first until directed |

## Deferred

Deferred items are recorded so the gates are not widened to accommodate
them; they are not scheduled.

- Playtesting of any kind: play is later, one project at a time, when the
  operator says. ZAO and SAO are not tested in the same window.
- Any UI beyond what existing moodle art and diagnostic output provide.
