#!/usr/bin/env python3
"""Verify afflicted-return physiology against the installed native engine."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PZ = Path(r"C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\projectzomboid.jar")
JDK = Path(r"C:\Users\jleyv\Peanut Butter\JetBrains\Java\bin")
PASS = "PASS native afflicted health"
CONTROLS = [
    ("leave-part-infected", "            part.SetInfected(false);",
     "            // defect: part infection survives",
     "return health restore refused"),
    ("scalar-only-health", "        liftTo(damage, MINIMUM_RETURN_HEALTH);",
     "        damage.setOverallBodyHealth(MINIMUM_RETURN_HEALTH);",
     "return health restore refused"),
    ("erase-all-injuries", "        liftTo(damage, MINIMUM_RETURN_HEALTH);",
     "        damage.RestoreToFullHealth();",
     "return health did not stop at critical viability"),
    ("overheal-return", "public static final float MINIMUM_RETURN_HEALTH = 25.0f;",
     "public static final float MINIMUM_RETURN_HEALTH = 100.0f;",
     "return health did not stop at critical viability"),
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", type=Path, default=ROOT)
    parser.add_argument("--receipt", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    source = root / "java/src/com/zao/engine/ZAOReturnHealth.java"
    probe = root / "tools/luacheck/ReturnHealthProbe.java"
    receipt = {"results": [], "commands": [], "limits":
        "Installed-engine body objects and native next update; no loaded world, save or renderer."}

    def run(argv, cwd):
        result = subprocess.run([str(value) for value in argv], cwd=cwd,
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=60)
        receipt["commands"].append({"argv": [str(value) for value in argv],
            "cwd": str(cwd), "returncode": result.returncode,
            "stdout": result.stdout, "stderr": result.stderr})
        return result

    try:
        required = (PZ, JDK / "javac.exe", JDK / "java.exe", source, probe)
        if not all(path.is_file() for path in required):
            print("SKIPPED native return health: installed engine/JDK absent")
            return 0
        receipt["hashes"] = {str(path): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in required + (Path(__file__),)}
        original = source.read_text(encoding="utf-8-sig")
        with tempfile.TemporaryDirectory(prefix="zao-return-health-") as temporary:
            scratch = Path(temporary)

            def case(name, text):
                work = scratch / name
                work.mkdir()
                changed = work / source.name
                changed.write_text(text, encoding="utf-8")
                classes = work / "classes"
                classes.mkdir()
                compiled = run([JDK / "javac.exe", "-encoding", "UTF-8",
                    "-cp", PZ, "-d", classes, changed, probe], work)
                if compiled.returncode:
                    raise RuntimeError(name + " compile failed: " + compiled.stderr)
                return run([JDK / "java.exe", f"-Duser.home={work}", "-cp",
                    os.pathsep.join((str(classes), str(PZ))), "ReturnHealthProbe"], work)

            production = case("production", original)
            if production.returncode or PASS not in production.stdout:
                raise RuntimeError("Production health probe failed: "
                    + production.stdout + production.stderr)
            receipt["results"].append({"case": "production", "passed": True})
            print(production.stdout.strip())

            for name, before, after, reason in CONTROLS:
                if original.count(before) != 1:
                    raise RuntimeError("Control target changed: " + name)
                result = case(name, original.replace(before, after, 1))
                combined = result.stdout + result.stderr
                if result.returncode == 0 or reason not in combined:
                    raise RuntimeError("Control failed for wrong reason: " + name + " " + combined)
                receipt["results"].append(
                    {"case": name, "passed": True, "reason": reason})
                print("CONTROL " + name + ": " + reason)
        receipt["status"] = "PASS"
        print("  7) PASS -- afflicted return physiology")
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        receipt["status"] = "FAIL"
        receipt["error"] = str(error)
        print("FAULT " + str(error))
    if args.receipt:
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    return 0 if receipt.get("status") == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
