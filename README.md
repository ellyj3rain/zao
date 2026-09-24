| Document | Zombie Awareness Overhaul |
|---|---|
| Version | `0.3.3.0-pre-alpha` |
| Author | ellyj3rain |
| Repository | `README.md` |
| Status | CANONICAL - human entry point. |

# Zombie Awareness Overhaul

A Project Zomboid Build 42 add-on to [Survivor Awareness
Overhaul](../survivor-awareness). SAO handles living survivors. This
handles a body after it turns, and the handover happens at death. With
ZAO disabled, vanilla handles every corpse.

The architecture across the three repositories - what SAO, ZAO and
[Speakeasy](../zomboid-speakeasy) each own, and the three seams between
them - is held in `../survivor-awareness/PROJECTS.md`, which is
[`PROJECTS.md`](https://github.com/ellyj3rain/sao/blob/main/PROJECTS.md)
on the forge. The relative path is for a reader with the three
repositories side by side, which is how they are worked on; the link
is for a reader who has only this one.

Two mechanisms, litigated separately and never merged:

- **Zombie intelligence** — modeled decay and neurodegeneration. A turned
  body acts on its person's own SAO record as that record degrades. It
  retains what they had perceived and the actions they could perform, and
  loses both over time at a rate that differs per body. Groups of the
  turned can form settlements the way living survivors do. That is rare by
  design and is built complete rather than stubbed.
- **Decay and mutation** — the pathogen's own mechanics, on two ledgers:
  what Knox does to bodies through which routes, and what anyone is
  permitted to know about it. No capability here requires another mod to
  be installed. Mutation moves on separate axes whose definition is
  reserved to the operator.

## Status

ZAO now ships a complete mod tree.

The runtime controller claims every zombie that carries `SAOPersonId`, drives
it according to its form, and writes the form and performance into modData for
Perception. Puker holds range, Skitter flanks, and the remaining forms close on
the target. The Java bridge applies per-form speed, strength, cognition,
memory, sight, and hearing, and exposes the same ownership, form, and
performance queries to Lua.

A35/A36 also establish the durable Afflicted-return boundary with SAO. ZAO holds
the exact old source until the living destination is committed, reconstructs
runtime controllers and courses from durable records, and uses a generation
journal to reconcile interrupted saves across the engine's separate native and
global persistence surfaces. This closes return ownership and reconstruction;
the canonical Crossed human action system remains open in the sister roadmap.

A37 implements the opposite ownership direction for an Afflicted person who
becomes Crossed. A reachable Crossed decision approaches and holds contact
through an interruptible blood action. Afflicted people are excluded from
ordinary feeding; only the completed durable action can produce the existing
Crossed-odds times susceptibility roll. Success transfers the same living human
shell and dormant snapshot from SAO to ZAO exactly once, with retry across busy
state, save/reload and later death. This closes the exposure/ownership slice;
retained weapons, tools, strategy and the wider human action vocabulary remain
unfinished.

A38 makes that retained human shell the Crossed person's actual communication
and shared-work body. The registered ZAO execution owner reports current
activity and only the capabilities the retained mind still supports. A threat
can interrupt the work; accepted work can own a tick; otherwise ordinary
Crossed deliberation continues. A Crossed-linked `IsoZombie` is rejected before
all admission side effects because it is not an alternate representation of
the human-looking Crossed. This is mechanically controlled, not yet observed
in loaded-world play.

G0 closed at `[A6]`: the engine's turn surface is established from the
installed build with file-and-line evidence, in F-001 through F-011.
`[A7]` to `[A9]` read the mods that already run behaviour on turned
bodies and set what this project does with them. G1 — one controller
per body — is built: the runtime controller shipped at `[A23]` and
drives every claimed body according to its form. Its proof by
observation is owed with the era's play receipts. Two forks stand open
in the ledger: Rarity (the spread's tails; how often a settlement of
the turned forms) and Publication.

[`SESSION_STATE.md`](SESSION_STATE.md) holds where the work stands and
[`ROADMAP.md`](ROADMAP.md) holds the gate order and the open forks.
This section states the tip and goes stale; those two are maintained.

## Reading order

[`NEO.md`](NEO.md) is the instruction surface. Then [`CORE.md`](CORE.md)
for identity and the two mechanisms, [`ARCHITECTURE.md`](ARCHITECTURE.md)
for the ratified shape, [`GOVERNANCE.md`](GOVERNANCE.md) for discipline,
[`DECISION_REGISTRY.md`](DECISION_REGISTRY.md) for what is ratified and
why. The gate is `tools/check.sh`; the version is
[`tools/version_replay.py`](tools/version_replay.py)'s output.

Licensed GPL-3.0.

## Loading the build

Run `tools/deploy.sh` with the game closed. In the mods list, enable
**Zombie Awareness Overhaul**. Press **O** to open the ZAO state panel.

With SAO enabled, the ZAO overlay also appears in the world. Every nearby
body that carries a form is labelled with that form and its normalized
performance. Healthy survivors are not labelled, because a body only carries a
form after the pathogen has acted on it: infected, dead, or turned.
