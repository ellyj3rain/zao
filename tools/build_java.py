#!/usr/bin/env python3
"""Build ZAO's Java bridge and install it into the mod tree."""

from __future__ import annotations

import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
JAVA_SRC = ROOT / "java" / "src"
JAVA_OUT = ROOT / "java" / "out"
JAVA_DIST = ROOT / "java" / "dist"
MOD_JAR = ROOT / "mod" / "42.20" / "media" / "java" / "ZAO.jar"
JDK = pathlib.Path(r"C:\Users\jleyv\Peanut Butter\JetBrains\Java\bin")
PZ_JAR = pathlib.Path(
    r"C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\projectzomboid.jar"
)
ZB_JAR = pathlib.Path(
    r"C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\ZombieBuddy.jar"
)


def run(command: list[str]) -> None:
    completed = subprocess.run(command, check=False)
    if completed.returncode != 0:
        raise SystemExit(completed.returncode)


def main() -> int:
    # The probe the gate uses to tell "cannot run here" (exit 2) from
    # "ran and failed" (exit 1). The build reads this machine's JDK and
    # the game's own jars; a machine without them - the forge's runner -
    # must see the border SKIP, never pass, per the sister's [C56] law.
    if "--can-build" in sys.argv[1:]:
        if not JDK.is_dir() or not PZ_JAR.is_file() or not ZB_JAR.is_file():
            return 2
        return 0

    if not JDK.is_dir():
        print("FAULT: JetBrains JDK not found")
        return 1
    if not PZ_JAR.is_file() or not ZB_JAR.is_file():
        print("FAULT: Project Zomboid jars not found")
        return 1

    shutil.rmtree(JAVA_OUT, ignore_errors=True)
    JAVA_OUT.mkdir(parents=True, exist_ok=True)
    JAVA_DIST.mkdir(parents=True, exist_ok=True)

    sources = sorted(path.as_posix() for path in JAVA_SRC.rglob("*.java"))
    if not sources:
        print("FAULT: no Java sources found")
        return 1
    source_list = JAVA_OUT / "sources.txt"
    source_list.write_text(
        "\n".join(f'"{source}"' for source in sources) + "\n",
        encoding="utf-8",
    )

    javac = JDK / "javac.exe"
    classpath = f"{PZ_JAR};{ZB_JAR}"
    run([
        str(javac),
        "-cp",
        classpath,
        "-d",
        str(JAVA_OUT),
        f"@{source_list}",
    ])

    manifest = JAVA_OUT / "MANIFEST.MF"
    manifest.write_text("Manifest-Version: 1.0\n", encoding="utf-8")

    jar = JDK / "jar.exe"
    built_jar = JAVA_DIST / "ZAO.jar"
    if built_jar.exists():
        built_jar.unlink()
    # [A31] The entry stamp every jar carries, fixed. The readiness
    # sweep of 2026-09-13 found the gate's own build step dirtying a
    # clean tree: the gate rebuilds the bridge on every run, and a
    # rebuild of unchanged source produced a jar that differed from
    # the committed one only in its zip entry timestamps - the classes
    # were entry-for-entry identical - so every check, including the
    # pre-commit hook, left the tree modified. With the stamp fixed, a
    # rebuild of the same source is the same jar and the gate leaves a
    # clean tree clean. The date is the county's own calendar anchor,
    # July 9 1993 - the day the Knox Event schedule starts, named on
    # the sister's ratified sandbox surface - so every jar is stamped
    # as of the world it ships into.
    jar_stamp = "1993-07-09T00:00:00Z"
    run([
        str(jar),
        "--create",
        "--date",
        jar_stamp,
        "--file",
        str(built_jar),
        "--manifest",
        str(manifest),
        "-C",
        str(JAVA_OUT),
        "com",
    ])

    MOD_JAR.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(built_jar, MOD_JAR)

    print(f"built {built_jar}")
    print(f"installed {MOD_JAR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
