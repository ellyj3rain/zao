#!/usr/bin/env python3
"""Border 13: Crossed human diet and blooded-weapon actions are physical."""
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
    ROOT / "mod/42.20/media/lua/client/ZAO_Diet.lua",
    ROOT / "mod/42.20/media/lua/client/ZAO_Contamination.lua",
]

RUNNER = r'''
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaThread;
public class CrossedMaterialActionsRun {
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
        System.out.println("CROSSED_MATERIAL_ACTIONS_OK");
    }
}
'''

HOST = r'''
require=function() return true end
local function derive(base)
 local child={} child.__index=child
 setmetatable(child,{__index=base})
 return child
end
ISBaseTimedAction={}
function ISBaseTimedAction:derive() return derive(self) end
function ISBaseTimedAction:new(character)
 return setmetatable({character=character},self)
end
function ISBaseTimedAction.stop() end
function ISBaseTimedAction.perform() end
function ISBaseTimedAction:setActionAnim() end
function ISBaseTimedAction:setOverrideHandModels() end
ISEatFoodAction=ISBaseTimedAction:derive('ISEatFoodAction')
function ISEatFoodAction:new(character,item)
 local value=ISBaseTimedAction.new(self,character) value.item=item return value
end
function ISEatFoodAction.stop() end
function ISEatFoodAction.complete() return true end
ISAddItemInRecipe={}
function ISAddItemInRecipe.complete(action)
 action.baseItem.extras[#action.baseItem.extras+1]=action.usedItem:getFullType()
 return true
end

local durable={}
ModData={getOrCreate=function(key) durable[key]=durable[key] or {} return durable[key] end}
Events={
 OnGameStart={Add=function() end,Remove=function() end},
 OnWeaponSwing={Add=function() end,Remove=function() end},
 OnWeaponHitCharacter={Add=function() end,Remove=function() end},
 OnPlayerAttackFinished={Add=function() end,Remove=function() end},
 OnTick={Add=function() end,Remove=function() end},
}
ItemTag={SHARP_KNIFE='SharpKnife'}
instanceof=function(value,kind) return value and value.kind==kind end

local nextId=100
local function list(values)
 return {size=function() return #values end,
  get=function(_,index) return values[index+1] end}
end
local function item(fullType,kind)
 nextId=nextId+1
 local value={fullType=fullType,kind=kind or 'Food',id=nextId,data={},extras={}}
 function value:getFullType() return self.fullType end
 function value:getID() return self.id end
 function value:getModData() return self.data end
 function value:getExtraItems() return list(self.extras) end
 function value:getProteins() return self.proteins or 6 end
 function value:getLipids() return self.lipids or 2 end
 function value:getCarbohydrates() return self.carbohydrates or 4 end
 function value:getCalories() return self.calories or 300 end
 function value:getHungerChange() return -.2 end
 function value:getMilkType() return self.milk end
 function value:isBroken() return false end
 function value:hasTag(tag) return self.sharp==true and tag==ItemTag.SHARP_KNIFE end
 function value:isRanged() return self.ranged==true end
 function value:getCurrentAmmoCount() return self.ammo or 0 end
 return value
end
local regular=item('Base.CannedBeans')
local flesh=item('ZombieAwareness.HumanFlesh')
flesh.data.ZAOHumanOrigin='ordinary-human-corpse'
flesh.data.ZAODonorTerminalState='ordinary'
local stew=item('Base.Stew') stew.extras={'ZombieAwareness.HumanFlesh'}
local ordinaryStew=item('Base.Stew') ordinaryStew.extras={'Base.Carrots'}
local afflictedFlesh=item('ZombieAwareness.HumanFlesh')
afflictedFlesh.data.ZAOHumanOrigin='afflicted-human-corpse'
afflictedFlesh.data.ZAODonorPersonId='afflicted'
afflictedFlesh.data.ZAODonorTerminalState='afflicted'
local afflictedStew=item('Base.Stew')
local knife=item('Base.KitchenKnife','HandWeapon') knife.sharp=true
local ranged=item('Base.Pistol','HandWeapon') ranged.ranged=true ranged.ammo=2

local inventory={items={knife}}
function inventory:getFirstEvalRecurse(predicate)
 for _,value in ipairs(self.items) do if predicate(value) then return value end end
 return nil
end
function inventory:AddItem(fullType)
 local value=item(fullType) self.items[#self.items+1]=value return value
end
local carrier={x=10,y=10,data={SAOPersonId='carrier'},primary=knife}
function carrier:getX() return self.x end
function carrier:getY() return self.y end
function carrier:getZ() return 0 end
function carrier:getModData() return self.data end
function carrier:getPrimaryHandItem() return self.primary end
function carrier:getInventory() return inventory end
function carrier:isTimedActionInstant() return false end
function carrier:getCell() return {getGridSquare=function() return nil end} end
function carrier:faceThisObject() end
function carrier:shouldBeTurning() return false end
function carrier:SetVariable() end
function carrier:reportEvent() end

local function target(id)
 local value={data={SAOPersonId=id},x=11,y=10}
 function value:getModData() return self.data end
 function value:getX() return self.x end
 function value:getY() return self.y end
 function value:getZ() return 0 end
 function value:getUsername() return id end
 return value
end
local human=target('human')
local afflicted=target('afflicted')
local otherCrossed=target('otherCrossed')

local function corpse(id,zombie,animal,form)
 nextId=nextId+1
 local value={data={SAOPersonId=id},id=nextId,x=11,y=10,
  zombie=zombie==true,animal=animal==true}
 if form then value.data.ZAOForm=form end
 function value:getModData() return self.data end
 function value:getObjectIDAsLong() return self.id end
 function value:getX() return self.x end
 function value:getY() return self.y end
 function value:getZ() return 0 end
 function value:isZombie() return self.zombie end
 function value:isAnimal() return self.animal end
 return value
end
local humanCorpse=corpse('human',false,false)
local afflictedCorpse=corpse('afflicted',false,false)
local zombieCorpse=corpse('zombie',true,false)
local animalCorpse=corpse('animal',false,true)
local mutantCorpse=corpse('mutant',false,false,'Husk')

local queued=nil
local queueAccept=true
local applyCalls,exposureCalls,ownershipCalls,physicalCalls,ordinaryEatCalls=0,0,0,0,0
local observedFood=nil
local sourceBegin=nil
local nativeUseOwners={}
SAO={
 Needs={queueVerified=function(action) queued=action return queueAccept end,
  eatCarried=function(id,seen)
   assert(id=='carrier' and seen==carrier)
   ordinaryEatCalls=ordinaryEatCalls+1 return true
  end},
 Identity={get=function(id) return id=='human' and {id='human'} or nil end},
 PhysicalFacts={refreshBodyFacts=function() physicalCalls=physicalCalls+1 end},
 History={countyHours=function() return 12 end},
 Places={comfortHorizon=function() return 40 end,
  commitHorizon=function() return 120 end},
 WorldSources={nearestObserved=function(id,x,y,category,horizon)
  if observedFood and id=='carrier' and category=='food' then return observedFood end
  return nil
 end},
 SourceUse={
  registerNativeUseOwner=function(owner,adapter)
   nativeUseOwners[owner]=adapter return true
  end,
  begin=function(id,body,place,category,admission,context)
   if not nativeUseOwners[context and context.nativeUseOwner] then
    return false,'native-use-owner-unavailable'
   end
   sourceBegin={id=id,body=body,place=place,category=category,
    admission=admission,context=context}
   return true,{id='source-reservation'}
  end,
 },
}
ZAO={Controller={controlled={carrier=carrier}}}
ZAO.Pathogen={
 stateOf=function(id) return ZAO.StateStore.store().people[tostring(id)] end,
 expose=function(id,carrierState,day,result)
  local pending=ZAO.StateStore.store().contaminationHits[result.token]
  assert(pending and pending.phase=='resolving' and result.targetId==id)
  exposureCalls=exposureCalls+1
  ZAO.StateStore.store().people[id].terminalState='crossed'
  return {converted=true,token=result.token}
 end,
}
ZAO.Exposure={ensureCrossedOwnership=function()
 ownershipCalls=ownershipCalls+1 return true,'transferred'
end}
ZAO.Driver={routeTo=function() return false,'unavailable' end,cancelRoute=function() end}
ZAOJavaBridge={
 hunger=function() return .8 end,
 applyCrossedBlood=function()
  applyCalls=applyCalls+1 return 'APPLIED:ForeArm_L'
 end,
}
SAOJavaBridge={findCarriedFood=function()
 for _,value in ipairs(inventory.items) do
  if value.kind=='Food' then return value end
 end
 return nil
end}

function __item(name)
 if name=='regular' then return regular end
 if name=='flesh' then return flesh end
 if name=='stew' then return stew end
 if name=='ordinaryStew' then return ordinaryStew end
 if name=='afflictedFlesh' then return afflictedFlesh end
 if name=='afflictedStew' then return afflictedStew end
 if name=='knife' then return knife end
 return ranged
end
function __corpse(name)
 if name=='human' then return humanCorpse end
 if name=='afflicted' then return afflictedCorpse end
 if name=='zombie' then return zombieCorpse end
 if name=='animal' then return animalCorpse end
 return mutantCorpse
end
function __target(name)
 if name=='human' then return human end
 if name=='afflicted' then return afflicted end
 return otherCrossed
end
function __carrier() return carrier end
function __queued() return queued end
function __clearQueue() queued=nil end
function __setItems(which)
 if which=='regular' then inventory.items={knife,regular}
 elseif which=='flesh' then inventory.items={knife,flesh}
 elseif which=='both' then inventory.items={knife,regular,flesh}
 elseif which=='afflictedFlesh' then inventory.items={knife,afflictedFlesh}
 elseif which=='afflictedStew' then inventory.items={knife,afflictedStew}
 else inventory.items={knife} end
end
function __observedFood(value)
 observedFood=value and {id='observed-pantry',cx=15,cy=10,
  minX=14,minY=9,maxX=16,maxY=11} or nil
 sourceBegin=nil
end
function __sourceBegin() return sourceBegin end
function __primary(value) carrier.primary=value end
function __counts() return applyCalls,exposureCalls,ownershipCalls,physicalCalls,
 ordinaryEatCalls end
function __inventoryCount() return #inventory.items end
function __inventoryItem(index) return inventory.items[index] end
function __root() return durable['ZombieAwareness_State'] end
function __evolveAfflictedStew()
 return ISAddItemInRecipe.complete({baseItem=afflictedStew,
  usedItem=afflictedFlesh})
end
function __evolveOrdinaryStew()
 return ISAddItemInRecipe.complete({baseItem=stew,usedItem=flesh})
end
'''

SETUP = r'''
local root=ZAO.StateStore.store()
root.people.carrier={personId='carrier',terminalState='crossed',history={}}
root.people.afflicted={personId='afflicted',terminalState='afflicted',history={}}
root.people.otherCrossed={personId='otherCrossed',terminalState='crossed',history={}}
root.people.mutant={personId='mutant',terminalState='turned',currentForm='Husk',history={}}
ZAO.Controller.controlled.afflicted=__target('afflicted')
'''

PROBE = r'''
local carrier=__carrier()
local regular,flesh=__item('regular'),__item('flesh')
assert(not ZAO.Diet.isHumanFood(regular) and ZAO.Diet.isHumanFood(flesh)
 and ZAO.Diet.isHumanFood(__item('stew'))
 and not ZAO.Diet.isHumanFood(__item('ordinaryStew')),
 'human-food provenance admitted ordinary food or lost a human stew')
local unknownAllowed,unknownReason=ZAO.Diet.profileAllowed('crossed',
 ZAO.Diet.foodProfile(__item('stew')))
assert(unknownAllowed==false and unknownReason=='human-source-unknown',
 'legacy anonymous human dish invented a non-Afflicted donor')
assert(__evolveOrdinaryStew()==true)
assert(ZAO.Diet.profileAllowed('crossed',
 ZAO.Diet.foodProfile(__item('stew')))==true,
 'known ordinary-human stew lost Crossed food eligibility')
assert(ZAO.Diet.corpseEligible(__corpse('human'))==true)
assert(ZAO.Diet.corpseEligible(__corpse('afflicted'))==true,
 'Afflicted corpse lost its source identity for Afflicted policy')
local crossedAfflicted,reason=ZAO.Diet.corpseEligibleFor('carrier',carrier,
 __corpse('afflicted'))
assert(crossedAfflicted==false and reason=='afflicted-not-food',
 'Crossed admitted an Afflicted corpse as food')
assert(ZAO.Diet.corpseEligibleFor('afflicted',__target('afflicted'),
 __corpse('afflicted'))==true,
 'Crossed non-feeding rule leaked into distinct Afflicted food policy')
assert(ZAO.Diet.corpseEligible(__corpse('zombie'))==false
 and ZAO.Diet.corpseEligible(__corpse('animal'))==false
 and ZAO.Diet.corpseEligible(__corpse('mutant'))==false,
 'zombie, animal, or mutant corpse entered the Crossed diet')

local afflictedFlesh=__item('afflictedFlesh')
local afflictedStew=__item('afflictedStew')
assert(__evolveAfflictedStew()==true)
local afflictedDish=ZAO.Diet.foodProfile(afflictedStew)
assert(afflictedDish and afflictedDish.human==true
 and afflictedDish.containsAfflictedHuman==true
 and afflictedDish.donor.terminalState=='afflicted',
 'evolved dish lost the exact Afflicted donor provenance')
assert(ZAO.Diet.beginEat('carrier',carrier,afflictedFlesh,1)==false
 and ZAO.Diet.beginEat('carrier',carrier,afflictedStew,1)==false,
 'Crossed directly admitted raw or cooked Afflicted human food')
assert(ZAO.Diet.createSourceUseAction('carrier',carrier,afflictedStew,
 {id='afflicted-source',nativeUseTerminalState='crossed',
  nativeUsePermitHuman=true})==nil,
 'SourceUse bypassed the Crossed-to-Afflicted non-feeding rule')
__setItems('afflictedStew')
assert(#ZAO.Diet.options('carrier',carrier,
 ZAO.Pathogen.stateOf('carrier'),{},1)==0,
 'Afflicted-origin dish entered Crossed choice arbitration')
__setItems('none') __clearQueue()
assert(ZAO.Diet.beginButcher('carrier',carrier,__corpse('afflicted'),1)==false
 and __queued()==nil and not __corpse('afflicted'):getModData().ZAOButchered,
 'Crossed queued Afflicted butchery before food admission')

local humanCorpse=__corpse('human')
assert(ZAO.Diet.beginButcher('carrier',carrier,humanCorpse,1))
local action=__queued() assert(action and action:isValid())
action:stop()
local root=__root()
local interrupted=nil
for _,result in pairs(root.butcherResults) do interrupted=result end
assert(interrupted and interrupted.outcome=='interrupted'
 and not humanCorpse:getModData().ZAOButchered,
 'interrupted butchery minted food or consumed the corpse')
__clearQueue()
assert(ZAO.Diet.beginButcher('carrier',carrier,humanCorpse,2))
action=__queued() assert(action:complete()==true)
local pieces=__inventoryCount()
assert(humanCorpse:getModData().ZAOButchered==true and pieces==5,
 'completed butchery did not produce four exact human pieces')
assert(action:complete()==false and __inventoryCount()==pieces,
 'butchery completion repeated')
assert(ZAO.Diet.beginEat('carrier',carrier,regular,3),
 'ordinary food did not enter the exact native eating action')
local ordinaryAction=__queued() ordinaryAction:stop()
__clearQueue()
local humanFood=__inventoryItem(2)
assert(ZAO.Diet.beginEat('carrier',carrier,humanFood,3))
local eat=__queued() assert(eat:complete()==true)
local eaten=nil
for _,result in pairs(root.dietResults) do eaten=result end
assert(eaten and eaten.outcome=='completed',
 'native human-food completion produced no receipt')

__setItems('regular') __clearQueue()
assert(SAOJavaBridge~=nil,'bridge vanished before ordinary sustenance')
assert(SAOJavaBridge:findCarriedFood(carrier)==regular,
 'ordinary carried-food fixture was unavailable')
local ordinaryOptions=ZAO.Diet.options('carrier',carrier,
 ZAO.Pathogen.stateOf('carrier'),{},4)
assert(#ordinaryOptions==1 and ordinaryOptions[1].kind=='diet-ordinary',
 'ordinary food was not a physiological sustenance option:'
  ..tostring(#ordinaryOptions)..':'
  ..tostring(ordinaryOptions[1] and ordinaryOptions[1].kind))
local committed,reason=ZAO.Diet.step('carrier',carrier,
 ZAO.Pathogen.stateOf('carrier'),{},4,'diet-ordinary')
assert(committed and reason=='feeding' and select(5,__counts())==0
 and __queued()~=nil,
 'ordinary carried food bypassed the exact native eating action')
assert(__queued():complete()==true,
 'ordinary native eating action did not complete')

__setItems('both')
local mixed=ZAO.Diet.options('carrier',carrier,
 ZAO.Pathogen.stateOf('carrier'),{},4)
local humanScore,ordinaryScore=nil,nil
for _,option in ipairs(mixed) do
 if option.kind=='diet-human' then humanScore=option.score end
 if option.kind=='diet-ordinary' then ordinaryScore=option.score end
end
assert(humanScore and ordinaryScore and humanScore>ordinaryScore,
 'human-origin food was not preferred over ordinary sustenance')

__setItems('none') __clearQueue() __observedFood(true)
local sourceOptions=ZAO.Diet.options('carrier',carrier,
 ZAO.Pathogen.stateOf('carrier'),{},4)
local sourceOption=nil
for _,option in ipairs(sourceOptions) do
 if option.kind=='diet-source' then sourceOption=option end
end
assert(sourceOption and ZAO.Diet.step('carrier',carrier,
 ZAO.Pathogen.stateOf('carrier'),{},4,sourceOption)==true,
 'private source knowledge did not become a SourceUse acquisition')
local sourceBegin=__sourceBegin()
assert(sourceBegin and sourceBegin.category=='food'
 and sourceBegin.context.nativeUseOwner=='ZAO.Diet'
 and sourceBegin.context.nativeUseTerminalState=='crossed'
 and sourceBegin.context.nativeUsePermitHuman==true,
 'ZAO duplicated acquisition or omitted state-owned consumption')
__observedFood(false)

__setItems('none') __primary(__item('knife')) __clearQueue()
local candidate,mode=ZAO.Contamination.preparationCandidate(carrier,'carrier')
assert(candidate==__item('knife') and mode=='melee' and __queued()==nil
 and __root().contaminationPrep.carrier==nil,
 'blooded weapon was automatic rather than a selectable tactic')
__primary(regular)
assert(ZAO.Contamination.preparationCandidate(carrier,'carrier')==nil,
 'equipped food was admitted as a melee contamination weapon')
__primary(__item('knife'))
assert(ZAO.Contamination.beginPreparation('carrier',carrier,__item('knife'),5))
local prep=__queued() prep:stop()
assert(not ZAO.Contamination.isPrepared(__item('knife'),'carrier'),
 'interrupted blood preparation stamped a weapon')
__clearQueue()
assert(ZAO.Contamination.beginPreparation('carrier',carrier,__item('knife'),6))
prep=__queued() assert(prep:complete()==true)
assert(ZAO.Contamination.isPrepared(__item('knife'),'carrier'))
ZAO.Contamination.onHit(carrier,__target('human'),__item('knife'))
local applied,exposed,owned,physical=__counts()
assert(applied==0,'blood infection resolved before native injury')
ZAO.Contamination.onAttackFinished(carrier)
applied,exposed,owned,physical=__counts()
assert(applied==1 and physical==1,
 'blooded knife did not infect through the post-injury bridge')
ZAO.Contamination.onHit(carrier,__target('human'),__item('knife'))
ZAO.Contamination.onAttackFinished(carrier)
assert(select(1,__counts())==1,'one-use blooded knife infected twice')

__clearQueue()
assert(ZAO.Contamination.beginPreparation('carrier',carrier,__item('knife'),7))
assert(__queued():complete()==true)
ZAO.Contamination.onHit(carrier,__target('afflicted'),__item('knife'))
ZAO.Contamination.onAttackFinished(carrier)
applied,exposed,owned,physical=__counts()
assert(applied==1 and exposed==1 and owned==1,
 'Afflicted blood exposure used feeding/native human infection instead of pathogen ownership')

__root().people.afflicted.terminalState='afflicted'
__clearQueue()
assert(ZAO.Contamination.beginPreparation('carrier',carrier,__item('knife'),8))
assert(__queued():complete()==true)
ZAO.Contamination.onHit(carrier,__target('otherCrossed'),__item('knife'))
ZAO.Contamination.onAttackFinished(carrier)
assert(select(1,__counts())==1 and select(2,__counts())==1,
 'Crossed target accepted another Crossed blood infection')

__primary(__item('ranged')) __clearQueue()
assert(ZAO.Contamination.beginPreparation('carrier',carrier,__item('ranged'),9))
assert(__queued():complete()==true)
ZAO.Contamination.onHit(carrier,__target('human'),__item('ranged'))
assert(select(1,__counts())==1,'projectile hit resolved before injury')
ZAO.Contamination.tickPending()
assert(select(1,__counts())==2,
 'projectile fallback without swing event did not consume and resolve')

__primary(__item('knife')) __clearQueue()
assert(ZAO.Contamination.beginPreparation('carrier',carrier,__item('knife'),10))
ZAO.Contamination.runtimeActions={}
ZAO.Contamination.resumePending()
local reconstructed=nil
for _,result in pairs(root.contaminationPrepResults) do
 if result.startedAtHours==10 then reconstructed=result end
end
assert(reconstructed and reconstructed.outcome=='interrupted'
 and not ZAO.Contamination.isPrepared(__item('knife'),'carrier'),
 'reload silently completed blood preparation')
'''


def run(work: Path, sources: dict[str, str]) -> subprocess.CompletedProcess[str]:
    paths = [str(work / "host.lua")]
    for index, path in enumerate(FILES):
        target = work / f"source-{index}.lua"
        target.write_text(sources[path.name], encoding="utf-8")
        paths.append(str(target))
    paths.extend([str(work / "setup.lua"), str(work / "probe.lua")])
    return subprocess.run(
        [str(JDK / "java.exe"), "-cp",
         f"{GAME / 'projectzomboid.jar'}{os.pathsep}{work}",
         "CrossedMaterialActionsRun", *paths], cwd=work,
        capture_output=True, text=True, timeout=30)


def main() -> int:
    required = [GAME / "projectzomboid.jar", GAME / "stdlib.lua",
                JDK / "java.exe", JDK / "javac.exe", *FILES]
    if not all(path.is_file() for path in required):
        print("Border 13 SKIPPED: installed game VM, JDK, or source absent")
        return 0
    sources = {path.name: path.read_text(encoding="utf-8-sig") for path in FILES}
    controls = [
        ("ordinary-food physiology", "ZAO_Diet.lua",
         "if not ok or not item or Diet.isHumanFood(item) then return nil end",
         "if true then return nil end"),
        ("human-origin preference", "ZAO_Diet.lua",
         "score = 68 + need * 22",
         "score = 20 + need * 22"),
        ("Crossed refusal of Afflicted corpses", "ZAO_Diet.lua",
         'if terminal == "crossed" and donor\n'
         '        and donor.terminalState == "afflicted" then',
         "if false then"),
        ("Crossed refusal of carried Afflicted food", "ZAO_Diet.lua",
         'if terminal == "crossed" and profile.human\n'
         '        and profile.containsAfflictedHuman == true then',
         "if false then"),
        ("anonymous human food fails closed", "ZAO_Diet.lua",
         'if terminal == "crossed" and profile.human\n'
         '        and profile.humanSourceKnown ~= true then',
         "if false then"),
        ("evolved-dish donor provenance", "ZAO_Diet.lua",
         "Diet.propagateHumanProvenance(action.baseItem, source, profile)",
         "Diet.propagateHumanProvenance(nil, source, profile)"),
        ("native SourceUse acquisition owner", "ZAO_Diet.lua",
         'SAO.SourceUse.registerNativeUseOwner("ZAO.Diet", {',
         'SAO.SourceUse.registerNativeUseOwner("ZAO.Diet.disabled", {'),
        ("post-injury resolution", "ZAO_Contamination.lua",
         "Contamination.pendingTargets[hit.token] = target\n    hit.targetId = targetIdentity(target)",
         "Contamination.pendingTargets[hit.token] = target\n    hit.targetId = targetIdentity(target)\n    Contamination.resolve(hit.token, target)"),
        ("finite contamination use", "ZAO_Contamination.lua",
         "data.ZAOCrossedBloodUses = row.uses - 1",
         "data.ZAOCrossedBloodUses = row.uses"),
        ("actual hand-weapon admission", "ZAO_Contamination.lua",
         'if not ok or not eligible then return nil end',
         'if not ok or not weapon then return nil end'),
        ("distinct Afflicted exposure", "ZAO_Contamination.lua",
         'elseif targetKind == "afflicted" then', "elseif false then"),
    ]
    for name, file_name, old, _ in controls:
        if sources[file_name].count(old) != 1:
            print(f"REFUSED: {name} mutation seam changed")
            return 1
    with tempfile.TemporaryDirectory(prefix="zao-crossed-material-") as tmp:
        work = Path(tmp)
        shutil.copy2(GAME / "stdlib.lua", work / "stdlib.lua")
        (work / "CrossedMaterialActionsRun.java").write_text(RUNNER, encoding="utf-8")
        (work / "host.lua").write_text(HOST, encoding="utf-8")
        (work / "setup.lua").write_text(SETUP, encoding="utf-8")
        (work / "probe.lua").write_text(PROBE, encoding="utf-8")
        built = subprocess.run(
            [str(JDK / "javac.exe"), "-cp", str(GAME / "projectzomboid.jar"),
             "CrossedMaterialActionsRun.java"], cwd=work,
            capture_output=True, text=True, timeout=120)
        if built.returncode:
            print("REFUSED: material-action runner did not compile\n" + built.stderr)
            return 1
        production = run(work, sources)
        if production.returncode or "CROSSED_MATERIAL_ACTIONS_OK" not in production.stdout:
            print("REFUSED: Crossed material-action production path failed")
            print(production.stdout + production.stderr)
            return 1
        for name, file_name, old, new in controls:
            changed = dict(sources)
            changed[file_name] = changed[file_name].replace(old, new, 1)
            result = run(work, changed)
            if result.returncode == 0:
                print(f"REFUSED: {name} control survived")
                return 1
    print("Border 13 PASS: Crossed ordinary food and source-known eligible human-origin food require exact native eating actions, while Afflicted corpses, carried flesh, cooked dishes, SourceUse results, and anonymous legacy human food are refused from donor provenance; Afflicted food policy stays distinct; butchery is source-bounded; only actual hand weapons admit finite blooded melee/projectile hits after injury; intentional Afflicted exposure stays separate; eleven controls fail")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
