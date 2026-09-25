#!/usr/bin/env python3
"""Border 11: Crossed execute through their human shell, never an IsoZombie."""
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
CONTROLLER = ROOT / "mod/42.20/media/lua/client/ZAO_Controller.lua"

RUNNER = r'''
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaThread;
public class CrossedOwnershipRun {
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
        System.out.println("CROSSED_OWNERSHIP_OK");
    }
}
'''

HOST = r'''
Events = { OnTick = { Add = function() end } }
getSpecificPlayer = function() return nil end
instanceof = function(value, kind)
    return kind == "IsoZombie" and value and value.kind == "IsoZombie"
end

local function body(kind)
    local value = { kind = kind, dead = false, data = {}, x = 10, y = 10 }
    function value:isDead() return self.dead end
    function value:getX() return self.x end
    function value:getY() return self.y end
    function value:getZ() return 0 end
    function value:getModData() return self.data end
    return value
end

local wrongBody = body("IsoZombie")
wrongBody.data.SAOPersonId = "person"
local humanBody = body("IsoPlayer")
local threatBody = body("IsoPlayer")
local rec = { id = "person", bodyOwner = "ZAO", bodyOwnerToken = "blood:1",
    x = 10, y = 10, z = 0 }
local threatRec = { id = "threat", dead = false }
local state = { personId = "person", terminalState = "crossed",
    currentForm = "none", history = {} }
local threatState = { personId = "threat", terminalState = "afflicted" }
local items = {}
local list = {
    size = function() return #items end,
    get = function(_, index) return items[index + 1] end,
}
getCell = function()
    return { getObjectListForLua = function() return list end }
end

local counts = {}
local workResult, mindCanMove, derivedCrossed = false, true, false
local adapter = nil
local function clearCounts()
    counts = { begin = 0, advance = 0, write = 0, settle = 0,
        mind = 0, perceive = 0, decide = 0, work = 0, activity = "none" }
end
clearCounts()

SAO = {
    History = { countyHours = function() return 24 end },
    Identity = {
        all = function() return { person = rec, threat = threatRec } end,
        get = function(id)
            if id == "person" then return rec end
            if id == "threat" then return threatRec end
            return nil
        end,
    },
    Body = {
        active = {}, foreign = {},
        canTransfer = function() return false end,
        materializeExternal = function() return nil end,
    },
    Communication = {
        registerExecutionOwner = function(owner, seen)
            assert(owner == "ZAO")
            adapter = seen
            return true
        end,
    },
    Perception = { observe = function(id, seen)
        assert(id == "person" and seen == humanBody)
        counts.perceive = counts.perceive + 1
    end },
    Controller = {
        coordinationRuntime = {},
        advanceExternalCoordination = function(id, seen, owner, activity)
            assert(id == "person" and seen == humanBody and owner == "ZAO")
            counts.work = counts.work + 1
            counts.activity = activity
            return workResult
        end,
    },
}
ZAO = {
    Pathogen = {
        stateOf = function(id)
            if id == "threat" then return threatState end
            if id == "person" or derivedCrossed then return state end
            return nil
        end,
        begin = function() counts.begin = counts.begin + 1 end,
        advance = function() counts.advance = counts.advance + 1 end,
        attributeString = function() return "" end,
    },
    StateStore = {
        read = function() return state end,
        write = function() counts.write = counts.write + 1 end,
        writeSettlement = function() counts.write = counts.write + 1 end,
    },
    State = { of = function() return state end },
    Mind = { of = function(seenRec, hour, seenBody)
        assert(seenRec == rec and hour == 24 and seenBody == humanBody)
        counts.mind = counts.mind + 1
        return { execution = { canMove = mindCanMove,
            canTarget = mindCanMove } }
    end },
    Settlement = {
        active = function() return {} end,
        notePresence = function()
            counts.settle = counts.settle + 1
            return nil
        end,
    },
    Sandbox = { policy = function() return {
        enabled = true, controller = true, mind = true, settlement = true,
    } end },
    Crossed = { decide = function()
        counts.decide = counts.decide + 1
        return true
    end },
}
ZAO.Driver = {
    currentActivity = function() return "idle" end,
    step = function(personId, seen, seenState, mind, now, hours)
        local activity = threatenedDriver and "hunt" or "idle"
        counts.work = counts.work + 1
        counts.activity = activity
        if not workResult then ZAO.Crossed.decide() end
        return true, workResult and "coordination" or activity
    end,
}

function __wrongBody() return wrongBody end
function __humanBody() return humanBody end
function __record() return rec end
function __counts() return counts end
function __adapter() return adapter end
function __wrongScan()
    clearCounts()
    items = { wrongBody }
    SAO.Body.active = {}
    SAO.Body.foreign.person = nil
    ZAO.Controller.controlled.person = nil
    ZAO.Controller.nextScanAt = 0
    wrongBody.data = { SAOPersonId = "person" }
    ZAO.Controller.tick(100)
end
function __derivedCrossedScan()
    clearCounts()
    items = { wrongBody }
    SAO.Body.active = {}
    SAO.Body.foreign.person = nil
    ZAO.Controller.controlled.person = nil
    ZAO.Controller.nextScanAt = 0
    wrongBody.data = {}
    derivedCrossed = true
    ZAO.Controller.tick(120)
    derivedCrossed = false
end
function __validShell(coordinates, threatened)
    clearCounts()
    items = {}
    SAO.Body.active = threatened and { threat = threatBody } or {}
    SAO.Body.foreign.person = humanBody
    ZAO.Controller.controlled.person = humanBody
    mindCanMove = true
    threatenedDriver = threatened == true
    workResult = coordinates == true
    __processExternalCrossed(200, 24, 1)
end
function __incapableSnapshot()
    mindCanMove = false
    local seen = __adapter().snapshot("person", rec)
    mindCanMove = true
    return seen
end
'''

PROBE = r'''
local stage='wrong representation'
local probeOk, probeProblem = pcall(function()
__wrongScan()
local rejected = __counts()
assert(__wrongBody().data.ZAOOwned == nil,
    "rejected IsoZombie was marked as ZAO-owned")
assert(rejected.begin == 0 and rejected.advance == 0,
    "rejected IsoZombie advanced the pathogen")
assert(rejected.settle == 0 and rejected.write == 0,
    "rejected IsoZombie changed settlement or durable state")
assert(rejected.mind == 0 and rejected.decide == 0,
    "rejected IsoZombie entered cognition or Crossed execution")
assert(ZAO.Controller.controlled.person == nil,
    "rejected IsoZombie entered the controlled roster")

stage='derived representation'
__derivedCrossedScan()
local rejectedDerived = __counts()
assert(__wrongBody().data.ZAOOwned == nil
    and rejectedDerived.begin == 0 and rejectedDerived.advance == 0,
    "derived IsoZombie with Crossed state entered ownership/pathogen work")
assert(rejectedDerived.settle == 0 and rejectedDerived.write == 0
    and rejectedDerived.mind == 0 and rejectedDerived.decide == 0,
    "derived IsoZombie with Crossed state reached downstream side effects")

stage='coordinated shell'
__validShell(true)
local coordinated = __counts()
assert(coordinated.work == 1 and coordinated.decide == 0,
    "accepted coordination did not own the valid human shell")
assert(coordinated.activity == "idle",
    "unpressured Crossed work was mislabeled as competing activity")
assert(coordinated.perceive == 1 and coordinated.mind == 1,
    "valid living shell did not acquire private sight before deliberation")
assert(__humanBody().data.ZAOOwned == true,
    "valid human shell lost its ZAO projection")
local owner = __adapter()
stage='registered body resolution'
assert(owner and owner.bodyFor("person", __record()) == __humanBody(),
    "communication could not resolve the registered ZAO execution owner")
stage='capable snapshot'
local snapshot = owner.snapshot("person", __record())
assert(snapshot.represented and snapshot.canAcquire and snapshot.canDeliver
    and snapshot.canExecute and not snapshot.incapable,
    "ZAO execution owner hid retained human capability")
stage='incapable snapshot'
local incapable = __incapableSnapshot()
assert(not incapable.canAcquire and not incapable.canCarry
    and not incapable.canDeliver and not incapable.canExecute
    and incapable.incapable,
    "ZAO execution owner leaked actions after retained verbs were unavailable")

stage='ordinary shell'
__validShell(false)
local ordinary = __counts()
assert(ordinary.work == 1 and ordinary.decide == 1,
    "ordinary Crossed deliberation did not resume when no work owned the tick")

stage='competing driver activity'
__validShell(false, true)
local threatened = __counts()
assert(threatened.activity == "hunt" and threatened.decide == 1,
    "an observed Crossed target did not become a competing activity")
end)
assert(probeOk, "Crossed ownership probe failed at " .. stage .. ": "
 .. tostring(probeProblem))
'''


def run(work: Path, source: str) -> subprocess.CompletedProcess[str]:
    instrumented = source.replace(
        "return ZAO.Controller",
        "__processExternalCrossed = processExternalCrossed\nreturn ZAO.Controller",
        1,
    )
    (work / "controller.lua").write_text(instrumented, encoding="utf-8")
    return subprocess.run(
        [str(JDK / "java.exe"), "-cp",
         f"{GAME / 'projectzomboid.jar'}{os.pathsep}{work}",
         "CrossedOwnershipRun", str(work / "host.lua"),
         str(work / "controller.lua"), str(work / "probe.lua")],
        cwd=work, capture_output=True, text=True, timeout=30)


def main() -> int:
    required = [GAME / "projectzomboid.jar", GAME / "stdlib.lua",
                JDK / "java.exe", JDK / "javac.exe", CONTROLLER]
    if not all(path.is_file() for path in required):
        print("Border 11 SKIPPED: installed game VM or JDK absent")
        return 0
    source = CONTROLLER.read_text(encoding="utf-8-sig")
    controls = [
        ("pre-admission representation guard",
         "and not representationRejected then", "then"),
        ("derived Crossed representation guard",
         'local rejected = not returnHeld and (rec and rec.bodyOwner == "ZAO"\n'
         '        or livingZAOState)',
         'local rejected = not returnHeld and rec and rec.bodyOwner == "ZAO"'),
        ("coordination owns the valid shell",
         "if mind and ZAO.Driver and ZAO.Driver.step then",
         "if false then"),
        ("actor-private perception before deliberation",
         'SAO.Perception.observe(personId, body, now, false)',
         'return false'),
        ("retained capability gates execution",
         "canExecute = canAct == true", "canExecute = true"),
        ("communication execution-owner registration",
         'SAO.Communication.registerExecutionOwner("ZAO", executionAdapter)',
         "return false"),
    ]
    if source.count("return ZAO.Controller") != 1:
        print("REFUSED: Crossed ownership instrumentation seam changed")
        return 1
    for name, old, _ in controls:
        if source.count(old) != 1:
            print(f"REFUSED: {name} mutation seam changed")
            return 1
    with tempfile.TemporaryDirectory(prefix="zao-crossed-ownership-") as tmp:
        work = Path(tmp)
        shutil.copy2(GAME / "stdlib.lua", work / "stdlib.lua")
        (work / "CrossedOwnershipRun.java").write_text(RUNNER, encoding="utf-8")
        (work / "host.lua").write_text(HOST, encoding="utf-8")
        (work / "probe.lua").write_text(PROBE, encoding="utf-8")
        built = subprocess.run(
            [str(JDK / "javac.exe"), "-cp", str(GAME / "projectzomboid.jar"),
             "CrossedOwnershipRun.java"], cwd=work,
            capture_output=True, text=True, timeout=60)
        if built.returncode:
            print(built.stdout + built.stderr)
            return 1
        fixed = run(work, source)
        if fixed.returncode or "CROSSED_OWNERSHIP_OK" not in fixed.stdout:
            print("REFUSED: Crossed ownership production path failed\n"
                  + fixed.stdout + fixed.stderr)
            return 1
        for name, old, new in controls:
            mutant = run(work, source.replace(old, new, 1))
            if mutant.returncode == 0:
                print(f"REFUSED: {name} mutation survived")
                return 1
    print("Border 11 PASS: Crossed coordination uses the retained human shell; IsoZombie admission is side-effect-free; private sight, driver activity and retained capability govern work; six controls fail")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
