#!/usr/bin/env python3
"""Compile actual ZAO source against installed PZ in private temporary JVMs.

No game, chunks, or saves are loaded. Receipt includes engine/source hashes,
commands, native javap line evidence, limits and defect-control outcomes.
"""
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
ZB = PZ.with_name("ZombieBuddy.jar")
PASS = "PASS native return hold/resume/removal"
MUTATIONS = [
    ("preserved-reanimated", "retention(Retention.PRESERVED, ReanimatedPlayers.instance).removeIf(value -> value == body);", "// defect: retain reanimated body", "partial removal retained body for reuse/reinsertion"),
    ("pooled-partial-source", "retention(Retention.REUSE, VirtualZombieManager.instance).removeIf(value -> value == body);", "// defect: retain reuse queue", "partial removal retained body for reuse/reinsertion"),
    ("no-held-scheduler-removal", "MovingObjectUpdateScheduler.instance.removeObject(body);", "// defect: still scheduled", "held source still scheduled"),
    ("ignore-detached-items", "collect(body.getPrimaryHandItem(), result); collect(body.getSecondaryHandItem(), result);", "// defect: detached hands ignored", "processing item acknowledged before drain"),
    ("resume-after-partial", "|| body.getModData().rawget(REMOVING) != null || body.isDead()", "|| body.isDead()", "partly removed source resumed"),
    ("accept-duplicates", "if (result != null && result != body) throw new IllegalStateException(\"Duplicate loaded person body\");", "// defect: duplicate accepted", "duplicate loaded identity accepted"),
    ("accept-active-actions", "body.getVehicle() != null || body.hasTimedActions()", "body.getVehicle() != null", "active timed action accepted"),
    ("omit-square-removal", "body.removeFromSquare();", "// defect: square retains body", "native removal retry failed"),
    ("weak-pending-ownership", "private static final Map<IsoZombie, Pending> PENDING = new IdentityHashMap<>();", "private static final Map<IsoZombie, Pending> PENDING = new java.util.WeakHashMap<>();", "pending source lost after Lua reload and GC"),
    ("no-failed-save-owner", "if (body.isReanimatedPlayer() && !body.isDead()", "if (false && body.isReanimatedPlayer() && !body.isDead()", "failed reanimated source has no native save owner"),
    ("no-native-update-guard", "return token instanceof String text && !text.isBlank();", "return false;", "loaded held source advanced before reconstruction"),
    ("no-loaded-item-reconstruction", "if (!hasHold(body)) continue;", "if (true) continue;", "loaded held cargo not paused before processing"),
]
WEAVE_MUTATIONS = [
    ("omit-native-postupdate-site", '.or(ElementMatchers.named("postupdate"))', '', "Native return weave mask mismatch"),
    ("omit-native-item-site", "ZAOReturnBody.restoreLoadedHolds(cell);", "// defect: missing reconstruction site", "Native return weave mask mismatch"),
    ("omit-full-save-selector", '"beginSaveRealZombies".equals(method) && "()V".equals(desc)', 'false', "Native population selection sites changed"),
    ("omit-cell-save-selector", '"requestSaveCell".equals(method) && "(II)V".equals(desc)', 'false', "Native population selection sites changed"),
    ("omit-pre-save-checkpoint", "ZAOReturnSourceStore.beforePopulationSave();", ";", "Native return weave mask mismatch"),
    ("omit-direct-virtualization", "return ZAOReturnSourceStore.virtualize(body);", "return false;", "Native return weave mask mismatch"),
    ("omit-outer-chunk-guard", "public static void enter(@Advice.This Object chunk) {\n            ZAOReturnSourceStore.beforeChunkUnload(chunk);", "public static void enter(@Advice.This Object chunk) {\n            ;", "Native return weave mask mismatch"),
    ("omit-population-chunk-guard", "public static void enter(@Advice.Argument(0) Object chunk) {\n            ZAOReturnSourceStore.beforeChunkUnload(chunk);", "public static void enter(@Advice.Argument(0) Object chunk) {\n            ;", "Native return weave mask mismatch"),
    ("omit-preserved-load-boundary", "ZAOReturnSourceStore.restorePreservedMaterials();", ";", "Native return weave mask mismatch"),
]
SOURCE_MUTATIONS = [
    ("restore-root-union", "snapshot", "if (roots.contains(item.id)) return false;", "if (true) return false;", "Source equipment/root restoration differs"),
    ("omit-original-item-tables", "snapshot", "entry.getValue().getModData().load(table, VERSION);", "table.position(table.limit());", "Source material identity/type/parent differs"),
    ("change-fake-dead-form", "snapshot", "body.setWasFakeDead(data.wasFake);", "body.setWasFakeDead(false);", "Source visual ownership changed"),
    ("accept-corrupt-checkpoint", "snapshot", "if (!MessageDigest.isEqual(hash(Arrays.copyOf(bytes, end))", "if (false && !MessageDigest.isEqual(hash(Arrays.copyOf(bytes, end))", "corrupt checkpoint accepted"),
    ("ordinary-population-duplicate", "store", "        return true;\n    }\n\n    /** Runs before native iteration", "        return false;\n    }\n\n    /** Runs before native iteration", "ordinary held source enters native population"),
    ("wrong-chunk-width", "store", "body.getX() / 8f", "body.getX() / 10f", "chunk unload did not detach exact held owner"),
    ("no-stream-detach", "store", "if (!ZAOReturnBody.detachForStreaming(body))", "if (false)", "native virtualization lost source checkpoint"),
    ("no-dormant-resolver", "body", "return loaded == null ? ZAOReturnSourceStore.resolveDetached(personId) : loaded;", "return loaded;", "checkpoint-backed dormant source did not resolve unpublished"),
    ("oversized-native-string", "store", "private static final int STRING_PART = 16000;", "private static final int STRING_PART = 40000;", "source checkpoint table serialization corrupted"),
    ("accept-wrong-incarnation", "store", 'if (!same(record, loaded)) throw new IllegalStateException("Loaded source incarnation differs");', ";", "checkpoint incarnation mismatch accepted"),
    ("omit-native-preserved-resolution", "body", 'if (body.isReanimatedPlayer() && body.getModData().rawget("SAOPersonId") instanceof String) candidates.add(body);', ";", "Native reanimated material restore missed load boundary"),
    ("omit-native-equipment-overlay", "store", "ZAOReturnSourceSnapshot.restoreMaterials(body, packed);", "if (packed.isEmpty()) ZAOReturnSourceSnapshot.restoreMaterials(body, packed);", "held reanimated equipment overlay lost"),
    ("no-native-load-isolation", "store", "automaticFailure(id, error);\n                    try { ZAOReturnBody.guardLoadedSource(body); }", "if (true) throw error;\n                    try { ZAOReturnBody.guardLoadedSource(body); }", "bad checkpoint escaped native registry callback"),
    ("no-record-isolation", "store", "} catch (RuntimeException error) { automaticFailure(key, error); }", "} catch (RuntimeException error) { throw error; }", "bad checkpoint prevented other native overlay"),
    ("no-body-isolation", "body", "} catch (RuntimeException error) { ZAOReturnSourceStore.automaticFailure(id, error); }", "} catch (RuntimeException error) { throw error; }", "bad source escaped native item callback"),
    ("allow-failed-native-material", "store", 'if (error != null) throw new IllegalStateException("Pending source unavailable: " + id, error);', 'if (error != null && !(error.getCause() instanceof java.io.IOException)) throw new IllegalStateException("Pending source unavailable: " + id, error);', "failed checkpoint identity remained accessible"),
]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", type=Path, default=ROOT)
    parser.add_argument("--receipt", type=Path)
    parser.add_argument("--production-only", action="store_true")
    parser.add_argument("--only-control", action="append")
    args = parser.parse_args()
    def selected(controls):
        return [] if args.production_only else [c for c in controls if not args.only_control or c[0] in args.only_control]
    root = args.root.resolve()
    source = root / "java/src/com/zao/engine/ZAOReturnBody.java"
    probe = root / "tools/luacheck/ReturnRemovalProbe.java"
    weave = root / "java/src/com/zao/engine/ZAOReturnWeave.java"
    snapshot = root / "java/src/com/zao/engine/ZAOReturnSourceSnapshot.java"
    store = root / "java/src/com/zao/engine/ZAOReturnSourceStore.java"
    source_probe = root / "tools/luacheck/ReturnSourceProbe.java"
    receipt = {"results": [], "commands": [], "limits": "Actual headless engine objects; no chunks/game/saves. Incoming Lua actions and arbitrary foreign mutation remain caller checks."}
    def run(argv, cwd):
        result = subprocess.run([str(x) for x in argv], cwd=cwd, capture_output=True,
            text=True, encoding="utf-8", errors="replace", timeout=60)
        receipt["commands"].append({"argv": [str(x) for x in argv], "cwd": str(cwd),
            "returncode": result.returncode, "stdout": result.stdout, "stderr": result.stderr})
        return result
    try:
        if not all(p.is_file() for p in (PZ, ZB, JDK / "javac.exe", JDK / "java.exe")):
            print("SKIPPED native return removal: installed engine/JDK absent")
            return 0
        receipt["hashes"] = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in (PZ, ZB, source, weave, snapshot, store, source_probe, probe, Path(__file__), root / "java/src/com/zao/Main.java")}
        original = source.read_text(encoding="utf-8-sig")
        original_weave = weave.read_text(encoding="utf-8-sig")
        original_snapshot = snapshot.read_text(encoding="utf-8-sig")
        original_store = store.read_text(encoding="utf-8-sig")
        with tempfile.TemporaryDirectory(prefix="zao-return-removal-") as tmp:
            scratch = Path(tmp)
            for cls in ("zombie.characters.IsoZombie", "zombie.VirtualZombieManager", "zombie.ReanimatedPlayers", "zombie.MovingObjectUpdateScheduler", "zombie.iso.IsoMovingObject", "zombie.iso.IsoCell", "zombie.iso.IsoChunk", "zombie.iso.IsoWorld", "zombie.popman.ZombiePopulationManager", "zombie.iso.objects.IsoDeadBody", "zombie.GameWindow$StringUTF", "se.krka.kahlua.j2se.KahluaTableImpl"):
                result = run([JDK / "javap.exe", "-classpath", PZ, "-c", "-p", "-l", cls], scratch)
                if result.returncode: raise RuntimeError("Engine evidence extraction failed")
            def case(name, text, weave_text=original_weave, snapshot_text=original_snapshot, store_text=original_store):
                work = scratch / name; work.mkdir()
                changed = work / source.name; changed.write_text(text, encoding="utf-8")
                changed_weave = work / weave.name; changed_weave.write_text(weave_text, encoding="utf-8")
                changed_snapshot = work / snapshot.name; changed_snapshot.write_text(snapshot_text, encoding="utf-8")
                changed_store = work / store.name; changed_store.write_text(store_text, encoding="utf-8")
                classes = work / "classes"; classes.mkdir()
                compiled = run([JDK / "javac.exe", "-encoding", "UTF-8", "-cp", os.pathsep.join((str(PZ), str(ZB))), "-d", classes, changed, changed_weave, changed_snapshot, changed_store, probe, source_probe], work)
                if compiled.returncode: raise RuntimeError(f"{name} compile failed: {compiled.stderr}")
                return run([JDK / "java.exe", "-XX:+EnableDynamicAgentLoading", f"-Duser.home={work}", "-cp", os.pathsep.join((str(classes), str(PZ), str(ZB))), "ReturnRemovalProbe"], work)
            production = case("production", original)
            if production.returncode or PASS not in production.stdout:
                raise RuntimeError("Production native probe failed: " + production.stdout + production.stderr)
            receipt["results"].append({"case": "production", "passed": True})
            print("PASS native return source hold, resume and terminal removal")
            for name, before, after, reason in selected(MUTATIONS):
                count = original.count(before)
                if count != (3 if name == "no-held-scheduler-removal" else 2 if name == "omit-square-removal" else 1):
                    raise RuntimeError(f"Control {name} target count changed: {count}")
                result = case(name, original.replace(before, after, 1))
                if result.returncode == 0 or reason not in result.stdout + result.stderr:
                    raise RuntimeError(f"Control {name} failed for wrong reason: {result.stdout}{result.stderr}")
                receipt["results"].append({"case": name, "passed": True, "reason": reason})
                print(f"CONTROL {name}: {reason}")
            for name, owner, before, after, reason in selected(SOURCE_MUTATIONS):
                originals = {"body": original, "snapshot": original_snapshot, "store": original_store}
                if originals[owner].count(before) != 1: raise RuntimeError(f"Control {name} target changed")
                originals[owner] = originals[owner].replace(before, after, 1)
                result = case(name, originals["body"], snapshot_text=originals["snapshot"], store_text=originals["store"])
                if result.returncode == 0 or reason not in result.stdout + result.stderr:
                    raise RuntimeError(f"Control {name} failed for wrong reason: {result.stdout}{result.stderr}")
                receipt["results"].append({"case": name, "passed": True, "reason": reason})
                print(f"CONTROL {name}: {reason}")
            for name, before, after, reason in selected(WEAVE_MUTATIONS):
                if original_weave.count(before) != 1: raise RuntimeError(f"Control {name} target changed")
                result = case(name, original, original_weave.replace(before, after, 1))
                if result.returncode == 0 or reason not in result.stdout + result.stderr:
                    raise RuntimeError(f"Control {name} failed for wrong reason: {result.stdout}{result.stderr}")
                receipt["results"].append({"case": name, "passed": True, "reason": reason})
                print(f"CONTROL {name}: {reason}")
        receipt["status"] = "PASS"
        print("  6) PASS -- native return removal")
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        receipt["status"] = "FAIL"; receipt["error"] = str(error)
        print("FAULT " + str(error))
    if args.receipt:
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    return 0 if receipt.get("status") == "PASS" else 1

if __name__ == "__main__":
    sys.exit(main())
