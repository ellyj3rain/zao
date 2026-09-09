| Document | Zombie Awareness Overhaul |
|---|---|
| Version | `0.1.1.6-pre-alpha` |
| Author | ellyj3rain |
| Repository | `README.md` |
| Status | CANONICAL - human entry point. |

# Zombie Awareness Overhaul

A Project Zomboid Build 42 add-on beside [Survivor Awareness
Overhaul](../survivor-awareness): SAO owns the living, ZAO owns the turned,
and the seam between them is the turn. With ZAO disabled, vanilla handles
every corpse.

The architecture across the three repositories - what SAO, ZAO and
[Speakeasy](../zomboid-speakeasy) each own, and the three seams between
them - is held in `../survivor-awareness/PROJECTS.md`, which is
[`PROJECTS.md`](https://github.com/ellyj3rain/sao/blob/main/PROJECTS.md)
on the forge. The relative path is for a reader with the three
repositories side by side, which is how they are worked on; the link
is for a reader who has only this one.

Two mechanisms, litigated separately and never merged:

- **Zombie intelligence** — modeled decay and neurodegeneration. What a
  turned body knows and does is its person's own SAO record rotting: what
  they had perceived, the verbs they carried in, falling off at different
  speeds on different bodies. Rarely, and on purpose, groups of the turned
  form settlements the way living survivors do — built whole, never stubbed
  for being rare.
- **Decay and mutation** — the pathogen's own mechanics, on two ledgers:
  what Knox does to bodies through which routes, and what anyone is
  permitted to know about it. Recovery mods (Antibodies and cousins) are
  inputs where loaded, never dependencies; mutation moves on separate axes
  whose definition is reserved to the operator.

## Status

`[A1]` — the governed repository exists; no mod code yet. The engine's turn
surface is unverified claim until G0 lands file-and-line evidence. See
[`SESSION_STATE.md`](SESSION_STATE.md) for where the work stands and
[`ROADMAP.md`](ROADMAP.md) for the gate order and the open-fork ledger.

## Reading order

[`NEO.md`](NEO.md) is the instruction surface. Then [`CORE.md`](CORE.md)
for identity and the two mechanisms, [`ARCHITECTURE.md`](ARCHITECTURE.md)
for the ratified shape, [`GOVERNANCE.md`](GOVERNANCE.md) for discipline,
[`DECISION_REGISTRY.md`](DECISION_REGISTRY.md) for what is ratified and
why. The gate is `tools/check.sh`; the version is
[`tools/version_replay.py`](tools/version_replay.py)'s output, nobody's
choice.

Licensed GPL-3.0.
