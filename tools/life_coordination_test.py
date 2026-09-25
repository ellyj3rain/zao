#!/usr/bin/env python3
"""Border 15: Afflicted provisioning and Crossed rendezvous remain distinct."""
from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parent.parent
SAO_ROOT = Path(os.environ.get(
    "SAO_ROOT", ROOT.parent / "survivor-awareness")).resolve()
GAME = Path(os.environ.get(
    "PZ_DIR", r"C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid"))
JDK = Path(os.environ.get(
    "JDK_BIN", r"C:\Users\jleyv\Peanut Butter\JetBrains\Java\bin"))
FILES = {
    "organization": SAO_ROOT / "mod/42.20/media/lua/shared/SAO_Organization.lua",
    "communication": SAO_ROOT / "mod/42.20/media/lua/shared/SAO_Communication.lua",
    "driver": ROOT / "mod/42.20/media/lua/client/ZAO_Driver.lua",
    "afflicted": ROOT / "mod/42.20/media/lua/client/ZAO_Afflicted.lua",
    "crossed": ROOT / "mod/42.20/media/lua/client/ZAO_Crossed.lua",
    "execution_owner": ROOT / "mod/42.20/media/lua/shared/ZAO_ExecutionOwner.lua",
    "controller": ROOT / "mod/42.20/media/lua/client/ZAO_Controller.lua",
}

RUNNER = r'''
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaThread;
public class ZAOLifeCoordinationRun {
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
        System.out.println("ZAO_LIFE_COORDINATION_OK");
    }
}
'''

HOST = r'''
Events=setmetatable({}, {__index=function(t,k)
 local slot={Add=function() end,Remove=function() end}; rawset(t,k,slot); return slot
end})
ISTimedActionQueue={queues={}}
nowHours=20
local root={driverResults={}}
local function body(id,x,y)
 local b={id=id,x=x,y=y,z=0,data={SAOPersonId=id}}
 function b:getX() return self.x end
 function b:getY() return self.y end
 function b:getZ() return self.z end
 function b:getModData() return self.data end
 function b:isRunning() return false end
 function b:isSprinting() return false end
 function b:setSitOnGround(v) self.sitting=v end
 function b:getPrimaryHandItem() return nil end
 return b
end
bodies={
 afflicted=body('afflicted',0,0), helper1=body('helper1',2,0),
 helper2=body('helper2',3,0), crossedBad=body('crossedBad',4,0),
 crossed=body('crossed',20,20), peer1=body('peer1',22,20),
 peer2=body('peer2',23,20), ordinary=body('ordinary',24,20),
}
records={}
for id,b in pairs(bodies) do records[id]={id=id,dead=false,bodyOwner='ZAO'} end
records.crossed.homeX,records.crossed.homeY,records.crossed.homeZ=30,30,0
records.affDormant={id='affDormant',dead=false,bodyOwner='ZAO',
 x=40,y=40,z=0,homeX=40,homeY=40,homeZ=0,dormantSleeping=false,
 speechAccessOrigin='generated-empty-traits'}
records.affUnknown={id='affUnknown',dead=false,bodyOwner='ZAO',
 x=41,y=40,z=0,homeX=41,homeY=40,homeZ=0,dormantSleeping=false,
 speechAccessOrigin='generated-empty-traits'}
records.crossDormant={id='crossDormant',dead=false,bodyOwner='ZAO',
 x=50,y=50,z=0,homeX=50,homeY=50,homeZ=0,dormantSleeping=false,
 speechAccessOrigin='generated-empty-traits'}
records.crossPeer={id='crossPeer',dead=false,bodyOwner='ZAO',
 x=51,y=50,z=0,homeX=51,homeY=50,homeZ=0,dormantSleeping=false,
 speechAccessOrigin='generated-empty-traits'}
states={}
for _,id in ipairs({'afflicted','helper1','helper2'}) do
 states[id]={terminalState='afflicted',driver={version=1,currentActivity='idle'}}
end
for _,id in ipairs({'crossed','crossedBad','peer1','peer2'}) do
 states[id]={terminalState='crossed',driver={version=1,currentActivity='idle'}}
end
states.affDormant={terminalState='afflicted',driver={version=1,
 currentActivity='idle',settlementPressure={terminalState='afflicted',
 hunger=.88,thirst=.12,value=.88,observedAtHours=19}}}
states.affUnknown={terminalState='afflicted',driver={version=1,
 currentActivity='idle'}}
states.crossDormant={terminalState='crossed',settlementGroup='cross-hold',
 driver={version=1,currentActivity='holding-home'}}
states.crossPeer={terminalState='crossed',settlementGroup='cross-hold',
 driver={version=1,currentActivity='holding-home'}}
needs={
 afflicted={hunger=.82,thirst=.18,fatigue=0}, helper1={hunger=.1,thirst=.1,fatigue=0},
 helper2={hunger=.1,thirst=.1,fatigue=0}, crossed={hunger=.1,thirst=.1,fatigue=0},
 peer1={hunger=.1,thirst=.1,fatigue=0}, peer2={hunger=.1,thirst=.1,fatigue=0},
 affUnknown={hunger=.92,thirst=.1,fatigue=0},
}
local relations={ helper1=.6,helper2=.2,crossedBad=.5,peer1=.5,peer2=-.7,ordinary=.4 }
SAO={
 History={countyHours=function() return nowHours end,speedModOf=function() return 1 end},
 Identity={get=function(id) return records[id] end,
  updatePosition=function(rec,x,y,z) rec.x,rec.y,rec.z=x,y,z return true end},
 Body={active={},foreign=bodies,hasRepresentation=function(id) return bodies[id]~=nil end},
 Controller={agents={},coordinationRuntime={}},
 Perception={EARSHOT=10,noteContactAttempt=function() return true end},
 Places={comfortHorizon=function() return 24 end},
 Standing={
  groupOf=function(id) return nil end,
  trust=function(id,other) return relations[other] or 0 end,
  isHostileTo=function(id,other) return (relations[other] or 0)<=-.45 end,
  outcastDriftDestination=function() return nil end,
 },
 Needs={read=function(b) return needs[b.id] or {hunger=0,thirst=0,fatigue=0} end,
  bleeding=function() return 0 end,cold=function() return 0 end},
 Locomotion={jobs={},cancel=function() end},
}
SAOJavaBridge={canConverseNow=function(self,a,b,reach) return a~=nil and b~=nil end}
getSpecificPlayer=function() return nil end
ZAO={
 StateStore={store=function() return root end},
 Pathogen={stateOf=function(id) return states[id] end},
 Settlement={groups={['cross-hold']={id='cross-hold',kind='crossed',
  occupied=true,place={x=50,y=50,z=0},
  members={crossDormant=true,crossPeer=true}}}},
 Diet={options=function() return {} end},
 Maintenance={predatoryPressure=function() return .2 end},
 Exposure={called=0,activeFor=function() return nil end,
  step=function() ZAO.Exposure.called=ZAO.Exposure.called+1 return false end},
 Predation={called=0,activeFor=function() return nil end,
  step=function() ZAO.Predation.called=ZAO.Predation.called+1 return false end},
 Mind={visiblePeople=function(mind) return mind.visible or {} end,
  of=function(rec,hours,b)
   return {physical=needs[rec.id] or {hunger=.1,thirst=.1,fatigue=0},
    disposition={compassion=.8,discipline=.1,initiative=.6,aggression=.3,
     nerve=.5,selfPreservation=.5,talkativeness=.5},standing={group=nil},
    execution={canMove=b~=nil,survival=1},perception={survival=1},visible={}}
  end},
}
'''

PROBE = r'''
local function optionOf(options,kind)
 for _,option in ipairs(options or {}) do if option.kind==kind then return option end end
 return nil
end
local function contains(values,wanted)
 for _,value in ipairs(values or {}) do if value==wanted then return true end end
 return false
end
for id,b in pairs(bodies) do ZAO.Controller.controlled[id]=b end
local affMind={physical=needs.afflicted,
 disposition={talkativeness=.6,compassion=.5,discipline=.4,initiative=.4,
  selfPreservation=.5,nerve=.5},standing={group=nil},
 execution={canMove=true,survival=1},perception={survival=1},
 visible={
  {id='helper1',state='afflicted',relationship=.6,body=bodies.helper1,distance=2},
  {id='helper2',state='afflicted',relationship=.2,body=bodies.helper2,distance=3},
  {id='crossedBad',state='crossed',relationship=.5,body=bodies.crossedBad,distance=4},
 }}
local affOptions=ZAO.Afflicted.options(bodies.afflicted,'afflicted',
 states.afflicted,affMind,10,nowHours)
local request=optionOf(affOptions,'provisioning-matter')
assert(request and request.proposal.scope.category=='food',
 'Afflicted personal necessity did not produce food provisioning')
assert(contains(request.addressedIds,'helper1') and contains(request.addressedIds,'helper2')
 and not contains(request.addressedIds,'crossedBad'),
 'Afflicted provisioning erased the Crossed distinction')
assert(ZAO.Afflicted.execute(request,bodies.afflicted,'afflicted',states.afflicted,
 affMind,10,nowHours)==true,'Afflicted request did not execute')
local affProcess=SAO.Organization.openMatter('afflicted','provisioning')
assert(affProcess and affProcess.revision==1
 and #SAO.Organization.pendingAppraisals('helper1')==1,
 'Afflicted request was not one acquired durable matter')
local second=optionOf(ZAO.Afflicted.options(bodies.afflicted,'afflicted',
 states.afflicted,affMind,11,nowHours),'provisioning-matter')
assert(second==nil and #SAO.Organization.processOrder==1,
 'Afflicted producer repeated an acquired matter per tick')

local helperMind={disposition={compassion=.7,discipline=.5,initiative=.3},
 standing={group=nil},execution={canMove=true},perception={survival=1}}
local h1=ZAO.Afflicted.appraiseMatter('helper1',bodies.helper1,states.helper1,
 helperMind,SAO.Organization.viewFor('helper1',affProcess.id,false),{
  currentActivity='idle',relationship=.6,ownNeed=.1,destinationKnown=true,
  canAcquire=true,canCarry=true,canDeliver=true,canExecute=true,
  constraints={represented=true},inputOwners={ownNeed='ZAO.Driver'}},nowHours)
local h2=ZAO.Afflicted.appraiseMatter('helper2',bodies.helper2,states.helper2,
 helperMind,SAO.Organization.viewFor('helper2',affProcess.id,false),{
  currentActivity='treating',relationship=.2,ownNeed=.1,destinationKnown=true,
  canAcquire=true,canCarry=true,canDeliver=true,canExecute=true,
  constraints={represented=true},inputOwners={ownNeed='ZAO.Driver'}},nowHours)
assert(h1.choice=='accept' and h2.choice=='defer'
 and h1.terminalState==nil and h1.diet==nil,
 'Afflicted recipients did not appraise independently or leaked state labels')
local hMissing=ZAO.Afflicted.appraiseMatter('helper1',nil,states.helper1,
 helperMind,SAO.Organization.viewFor('helper1',affProcess.id,false),{
  currentActivity='dormant',relationship=.6,ownNeed=.1,destinationKnown=true,
  incapable=true,canExecute=false,
  constraints={represented=false,executionOwnerAvailable=true},
  inputOwners={ownNeed='ZAO.Driver'}},nowHours)
assert(hMissing.choice=='defer' and hMissing.incapable==false,
 'missing Afflicted representation was misreported as proven incapability')
SAO.Organization.appraiseMatter(affProcess.id,'helper1',h1)
SAO.Organization.appraiseMatter(affProcess.id,'helper2',h2)
SAO.Communication.deliverPendingResponses('helper1','afflicted',nil,{})
SAO.Communication.deliverPendingResponses('helper2','afflicted',nil,{})
assert(SAO.Organization.activeCommitment('helper1','provisioning')~=nil,
 'Afflicted acceptance did not create scoped work')

needs.afflicted.hunger,needs.afflicted.thirst=.2,.84
local revision=optionOf(ZAO.Afflicted.options(bodies.afflicted,'afflicted',
 states.afflicted,affMind,12,nowHours),'provisioning-matter')
assert(revision and revision.proposal.scope.category=='water',
 'changed Afflicted necessity did not revise its resource')
ZAO.Afflicted.execute(revision,bodies.afflicted,'afflicted',states.afflicted,
 affMind,12,nowHours)
assert(#SAO.Organization.processOrder==1 and affProcess.revision==2
 and SAO.Organization.activeCommitment('helper1','provisioning')==nil,
 'Afflicted revision duplicated or retained superseded work')
needs.afflicted.hunger,needs.afflicted.thirst=.1,.1
local withdraw=optionOf(ZAO.Afflicted.options(bodies.afflicted,'afflicted',
 states.afflicted,affMind,13,nowHours),'provisioning-withdraw')
assert(withdraw and ZAO.Afflicted.execute(withdraw,bodies.afflicted,'afflicted',
 states.afflicted,affMind,13,nowHours)==true and affProcess.status=='withdrawn',
 'resolved Afflicted necessity did not explicitly withdraw')

local crossMind={physical=needs.crossed,
 disposition={discipline=.7,initiative=.6,aggression=.3,nerve=.5},
 standing={group=nil},execution={canMove=true,survival=1},perception={survival=1},
 visible={
  {id='peer1',state='crossed',relationship=.5,body=bodies.peer1,distance=2},
  {id='peer2',state='crossed',relationship=-.7,body=bodies.peer2,distance=3},
  {id='ordinary',state='ordinary',relationship=.4,body=bodies.ordinary,distance=4,
   visibleDistress=0},
 }}
local crossOptions=ZAO.Crossed.options(bodies.crossed,'crossed',states.crossed,
 crossMind,20,nowHours)
local rendezvous=optionOf(crossOptions,'rendezvous-matter')
assert(rendezvous and rendezvous.proposal.scope.action=='rendezvous-holding'
 and contains(rendezvous.addressedIds,'peer1')
 and contains(rendezvous.addressedIds,'peer2')
 and not contains(rendezvous.addressedIds,'ordinary'),
 'Crossed rendezvous did not remain associate- and place-specific')
assert(ZAO.Crossed.execute(rendezvous,bodies.crossed,'crossed',states.crossed,
 crossMind,20,nowHours)==true,'Crossed rendezvous did not execute')
local crossProcess=SAO.Organization.openMatter('crossed','rendezvous-holding')
assert(crossProcess and #SAO.Organization.processOrder==2,
 'Crossed rendezvous duplicated or reused Afflicted provisioning')
local p1=ZAO.Crossed.appraiseMatter('peer1',bodies.peer1,states.peer1,crossMind,
 SAO.Organization.viewFor('peer1',crossProcess.id,false),{
  currentActivity='idle',relationship=.5,ownNeed=.1,destinationKnown=true,
  canAcquire=true,canCarry=true,canDeliver=true,canExecute=true,
  constraints={represented=true},inputOwners={ownNeed='ZAO.Driver'}},nowHours)
local p2=ZAO.Crossed.appraiseMatter('peer2',bodies.peer2,states.peer2,crossMind,
 SAO.Organization.viewFor('peer2',crossProcess.id,false),{
  currentActivity='idle',relationship=-.7,ownNeed=.1,destinationKnown=true,
  canAcquire=true,canCarry=true,canDeliver=true,canExecute=true,
  contest=true,constraints={represented=true},
  inputOwners={ownNeed='ZAO.Driver'}},nowHours)
assert(p1.choice=='accept' and p2.choice=='contest'
 and p1.terminalState==nil and p1.diet==nil,
 'Crossed recipients did not use distinct private priorities')
local pMissing=ZAO.Crossed.appraiseMatter('peer1',nil,states.peer1,crossMind,
 SAO.Organization.viewFor('peer1',crossProcess.id,false),{
  currentActivity='dormant',relationship=.5,ownNeed=.1,destinationKnown=true,
  incapable=true,canExecute=false,
  constraints={represented=false,executionOwnerAvailable=true},
  inputOwners={ownNeed='ZAO.Driver'}},nowHours)
assert(pMissing.choice=='defer' and pMissing.incapable==false,
 'missing Crossed representation was misreported as proven incapability')
SAO.Organization.appraiseMatter(crossProcess.id,'peer1',p1)
SAO.Organization.appraiseMatter(crossProcess.id,'peer2',p2)
SAO.Communication.deliverPendingResponses('peer1','crossed',nil,{})
SAO.Communication.deliverPendingResponses('peer2','crossed',nil,{})
local commitment=SAO.Organization.activeCommitment('peer1','rendezvous-holding')
assert(commitment,'accepted Crossed rendezvous created no scoped commitment')
SAO.Organization.startWork(commitment.id,'ZAO','travelling')
local route=SAO.Organization.noteRoute(commitment.id,'Locomotion',30,30,0,
 'travelling')
assert(SAO.Organization.completeArrival(commitment.id,route.id,
 'holding-home',{})==false,'selection manufactured Crossed arrival')
SAO.Organization.routeOutcome(commitment.id,'arrived','arrived')
assert(SAO.Organization.completeArrival(commitment.id,route.id,
 'holding-home',{})==true and commitment.status=='completed'
 and ZAO.Predation.called==0 and ZAO.Exposure.called==0,
 'Crossed arrival was not exact or manufactured a downstream act')
crossMind.visible={}
local abandon=optionOf(ZAO.Crossed.options(bodies.crossed,'crossed',states.crossed,
 crossMind,21,nowHours),'rendezvous-withdraw')
assert(abandon and ZAO.Crossed.execute(abandon,bodies.crossed,'crossed',
 states.crossed,crossMind,21,nowHours)==true and crossProcess.status=='withdrawn',
 'Crossed lost opportunity did not remain abandonable')

-- The same registered ZAO execution owner now reaches both policies when no
-- shell is loaded. Afflicted origin requires retained hunger/thirst evidence;
-- Crossed origin requires retained associates and held ground. Neither may
-- borrow the other policy's motive, matter kind, or hidden current state.
local affDormant,affDormantStatus=SAO.Communication.actorMatter('affDormant',{
 atHours=nowHours,currentActivity='dormant',knownContacts={
  {id='helper1',hostile=false},
  {id='crossedBad',hostile=false,form='crossed'},
 }})
assert(affDormant and affDormantStatus=='open'
 and affDormant.kind=='provisioning'
 and affDormant.revisions['1'].proposal.scope.category=='food'
 and affDormant.participants.helper1~=nil
 and affDormant.participants.crossedBad==nil
 and affDormant.participants.helper1.receptions['1']==nil
 and affDormant.privateInputs.affDormant['1'].source
  =='retained-personal-necessity',
 'bodyless Afflicted origin lacked exact retained necessity or crossed policy')
local beforeUnknown=#SAO.Organization.processOrder
local affUnknown,affUnknownStatus=SAO.Communication.actorMatter('affUnknown',{
 atHours=nowHours,currentActivity='dormant',knownContacts={{id='helper1'}}})
assert(affUnknown==nil and affUnknownStatus=='no-afflicted-situation'
 and #SAO.Organization.processOrder==beforeUnknown,
 'bodyless Afflicted origin invented need from an unowned current value')

local crossDormant,crossDormantStatus=SAO.Communication.actorMatter(
 'crossDormant',{atHours=nowHours,currentActivity='dormant',
  knownContacts={{id='helper1'}}})
assert(crossDormant and crossDormantStatus=='open'
 and crossDormant.kind=='rendezvous-holding'
 and crossDormant.organizationId=='cross-hold'
 and crossDormant.revisions['1'].proposal.scope.action=='rendezvous-holding'
 and crossDormant.revisions['1'].proposal.scope.category==nil
 and crossDormant.participants.crossPeer~=nil
 and crossDormant.participants.helper1==nil
 and crossDormant.participants.crossPeer.receptions['1']==nil,
 'bodyless Crossed origin borrowed provisioning or ignored retained holding')
assert(SAO.Organization.openMatter('affDormant','rendezvous-holding')==nil
 and SAO.Organization.openMatter('crossDormant','provisioning')==nil,
 'shared ZAO driver merged Afflicted and Crossed policy')
local affContact={processId=affDormant.id,processRevision=1,
 recipientId='helper1',beliefKey='Helper One',observedAt=100,x=44,y=40}
local crossContact={processId=crossDormant.id,processRevision=1,
 recipientId='crossPeer',beliefKey='Cross Peer',observedAt=100,x=54,y=50}
local affMoving=SAO.Communication.actorContactStep('affDormant',affContact,
 {atHours=20,tick=180000})
local crossMoving=SAO.Communication.actorContactStep('crossDormant',crossContact,
 {atHours=20,tick=180000})
nowHours=24
local affArrived,affArrival=SAO.Communication.actorContactStep(
 'affDormant',affContact,{atHours=24,tick=216000})
local crossArrived,crossArrival=SAO.Communication.actorContactStep(
 'crossDormant',crossContact,{atHours=24,tick=216000})
local arrivedWaiting=affDormant.contactAttempts[1].status=='waiting'
 and crossDormant.contactAttempts[1].status=='waiting'
 and affDormant.contactAttempts[1].arrivedAt==24
 and crossDormant.contactAttempts[1].arrivedAt==24
local affAttempt=affDormant.contactAttempts[1]
local crossAttempt=crossDormant.contactAttempts[1]
local affWaitUntil=affAttempt.waitUntilAt
local crossWaitUntil=crossAttempt.waitUntilAt
local affFresh={processId=affDormant.id,processRevision=1,
 recipientId='helper1',beliefKey='Helper One',observedAt=101,x=45,y=40}
local crossFresh={processId=crossDormant.id,processRevision=1,
 recipientId='crossPeer',beliefKey='Cross Peer',observedAt=101,x=55,y=50}
nowHours=25
local affWaiting,affWaitStatus=SAO.Communication.actorContactStep(
 'affDormant',affFresh,{atHours=25,tick=225000})
local crossWaiting,crossWaitStatus=SAO.Communication.actorContactStep(
 'crossDormant',crossFresh,{atHours=25,tick=225000})
local freshSightingContinued=#affDormant.contactAttempts==1
 and #crossDormant.contactAttempts==1
 and states.affDormant.driver.contact.contactAttemptId==affAttempt.id
 and states.crossDormant.driver.contact.contactAttemptId==crossAttempt.id
 and affAttempt.waitUntilAt==affWaitUntil
 and crossAttempt.waitUntilAt==crossWaitUntil
nowHours=27
local affUnanswered,affEndStatus=SAO.Communication.actorContactStep(
 'affDormant',affFresh,{atHours=27,tick=243000})
local crossStillWaiting,crossStillStatus=SAO.Communication.actorContactStep(
 'crossDormant',crossFresh,{atHours=27,tick=243000})
nowHours=39
local crossUnanswered,crossEndStatus=SAO.Communication.actorContactStep(
 'crossDormant',crossFresh,{atHours=39,tick=351000})
assert(affMoving==true and crossMoving==true
 and affArrived==true and affArrival=='arrived-address'
 and crossArrived==true and crossArrival=='arrived-address'
 and records.affDormant.x==44 and records.crossDormant.x==54
 and arrivedWaiting
 and freshSightingContinued
 and affWaiting==true and affWaitStatus=='waiting-address'
 and crossWaiting==true and crossWaitStatus=='waiting-address'
 and affUnanswered==true and affEndStatus=='unanswered'
 and crossStillWaiting==true and crossStillStatus=='waiting-address'
 and crossUnanswered==true and crossEndStatus=='unanswered'
 and states.affDormant.driver.currentActivity=='idle'
 and states.crossDormant.driver.currentActivity=='idle'
 and #affDormant.contactAttempts==1
 and affDormant.contactAttempts[1].status=='unanswered'
 and affDormant.participants.helper1.receptions['1']==nil
 and #crossDormant.contactAttempts==1
 and crossDormant.contactAttempts[1].status=='unanswered'
 and crossDormant.participants.crossPeer.receptions['1']==nil,
 'Afflicted and Crossed did not share ZAO-owned contact travel and waiting: '
  ..tostring(affArrival)..'/'..tostring(crossArrival)..' wait='
  ..tostring(affWaitStatus)..'/'..tostring(crossWaitStatus)..' end='
  ..tostring(affEndStatus)..'/'..tostring(crossStillStatus)..'/'
  ..tostring(crossEndStatus)..' status='
  ..tostring(affDormant.contactAttempts[1].status)..'/'
  ..tostring(crossDormant.contactAttempts[1].status)..' activity='
  ..tostring(states.affDormant.driver.currentActivity)..'/'
  ..tostring(states.crossDormant.driver.currentActivity))

local continuity=SAO.Organization.raiseMatter('afflicted','continuity-probe',nil,{
 intentKey='before-conversion',destinationRequired=true,
 destination={minX=0,minY=0,maxX=2,maxY=2,z=0},
 requiredCapabilities={execute=true},scope={action='hold'}
},{'helper1'},{source='private'})
SAO.Communication.deliverProcessProposal('afflicted','helper1',continuity.id,nil,{})
local continuityBase={currentActivity='idle',relationship=0,ownNeed=.1,
 destinationKnown=true,canAcquire=true,canCarry=true,canDeliver=true,
 canExecute=true,constraints={represented=true,executionOwnerAvailable=true},
 inputOwners={ownNeed='ZAO.Driver'}}
local before=SAO.Communication.actorAppraisal('helper1',
 SAO.Organization.viewFor('helper1',continuity.id,false),continuityBase)
assert(before and before.choice=='accept' and before.terminalState==nil,
 'Afflicted appraisal was not dispatched through the registered owner')
SAO.Organization.appraiseMatter(continuity.id,'helper1',before)
SAO.Communication.deliverPendingResponses('helper1','afflicted',nil,{})
local priorCommitment=SAO.Organization.activeCommitment(
 'helper1','continuity-probe')
SAO.Organization.reviseMatter(continuity.id,'afflicted',{
 intentKey='after-conversion',destinationRequired=true,
 destination={minX=0,minY=0,maxX=2,maxY=2,z=0},
 requiredCapabilities={execute=true},scope={action='hold'}
},{source='same-private-matter'})
SAO.Communication.deliverProcessProposal('afflicted','helper1',continuity.id,nil,{})
states.helper1.terminalState='crossed'
local after=SAO.Communication.actorAppraisal('helper1',
 SAO.Organization.viewFor('helper1',continuity.id,false),continuityBase)
assert(after and after.choice=='qualify' and after.terminalState==nil
 and continuity.revision==2 and priorCommitment.status=='superseded',
 'conversion did not retain the process while reappraising Crossed policy')
'''


def run(work: Path, sources: dict[str, str]) -> subprocess.CompletedProcess[str]:
    files = {
        "host.lua": HOST,
        "organization.lua": sources["organization"],
        "communication.lua": sources["communication"],
        "driver.lua": sources["driver"],
        "afflicted.lua": sources["afflicted"],
        "crossed.lua": sources["crossed"],
        "execution_owner.lua": sources["execution_owner"],
        "controller.lua": sources["controller"],
        "probe.lua": PROBE,
    }
    paths = []
    for name, source in files.items():
        path = work / name
        path.write_text(source, encoding="utf-8")
        paths.append(str(path))
    return subprocess.run(
        [str(JDK / "java.exe"), "-cp", f"{GAME / 'projectzomboid.jar'};.",
         "ZAOLifeCoordinationRun", *paths], cwd=work,
        capture_output=True, text=True, timeout=300)


def static_contract(sources: dict[str, str]) -> tuple[bool, str]:
    if ("function Driver.performMatter" not in sources["driver"]
            or "function Driver.matterNeedsAction" not in sources["driver"]
            or "function Driver.advanceDormantContact" not in sources["driver"]):
        return False, "the shared driver does not own matter continuity"
    if ("afflictedProvisioningSituation" not in sources["afflicted"]
            or '"provisioning"' not in sources["afflicted"]):
        return False, "Afflicted provisioning producer is absent"
    if ("rendezvousSituation" not in sources["crossed"]
            or '"rendezvous-holding"' not in sources["crossed"]):
        return False, "Crossed rendezvous producer is absent"
    execution_owner = sources["execution_owner"]
    if ("function adapter.appraiseMatter" not in execution_owner
            or "provider.appraiseMatter" not in execution_owner
            or "function adapter.originateMatter" not in execution_owner
            or "provider.originateMatter" not in execution_owner
            or "function adapter.advanceContact" not in execution_owner):
        return False, "registered ZAO appraisal/origination is not state-dispatched"
    forbidden = ("terminalState = terminal", "diet =", "dietKnown =")
    appraisal = sources["afflicted"] + sources["crossed"]
    if any(value in appraisal for value in forbidden):
        return False, "condition-private labels cross the appraisal seam"
    return True, "distinct producers share only driver and SAO services"


def main() -> int:
    print("=" * 74)
    print("DISTINCT AFFLICTED AND CROSSED LIFE COORDINATION")
    print("=" * 74)
    missing = [path for path in FILES.values() if not path.is_file()]
    if missing:
        print("REFUSED: missing source: " + ", ".join(map(str, missing)))
        return 1
    prerequisites = [GAME / "projectzomboid.jar", GAME / "stdlib.lua",
                     JDK / "java.exe", JDK / "javac.exe"]
    if not all(path.is_file() for path in prerequisites):
        print("Border 15 SKIPPED: installed game VM or JDK absent")
        return 0
    sources = {name: path.read_text(encoding="utf-8-sig")
               for name, path in FILES.items()}
    static_ok, detail = static_contract(sources)
    print("  static contract: " + ("PASS" if static_ok else "FAIL")
          + " (" + detail + ")")
    with tempfile.TemporaryDirectory(prefix="zao-life-coordination-") as tmp:
        work = Path(tmp)
        shutil.copy2(GAME / "stdlib.lua", work / "stdlib.lua")
        (work / "ZAOLifeCoordinationRun.java").write_text(RUNNER, encoding="utf-8")
        built = subprocess.run(
            [str(JDK / "javac.exe"), "-cp", str(GAME / "projectzomboid.jar"),
             "ZAOLifeCoordinationRun.java"], cwd=work,
            capture_output=True, text=True, timeout=300)
        if built.returncode != 0:
            print("REFUSED: runner compile failed " + (built.stderr or built.stdout))
            return 1
        base = run(work, sources)
        if base.returncode != 0 or "ZAO_LIFE_COORDINATION_OK" not in base.stdout:
            print("REFUSED: production probe failed "
                  + ((base.stdout or "") + (base.stderr or ""))[-3000:])
            return 1
        controls = [
            ("Afflicted do not address Crossed as provisioning peers", "afflicted",
             'if person.state ~= "crossed" and person.relationship > -0.35 then',
             "if true then"),
            ("Crossed rendezvous addresses Crossed associates", "crossed",
             'if person.id ~= personId and person.state == "crossed" then',
             "if person.id ~= personId then"),
            ("acquired matters do not repeat per tick", "afflicted",
             "if not shouldAct then return nil end",
             "if false then return nil end"),
            ("bodyless Afflicted requires retained necessity", "afflicted",
             "local personalEvidence = body ~= nil and (physical.hunger ~= nil\n"
             "        or physical.thirst ~= nil)",
             "local personalEvidence = physical.hunger ~= nil\n"
             "        or physical.thirst ~= nil"),
            ("Afflicted retained knowledge excludes known Crossed threats", "afflicted",
             'and hostile ~= true and tostring(knownForm or "") ~= "crossed"\n'
             "            and not seen[otherId] then",
             "and hostile ~= true and not seen[otherId] then"),
            ("bodyless Crossed requires retained holding", "crossed",
             "local function retainedAssociates(personId, state)\n"
             "    local groupId = state and state.settlementGroup or nil",
             "local function retainedAssociates(personId, state)\n"
             "    local groupId = nil"),
            ("Crossed matter does not collapse into provisioning", "crossed",
             "local _, status, process = ZAO.Driver.performMatter(personId,\n"
             '        "rendezvous-holding", option.organizationId, option.proposal,',
             "local _, status, process = ZAO.Driver.performMatter(personId,\n"
             '        "provisioning", option.organizationId, option.proposal,'),
            ("appraisal exports no pathogen label", "crossed",
             'bodyOwner = "ZAO", currentActivity = activity,',
             'bodyOwner = "ZAO", terminalState = state.terminalState, '
             'currentActivity = activity,'),
            ("conversion appraisal dispatches current state policy", "execution_owner",
             '    local provider = state and state.terminalState == "afflicted"\n'
             '        and ZAO.Afflicted or state and state.terminalState == "crossed"\n'
             '        and ZAO.Crossed or nil\n'
             '    if not (state and provider and type(provider.appraiseMatter) == "function") then',
             '    local provider = state and state.terminalState == "afflicted"\n'
             '        and ZAO.Afflicted or state and state.terminalState == "crossed"\n'
             '        and ZAO.Afflicted or nil\n'
             '    if not (state and provider and type(provider.appraiseMatter) == "function") then'),
            ("bodyless origination dispatches current state policy", "execution_owner",
             '    local provider = state and state.terminalState == "afflicted"\n'
             '        and ZAO.Afflicted or state and state.terminalState == "crossed"\n'
             '        and ZAO.Crossed or nil\n'
             '    if not (state and provider and type(provider.originateMatter) == "function") then',
             '    local provider = state and state.terminalState == "afflicted"\n'
             '        and ZAO.Afflicted or state and state.terminalState == "crossed"\n'
             '        and ZAO.Afflicted or nil\n'
             '    if not (state and provider and type(provider.originateMatter) == "function") then'),
            ("registered owner retains bodyless contact movement", "execution_owner",
             "    return ZAO.Driver.advanceDormantContact(tostring(personId), rec, state,\n"
             "        candidate, type(context) == \"table\" and context or {})",
             "    return false, \"contact-disabled\""),
            ("shared ZAO contact travel records a durable attempt", "driver",
             "        contactAttemptId = attempt.id,",
             "        contactAttemptId = nil,"),
            ("ZAO arrival becomes presence rather than reception", "driver",
             "        local waiting = arriveDriverContact(personId, state, {",
             "        local waiting = nil and arriveDriverContact(personId, state, {"),
            ("fresh sighting preserves shared ZAO contact attempt", "driver",
             "        and tonumber(prior.processRevision) == tonumber(candidate.processRevision)\n",
             "        and tonumber(prior.processRevision) == tonumber(candidate.processRevision)\n"
             "        and tonumber(prior.observedAt) == tonumber(candidate.observedAt)\n"),
            ("ZAO silence terminates unanswered", "driver",
             '            finishDriverContact(personId, state, "unanswered", {\n'
             '                owner = "ZAO.Driver",\n'
             '                representation = "dormant-zao",',
             '            finishDriverContact(personId, state, "arrived", {\n'
             '                owner = "ZAO.Driver",\n'
             '                representation = "dormant-zao",'),
        ]
        for name, file_name, old, new in controls:
            if sources[file_name].count(old) != 1:
                print(f"REFUSED: {name} mutation seam changed")
                return 1
            changed = dict(sources)
            changed[file_name] = changed[file_name].replace(old, new, 1)
            result = run(work, changed)
            if result.returncode == 0:
                print(f"REFUSED: {name} control survived")
                return 1
    if not static_ok:
        return 1
    print("  mutation controls: PASS (fifteen production controls)")
    print("  15) Afflicted provisioning and Crossed rendezvous originate, revise, "
          "diverge, execute and end through one driver, loaded or bodyless, "
          "without merging policy")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
