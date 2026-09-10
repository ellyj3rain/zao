| Document | Zombie Awareness Overhaul Architecture |
|---|---|
| Version | `0.1.1.9-pre-alpha` |
| Author | ellyj3rain |
| Repository | `ARCHITECTURE.md` |
| Status | ACTIVE - ratified framework shape. Engine surfaces claimed here are unverified until `FINDINGS.md` carries them. |

# Architecture

## Product boundary

ZAO owns the turned body while ZAO is enabled: what remains of the person's
mind, how it rots, what the pathogen does to the body, and what anyone is
permitted to know about either. It owns none of the living — a living person
is SAO's until the turn, vanilla's where SAO is absent — and it owns nothing
when disabled: switch ZAO off and vanilla handles every corpse (DR-004).

Project Zomboid owns the active engine representation and every world
mechanic that can be reused safely. The engine surfaces this project needs —
how a character turns, what survives onto the reanimated object, the zombie
update and AI seams, the sandbox lore options — are claimed, not verified;
establishing them with file-and-line evidence is G0 in `ROADMAP.md`, and
until then every one is a hypothesis.

## The ownership seam

The turn is the seam. Before it, nothing here runs. At it, exactly one of
three owners takes the body:

| ZAO state | Owner of the turned body |
|---|---|
| enabled | ZAO |
| disabled | vanilla |
| (any) | never a second brain beside another owner |

Knox Survivors may be in the load order; it does not own the infected. SAO's
social handling of the turn — witnesses, grief, promises kept — is SAO's and
stays there; ZAO takes the body, not the funeral.

## Mechanism one — the turned mind

Modeled decay and neurodegeneration over the record the person already had.
The composition is SAO's four pillars with decay operating on each pillar's
record; there is no fifth pillar and no second planner (DR-002).

- **Perception** starts from what the person had actually perceived — places,
  routes, people — and rots. A turned body never acquires map truth its
  person did not hold. Post-turn acquisition exists only within whatever the
  engine's own senses grant a zombie, degraded by how far gone the body is.
- **Disposition** decays toward the engine's own drives. What order it decays
  in, and what texture remains early, follows from who the person was.
- **Standing** is what lets a group of the turned keep a place (DR-006).
  Settlement formation is rare on purpose and built whole: a new place,
  kept, occupied, grouped, the way living survivors form one — not a pile at
  a car alarm, and not only the house they already had.
- **Execution** retains the person's verbs early — a door, a window, whatever
  was already in the hand — and loses them at speeds that differ per body.
  Some bodies dump fast into an ordinary shambler; some keep more of the
  record for longer. Retention is never addition: no verb appears after the
  turn that the person did not carry into it.

## Mechanism two — decay and mutation

The pathogen's own mechanics, litigated separately from intelligence
(DR-001) so they can hook other mods without depending on them (DR-005).

- **Two ledgers define Knox (DR-007).** Epidemiological: what the pathogen
  does to bodies, and through which routes. Epistemological: what anyone in
  the county is permitted to know — moodles, rumor, what SAO already permits
  a person to perceive — never a percentage on the forehead.
- **Outcomes are distinct (DR-008).** Zombification is a spread of outcomes
  and the Knox default is only one of them (DR-003). A body can go past
  ordinary zombie. A still-human, bloodlusted type exists and is its own
  outcome, not a grade of anything else. A mutant is past that, and is a
  third thing. These are never flattened into one type. The axes on which
  mutation moves are **unratified** — the operator decides them
  (`ROADMAP.md`, open forks), including the operator-proposed candidate of
  hybridization as a form of mutation that can move both directions, good
  and bad.
- **Recovery mods are inputs (DR-005).** Antibodies and its cousins (They
  Knew, The Only Cure): where loaded, their antibody, recovery, cure, and
  repeat-infection state — and the modifiers and moodles they already put on
  screen — are inputs here. Where absent, ZAO runs a course of its own.
  Immunity and staying-a-person are events on this mechanism, not on
  mechanism one.
- **Existing art first.** Where a mutated or recovering body needs to read
  on screen and existing moodle art already reads, use it.

## What is not ratified

Ratified shape ends here. Strain identities and names, rarity, enable
defaults, the mutation axes themselves, whether the player walks the same
axes as NPCs, the SAO dependency posture, and the treatment of the county's
preexisting zombies are open forks listed in `ROADMAP.md`, reserved to the
operator. Nothing below this line of the design exists yet, and nothing in
this file may be cited as if it settled one of those forks.
