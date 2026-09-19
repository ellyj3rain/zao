#!/usr/bin/env python3
"""Border 8: ZAO durable state reconstructs disposable Lua/Java projections."""

from __future__ import annotations

import re
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LUA = ROOT / "mod/42.20/media/lua/shared"
GAME = Path(r"C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid")
JDK = Path(r"C:\Users\jleyv\Peanut Butter\JetBrains\Java\bin")
RECON = ROOT / "tools/luacheck/ZAORuntimeReconstructionProbe.java"
RESET = ROOT / "tools/luacheck/ZAORuntimeResetProbe.java"
GENERATION = ROOT / "tools/luacheck/SaveGenerationProbe.java"
RETURN_SOURCE = ROOT / "tools/luacheck/ReturnSourceProbe.java"
JAR = ROOT / "mod/42.20/media/java/ZAO.jar"
ZB = GAME / "ZombieBuddy.jar"


def method(class_name: str, signature: str) -> str:
    result = subprocess.run(
        [str(JDK / "javap.exe"), "-c", "-p", "-classpath",
         str(GAME / "projectzomboid.jar"), class_name],
        capture_output=True, text=True, timeout=30,
    )
    if result.returncode:
        raise RuntimeError(result.stderr)
    lines = result.stdout.splitlines()
    start = next(i for i, line in enumerate(lines) if signature in line)
    end = next((i for i in range(start + 1, len(lines))
                if re.match(r"^  (public|private|protected|static) ", lines[i])), len(lines))
    return "\n".join(lines[start:end])


def engine_contract() -> None:
    init = method("zombie.world.moddata.GlobalModData", "public void init()")
    world = method("zombie.iso.IsoWorld", "public void init()")
    exit_body = method("zombie.gameStates.IngameState", "public void exit()")
    save = method("zombie.GameWindow", "public static void save(boolean)")
    positions = lambda body, term: [int(value) for value in re.findall(
        r"^\s*(\d+):.*" + re.escape(term) + r".*$", body, re.M)]
    assert positions(init, "Method reset:()V")[0] < positions(init, "Method load:()V")[0] \
        < positions(init, "String OnInitGlobalModData")[0]
    assert positions(world, "Method zombie/world/moddata/GlobalModData.init:()V")[0] \
        < positions(world, "Method zombie/ReanimatedPlayers.loadReanimatedPlayers:()V")[0]
    assert positions(exit_body, "Method zombie/Lua/LuaManager.init:()V")[0] \
        < positions(exit_body, "Method zombie/Lua/LuaManager.LoadDirBase:()V")[0]
    assert positions(save, "String OnSave")[-1] < positions(save, "Method zombie/iso/IsoCell.save:")[0] \
        < positions(save, "Method zombie/world/moddata/GlobalModData.save:")[0]
    print("ENGINE lifecycle: journal replay < native load; OnSave < native save < GlobalModData")


def build(work: Path) -> None:
    engine_cp = str(GAME / "projectzomboid.jar")
    result = subprocess.run(
        [str(JDK / "javac.exe"), "-encoding", "UTF-8", "-cp", engine_cp,
         "-d", str(work), str(RECON)], capture_output=True, text=True, timeout=120,
    )
    if result.returncode:
        raise RuntimeError("reconstruction probe compile failed\n" + result.stderr)
    result = subprocess.run(
        [str(JDK / "javac.exe"), "-encoding", "UTF-8", "-cp", engine_cp + ";" + str(JAR),
         "-d", str(work), str(RESET)], capture_output=True, text=True, timeout=120,
    )
    if result.returncode:
        raise RuntimeError("reset probe compile failed\n" + result.stderr)
    generation_cp = engine_cp + ";" + str(ZB) + ";" + str(JAR)
    result = subprocess.run(
        [str(JDK / "javac.exe"), "-encoding", "UTF-8", "-cp", generation_cp,
         "-d", str(work), str(RETURN_SOURCE), str(GENERATION)],
        capture_output=True, text=True, timeout=120,
    )
    if result.returncode:
        raise RuntimeError("save-generation probe compile failed\n" + result.stderr)


def run_reconstruction(work: Path, root: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(JDK / "java.exe"), "-cp", str(GAME / "projectzomboid.jar") + ";" + str(work),
         "ZAORuntimeReconstructionProbe", str(root)], cwd=work,
        capture_output=True, text=True, timeout=90,
    )


def mirror(work: Path, state_store: str) -> Path:
    root = work / ("mirror-" + str(abs(hash(state_store))))
    target = root / "mod/42.20/media/lua/shared"
    target.mkdir(parents=True)
    shutil.copy2(LUA / "ZAO_Settlement.lua", target / "ZAO_Settlement.lua")
    (target / "ZAO_StateStore.lua").write_text(state_store, encoding="utf-8")
    return root


def main() -> int:
    required = [GAME / "projectzomboid.jar", GAME / "stdlib.lua", JDK / "java.exe",
                JDK / "javac.exe", JDK / "javap.exe", RECON, RESET, GENERATION,
                RETURN_SOURCE, JAR, ZB]
    if not all(path.is_file() for path in required):
        print("Border 8 SKIPPED: installed engine, JDK, probes or shipped jar absent")
        return 0
    faults: list[str] = []
    try:
        engine_contract()
        controller = (ROOT / "java/src/com/zao/engine/ZAOControllerStore.java").read_text(encoding="utf-8")
        bootstrap = (ROOT / "java/src/com/zao/bridge/ZAOBridgeBootstrap.java").read_text(encoding="utf-8")
        bridge = (ROOT / "java/src/com/zao/bridge/ZAOBridge.java").read_text(encoding="utf-8")
        for label, present in {
            "course seeded from recovery": "course.restore(recovery.repeatInfections()" in controller,
            "environment change triggers teardown":
                "env != exposedInto && env != resetForEnv" in bootstrap
                and "resetRuntimeForWorld()" in bootstrap,
            "return runtime reset is included":
                "ZAOReturnBody.resetRuntimeForWorld()" in bridge
                and "ZAOReturnSourceStore.resetRuntimeForWorld()" in bridge,
        }.items():
            if not present:
                faults.append(label)

        with tempfile.TemporaryDirectory(prefix="zao-runtime-reconstruction-") as tmp:
            work = Path(tmp)
            shutil.copy2(GAME / "stdlib.lua", work / "stdlib.lua")
            build(work)
            production = run_reconstruction(work, ROOT)
            if production.returncode or "ZAO_RUNTIME_RECONSTRUCTION_OK" not in production.stdout:
                print(production.stdout + production.stderr)
                faults.append("production settlement reconstruction")
            else:
                print("LUA production: pathogen facts persist and settlement projection is replaced")

            source = (LUA / "ZAO_StateStore.lua").read_text(encoding="utf-8")
            controls = [
                ("prior-world settlement",
                 source.replace("    for key in pairs(ZAO.Settlement.groups) do",
                                "    for key in pairs({}) do", 1)),
                ("duplicate reconstruction callback",
                 source.replace("    Events.OnGameStart.Remove(StateStore.onGameStart)",
                                "    -- callback intentionally retained", 1)),
            ]
            for label, changed in controls:
                result = run_reconstruction(work, mirror(work, changed))
                rejected = result.returncode != 0
                print("CONTROL " + label + ": " + ("REJECTED" if rejected else "SURVIVED"))
                if not rejected:
                    faults.append(label)

            cp = str(GAME / "projectzomboid.jar") + ";" + str(JAR) + ";" + str(work)
            reset = subprocess.run([str(JDK / "java.exe"), "-cp", cp,
                                    "ZAORuntimeResetProbe"], cwd=work,
                                   capture_output=True, text=True, timeout=90)
            if reset.returncode or "ZAO_RUNTIME_RESET_OK" not in reset.stdout:
                print(reset.stdout + reset.stderr)
                faults.append("native controller/course reconstruction")
            else:
                print("NATIVE production: controller maps clear and course mirror reconstructs")

            generation_cp = str(GAME / "projectzomboid.jar") + ";" + str(ZB) \
                + ";" + str(JAR) + ";" + str(work)
            generation = subprocess.run(
                [str(JDK / "java.exe"), "-cp", generation_cp, "SaveGenerationProbe"],
                cwd=work, capture_output=True, text=True, timeout=120,
            )
            if generation.returncode or "SAVE_GENERATION_OK" not in generation.stdout:
                print(generation.stdout + generation.stderr)
                faults.append("interrupted native/global save generation")
            else:
                print(generation.stdout.strip())
    except Exception as error:
        print("FAULT: " + str(error))
        faults.append("probe error")

    if faults:
        print("Border 8 FAULT: " + ", ".join(dict.fromkeys(faults)))
        return 1
    print("Border 8 PASS: reconstruction, teardown and every native/global save-generation pairing")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
