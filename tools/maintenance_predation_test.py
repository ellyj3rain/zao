#!/usr/bin/env python3
"""Border 14: living-state maintenance and Crossed acute flows need evidence."""
from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parent.parent
GAME = Path(os.environ.get(
    "PZ_DIR", r"C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid"))
JDK = Path(os.environ.get(
    "JDK_BIN", r"C:\Users\jleyv\Peanut Butter\JetBrains\Java\bin"))
FILES = [
    ROOT / "mod/42.20/media/lua/shared/ZAO_StateStore.lua",
    ROOT / "mod/42.20/media/lua/shared/ZAO_Maintenance.lua",
    ROOT / "mod/42.20/media/lua/client/ZAO_Predation.lua",
]

RUNNER = r'''
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaThread;
public class MaintenancePredationRun {
    public static void main(String[] args) throws Exception {
        var platform = new J2SEPlatform();
        var env = platform.newEnvironment();
        var thread = new KahluaThread(platform, env);
        thread.debugOwnerThread = Thread.currentThread();
        for (String path : args) {
            try (var reader = Files.newBufferedReader(
                    Path.of(path), StandardCharsets.UTF_8)) {
                thread.call(LuaCompiler.loadis(reader, path, env), null, null, null);
            }
        }
        System.out.println("MAINTENANCE_PREDATION_OK");
    }
}
'''

HOST = r'''
local durable={}
ModData={getOrCreate=function(key)
 durable[key]=durable[key] or {} return durable[key]
end}
Events={OnGameStart={Add=function() end,Remove=function() end}}
CharacterStat={HUNGER='hunger',THIRST='thirst'}

local function body(id,x,y)
 local stats={hunger=.2,thirst=.1}
 local value={id=id,x=x or 0,y=y or 0,health=100,dead=false,
  running=false,sprinting=false,data={SAOPersonId=id},stats=stats}
 function value:getX() return self.x end
 function value:getY() return self.y end
 function value:getZ() return 0 end
 function value:getHealth() return self.health end
 function value:isDead() return self.dead end
 function value:isRunning() return self.running end
 function value:isSprinting() return self.sprinting end
 function value:getUsername() return self.id end
 function value:getModData() return self.data end
 function value:getStats()
  return {get=function(_,key) return stats[key] end,
   set=function(_,key,amount) stats[key]=amount end}
 end
 return value
end

local bodies={}
local deliveryMode='delivered'
local responseMode=nil
local yielded=nil
local activeCombatTarget=nil
local damageOnTick=0
local combatStarts=0

SAO={
 Communication={
  bodyFor=function(id) return bodies[tostring(id)] end,
  deliverThreat=function(fromId,toId,token,evidence)
   if deliveryMode=='missing' then return nil,'not-heard' end
   if deliveryMode=='refused' then return {delivered=false},'not-heard' end
   return {delivered=true,fromId=fromId,toId=toId,token=token,
    evidence=evidence},'delivered'
  end,
  observeThreatResponse=function(toId,fromId,token)
   if responseMode=='flight' then
    return {kind='flight',activity='flee',token=token}
   end
   return nil
  end,
 },
 Handover={
  currentSequence=function() return 7 end,
  completedSince=function(sequence,actorId,recipientId,kind,consumed)
   if yielded and sequence==7 and actorId==yielded.actorId
    and recipientId==yielded.recipientId and kind=='yield'
    and not consumed[yielded.id] then return yielded end
   return nil
  end,
 },
}
ZAO={
 Pathogen={stateOf=function(id)
  return ZAO.StateStore.store().people[tostring(id)]
 end},
 Driver={routeTo=function() return false,'completed' end,
  cancelRoute=function() return true end},
}
SAOJavaBridge={
 beginCombatWithName=function(self,carrier,name)
  combatStarts=combatStarts+1 activeCombatTarget=bodies[name]
  return 'COMBAT_STARTED:'..name
 end,
 tickCombat=function()
  if activeCombatTarget and damageOnTick>0 then
   activeCombatTarget.health=math.max(0,activeCombatTarget.health-damageOnTick)
   if activeCombatTarget.health<=0 then activeCombatTarget.dead=true end
   damageOnTick=0
  end
  return activeCombatTarget and activeCombatTarget.dead
   and 'COMBAT_SUCCEEDED' or 'COMBAT_RUNNING'
 end,
 resetCombat=function() activeCombatTarget=nil return true end,
}

function __body(id,x,y)
 local value=body(id,x,y) bodies[id]=value return value
end
function __state(id,terminal,pressure)
 local state={personId=id,terminalState=terminal,history={}}
 if pressure then state.maintenance={version=1,lastAdvancedHours=0,
  receiptSequence=0,predatory={pressure=pressure}} end
 ZAO.StateStore.store().people[id]=state return state
end
function __delivery(mode) deliveryMode=mode end
function __response(mode) responseMode=mode end
function __yield(value) yielded=value end
function __damage(value) damageOnTick=value end
function __combatStarts() return combatStarts end
function __root() return durable['ZombieAwareness_State'] end
'''

PROBE = r'''
local function near(a,b,epsilon)
 return math.abs(a-b)<(epsilon or .00001)
end

-- Dormant physiology is state-owned: Crossed keep ordinary food viability but
-- accrue caloric pressure at one quarter the survivor rate; water is shared.
local crossed=__state('dormant-crossed','crossed',0)
local crossedBody=__body('dormant-crossed',0,0)
assert(ZAO.Maintenance.advanceDormant('dormant-crossed',crossed,crossedBody,
 10,10)==true)
assert(near(crossedBody:getStats():get(CharacterStat.HUNGER),.23)
 and near(crossedBody:getStats():get(CharacterStat.THIRST),.30),
 'Crossed dormant physiology borrowed survivor hunger or lost human thirst')
local afflicted=__state('dormant-afflicted','afflicted')
local afflictedBody=__body('dormant-afflicted',0,0)
assert(ZAO.Maintenance.advanceDormant('dormant-afflicted',afflicted,
 afflictedBody,10,10)==true)
assert(near(afflictedBody:getStats():get(CharacterStat.HUNGER),.32)
 and near(afflictedBody:getStats():get(CharacterStat.THIRST),.30),
 'Afflicted dormant physiology did not retain distinct caloric pressure')

local whole=__state('whole','crossed',0)
local split=__state('split','crossed',0)
ZAO.Maintenance.advanceState(whole,24)
ZAO.Maintenance.advanceState(split,12)
ZAO.Maintenance.advanceState(split,24)
assert(near(ZAO.Maintenance.predatoryPressure(whole,24),
 ZAO.Maintenance.predatoryPressure(split,24)),
 'predatory pressure changed with dormant partitioning')

local resultState=__state('result-crossed','crossed',.8)
local fear=ZAO.Maintenance.recordPredatoryOutcome('result-crossed',resultState,
 'fear',nil,'exact-fear',1,{targetId='victim'})
local afterFear=ZAO.Maintenance.predatoryPressure(resultState,1)
local replay=ZAO.Maintenance.recordPredatoryOutcome('result-crossed',resultState,
 'fear',.5,'exact-fear',2,{targetId='other'})
local afterReplay=ZAO.Maintenance.predatoryPressure(resultState,2)
local replayAgain=ZAO.Maintenance.recordPredatoryOutcome('result-crossed',
 resultState,'fear',.5,'exact-fear',2,{targetId='third'})
assert(fear==replay and replay==replayAgain and near(afterReplay,
 ZAO.Maintenance.predatoryPressure(resultState,2)),
 'replayed predatory result relieved pressure twice')
local beforeDeath=ZAO.Maintenance.predatoryPressure(resultState,2)
local death=ZAO.Maintenance.recordPredatoryOutcome('result-crossed',resultState,
 'death',nil,'exact-death',2,{targetId='victim'})
assert(death.relief==0 and near(beforeDeath,
 ZAO.Maintenance.predatoryPressure(resultState,2)),
 'death falsely supplied fear, pain, control, or sustenance')

local nutrition=__state('nutrition','afflicted')
local alternative=ZAO.Maintenance.recordAfflictedMeal('nutrition',nutrition,
 {class='alternative'},'alternative',10)
assert(alternative.performancePenalty==.18
 and ZAO.Maintenance.afflictedPenalty(nutrition,20)==.18,
 'non-dairy alternative carried no Afflicted consequence')
ZAO.Maintenance.recordAfflictedMeal('nutrition',nutrition,{class='protein'},
 'protein',21)
assert(ZAO.Maintenance.afflictedPenalty(nutrition,21)==0,
 'protein did not clear the alternative-food penalty')
local weakState=__state('weak-donor','afflicted')
local strongState=__state('strong-donor','afflicted')
local weak=ZAO.Maintenance.recordAfflictedMeal('weak-donor',weakState,
 {class='human',donor={personId='weak',health=0,infectionsSurvived=0,
  immuneProgress=0}},'weak-meal',30)
local strong=ZAO.Maintenance.recordAfflictedMeal('strong-donor',strongState,
 {class='human',donor={personId='strong',health=1,infectionsSurvived=2,
  immuneProgress=.8}},'strong-meal',30)
local protection,source=ZAO.Maintenance.exposureProtection(strongState,31)
assert(strong.crossedProtection>weak.crossedProtection
 and near(protection,strong.crossedProtection)
 and source.sourceToken=='strong-meal',
 'human donor health and Knox adaptation did not affect Afflicted protection')

-- A running target cannot supply fear unless the actual threat delivery was
-- admitted. A refused delivery proceeds to violence without minting hearing.
local noHearState=__state('no-hear','crossed',.8)
local noHear=__body('no-hear',0,0)
local noHearTarget=__body('no-hear-target',2,0) noHearTarget.running=true
__delivery('refused') __response(nil)
local active,activity=ZAO.Predation.step('no-hear',noHear,
 'no-hear-target',noHearTarget,1)
assert(active and activity=='combat'
 and __root().predationActions['no-hear'].threatFailure=='not-heard',
 'refused speech was treated as a heard threat')
for token,row in pairs(__root().maintenanceResults) do
 assert(not (row.personId=='no-hear' and row.kind=='fear'),
  'unheard threat created fear relief')
end

local fearState=__state('fear-carrier','crossed',.8)
local fearCarrier=__body('fear-carrier',0,0)
local fearTarget=__body('fear-target',2,0)
__delivery('delivered') __response('flight')
assert(ZAO.Predation.step('fear-carrier',fearCarrier,'fear-target',fearTarget,1))
local pressureBefore=ZAO.Maintenance.predatoryPressure(fearState,1.02)
assert(ZAO.Predation.step('fear-carrier',fearCarrier,'fear-target',fearTarget,
 1.02)==true)
local pressureAfter=ZAO.Maintenance.predatoryPressure(fearState,1.02)
assert(pressureAfter<pressureBefore,
 'heard threat plus public flight produced no evidenced fear flow')

local controlState=__state('control-carrier','crossed',.8)
local controlCarrier=__body('control-carrier',0,0)
local controlTarget=__body('control-target',2,0)
__response(nil) __yield(nil)
assert(ZAO.Predation.step('control-carrier',controlCarrier,
 'control-target',controlTarget,2))
__yield({id='yield-1',actorId='control-target',recipientId='control-carrier',
 kind='yield',itemId=11,itemType='Base.WaterBottle'})
local continuing,outcome=ZAO.Predation.step('control-carrier',controlCarrier,
 'control-target',controlTarget,2.01)
assert(not continuing and outcome=='control'
 and __root().predationConsumedHandovers['yield-1']==true,
 'control was not bound to one completed post-threat handover')

local painState=__state('pain-carrier','crossed',.8)
local painCarrier=__body('pain-carrier',0,0)
local painTarget=__body('pain-target',2,0)
__delivery('refused') __yield(nil)
assert(ZAO.Predation.step('pain-carrier',painCarrier,
 'pain-target',painTarget,3)==true)
local painBefore=ZAO.Maintenance.predatoryPressure(painState,3.01)
__damage(20)
local fighting,painOutcome=ZAO.Predation.step('pain-carrier',painCarrier,
 'pain-target',painTarget,3.01)
assert(not fighting and painOutcome=='pain' and painTarget.health==80
 and ZAO.Maintenance.predatoryPressure(painState,3.01)<painBefore,
 'pain relief was not bound to actual native health loss')

local reloadState=__state('reload-carrier','crossed',.8)
local reloadCarrier=__body('reload-carrier',0,0)
local reloadTarget=__body('reload-target',2,0)
assert(ZAO.Predation.step('reload-carrier',reloadCarrier,
 'reload-target',reloadTarget,4)==true)
ZAO.Predation.runtimeCombats={}
ZAO.Predation.resumePending(5)
local reloadResult=nil
for _,row in pairs(__root().predationResults) do
 if row.carrierId=='reload-carrier' then reloadResult=row end
end
assert(reloadResult and reloadResult.outcome=='interrupted'
 and reloadResult.reason=='runtime-reconstructed',
 'reload invented completion for a lost native combat handle')
'''


def run(work: Path, sources: dict[str, str]) -> subprocess.CompletedProcess[str]:
    paths = [str(work / "host.lua")]
    for index, path in enumerate(FILES):
        target = work / f"source-{index}.lua"
        target.write_text(sources[path.name], encoding="utf-8")
        paths.append(str(target))
    paths.append(str(work / "probe.lua"))
    return subprocess.run(
        [str(JDK / "java.exe"), "-cp",
         f"{GAME / 'projectzomboid.jar'}{os.pathsep}{work}",
         "MaintenancePredationRun", *paths], cwd=work,
        capture_output=True, text=True, timeout=30)


def main() -> int:
    required = [GAME / "projectzomboid.jar", GAME / "stdlib.lua",
                JDK / "java.exe", JDK / "javac.exe", *FILES]
    if not all(path.is_file() for path in required):
        print("Border 14 SKIPPED: installed game VM, JDK, or source absent")
        return 0
    sources = {path.name: path.read_text(encoding="utf-8-sig") for path in FILES}
    controls = [
        ("Crossed reduced caloric pressure", "ZAO_Maintenance.lua",
         "and Maintenance.profile.crossedCaloricFactor or 1.0",
         "and 1.0 or 1.0"),
        ("exact-once predatory result", "ZAO_Maintenance.lua",
         'or state.terminalState ~= "crossed" then return nil end\n'
         "    if root.maintenanceResults[token] then return root.maintenanceResults[token] end",
         'or state.terminalState ~= "crossed" then return nil end\n'
         "    if false then return root.maintenanceResults[token] end"),
        ("death is not acute relief", "ZAO_Maintenance.lua",
         "death = 0.0,", "death = 0.20,"),
        ("donor-conditioned protection", "ZAO_Maintenance.lua",
         "0.12 + health * 0.20 + adaptation * 0.43",
         "0.12 + health * 0.0 + adaptation * 0.0"),
        ("hearing gates fear", "ZAO_Predation.lua",
         'if type(receipt) ~= "table" or receipt.delivered ~= true then',
         "if false then"),
        ("completed yield gates control", "ZAO_Predation.lua",
         "if yielded then", "if false then"),
        ("health delta gates pain", "ZAO_Predation.lua",
         "if before and after and after < before - 0.001 then",
         "if false then"),
    ]
    for name, file_name, old, _ in controls:
        if sources[file_name].count(old) != 1:
            print(f"REFUSED: {name} mutation seam changed")
            return 1
    with tempfile.TemporaryDirectory(prefix="zao-maintenance-predation-") as tmp:
        work = Path(tmp)
        shutil.copy2(GAME / "stdlib.lua", work / "stdlib.lua")
        (work / "MaintenancePredationRun.java").write_text(RUNNER, encoding="utf-8")
        (work / "host.lua").write_text(HOST, encoding="utf-8")
        (work / "probe.lua").write_text(PROBE, encoding="utf-8")
        built = subprocess.run(
            [str(JDK / "javac.exe"), "-cp", str(GAME / "projectzomboid.jar"),
             "MaintenancePredationRun.java"], cwd=work,
            capture_output=True, text=True, timeout=120)
        if built.returncode:
            print("REFUSED: maintenance runner did not compile\n" + built.stderr)
            return 1
        production = run(work, sources)
        if production.returncode or "MAINTENANCE_PREDATION_OK" not in production.stdout:
            print("REFUSED: maintenance/predation production path failed")
            print(production.stdout + production.stderr)
            return 1
        for name, file_name, old, new in controls:
            changed = dict(sources)
            changed[file_name] = changed[file_name].replace(old, new, 1)
            result = run(work, changed)
            if result.returncode == 0:
                print(f"REFUSED: {name} control survived")
                return 1
    print("Border 14 PASS: Afflicted and Crossed maintenance stays distinct across dormancy; completed nutrition and acute predatory effects are exact-once; heard flight, native pain, and completed yield each require their own evidence; death grants none; seven controls fail")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
