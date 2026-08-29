| Document | Zombie Awareness Overhaul Findings |
|---|---|
| Version | `0.1.1.1-pre-alpha` |
| Author | ellyj3rain |
| Repository | `FINDINGS.md` |
| Status | CANONICAL, APPEND-ONLY - verified engine findings from F-001. |

# Findings

Verified engine findings, numbered from F-001. A finding is admitted when it
is reproducible from stated inputs and its verification method is recorded
(`GOVERNANCE.md`, evidence standard).

Left empty by design at `[A1]`; the [A2] modeling pass admitted the first
entries. Structural findings (bytecode, shipped files) are marked so; no
finding below has a live receipt yet. Method note: "hand-checked" means
re-derived in this repository's own [A2] disassembly pass, not carried from
a sweep's report. `ENGINE_CONTRACT.md` holds each finding's full context.

---

## F-001 — Reanimation is a timer on the corpse, and Lua can set it

**Verified** [A2], structural. `IsoDeadBody.update()` compares private
`reanimateTime` against `GameTime.getWorldAgeHours()` and calls
`reanimate()`; `reanimateNow()/reanimateLater()` set the timer; there is no
`shouldReanimate()`. Shipped Lua calls `body:reanimateNow()`
(`DebugContextMenu.lua:680-688`) and `zombie:setReanimateTimer(s)`
(`Tutorial/Steps.lua:922,962,1282`). Method: `javap -p -c` on the installed
jar; shipped-Lua reads.

## F-002 — The corpse's modData rides the turn; nothing fills it for you

*Corrected by F-007 ([A3]): the "nothing fills it" half is false — a third
`copyTable` site fills the corpse from the character unconditionally.*

**Verified** [A2], hand-checked. `IsoDeadBody.reanimate()` copies the
corpse's modData onto the new zombie via `LuaManager.copyTable`
(offsets 234-242: `zombie.getModData() ← this.getModData()`). The class
contains exactly two `copyTable` sites (`reanimate()`, `reanimateAnimal()`),
so the corpse's own modData is NOT populated from the dying character — a
mod stamps the corpse itself (`Events.OnDeadBodySpawn` hands the body;
shipped subscriber `ISWorldObjectContextMenu.lua:2795`). This is ZAO's
identity channel through the turn.

## F-003 — Names do not survive the turn; player corpses carry no descriptor

*Corrected by F-008 ([A3]): the corpse-side half is false — the descriptor
copy is unguarded and player corpses carry the full descriptor. The
zombie-side half (the risen body's fresh, nameless descriptor) stands.*

**Verified** [A2], hand-checked. `reanimate()` constructs a fresh
`SurvivorDesc` copying only gender (offset 56) and voice prefix (60-74) —
no forename/surname call exists in the method. The `IsoDeadBody`
constructor writes `desc` only under `instanceof IsoZombie` (offset 626)
and `instanceof IsoSurvivor` (offset 1019); `getDescriptor()` is a bare
field read. An `IsoPlayer`-class corpse therefore has a null descriptor,
and its zombie a nameless fresh one. Consequence: any turn-recognition
chain built on descriptor names is structurally dead for player-backed
NPCs — including the sister's (`SAO_SEAM_AUDIT.md` §4, reported upstream).

## F-004 — DoZombieStats() re-rolls the per-body knobs, during reanimation

**Verified** [A2], call site hand-checked. `reanimate()` invokes
`IsoZombie.DoZombieStats()` at offset 374; that method reads
`SandboxOptions.instance.lore` values into the public `cognition`,
`strength`, `doorOpeningPercentage` fields (per-field pattern from the [A2]
sweep's disassembly). Any per-body override must land after reanimation and
be re-applied after every engine re-roll; other call sites UNCHECKED
(`ENGINE_CONTRACT.md` §10.5).

## F-005 — The per-body axes already exist, in vanilla's own vocabulary

**Verified** [A2], structural (javap). `IsoZombie` carries public mutable
int fields `speedType, strength, cognition, memory, hearing, sight` —
per-body versions of the same axes the sandbox lore page sets fleet-wide.
`IsoZombie` is final: ZAO drives real zombies, no subclass shell. Whether
Kahlua reaches public FIELDS (vs methods) is UNCHECKED and decides Lua-side
vs Java-side control (`ENGINE_CONTRACT.md` §9).

## F-006 — The unloaded crowd is native and opaque

**Verified** [A2], structural (javap). Unloaded-area zombie population is
owned by `zombie.popman.ZombiePopulationManager` backed by native
`PZPopMan64.dll` (`n_realZombieCount`, `n_spawnHorde`);
`virtualizeZombie(IsoZombie)` hands a real body to the native pool with no
identity-preserving return path visible to Java or Lua. Off-screen
continuity for owned bodies must live in ZAO's record layer, on the
sister's dormant precedent (`SAO_SEAM_AUDIT.md` §6).

## F-007 — The character's modData reaches the corpse by the engine's own hand

**Verified** [A3], hand-checked; supersedes F-002's "nothing fills it"
half after SAO's falsifying pass (SAO F-044..F-047). `IsoDeadBody` has
THREE `copyTable` sites, not two: the `IsoDeadBody(IsoGameCharacter)`
constructor copies the character's modData onto the corpse at offsets
1102-1113 (`this.getModData() ← chr.getModData()`), sitting at the join
point every constructor path reaches — unconditional, every character
class. [A2]'s two-site count was the sweep's, repeated without an
enumeration of my own; this pass enumerated (`grep LuaManager.copyTable`
over the full `javap -p -c` dump: offsets 1110, 242, 159). Consequence:
stamping the LIVING character suffices — the chain character → corpse
(ctor) → risen zombie (`reanimate()` 234-242, F-002's still-true half) is
engine-owned end to end. The corpse's modData also persists while the body
lies there: `IsoObject`'s serialization paths read
`hasModData()/getModData()` (spot-checked in this pass; full offsets in
SAO's receipts).

## F-008 — The corpse knows the name; the risen body does not

**Verified** [A3], hand-checked; supersedes F-003's corpse-side half after
SAO's falsifying pass. In the `IsoDeadBody(IsoGameCharacter)` constructor,
the `instanceof IsoSurvivor` at offset 989 branches `ifeq 1007` — it
guards ONLY the survivor-list removal (995-1006). The descriptor copy at
1007-1019 (`new SurvivorDesc(chr.getDescriptor())` → `desc`) runs for
every non-animal character, `IsoPlayer` included; a player corpse then has
its voice prefix adjusted to Male/FemaleZombie (1035-1064). [A2] inferred
the guard from a truncated context window; the branch target says
otherwise. F-003's zombie-side half STANDS unchanged: `reanimate()` builds
the risen body a fresh descriptor carrying gender and voice prefix only
(offsets 43-74, hand-checked at [A2] and unchanged), and per SAO's pass
`SharedDescriptors.createPlayerZombieDescriptor` opens with
`if (!GameServer.server) return` — a no-op in single player. Net contract:
named-corpse reads are legitimate; the risen body is nameless; identity
through the turn rides modData only (F-007).
