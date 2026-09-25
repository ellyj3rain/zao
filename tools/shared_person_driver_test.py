#!/usr/bin/env python3
"""Border 12: one ZAO driver owns distinct Afflicted/Crossed conduct."""
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
    ROOT / "mod/42.20/media/lua/shared/ZAO_Settlement.lua",
    ROOT / "mod/42.20/media/lua/shared/ZAO_Mind.lua",
    ROOT / "mod/42.20/media/lua/client/ZAO_Afflicted.lua",
    ROOT / "mod/42.20/media/lua/client/ZAO_Crossed.lua",
    ROOT / "mod/42.20/media/lua/client/ZAO_Driver.lua",
]

RUNNER = r'''
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaThread;
public class SharedPersonDriverRun {
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
        System.out.println("SHARED_PERSON_DRIVER_OK");
    }
}
'''

HOST = r'''
local durable = {}
ModData = { getOrCreate = function(key)
 durable[key] = durable[key] or {} return durable[key]
end }
Events = { OnGameStart = { Add=function() end, Remove=function() end } }
ISTimedActionQueue = { queues = {} }

local function body(id,x,y)
 local value={id=id,x=x,y=y,data={SAOPersonId=id},asleep=false,running=false}
 function value:getX() return self.x end
 function value:getY() return self.y end
 function value:getZ() return 0 end
 function value:getModData() return self.data end
 function value:isRunning() return self.running end
 function value:isSprinting() return false end
 function value:setSitOnGround(v) self.sitting=v end
 return value
end
local afflicted=body('afflicted',10,10)
local peer=body('peer',15,10)
local crossed=body('crossed',12,10)
local nearHuman=body('nearHuman',14,10)
local farHuman=body('farHuman',22,10)
farHuman.running=true
local records={
 afflicted={id='afflicted',dead=false,traitEchoes={aggression=.05}},
 peer={id='peer',dead=false,traitEchoes={aggression=.05}},
 crossed={id='crossed',dead=false,traitEchoes={aggression=.05}},
 nearHuman={id='nearHuman',dead=false,traitEchoes={}},
 farHuman={id='farHuman',dead=false,traitEchoes={}},
}
local needs={hunger=.9,thirst=0,fatigue=0,endurance=0}
local drinkCalls,eatCalls,physicalCalls,crossedCalls=0,0,0,0
local routeComplete=false
local routeOrders={}
local outcastCandidate=nil
local outcastCompletions=0
local personalSource=nil
local sourceTickResult='pending'

SAOJavaBridge = {
 canSeePersonNow=function() return true end,
 setShellAsleep=function(self,seen,value) seen.asleep=value end,
 restRecoverTick=function() return true end,
 hunger=function() return needs.hunger end,
}
SAO = {
 Identity={
  get=function(id) return records[tostring(id)] end,
  all=function() return records end,
  idByName=function(name)
   if name=='Crossed' then return 'crossed' end
   if name=='Peer' then return 'peer' end
   if name=='Near' then return 'nearHuman' end
   if name=='Far' then return 'farHuman' end
   return records[name] and name or nil
  end,
 },
 Perception={beliefs={
  afflicted={people={},zombies={}}, peer={people={},zombies={}},
  crossed={people={},zombies={}},
 },freshObservedPerson=function(id,key,tick)
  local belief=SAO.Perception.beliefs[id]
   and SAO.Perception.beliefs[id].people[key] or nil
  if belief and belief.source=='observed' and not belief.dead
   and tick-belief.at<=120 then return belief end
  return nil
 end},
 Communication={bodyFor=function(id)
  return ZAO.Controller.controlled[tostring(id)]
 end},
 PhysicalFacts={refreshBodyFacts=function() physicalCalls=physicalCalls+1 return true end},
 Needs={
  read=function() return needs end,
  cold=function() return 0 end,
  bleeding=function() return 0 end,
  bandageSelf=function() return false end,
  drinkCarried=function() drinkCalls=drinkCalls+1 return true end,
  findWater=function() return nil end,
  queueDrinkFrom=function() return false end,
  eatCarried=function() eatCalls=eatCalls+1 return true end,
 },
 Disposition={
  traits=function() return {aggression=.8,selfPreservation=.7,
   discipline=.6,initiative=.5,nerve=.4,compassion=.2} end,
  drinkAt=function() return .3 end,
 },
 Gesture={standUp=function() end},
 Controller={coordinationRuntime={},advanceExternalCoordination=function() return false end},
 WorldSources={pendingActionFor=function(id)
  return tostring(id)=='afflicted' and personalSource or nil
 end},
 SourceUse={
  onMovementDone=function(id,seen,status)
   if status=='done:arrived' then
    personalSource.phase=personalSource.phase=='approaching-place'
     and 'approaching-source' or 'transferring'
    return personalSource.phase=='approaching-source' and 'moving' or 'using'
   end
   return 'failed'
  end,
  tick=function()
   local result=sourceTickResult
   if result~='pending' then personalSource=nil end
   return result
  end,
  interrupt=function() personalSource=nil return true end,
  closeForOwnershipTransfer=function() personalSource=nil return true end,
 },
 Locomotion={jobs={},
  order=function(id,seen,x,y,z,running)
   SAO.Locomotion.jobs[id]={body=seen}
   routeOrders[#routeOrders+1]={id=id,x=x,y=y,kind=running and 'run' or 'walk'}
   return true
  end,
  tick=function() end,
  status=function() return routeComplete and 'done:arrived' or 'moving' end,
  cancel=function(id) SAO.Locomotion.jobs[id]=nil return true end,
 },
 Standing={
  groupOf=function() return nil end,
  relationsOf=function() return {remembered=.6} end,
  claimOf=function() return nil end,
  groupClaimOf=function() return nil end,
  trust=function() return .1 end,
  keyForObserved=function(name) return SAO.Identity.idByName(name) end,
  outcastDriftDestination=function() return outcastCandidate end,
  completeOutcastDrift=function(id,seen,candidate)
   assert(id=='afflicted' and seen==afflicted and candidate==outcastCandidate)
   outcastCompletions=outcastCompletions+1 return true
  end,
 },
 Rand={unit=function() return 0 end},
}
ZAO = {
 Controller={controlled={}},
 Pathogen={stateOf=function(id)
  return ZAO.StateStore.store().people[tostring(id)]
 end},
 Sandbox={policy=function() return {settlementOdds=1} end},
 State={of=function(rec)
  return ZAO.StateStore.store().people[tostring(rec.id)]
 end},
}
ZAO.Maintenance={predatoryPressure=function(state)
 return tonumber(state and state.testPredatoryPressure) or 0
end}

function __body(which)
 if which=='afflicted' then return afflicted end
 if which=='peer' then return peer end
 if which=='nearHuman' then return nearHuman end
 if which=='farHuman' then return farHuman end
 return crossed
end
function __mind(which)
 local seen=which=='crossed' and crossed or afflicted
 return ZAO.Mind.of(records[which or 'afflicted'],1,seen)
end
function __needs(hunger,thirst,fatigue)
 needs.hunger=hunger needs.thirst=thirst needs.fatigue=fatigue needs.endurance=0
end
function __counts() return drinkCalls,eatCalls,physicalCalls,crossedCalls,
 #routeOrders,outcastCompletions end
function __controlled(mode)
 local people=SAO.Perception.beliefs.afflicted.people
 for key in pairs(people) do people[key]=nil end
 local crossedPeople=SAO.Perception.beliefs.crossed.people
 for key in pairs(crossedPeople) do crossedPeople[key]=nil end
 if mode=='threat' then ZAO.Controller.controlled={afflicted=afflicted,crossed=crossed}
 elseif mode=='peers' then ZAO.Controller.controlled={afflicted=afflicted,peer=peer}
 elseif mode=='crossed' then ZAO.Controller.controlled={crossed=crossed}
 elseif mode=='crossed_afflicted' then
  ZAO.Controller.controlled={crossed=crossed,afflicted=afflicted}
 elseif mode=='crossed_targets' or mode=='global_only' then
  ZAO.Controller.controlled={crossed=crossed,nearHuman=nearHuman,farHuman=farHuman}
 else ZAO.Controller.controlled={afflicted=afflicted} end
 if mode=='threat' then people.Crossed={id='crossed',source='observed',at=0,x=12,y=10} end
 if mode=='peers' then people.Peer={id='peer',source='observed',at=0,x=15,y=10} end
 if mode=='crossed_targets' then
  crossedPeople.Near={id='nearHuman',source='observed',at=7,x=14,y=10}
  crossedPeople.Far={id='farHuman',source='observed',at=7,x=22,y=10}
 end
 if mode=='crossed_afflicted' then
  crossedPeople.afflicted={id='afflicted',source='observed',at=7,x=10,y=10}
 end
end
function __routeComplete(value) routeComplete=value end
function __outcast(value)
 outcastCandidate=value and {id='ruin',place={cx=30,cy=40,minX=28},visits=3} or nil
end
function __personalSource(phase,outcome)
 if not phase then personalSource=nil return end
 personalSource={id='personal-source',actorId='afflicted',status='reserved',
  nativeUseOwner='ZAO.Diet',phase=phase}
 sourceTickResult=outcome or 'pending'
end
'''

SETUP = r'''
local root=ZAO.StateStore.store()
root.people.afflicted={personId='afflicted',terminalState='afflicted',history={}}
root.people.peer={personId='peer',terminalState='afflicted',history={}}
root.people.crossed={personId='crossed',terminalState='crossed',history={}}
'''

PROBE = r'''
local afflicted,peer,crossed=__body('afflicted'),__body('peer'),__body('crossed')
local mind=__mind('afflicted')
local crossedMind=__mind('crossed')
local astate=ZAO.Pathogen.stateOf('afflicted')
local cstate=ZAO.Pathogen.stateOf('crossed')
local asnap=ZAO.Driver.snapshot('afflicted',SAO.Identity.get('afflicted'),
 afflicted,astate,mind)
local csnap=ZAO.Driver.snapshot('crossed',SAO.Identity.get('crossed'),
 crossed,cstate,crossedMind)
assert(asnap.executor=='ZAO.Driver' and csnap.executor=='ZAO.Driver',
 'states do not share the ZAO driver')
local dormantMind=ZAO.Mind.of(SAO.Identity.get('afflicted'),1,nil)
local dormantSnap=ZAO.Driver.snapshot('afflicted',
 SAO.Identity.get('afflicted'),nil,astate,dormantMind)
assert(dormantSnap.represented==false and dormantSnap.canExecute==false
 and dormantSnap.canAcquire==false and dormantSnap.canCarry==false
 and dormantSnap.canDeliver==false,
 'dormant ZAO person claimed executable native work without a body')
assert(mind.perception.beliefs==SAO.Perception.beliefs.afflicted
 and mind.disposition.aggression==.8
 and mind.standing.relations.remembered==.6
 and mind.inputOwners.perception=='SAO.Perception',
 'ZAO mind did not consume the real person-owned pillar stores')
assert(asnap.competingPressure==.9 and csnap.competingPressure==.9
 and asnap.inputOwners.competingPressure=='SAO.Needs via ZAO.Mind',
 'execution snapshot replaced body pressure with a species diet rule')

__needs(.9,.9,0) __controlled('threat')
assert(ZAO.Driver.step('afflicted',afflicted,astate,mind,1,1)==true,
 'Afflicted threat did not commit')
assert(astate.driver.route and astate.driver.route.kind=='flee',
 'body need displaced the established Crossed fear response')
ZAO.Driver.cancelRoute('afflicted',astate,'test',1)

__needs(.1,.1,.1) __controlled('peers')
assert(ZAO.Driver.step('afflicted',afflicted,astate,mind,2,2)==true,
 'groupless Afflicted did not gather')
assert(astate.driver.route and astate.driver.route.kind=='afflicted-gather',
 'Afflicted gathering did not use the shared durable route')
ZAO.Driver.cancelRoute('afflicted',astate,'test',2)

__controlled('alone') __outcast(true) __routeComplete(true)
assert(ZAO.Driver.step('afflicted',afflicted,astate,mind,3,3)==true,
 'Afflicted did not complete evidenced outcast travel')
local d,e,p,c,routes,settled=__counts()
assert(settled==1 and astate.driver.route==nil,
 'claim owner ran before arrival or route remained live')
local groundedReceipt=nil
for _,result in pairs(ZAO.StateStore.store().driverResults) do
 if result.kind=='afflicted-outcast' then groundedReceipt=result end
end
assert(groundedReceipt and groundedReceipt.targetId=='ruin',
 'Afflicted completion was not bound to the known building key')
__outcast(false) __routeComplete(false)

__needs(.9,.8,0) __controlled('alone')
assert(ZAO.Driver.step('afflicted',afflicted,astate,mind,4,4)==true
 and astate.driver.currentActivity=='drinking',
 'Afflicted human thirst did not execute through the shared driver')
__controlled('crossed')
assert(ZAO.Driver.step('crossed',crossed,cstate,crossedMind,5,5)==true)
d,e,p,c,routes,settled=__counts()
assert(d==2 and e==0 and p>=1 and c==0,
 'both living states did not retain shared water physiology')

__needs(.9,0,.9)
assert(ZAO.Driver.step('crossed',crossed,cstate,crossedMind,6,6)==true)
assert(crossed.asleep==true and cstate.driver.currentActivity=='resting',
 'Crossed human fatigue did not reach native rest')

__needs(.1,0,.1)
ZAO.Driver.step('crossed',crossed,cstate,crossedMind,6,6.1)
assert(crossed.asleep==false and cstate.driver.resting==nil,
 'completed Crossed rest remained an active option')

__controlled('alone') __needs(.1,0,.1) __routeComplete(false)
__personalSource('approaching-place','pending')
assert(ZAO.Driver.step('afflicted',afflicted,astate,mind,6,6.2)==true
 and astate.driver.currentActivity=='acquiring-food'
 and ZAO.Driver.currentActivity('afflicted',afflicted,astate)=='acquiring-food',
 'shared driver did not advance the personal SourceUse route')
__personalSource('using','pending')
assert(ZAO.Driver.step('afflicted',afflicted,astate,mind,6,6.3)==true
 and astate.driver.currentActivity=='feeding',
 'shared driver did not serialize native SourceUse consumption')
__personalSource('native-complete','completed')
assert(ZAO.Driver.step('afflicted',afflicted,astate,mind,6,6.4)==true
 and astate.driver.currentActivity=='food-source-completed',
 'shared driver inferred idleness before the SourceUse receipt closed')

__controlled('global_only')
local hiddenOptions=ZAO.Crossed.options(crossed,'crossed',cstate,
 crossedMind,7,7)
for _,option in ipairs(hiddenOptions) do
 assert(option.kind~='predation',
  'controller-wide bodies became Crossed targets without private perception')
end
__controlled('crossed_afflicted')
cstate.testPredatoryPressure=1
local afflictedOptions=ZAO.Crossed.options(crossed,'crossed',cstate,
 crossedMind,7,7)
local exposureSeen,predationSeen=false,false
for _,option in ipairs(afflictedOptions) do
 if option.targetId=='afflicted' and option.kind=='exposure' then
  exposureSeen=true
 end
 if option.targetId=='afflicted' and option.kind=='predation' then
  predationSeen=true
 end
end
assert(exposureSeen and not predationSeen,
 'Afflicted exposure disappeared or fell through to Crossed prey selection')
cstate.testPredatoryPressure=nil
__controlled('crossed_targets')
local crossedOptions=ZAO.Crossed.options(crossed,'crossed',cstate,
 crossedMind,7,7)
local selected=ZAO.Driver.chooseOption(crossedOptions)
assert(selected and selected.kind=='predation'
 and selected.targetId=='farHuman',
 'Crossed strategy collapsed to nearest-human pursuit instead of using the actor evidence')

ZAO.Settlement.groups={} ZAO.Settlement.lingering={}
for _,day in ipairs({1,2}) do
 for _,id in ipairs({'a','b','c'}) do
  assert(ZAO.Settlement.notePresence('yard',id,day,'afflicted',
   {x=1,y=2,z=0})==nil,'proximity without holding evidence formed a settlement')
 end
end
ZAO.Settlement.groups={} ZAO.Settlement.lingering={}
local afflictedHold={activity='gathered',activityRevision=2,observedAtHours=6}
local crossedHold={activity='holding-with-kin',activityRevision=3,
 observedAtHours=6}
for day=1,3 do
 for scan=1,20 do
  assert(ZAO.Settlement.notePresence('yard','afflicted',day,'afflicted',
   {x=1,y=2,z=0},afflictedHold)==nil,
   'one body impersonated a settlement')
 end
end
ZAO.Settlement.groups={} ZAO.Settlement.lingering={}
for _,id in ipairs({'a','b'}) do
 ZAO.Settlement.notePresence('yard',id,1,'afflicted',{x=1,y=2,z=0},
  afflictedHold)
 ZAO.Settlement.notePresence('yard',id,1,'crossed',{x=1,y=2,z=0},
  crossedHold)
end
assert(ZAO.Settlement.notePresence('yard','c',2,'afflicted',
 {x=1,y=2,z=0},afflictedHold)==nil,
 'mixed terminal states formed one group')
ZAO.Settlement.groups={} ZAO.Settlement.lingering={}
for _,day in ipairs({1,2}) do
 local formed=nil
 for _,id in ipairs({'a','b','c'}) do
  formed=ZAO.Settlement.notePresence('yard',id,day,'afflicted',
    {x=11,y=12,z=0},afflictedHold) or formed
 end
 if day==2 then
  assert(formed and formed.kind=='afflicted' and formed.place.x==11
    and formed.members.a and formed.members.b and formed.members.c
    and formed.formationEvidence.members.a.activity=='gathered',
    'distinct Afflicted holding acts did not form an evidenced grounded group')
 end
end

__needs(.9,.1,.2)
assert(SAOJavaBridge:hunger(crossed)==.9,'hunger bridge fixture failed')
local afflictedPressure,ap=ZAO.Driver.settlementPressure(
 'afflicted',afflicted,astate)
local crossedPressure,cp=ZAO.Driver.settlementPressure(
 'crossed',crossed,cstate)
assert(afflictedPressure==.9 and ap.hunger==.9
 and ap.satisfierOwner=='ZAO.Afflicted',
 'Afflicted body hunger disappeared because its satisfier is unfinished')
assert(crossedPressure==.9 and cp.hunger==.9
 and cp.satisfierOwner=='ZAO.Crossed',
 'Crossed physiological hunger was lost from settlement necessity: '
  ..tostring(crossedPressure)..':'..tostring(cp and cp.hunger)..':'
  ..tostring(cp and cp.satisfierOwner))
'''


def run(work: Path, sources: dict[str, str]) -> subprocess.CompletedProcess[str]:
    paths: list[str] = [str(work / "host.lua")]
    for index, path in enumerate(FILES):
        target = work / f"source-{index}.lua"
        target.write_text(sources[path.name], encoding="utf-8")
        paths.append(str(target))
    paths.extend([str(work / "setup.lua"), str(work / "probe.lua")])
    return subprocess.run(
        [str(JDK / "java.exe"), "-cp",
         f"{GAME / 'projectzomboid.jar'}{os.pathsep}{work}",
         "SharedPersonDriverRun", *paths], cwd=work,
        capture_output=True, text=True, timeout=30)


def main() -> int:
    required = [GAME / "projectzomboid.jar", GAME / "stdlib.lua",
                JDK / "java.exe", JDK / "javac.exe", *FILES]
    if not all(path.is_file() for path in required):
        print("Border 12 SKIPPED: installed game VM, JDK, or source absent")
        return 0
    sources = {path.name: path.read_text(encoding="utf-8-sig") for path in FILES}
    controls = [
        ("distinct settlement participants", "ZAO_Settlement.lua",
         "if not linger.members[personId] then", "if true then"),
        ("holding evidence before formation", "ZAO_Settlement.lua",
         'if kind ~= "turned" then', "if false then"),
        ("Afflicted shares human physiology", "ZAO_Afflicted.lua",
         "if ZAO.Driver and ZAO.Driver.humanPhysiologyOptions then",
         "if false then"),
        ("Afflicted-only gathering", "ZAO_Afflicted.lua",
         'person.state == "afflicted"',
         'person.state == "crossed"'),
        ("real Disposition pillar", "ZAO_Mind.lua",
         'and SAO.Disposition.traits(id) or nil',
         'and nil or nil'),
        ("hunger remains a body pressure", "ZAO_Driver.lua",
         'local hunger = clamp01(needs and needs.hunger or 0)',
         'local hunger = 0'),
        ("dormant execution requires a body", "ZAO_Driver.lua",
         'local canAct = body ~= nil and rec and rec.dead ~= true and mind',
         'local canAct = rec and rec.dead ~= true and mind'),
        ("personal acquisition remains SourceUse-owned", "ZAO_Driver.lua",
         'and tostring(reservation.nativeUseOwner or "") == "ZAO.Diet" then',
         'and false then'),
        ("Crossed target evidence", "ZAO_Crossed.lua",
         '+ observedFear * 12 - distanceCost',
         '+ observedFear * 0 - distanceCost'),
        ("Afflicted exposure is not prey selection", "ZAO_Crossed.lua",
         'if person.state == "afflicted" then',
         "if false then"),
        ("visible rather than hidden fear evidence", "ZAO_Mind.lua",
         'fresh.zaoVisibleDistress = visibleDistress(other)',
         'fresh.zaoVisibleDistress = 0'),
    ]
    for name, file_name, old, _ in controls:
        if sources[file_name].count(old) != 1:
            print(f"REFUSED: {name} mutation seam changed")
            return 1
    with tempfile.TemporaryDirectory(prefix="zao-shared-driver-") as tmp:
        work = Path(tmp)
        shutil.copy2(GAME / "stdlib.lua", work / "stdlib.lua")
        (work / "SharedPersonDriverRun.java").write_text(RUNNER, encoding="utf-8")
        (work / "host.lua").write_text(HOST, encoding="utf-8")
        (work / "setup.lua").write_text(SETUP, encoding="utf-8")
        (work / "probe.lua").write_text(PROBE, encoding="utf-8")
        built = subprocess.run(
            [str(JDK / "javac.exe"), "-cp", str(GAME / "projectzomboid.jar"),
             "SharedPersonDriverRun.java"], cwd=work,
            capture_output=True, text=True, timeout=120)
        if built.returncode:
            print("REFUSED: shared driver runner did not compile\n" + built.stderr)
            return 1
        production = run(work, sources)
        if production.returncode or "SHARED_PERSON_DRIVER_OK" not in production.stdout:
            print("REFUSED: shared person driver production path failed")
            print(production.stdout + production.stderr)
            return 1
        for name, file_name, old, new in controls:
            changed = dict(sources)
            changed[file_name] = changed[file_name].replace(old, new, 1)
            result = run(work, changed)
            if result.returncode == 0:
                print(f"REFUSED: {name} control survived")
                return 1
    print("Border 12 PASS: one ZAO driver arbitrates distinct living-state options from real Perception, Disposition and Standing inputs; dormant people cannot execute native work without a body; Afflicted fear, gathering and evidenced travel coexist with shared human physiology; personal acquisition stays serialized under SAO SourceUse; Crossed strategy uses privately visible distress while Afflicted exposure cannot fall through to prey selection; distinct-person settlement formation is required; eleven controls fail")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
