| Document | SAO Seam Audit |
|---|---|
| Version | `0.1.1.12-pre-alpha` |
| Author | ellyj3rain |
| Repository | `SAO_SEAM_AUDIT.md` |
| Status | CANONICAL - reference audit of the sister at the turn; mechanics read, files never copied. |

# The sister at the seam — what SAO is when a person dies

Read at [A2] from `../survivor-awareness` at its `[C7]` tip
(`1.10.6.0-pre-alpha`). This maps what SAO owns, what it does not, and
where ZAO must not collide. Citations are SAO paths; line numbers are as of
the audited tip and drift with the sister's own work.

A note on intent: where this audit says "deliberately" or quotes a
doctrine, it reports what the sister's code and comments claim about
themselves — not ratified operator intent. The operator may overturn any of
it, and after [A2] directed exactly that: the seam items below went back to
SAO as repairs and decisions, not as settled design.

## 1 · What a person IS over there

The authoritative person is a plain-Lua record in global ModData under
`"SurvivorAwareness_Records"` (`SAO_Identity.lua:17,32-38`), keyed
`sao-<n>`. Three key domains exist — `sao-<n>`, `player:<username>`,
`foreign:<name>` (`SAO_Standing.lua:52-91`) — and ZAO adopts them rather
than minting a fourth for people (a fourth domain for the ambient dead,
DR-011, is a ZAO decision to take deliberately, not by drift).

Load-bearing asymmetries:

- **Records are save-scoped; beliefs are session-scoped.** The perception
  store (`P.beliefs`, provenance `observed/heard/told`,
  `SAO_Perception.lua:138-144,207`) is module-scope runtime state and dies
  with the session, while the record persists forever. A turned mind cannot
  inherit the living mind's belief table across a reload — what rides the
  turn is the RECORD (place, occupation, home, history), not the belief
  cache. DR-002's "what they had perceived" is bounded by this fact.
- **Temperament is derived, not stored.** All eight disposition traits, age,
  birth year, and the occupation draw are hash-derived from the id
  (`SAO_Disposition.lua:25-50`, `SAO_History.lua:86-110`,
  `SAO_Census.lua:356-366`, centralized in `SAO_Hash` after [B48]). A
  rotting mind needs almost no new storage: the id re-derives the person;
  decay is a transform over what the hash and the record yield.

## 2 · Death, over there

One funnel: `Identity.markDead(rec, tick, cause)`
(`SAO_Identity.lua:138-220`), idempotent, reached from exactly three sites —
two body-poll branches in `SAO_Controller.lua:4321,4380` (death is detected
by polling `body:isDead()`, no engine event) and dormant attrition
(`SAO_Population.lua:1473`). It writes `dead/deathCause/diedAtHours`, drops
every per-id runtime cache (the [B51] cleanup), and **keeps the record
forever** — "a person existed and died there."

The cleanup is a border: SAO's Border 72
(`tools/forget_on_death_test.py:69-131`) holds a machine-readable contract
of every per-id cache and its death-reachable forget, bidirectionally — an
undeclared cache is a fault. **ZAO consequence: every per-id cache ZAO ever
holds needs the same contract, and if ZAO caches key on SAO ids, ZAO's gate
needs its own mirror of this border.**

Bite state is copied onto the record at dormancy
(`rec.bitten/bittenAtHours/woundInfected`, `SAO_Population.lua:949-964`);
the dormant turning writes `rec.turnedDormant = true` + `markDead(...,
"zombie")` with **no body fabricated** (`SAO_Population.lua:1465-1474`) —
the claim travels as told-provenance news. SAO's dormant bite-risk constants
(`0.10 + min(0.5, hours/480)`, `:1416-1418`) claim to be "the engine's own
turning odds" with no citation — treat as SAO's tuning, not engine fact.

## 3 · The corpse, over there — a gap, not a principle

Nothing in the sister's tree touches the body after death: no corpse
removal ("never removeFromWorld a corpse", `SAO_Controller.lua:4390`), no
reanimation, no zombify, no driving of a turned body (full-tree sweep at
[A2]: the only `reanimat*` hits are a javap note and an unshipped roadmap
line). Its code comments dress this as doctrine ("the corpse is the
engine's", `:4357-4359`); the operator has since ruled it a GAP to repair:
SAO owns death of the person completely — the record, the corpse's
identity, and ensuring the turn actually fires under the game's own rules —
while the risen body's brain stays vanilla's, or ZAO's when ZAO is on
(DR-004). The sharpest edge at [A2] — nothing arming `reanimateTime` for a
dead shell's corpse, so a bitten survivor possibly never rose at all —
went to SAO in the repair prompt and was repaired in its hardening (SAO
1.11.2.0, its DR-016); the verified single-player arming chain is recorded
at `ENGINE_CONTRACT.md` §9a. Its zombie director
(`SAOZombieDirector.java`) drives vanilla zombies AT its shells for combat
and is harness-only in Lua.

**The surface ZAO exists to own — the risen body's mind — is genuinely
empty**, and stays ZAO's after the SAO-side repairs: SAO makes the turn
happen; ZAO is what the turned body IS.

## 4 · Turning recognition, over there — and where it breaks

SAO does not detect turning; it recognizes it: the perception scanner names
`Z:` rows from the zombie's descriptor
(`SAOPerceptionScanner.java:272-290`), and Lua matches that name against a
record already marked dead (`SAO_Perception.lua:208-233` — `zrec.dead` is
the entire test), then fires witness/grief/promise machinery
(`SAO_Controller.lua:4073-4108`).

**Corrected at [A3] (F-008 supersedes [A2]'s F-003 reading):** the chain
breaks ONCE, not twice. The corpse DOES carry the person's full descriptor
— the constructor's copy is unguarded for non-animal characters — so
named-corpse reads (`findNamedCorpsesNear`, `SAONeeds.java:2089-2135`) are
legitimate. What stays broken is the risen body: `reanimate()` builds it a
fresh descriptor carrying gender and voice prefix only, and the shared
player-zombie descriptor path no-ops in single player, so the zombie of a
turned survivor is nameless and name-keyed recognition can never fire on
it. SAO's hardening answered by ratifying identity onto modData: the
`SAOPersonId` key (SAO DR-019), which the engine relays character →
corpse → risen zombie by itself (F-007) and which ZAO reads verbatim
(DR-013).

## 5 · Collision points — negotiated, not discovered later

1. **`takeFromThePool`** (`SAOBridge.java:1671-1697`): every SAO survivor
   materialization deletes the nearest zombie within 12 tiles
   (`removeFromWorld()`, no id check, called from `spawnShellNamed:1725`).
   The [B21] doctrine is right for vanilla crowds and blind to owned
   bodies. **Needed: an exchange the two mods agree on** — ZAO marking
   bodies it owns (modData) and SAO's pool-take skipping marked bodies, or
   ZAO reclaiming identity on removal. A SAO-side change; queue it as a
   cross-project item when ZAO first owns a body.
2. **The kept promise swings at the nearest zombie**, not the named one
   (`SAO_Controller.lua:2912` → `beginCombatNearest`). Once ZAO owns turned
   bodies, "end the person who turned" must be able to name its target;
   today it cannot.
3. **The graveyard scaling precedent** (`SAO_Population.lua:1550-1569`):
   the dormant sweep once cost 13.1 ms/pass at 10,000 graves before being
   hoisted. ZAO's settlement machinery operates on exactly that population;
   budgeted walks with rotating cursors (SAO's `ENCOUNTER_BUDGET = 12`
   idiom) are the working pattern.
4. **Frame-time cadence** (SAO `SESSION_STATE.md`, operator-blocked): the
   county runs 2.4× faster at 144 Hz. ZAO does not copy the frame-counting
   idiom into new timers without flagging the same disclosure.
5. **One-brain enforcement is cooperative**: SAO's shells always remain
   legitimate zombie targets (`setZombiesDontAttack(false)` at three sites,
   never true) and its zombie reads skip `isDead()` bodies. Nothing in SAO
   will fight ZAO for a corpse — the risk is only ever №1's deletion and
   any future SAO feature that assumes zombies are fungible.

## 6 · The dormant precedent ZAO's settlements ride

SAO already runs people the engine cannot see: a packed body snapshot
(`SAOHibernation.java`, v2 string format, sanitized at [B50]) plus
record-level drift (`dormantLife`, `SAO_Population.lua:1178-1298` — "coarse
on purpose: a few tiles a minute, no pathfinding, no walls"), attrition
(`:1396-1482`), and encounters (`:1546+`, budget 12, cooldowns, "nobody dies
unwitnessed"). The engine's own virtual crowd is native and opaque
(`ENGINE_CONTRACT.md` §5), so this record-level pattern is the ONLY working
precedent for kept places of the dead persisting off-screen. ZAO mirrors
the shape — thin state on the record, budgeted sweeps, loud honesty about
coarseness — with its own stores.

## 7 · The Java posture

SAO ships a Java component because Kahlua cannot do everything (typed ECS
access, bytecode-era combat gates), loaded in-process by ZombieBuddy from
`mod.info` keys (`javaJarFile=`, `javaPkgName=`; SAO `ENGINE_CONTRACT.md`
§8). Whether ZAO needs one turns on the Lua-field-exposure question
(`ENGINE_CONTRACT.md` §9-10): if Kahlua cannot write `IsoZombie.cognition`
et al., ZAO's per-body coordinates are Java-side and ZombieBuddy is the
load path, same as the sister.
