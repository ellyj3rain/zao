| Document | Zombie Awareness Overhaul Core |
|---|---|
| Version | `0.5.1.0-pre-alpha` |
| Author | ellyj3rain |
| Repository | `CORE.md` |
| Status | ACTIVE - genesis identity for this project. |

# Zombie Awareness Overhaul — core

**Zombie Awareness Overhaul** is a Project Zomboid Build 42 add-on that owns
the turned. It is a sibling of Survivor Awareness Overhaul
(`../survivor-awareness`), built in the same house to the same discipline,
and it is an add-on that can be turned off: with ZAO absent or disabled,
vanilla handles the corpse and nothing here is missed by the engine.

The design objective is that zombification stops being one outcome. What a
turned body does follows from who the person was and how far the rot has
gone — not from a species-level behavior table, and not from a second planner
that ignores who they were.

## Identity

| Field | Value |
|---|---|
| Display name | Zombie Awareness Overhaul |
| Project key | `zao` |
| Mod id | reserved — the operator names it before the mod tree ships |
| Target | Project Zomboid Build 42.20 |
| Author | ellyj3rain |
| Sibling ground truth | the installed `projectzomboid.jar` and `media/` script + Lua tree |

The local project tree is canonical. Its governed batch and provenance records
are the portable project history.

## The two mechanisms

There are two things. They sit in the same county. They are not the same
mechanic, and they are litigated separately (DR-001):

**Zombie intelligence** is modeled decay and neurodegeneration. The mind that
is rotting is the SAO person — what they had already perceived, what they
could still do, how they moved, whether they could hold a tool. Early after
the turn, verbs the person already had are still on the table: a door, a
window, whatever was in the hand. Those verbs fall off at different speeds on
different bodies. Whatever is left is always that record rotting (DR-002). It
includes, rarely and on purpose, settlement formation by the turned (DR-006).

**Decay and mutation** are the pathogen's own mechanics: what Knox does to
bodies and through which routes, and what anyone in the county is permitted
to know about it (DR-007). Mutation moves on separate axes, and its outcomes
are distinct — past-ordinary-zombie is not the still-human bloodlusted type,
and neither is the mutant (DR-008). This mechanism hooks the recovery mods
where they are loaded and runs its own course where they are not (DR-005).

Immunity, recovery, and staying a person are events on the second mechanism.
"The zombies got smarter" is a statement about the first. The two are never
merged to make a spec look clean.

## Canonical composition

ZAO adds no fifth pillar and no new planner. The composition is SAO's,

`Perception admits → Disposition decides → Standing channels → Execution acts`

with decay operating on the record each pillar holds. What a turned body
perceived while alive is what its perception starts from; the verbs execution
retains are the ones the person had; standing is what lets a group of them
keep a place. The rates and axes of that decay belong to the second
mechanism. `ARCHITECTURE.md` holds the ratified shape.

## Governing constraints

- **Verified APIs only.** Ground truth is the installed game — the decompiled
  `projectzomboid.jar` and the shipped `media/lua` and `media/scripts` trees.
  Engine behavior is never asserted from memory. A claim without a file and
  line behind it is a hypothesis, and is labelled as one.
- **One brain per body.** SAO executes ordinary living survivors. ZAO executes
  the turned and both living pathogen states, Afflicted and Crossed, while it
  is enabled. Afflicted and Crossed use one durable ZAO driver with distinct
  state policies; SAO supplies shared county and native-action services without
  becoming a second planner. With ZAO off, vanilla handles the corpse and ZAO's
  living pathogen states are not produced. Knox Survivors may be in the load
  order; it does not own the infected (DR-004, DR-030).
- **The mind that rots is the record.** No map omniscience, no second
  planner, no species brain pasted onto a walker (DR-002).
- **Rare is not stubbed.** Settlement formation is rare on purpose and built
  whole — path, group, claim, tools, occupancy (DR-006).
- **Declarations are promises.** Settings copy and in-game text match shipped
  behavior exactly.
- **Names are the operator's.** Strain names, rarity, enable defaults, and
  the player's relationship to the mutation axes are asked, never authored
  into prose.

## Relationship to the siblings

This project shares its methodology with `../survivor-awareness` and
`../colonist-awareness` — the governed doc-pack, batch discipline, the
version machine, and the constraint that a body's capabilities never exceed
what its record supports. SAO executes ordinary living survivors; ZAO owns the
turned, Afflicted and Crossed. Return into Afflicted transfers the human shell
to ZAO execution, while Afflicted-to-Crossed conversion changes state policy
without changing executor. DR-004, DR-030 and MUTATION.md define the seams.
