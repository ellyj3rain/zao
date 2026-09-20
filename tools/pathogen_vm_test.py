#!/usr/bin/env python3
"""Border 5: pathogen state and elapsed days on the installed Kahlua VM.

The tiny Java runner follows SAO tools/luacheck/LuaRun.java's engine-VM
pattern. ZAO owns this copy so core checks require no sibling checkout;
when present, SAO's actual event emitter also exercises the terminal seam.
"""
from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
LUA = ROOT / "mod/42.20/media/lua/shared"
GAME = Path(os.environ.get("PZ_DIR", r"C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid"))
JDK = Path(os.environ.get("JDK_BIN", r"C:\Users\jleyv\Peanut Butter\JetBrains\Java\bin"))
RUNNER = r'''
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaThread;
public class PathogenRun {
    public static void main(String[] args) throws Exception {
        var platform = new J2SEPlatform();
        var env = platform.newEnvironment();
        var thread = new KahluaThread(platform, env);
        thread.debugOwnerThread = Thread.currentThread();
        for (String path : args) {
            try (var reader = Files.newBufferedReader(Path.of(path), StandardCharsets.UTF_8)) {
                thread.call(LuaCompiler.loadis(reader, path, env), null, null, null);
            }
        }
        System.out.println("PATHOGEN_VM_OK");
    }
}
'''
HOST = r'''
local stores = {}
Events = { OnGameStart = { Add = function() end } }
ModData = { getOrCreate = function(key)
    stores[key] = stores[key] or {}
    return stores[key]
end }
local roll = 0
local rolls = nil
local draws = 0
function setRoll(value) roll = value; rolls = nil; draws = 0 end
function setRolls(values) rolls = values; draws = 0 end
function drawCount() return draws end
SAO = { Rand = { unit = function()
    draws = draws + 1
    if rolls then
        assert(rolls[draws] ~= nil, "unexpected pathogen random draw")
        return rolls[draws]
    end
    return roll
end } }
local courseCalls = {}
function resetCourseCalls() courseCalls = {} end
function courseCallCount(verb) return courseCalls[verb] or 0 end
ZAOJavaBridge = {}
for _, verb in ipairs({ "coursePassDeath", "courseInfect", "courseSurvive" }) do
    local name = verb
    ZAOJavaBridge[name] = function()
        courseCalls[name] = (courseCalls[name] or 0) + 1
    end
end
'''
PROBE = r'''
-- The real shipped VM has pairs but no global next.
assert(next == nil, "engine contract changed: inspect next before updating control")
local brain = ZAO.Brain.stateFor("brain-only", true)
assert(brain and brain.version == 2 and type(brain.history) == "table")
assert(ZAO.StateStore.store().brain["brain-only"] == brain,
    "brain history did not use the durable owner")
assert(ZAO.Pathogen.begin(nil) == nil)
local state = ZAO.Pathogen.begin("person", "turned", 3, "vm-test")
assert(state and state.currentForm == "Puker")
assert(state.attributeMutations.Speed ~= nil, "empty table failed mutation")
assert(ZAO.StateStore.read("person") == state, "state not persisted")
state.attributeMutations.Speed = 0.7
setRoll(0.9)
assert(ZAO.Pathogen.begin("person", "turned", 3, "vm-repeat") == state)
assert(state.attributeMutations.Speed == 0.7, "same-day begin changed existing attribute")
assert(state.startedDay == 3 and #state.history == 2)
state.attributeMutations = "legacy-malformed"
setRoll(0)
ZAO.Pathogen.begin("person", "turned", 5, "vm-legacy")
assert(type(state.attributeMutations) == "table")
assert(state.attributeMutations.Speed ~= nil)
ZAO.Pathogen.begin("person", "crossed", 6, "vm-crossed")
assert(state.currentForm == "none" and state.terminalState == "crossed")
local count = 0
for _ in pairs(state.attributeMutations) do count = count + 1 end
assert(count == 0, "crossed retained mutation")

setRoll(0.9)
local timed = ZAO.Pathogen.begin("timed", "infected", 0, "vm-clock")
assert(timed.humanCapability == 1 and timed.lastAdvancedDay == 0)
assert(not ZAO.Pathogen.advance("timed", 0), "charged growth at begin")
assert(timed.humanCapability == 1, "day zero changed capability")
assert(ZAO.Pathogen.advance("timed", 1), "next day did not advance")
assert(math.abs(timed.humanCapability - 0.9) < 0.000001)
assert(not ZAO.Pathogen.advance("timed", 1), "charged same day twice")
assert(not ZAO.Pathogen.advance("timed", 0), "backward day advanced")
ZAO.Pathogen.begin("timed", "turned", 2, "vm-transition")
assert(timed.terminalState == "turned" and timed.lastAdvancedDay == 2)
assert(timed.humanCapability < 0.9, "prior state's accrued day was lost")
local capability = timed.humanCapability
ZAO.Pathogen.begin("timed", "turned", 2, "vm-repeat-transition")
assert(timed.humanCapability == capability, "transition day charged twice")
assert(not ZAO.Pathogen.advance("timed", 2))
local legacy = { terminalState = "infected", attributeMutations = {}, humanCapability = 1 }
ZAO.StateStore.store().people.legacy = legacy
assert(not ZAO.Pathogen.advance("legacy", 8), "invented legacy elapsed days")
assert(ZAO.Pathogen.advance("legacy", 9), "legacy did not resume")

-- The loaded-body controller projects the pathogen through State.of and
-- writes that projection back on every scan. Both persisted clocks must
-- survive that real path, including repeated scans on the same day.
local record = { id = "projected", knoxInfected = true }
ZAO.Pathogen.begin(record.id, "infected", 0, "vm-projection")
assert(ZAO.StateStore.write(record.id, ZAO.State.of(record, 0)))
assert(ZAO.Pathogen.advance(record.id, 1),
    "projected state failed next-day advance")
local projected = ZAO.Pathogen.stateOf(record.id)
assert(math.abs(projected.humanCapability - 0.9) < 0.000001)
assert(projected.startedDay == 0 and projected.lastAdvancedDay == 1)
assert(ZAO.StateStore.write(record.id, ZAO.State.of(record, 24)))
assert(not ZAO.Pathogen.advance(record.id, 1),
    "projected state charged same day twice")
assert(ZAO.Pathogen.advance(record.id, 2),
    "projected state lost later elapsed day")

-- The same mutation and draw stream must produce the same nonlinear
-- course whether a body is seen daily or returns after being unloaded.
local function course(id, skipped)
    setRolls({ 0, 0.2, 0.6, 0, 0.4, 0.8,
        0.9, 0, 0, 0.1, 0.2, 0, 0.8, 0.1, 0.9, 0.9 })
    local result = ZAO.Pathogen.begin(id, "turned", 0, "vm-gap")
    if skipped then
        assert(ZAO.Pathogen.advance(id, 5))
    else
        for day = 1, 5 do assert(ZAO.Pathogen.advance(id, day)) end
    end
    return result, drawCount()
end
local function same(left, right, path)
    assert(type(left) == type(right), "gap replay differs from daily state: " .. path)
    if type(left) ~= "table" then
        assert(left == right, "gap replay differs from daily state: " .. path)
        return
    end
    for key, value in pairs(left) do
        if key ~= "personId" then same(value, right[key], path .. "." .. tostring(key)) end
    end
    for key in pairs(right) do
        assert(left[key] ~= nil, "gap replay differs from daily state: extra " .. tostring(key))
    end
end
local daily, dailyDraws = course("daily", false)
local skipped, skippedDraws = course("skipped", true)
same(daily, skipped, "course")
assert(dailyDraws == 16 and skippedDraws == dailyDraws, "gap replay changed draw sequence")
assert(daily.currentForm == "Husk" and daily.attributeMutations.Strength > 0)
assert(daily.terminalState == "afflicted" and #daily.history == 4)
assert(daily.history[2].type == "reversion" and daily.history[2].day == 2)
assert(daily.history[3].type == "decay-episode" and daily.history[3].day == 3)
assert(daily.history[4].type == "decay-episode" and daily.history[4].day == 4)
assert(daily.identityAxes.selfPreservation == 0.9 and daily.identityAxes.verbs == 0.9)

setRoll(0.9)
local beforeTransition = ZAO.Pathogen.begin("before-transition", "infected", 0, "vm-gap-transition")
local gapTransition = ZAO.Pathogen.begin("gap-transition", "infected", 0, "vm-gap-transition")
for day = 1, 3 do ZAO.Pathogen.advance("before-transition", day) end
ZAO.Pathogen.begin("before-transition", "turned", 3, "vm-transition")
ZAO.Pathogen.begin("gap-transition", "turned", 3, "vm-transition")
same(beforeTransition, gapTransition, "transition")
assert(not ZAO.Pathogen.advance("gap-transition", 3), "gap transition charged twice")

-- Infection may already have produced terminal crossed while SAO's
-- record subsequently reports death or recovery. Exercise the real
-- event emitter when the sibling exists, otherwise the same public API.
resetCourseCalls()
setRoll(0)
local crossedRecord = { id = "crossed-events", knoxInfected = true }
local crossed = ZAO.Pathogen.begin(crossedRecord.id, "infected", 0, "infection")
assert(crossed.terminalState == "crossed")
assert(courseCallCount("coursePassDeath") == 1)
local function externalEvent(kind, terminal, day)
    local atHours = day * 24 + 0.75
    if SAO.PathogenEvents then
        assert(SAO.PathogenEvents.emit(kind, crossedRecord.id, day,
            { record = crossedRecord, atHours = atHours }))
    else
        assert(ZAO.Pathogen.begin(crossedRecord.id, terminal, day, kind,
            crossedRecord, atHours))
    end
    assert(crossed.terminalState == "crossed", "crossed changed on external event")
    assert(crossed.decayState == "crossed" and crossed.currentForm == "none")
    assert(crossed.source == kind and crossed.lastAdvancedDay == day)
    local event = crossed.history[#crossed.history]
    assert(event.source == kind and event.day == day and event.terminalState == "crossed")
    assert(event.atHours == atHours, "exact pathogen event time was rounded to a day")
    assert(event.eventTerminalState == terminal, "external event input was lost")
end
setRoll(0.9)
crossedRecord.dead = true
crossedRecord.turnedDormant = true
externalEvent("death", "turned", 1)
externalEvent("turn", "turned", 1)
crossedRecord.dead = nil
crossedRecord.turnedDormant = nil
crossedRecord.knoxInfected = nil
externalEvent("recovery", "living", 2)
crossedRecord.knoxInfected = true
externalEvent("infection", "infected", 3)
assert(drawCount() == 0, "terminal crossed rerolled")
assert(courseCallCount("coursePassDeath") == 1
    and courseCallCount("courseInfect") == 0
    and courseCallCount("courseSurvive") == 0, "terminal crossed restarted bridge course")
assert(not ZAO.Pathogen.advance(crossedRecord.id, 6))
assert(crossed.lastAdvancedDay == 6 and drawCount() == 0)
'''


def main() -> int:
    jar = GAME / "projectzomboid.jar"
    stdlib = GAME / "stdlib.lua"
    java, javac = JDK / "java.exe", JDK / "javac.exe"
    if not all(p.is_file() for p in (jar, stdlib, java, javac)):
        print("Border 5 SKIPPED: installed game VM or JDK absent")
        return 0
    source = (LUA / "ZAO_Pathogen.lua").read_text(encoding="utf-8")
    state_source = (LUA / "ZAO_State.lua").read_text(encoding="utf-8")
    event_source = ROOT.parent / "survivor-awareness/mod/42.20/media/lua/shared/SAO_PathogenEvents.lua"
    if not event_source.is_file():
        print("Border 5 integration SKIPPED: SAO event-emitter source absent; core terminal checks still run")
    seam = "not hasEntries(state.attributeMutations)"
    if source.count(seam) != 1:
        print("REFUSED: old-code control seam changed")
        return 1
    with tempfile.TemporaryDirectory(prefix="zao-pathogen-vm-") as tmp:
        work = Path(tmp)
        shutil.copy2(stdlib, work / "stdlib.lua")
        for name, contents in (("PathogenRun.java", RUNNER), ("host.lua", HOST),
                               ("probe.lua", PROBE), ("pathogen.lua", source),
                               ("state.lua", state_source)):
            (work / name).write_text(contents, encoding="utf-8")
        built = subprocess.run([str(javac), "-cp", str(jar), "PathogenRun.java"],
                               cwd=work, capture_output=True, text=True, timeout=60)
        if built.returncode:
            print(built.stdout + built.stderr)
            return 1
        args = [str(java), "-cp", f"{jar}{os.pathsep}{work}", "PathogenRun",
                str(work / "host.lua"), str(LUA / "ZAO_StateStore.lua"),
                str(LUA / "ZAO_Brain.lua"),
                str(LUA / "ZAO_Forms.lua"), str(work / "pathogen.lua"),
                str(work / "state.lua")]
        if event_source.is_file():
            args.append(str(event_source))
        args.append(str(work / "probe.lua"))
        fixed = subprocess.run(args, cwd=work, capture_output=True, text=True, timeout=30)
        if fixed.returncode or "PATHOGEN_VM_OK" not in fixed.stdout:
            print("REFUSED: current pathogen failed real VM\n" + fixed.stdout + fixed.stderr)
            return 1
        (work / "pathogen.lua").write_text(
            source.replace(seam, "next(state.attributeMutations) == nil"), encoding="utf-8")
        control = subprocess.run(args, cwd=work, capture_output=True, text=True, timeout=30)
        if control.returncode == 0 or "Object tried to call nil" not in control.stderr + control.stdout:
            print("REFUSED: old next() control did not reproduce\n" + control.stdout + control.stderr)
            return 1
        # Restore real code, then charge a day when the monotone guard
        # should return. The probe must name repeated same-day growth.
        broken_clock = source.replace(
            "if day <= previous then return false end",
            "if day <= previous then advanceDay(state, day); return true end")
        if broken_clock == source:
            print("REFUSED: daily-clock control seam changed")
            return 1
        (work / "pathogen.lua").write_text(broken_clock, encoding="utf-8")
        control = subprocess.run(args, cwd=work, capture_output=True, text=True, timeout=30)
        if control.returncode == 0 or "same-day begin changed existing attribute" not in control.stderr + control.stdout:
            print("REFUSED: daily-clock control did not reproduce\n" + control.stdout + control.stderr)
            return 1
        (work / "pathogen.lua").write_text(source, encoding="utf-8")
        broken_projection = state_source
        for field in ("startedDay", "lastAdvancedDay"):
            projection_seam = f"        {field} = saved and saved.{field} or nil,\n"
            if broken_projection.count(projection_seam) != 1:
                print("REFUSED: state-projection control seam changed")
                return 1
            broken_projection = broken_projection.replace(projection_seam, "")
        (work / "state.lua").write_text(broken_projection, encoding="utf-8")
        control = subprocess.run(args, cwd=work, capture_output=True, text=True, timeout=30)
        if control.returncode == 0 or "projected state failed next-day advance" not in control.stderr + control.stdout:
            print("REFUSED: state-projection control did not reproduce\n" + control.stdout + control.stderr)
            return 1
        (work / "state.lua").write_text(state_source, encoding="utf-8")
        for label, old, new, failure in (
            ("elapsed-gap", "for elapsedDay = previous + 1, day do",
             "for elapsedDay = day, day do", "gap replay differs from daily state"),
            ("terminal-crossed", 'if prior and state.terminalState == "crossed" then',
             "if false then", "crossed changed on external event"),
            ("exact-event-time", "local eventAtHours = tonumber(atHours) or eventDay * 24.0",
             "local eventAtHours = eventDay * 24.0",
             "exact pathogen event time was rounded to a day"),
        ):
            if source.count(old) != 1:
                print(f"REFUSED: {label} control seam changed")
                return 1
            (work / "pathogen.lua").write_text(source.replace(old, new), encoding="utf-8")
            control = subprocess.run(args, cwd=work, capture_output=True, text=True, timeout=30)
            if control.returncode == 0 or failure not in control.stderr + control.stdout:
                print(f"REFUSED: {label} control did not reproduce\n" + control.stdout + control.stderr)
                return 1
    integration = "; actual SAO event emitter" if event_source.is_file() else ""
    print("Border 5 PASS: real VM mutation, persistence, legacy, terminal crossed, daily/gap equivalence and controller projection"
          + integration + "; six named controls fail")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
