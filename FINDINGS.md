| Document | Zombie Awareness Overhaul Findings |
|---|---|
| Version | `0.1.1.0-pre-alpha` |
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

**Verified** [A2], hand-checked. `IsoDeadBody.reanimate()` copies the
corpse's modData onto the new zombie via `LuaManager.copyTable`
(offsets 234-242: `zombie.getModData() ← this.getModData()`). The class
contains exactly two `copyTable` sites (`reanimate()`, `reanimateAnimal()`),
so the corpse's own modData is NOT populated from the dying character — a
mod stamps the corpse itself (`Events.OnDeadBodySpawn` hands the body;
shipped subscriber `ISWorldObjectContextMenu.lua:2795`). This is ZAO's
identity channel through the turn.

## F-003 — Names do not survive the turn; player corpses carry no descriptor

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
