| Document | Zombie Awareness Overhaul Architecture |
|---|---|
| Version | `0.5.3.0-pre-alpha` |
| Author | ellyj3rain |
| Repository | `ARCHITECTURE.md` |
| Status | ACTIVE - ratified framework shape. Engine surfaces claimed here are unverified until `FINDINGS.md` carries them. |

# Architecture

## Product boundary

ZAO owns the turned body and the living states its pathogen creates while ZAO
is enabled: what remains of the person's mind, how it rots, what the pathogen
does to the body, what anyone is permitted to know about either, and how an
Afflicted or Crossed person acts. SAO owns ordinary living-survivor execution
and supplies county identity, communication, material-action and locomotion
services to ZAO-owned people. It is not a second planner. When ZAO is disabled,
vanilla handles every corpse and ZAO's living pathogen states are absent
(DR-004, DR-030).

Project Zomboid owns the active engine representation and every world
mechanic that can be reused safely. The engine surfaces this project needs —
how a character turns, what survives onto the reanimated object, the zombie
update and AI seams, the sandbox lore options — are claimed, not verified;
establishing them with file-and-line evidence is G0 in `ROADMAP.md`, and
until then every one is a hypothesis.

## The ownership seam

The turn is the first seam. An authorized return into Afflicted is the second.
A completed Afflicted blood exposure changes the living state but not the
execution owner. At every boundary exactly one owner runs the body:

| Person state | Execution owner |
|---|---|
| ordinary living survivor | SAO |
| turned or mutant, ZAO enabled | ZAO |
| Afflicted, ZAO enabled | ZAO driver on the living human shell; Afflicted policy |
| Crossed, ZAO enabled | the same ZAO driver on the living human shell; Crossed policy |
| ZAO disabled | vanilla owns corpses; no ZAO Afflicted/Crossed state is produced |
| any | never a second brain beside another owner |

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

### State surface

`ZAO_State.lua` is the runtime state surface. It reads the event-driven state
produced by `ZAO_Pathogen.lua`: terminal state, current form, form
performance, attribute mutations, decay state, retained ability, and visible
forms. A body with no assigned form is in the `none` form, and its performance
is zero. No state is derived from a person id or a clock.

`tools/state_dump.py` projects that state onto an SAO decision without changing
the decision identity. Its key is exactly run, county, person, event and hour;
two decisions by one person in one hour remain two rows. It validates all input
before an atomic replace and never invents a form when the person record carries
no event-driven ZAO state.

### Java bridge

`ZAO.jar` owns the per-body actuators. It applies each form's speed,
strength, cognition, memory, sight, and hearing to the engine's own public
`IsoZombie` fields, then drives the body through the engine's own target and
path methods. Lua reaches it as `ZAOJavaBridge`.

### Persistence reconstruction

Pathogen, recovery, settlement and return-source tables are durable authorities.
Controllers, courses, settlement groups, loaded-body ownership and Java maps are
runtime projections rebuilt for each world. Afflicted return additionally spans
the engine's native body and global ModData surfaces. `ZAOSaveGeneration` writes
a narrow generation journal after Lua save callbacks and before native body
save; it replays after global data load and before native reanimated-player load.
The journal contains only participating return identities and reconciles an
exact source receipt or tombstone rather than duplicating general world state.

A37 established the transfer machinery using Afflicted-to-Crossed conversion.
A39 generalizes it to the actual boundary: an authorized Afflicted return hands
the living shell directly to ZAO, and conversion later preserves the same
driver token. Action and pathogen receipts remain distinct from ownership.
Busy actions retry, reload can transfer the dormant envelope without briefly
adopting the person under SAO, and later death returns the corpse through SAO's
existing death and witness path.

### Living ZAO execution owner

The retained living shell is the Afflicted or Crossed person's communication
and work body. Shared `ZAO_ExecutionOwner` registers the common `ZAO.Driver`
adapter with SAO and exposes only current body presence, competing activity and
capabilities derived from that person's current mind. `ZAO_Controller` renews
the registration in loaded execution but does not own or define the adapter;
dormant and headless execution use the same shared module. SAO may address the
person and perform an accepted native action through the adapter; ZAO decides
whether the actor does it.

The shared driver supplies arbitration, current activity, durable movement and
exact-once route outcomes. Each state provider admits its own motives and
actions. Afflicted fear actual Crossed threats, seek other Afflicted and travel
toward evidenced ground. They require water, prefer meat/protein, can accept
non-dairy alternatives with reduced relief, and may individually choose
human-origin food. Crossed retain ordinary human caloric passage and may choose
native wound care, drinking, rest or ordinary food
alongside their distinct predation, exposure, driving, holding and material
actions. Predation appraisal may use distress visible to that observer, such
as running or sprinting; it never reads the target's hidden moodles. Settlement formation requires state-specific
acts of holding ground by distinct people over time; proximity is not assent.

Crossed can subsist on ordinary food. Eligible ordinary-human-origin food remains a preferred
option because sustenance can coincide with cruelty, mutilation, domination,
terror and contagion; it is not a biological-only diet. Their first material
producer butchers eligible ordinary human corpses into human flesh and preserves
both human origin and donor identity through evolved dishes. Afflicted sources
are categorically rejected; anonymous legacy donor provenance fails closed.
Crossed, mutant, zombie and animal bodies remain excluded. Weapon contamination is a
separately selected tactic on an exact equipped melee or projectile weapon;
finite native hits resolve only after an actual wound exists. An Afflicted
target enters the separate intentional-exposure pathogen action when that act
is chosen; feeding does not imply exposure.

`ZAO_Maintenance` owns the state-specific passage of time. Afflicted alternative
food applies a bounded nutrition penalty, protein clears it, and a chosen human
meal may provide temporary exposure protection derived from donor health and
Knox adaptation. Crossed predatory pressure is separate from hunger. It changes
only after an exact result: heard threat plus public flight, native health loss,
a completed post-threat yield, or completed consumption/desecration. Death
closes the encounter without manufacturing fear, pain, control or sustenance.

Private food knowledge invokes SAO's existing SourceUse owner. That owner keeps
the exact source revision, locomotion, transfer, carried item and native-use
receipt. `ZAO_Diet` registers only the state-specific eating action after the
item is physically carried. Dormant external shells restore at zero survivor
elapsed time before ZAO observes native hunger and thirst and advances the
separately owned predatory state.

### Private contact continuation and maintenance correction (A42)

Each Afflicted or Crossed provider may pursue the particular contacts retained
for its current state-authored matter through the same `ZAO.Driver`. The sister's
Communication owner keeps contact attempt, address arrival, proposal reception,
private appraisal and returned response separate. `ZAO_ExecutionOwner` exposes
current presence, activity and capability in loaded, dormant and headless
execution; it does not convert missing representation into hearing or assent.

Crossed material admission revalidates the donor at option formation,
timed-action start, every validity check, native completion and SourceUse use.
Raw flesh and evolved dishes carry the provenance. Known ordinary-human donors
may pass; known Afflicted donors and anonymous legacy human-origin items fail.
This is a Crossed policy boundary only. It neither changes Afflicted food policy
nor joins eating to the distinct intentional-exposure action.

### Distinct durable coordination

`ZAO.Driver` exposes one common bridge into SAO's Organization and
Communication owners. It may originate, revise, deliver or withdraw a matter,
but it does not store a second social process. The Afflicted provider raises
food or water provisioning from current personal hunger/thirst or an evidenced
settlement necessity. The Crossed provider raises a bounded rendezvous/holding
matter for currently evidenced associates using retained home, held ground or
present opportunity. These are different action producers sharing an execution
adapter, not a shared motive or maintenance rule.

After actual proposal acquisition, the current state provider appraises the
recipient from their own activity, capabilities, pressure, relationship and
disposition. Missing representation defers. An Afflicted-to-Crossed change
keeps the same person, process and proposal revision but changes which provider
forms a later response. Accepted provisioning returns to SAO's exact SourceUse,
Locomotion and Handover owners. Accepted rendezvous returns to Locomotion and
records holding activity only after the matching promised arrival. The result
can therefore inform existing settlement evidence without proximity becoming
assent or completion.

A41 makes this dispatch representation-neutral. The shared execution owner
resolves a loaded body only when the person's stable ZAO control token owns the
retained human shell. Otherwise it supplies a bodyless snapshot or an explicit
observation gap and dispatches the final appraisal to the current Afflicted or
Crossed provider. The adapter never treats common execution as common
physiology, sustenance, motives or policy and exports no terminal-state label
through SAO's generic response envelope.

An `IsoZombie` carrying a ZAO-owned or durably Crossed identity is malformed at
this boundary. The controller rejects it before ownership, pathogen,
settlement, persistence or cognition side effects. Rejection is an admission
rule, not a body transition: it does not manufacture death, revival, migration
or a substitute shell. The separate retained-shell driving adapter is
unchanged. Crossed planning is ordinary retained cognition, not a rare subtype.
Butchery, cooked human dishes and weapon contamination are concrete producers,
not an exhaustive vocabulary, an automatic encounter sequence or a claim that
those examples define the state.

## What is not ratified

Ratified shape ends here. Strain identities and names, rarity, enable
defaults, the mutation axes themselves, whether the player walks the same
axes as NPCs, the SAO dependency posture, and the treatment of the county's
preexisting zombies are open forks listed in `ROADMAP.md`, reserved to the
operator. Nothing below this line of the design exists yet, and nothing in
this file may be cited as if it settled one of those forks.
