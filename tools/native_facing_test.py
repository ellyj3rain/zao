#!/usr/bin/env python3
"""Border 16: native facing, emitter vocals and production form windups.

Uses the existing ZAO installed-Kahlua runner. The Java reflection check binds
the fixture actuators to the installed engine; Lua controls restore the actual
invalid body calls and must fail despite the production pcall wrappers.
"""
from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile

from pathogen_vm_test import GAME, JDK, RUNNER

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "mod/42.20/media/lua/client/ZAO_Behaviors.lua"
CHECK = r'''
Events = { OnWeaponHitCharacter = { Add = function() end } }
local target = {
    getX = function() return 12 end, getY = function() return 10 end,
    getZ = function() return 0 end, getVehicle = function() return nil end,
}
function facingChecks()
    for _, form in ipairs({ "Puker", "Wrecker", "Leaper" }) do
        local data = { ZAOForm = form, ZAOWreckerShaped = true }
        local faces, vocals = 0, 0
        local voiceName = "native-selected-voice-" .. form
        local emitter = {}
        function emitter:playVocals(name)
            assert(name == voiceName, "native voice name changed")
            vocals = vocals + 1
            return 17
        end
        local body = {
            getModData = function() return data end,
            getX = function() return 10 end, getY = function() return 10 end,
            getZ = function() return 0 end,
            pathToLocationF = function() end,
            getEmitter = function() return emitter end,
            getVoiceSoundName = function() return voiceName end,
            faceThisObject = function(self, object)
                assert(object == target, "wrong native facing target")
                faces = faces + 1
            end,
        }
        local state = { formPerformance = 0.5 }
        assert(ZAO.Behaviors.drive(body, state, target, 100, 2) == "hold", "windup did not begin")
        assert(faces == 1, "native facing not executed")
        assert(vocals == 1, "native emitter vocal not executed")
        assert(ZAO.Behaviors.drive(body, state, target, 101, 2) == "hold", "windup disappeared")
        assert(faces == 2, "native facing not maintained")
        assert(vocals == 1, "windup vocal repeated every tick")
    end
end
'''


def main():
    jar = GAME / "projectzomboid.jar"
    if not all(p.is_file() for p in (jar, GAME / "stdlib.lua", JDK / "javac.exe", JDK / "java.exe")):
        print("Border 16 SKIPPED: installed game VM or JDK absent")
        return 0
    source = SOURCE.read_text(encoding="utf-8")
    seam = "zombie:faceThisObject(target)"
    vocal_seam = "if emitter and name then emitter:playVocals(name) end"
    if source.count(seam) != 1 or source.count(vocal_seam) != 1:
        raise AssertionError("native facing/vocal control seam differs")
    runner = RUNNER.replace("PathogenRun", "NativeFacingRun").replace("PATHOGEN_VM_OK", "NATIVE_FACING_OK")
    runner = runner.replace("var platform =", """
        zombie.characters.IsoZombie.class.getMethod("faceThisObject", zombie.iso.IsoObject.class);
        var emitter = zombie.characters.IsoZombie.class.getMethod("getEmitter").getReturnType();
        if (emitter.getMethod("playVocals", String.class).getReturnType() != long.class
            || zombie.characters.IsoZombie.class.getMethod("getVoiceSoundName").getReturnType() != String.class) {
            throw new AssertionError("native vocal contract changed");
        }
        try {
            zombie.characters.IsoZombie.class.getMethod("playVocals");
            throw new AssertionError("engine contract changed: inspect former body vocal method");
        } catch (NoSuchMethodException expected) { }
        try {
            zombie.characters.IsoZombie.class.getMethod("faceObject", zombie.iso.IsoObject.class);
            throw new AssertionError("engine contract changed: inspect former facing method");
        } catch (NoSuchMethodException expected) { }
        var platform =""")
    with tempfile.TemporaryDirectory(prefix="zao-native-facing-") as name:
        work = Path(name)
        shutil.copy2(GAME / "stdlib.lua", work / "stdlib.lua")
        (work / "NativeFacingRun.java").write_text(runner, encoding="utf-8")
        (work / "check.lua").write_text(CHECK, encoding="utf-8")
        (work / "run.lua").write_text("facingChecks()\n", encoding="utf-8")
        subprocess.run([str(JDK / "javac.exe"), "-cp", str(jar), "NativeFacingRun.java"],
                       cwd=work, check=True, capture_output=True, timeout=60)
        command = [str(JDK / "java.exe"), "-Djava.awt.headless=true", "-cp", str(jar)+os.pathsep+str(work),
                   "NativeFacingRun", "check.lua", "source.lua", "run.lua"]
        cases = (
            ("production", source, None),
            ("invalid facing call", source.replace(seam, "zombie:faceObject(target)"),
             "native facing not executed"),
            ("invalid body vocal call", source.replace(vocal_seam, "zombie:playVocals()"),
             "native emitter vocal not executed"),
        )
        for label, code, expected in cases:
            (work / "source.lua").write_text(code, encoding="utf-8")
            result = subprocess.run(command, cwd=work, text=True, capture_output=True, timeout=30)
            if label == "production":
                if result.returncode or "NATIVE_FACING_OK" not in result.stdout:
                    raise AssertionError(result.stdout + result.stderr)
            elif result.returncode == 0 or expected not in result.stderr + result.stdout:
                raise AssertionError(label + " control was not detected: " + result.stdout + result.stderr)
    print("Border 16 PASS: installed facing and emitter-vocal APIs; Puker, Wrecker and Leaper windups; both original invalid body-call controls refused")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
