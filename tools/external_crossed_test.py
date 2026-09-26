#!/usr/bin/env python3
"""Border 9: ZAO returns a dead transferred Crossed shell to SAO exactly once."""
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
public class ExternalCrossedRun {
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
        System.out.println("EXTERNAL_CROSSED_OK");
    }
}
'''

HOST = r'''
Events = { OnTick = { Add = function() end } }
local player = { x = 0, y = 0,
    getX = function(self) return self.x end, getY = function(self) return self.y end,
    getZ = function() return 0 end,
    getModData = function() return { SAO_ObserverAnchor = true } end }
local terminalState, hibernations = "crossed", 0
getSpecificPlayer = function() return player end
getCell = function() return nil end
local rec = { id = "person", bodyOwner = "ZAO", bodyOwnerToken = "blood:1",
    x = 10, y = 10, z = 0 }
local body = { dead = false, data = {}, x = 10, y = 10, z = 0 }
function body:isDead() return self.dead end
function body:getX() return self.x end
function body:getY() return self.y end
function body:getZ() return self.z end
function body:getModData() return self.data end
local deathCalls, writes, materializations, exposureResumes, acceptDeath =
    0, 0, 0, 0, true
SAO = {
    Identity = {
        all = function() return { person = rec } end,
        get = function(id) return id == "person" and rec or nil end,
    },
    Body = {
        active = {}, foreign = { person = body },
        canTransfer = function() return true end,
        hibernateExternal = function()
            hibernations = hibernations + 1
            SAO.Body.foreign.person = nil
            return true
        end,
        materializeExternal = function()
            materializations = materializations + 1
            SAO.Body.foreign.person = body
            return body
        end,
    },
    Controller = {
        observeExternalDeath = function(id, seen, owner)
            assert(id == "person" and seen == body and owner == "ZAO")
            deathCalls = deathCalls + 1
            if not acceptDeath then return false end
            rec.dead, rec.bodyOwner, rec.bodyOwnerToken = true, nil, nil
            SAO.Body.foreign.person = nil
            return true
        end,
    },
}
ZAO = {
    Pathogen = {
        stateOf = function() return {
            terminalState = terminalState, currentForm = "none", history = {},
        } end,
    },
    StateStore = { write = function() writes = writes + 1 end },
    Exposure = { resumePending = function()
        exposureResumes = exposureResumes + 1
    end },
}
function __reset(dead, accepted)
    SAO.Body.recover = nil
    player.x, player.y, terminalState, hibernations = 0, 0, "crossed", 0
    rec.dead, rec.bodyOwner, rec.bodyOwnerToken = nil, "ZAO", "blood:1"
    body.dead, body.data = dead == true, {}
    SAO.Body.foreign.person = body
    ZAO.Controller.controlled.person = body
    deathCalls, writes, materializations, acceptDeath = 0, 0, 0,
        accepted == true
end
function __deathCalls() return deathCalls end
function __writes() return writes end
function __materializations() return materializations end
function __exposureResumes() return exposureResumes end
function __body() return body end
function __rec() return rec end
function __dormant(state)
    terminalState = state
    SAO.Body.foreign.person = nil
    ZAO.Controller.controlled.person = nil
end
function __moveRegion(x, y) player.x, player.y = x, y end
function __hibernations() return hibernations end
'''

PROBE = r'''
__reset(true, true)
__processExternalCrossed(1, 1, 0)
assert(__deathCalls() == 1, "dead body was not returned to SAO")
assert(ZAO.Controller.controlled.person == nil, "dead body remained controlled")
assert(__rec().dead and __rec().bodyOwner == nil,
    "accepted death retained living ownership")
assert(__writes() == 0, "dead body was advanced after death")

-- If SAO cannot accept the hand-back yet, the corpse stays discoverable and
-- the next tick retries; neither tick drives it.
__reset(true, false)
__processExternalCrossed(2, 2, 0)
__processExternalCrossed(3, 3, 0)
assert(__deathCalls() == 2, "failed hand-back was not retried")
assert(SAO.Body.foreign.person == __body(), "failed hand-back lost corpse")
assert(ZAO.Controller.controlled.person == nil and __writes() == 0,
    "unaccepted corpse remained active")
assert(__materializations() == 0, "dead body was rematerialized during hand-back")

-- A living transferred shell remains ZAO-owned and follows the ordinary
-- Crossed projection path.
__reset(false, true)
__processExternalCrossed(4, 4, 0)
assert(__deathCalls() == 0, "living body entered death funnel")
assert(ZAO.Controller.controlled.person == __body() and __writes() == 1,
    "living transferred body did not remain controlled")
assert(__body().data.ZAOOwned == true
    and __body().data.ZAOTerminalState == "crossed",
    "living body lost its owner projection")

local beforeResume = __exposureResumes()
ZAO.Controller.tick(100)
assert(__exposureResumes() == beforeResume + 1,
    "controller did not resume a converted action whose transfer was pending")

assert(ZAO.Participants.player(0) == nil, "observer admitted as participant")
__reset(false, true)
SAO.Body.recover = function(rec) return false, "native-unload-pending" end
__processExternalCrossed(150, 150, 0)
assert(ZAO.Controller.controlled.person == nil and __writes() == 0
    and SAO.Body.foreign.person == __body() and __materializations() == 0,
    "unresolved native unload still drove external person")
SAO.Body.recover = function(rec) return true end
__processExternalCrossed(151, 151, 0)
assert(ZAO.Controller.controlled.person == __body() and __writes() == 1,
    "resolved native presence did not resume external person")
for _, state in ipairs({ "afflicted", "crossed" }) do
    __reset(false, true)
    __dormant(state)
    __processExternalCrossed(200, 200, 0)
    assert(__materializations() == 1 and ZAO.Controller.controlled.person == __body(),
        "observer region did not materialize living external person")
    assert(__body().data.ZAOTerminalState == state, "living state changed during residency")
    __moveRegion(1000, 1000)
    __processExternalCrossed(201, 201, 0)
    assert(__hibernations() == 1 and SAO.Body.foreign.person == nil,
        "observer region did not hibernate distant external person")
end
'''


def run(work: Path, source: str) -> subprocess.CompletedProcess[str]:
    instrumented = source.replace(
        "return ZAO.Controller",
        "__processExternalCrossed = processExternalCrossed\nreturn ZAO.Controller",
        1,
    )
    (work / "host.lua").write_text(HOST, encoding="utf-8")
    (work / "controller.lua").write_text(instrumented, encoding="utf-8")
    (work / "probe.lua").write_text(PROBE, encoding="utf-8")
    return subprocess.run(
        [str(JDK / "java.exe"), "-cp", f"{GAME / 'projectzomboid.jar'}{os.pathsep}{work}",
         "ExternalCrossedRun", str(work / "host.lua"),
         str(ROOT / "mod/42.20/media/lua/shared/ZAO_Participants.lua"),
         str(work / "controller.lua"), str(work / "probe.lua")],
        cwd=work, capture_output=True, text=True, timeout=30)


def main() -> int:
    required = [GAME / "projectzomboid.jar", GAME / "stdlib.lua",
                JDK / "java.exe", JDK / "javac.exe", CONTROLLER]
    if not all(path.is_file() for path in required):
        print("Border 9 SKIPPED: installed game VM or JDK absent")
        return 0
    source = CONTROLLER.read_text(encoding="utf-8-sig")
    controls = [
        ("native unload ownership", "available = SAO.Body.recover(rec) == true", "SAO.Body.recover(rec) available = true"),
        ("observer residency", "ZAO.Participants.residencyCenter()", "nil, nil"),
        ("dead-body detection", "if dead then", "if false then"),
        ("pending transfer retry", "ZAO.Exposure.resumePending()",
         "-- pending exposure retry omitted"),
    ]
    if (source.count("return ZAO.Controller") != 1
            or any(source.count(old) != 1 for _, old, _ in controls)):
        print("REFUSED: external death instrumentation seam changed")
        return 1
    with tempfile.TemporaryDirectory(prefix="zao-external-crossed-") as tmp:
        work = Path(tmp)
        shutil.copy2(GAME / "stdlib.lua", work / "stdlib.lua")
        (work / "ExternalCrossedRun.java").write_text(RUNNER, encoding="utf-8")
        built = subprocess.run(
            [str(JDK / "javac.exe"), "-cp", str(GAME / "projectzomboid.jar"),
             "ExternalCrossedRun.java"], cwd=work,
            capture_output=True, text=True, timeout=60)
        if built.returncode:
            print(built.stdout + built.stderr)
            return 1
        fixed = run(work, source)
        if fixed.returncode or "EXTERNAL_CROSSED_OK" not in fixed.stdout:
            print("REFUSED: external Crossed production path failed\n"
                  + fixed.stdout + fixed.stderr)
            return 1
        for label, old, new in controls:
            mutant = run(work, source.replace(old, new, 1))
            if mutant.returncode == 0:
                print(f"REFUSED: {label} mutation survived")
                return 1
    print("Border 9 PASS: living Crossed stays controlled; death hands the corpse to SAO, retries refusal, never drives the dead, and resumes pending conversion transfer; observer-driven residency covers Afflicted and Crossed without a participant; unresolved native unload retains ownership without driving; four controls fail")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
