# A28 - The Java bridge is built

| Field | Record |
| --- | --- |
| Batch | `A28` |
| Date | 2026-09-11 |
| Name | The Java bridge is built |
| Status | Closed append-only batch - implementation and records |
| Threads | [`T-001`](Batches/THREADS.md#t-001), [`T-002`](Batches/THREADS.md#t-002) |

## Record

ZAO now ships the Java-side actuator surface the engine contract requires.

`ZAO.jar` is built from `java/src/com/zao`, installed into
`mod/42.20/media/java/`, and loaded by ZombieBuddy through `mod.info`. The
bridge exposes:

- `ZAOJavaBridge:apply`
- `ZAOJavaBridge:drive`
- `ZAOJavaBridge:release`
- `ZAOJavaBridge:owns`
- `ZAOJavaBridge:formOf`
- `ZAOJavaBridge:performanceOf`
- `ZAOJavaBridge:stats`

The bridge applies per-form speed, strength, cognition, memory, sight, and
hearing to the engine's own public `IsoZombie` fields, then drives the body
through the engine's own target and path methods.

## What changed

- `java/src/com/zao/Main.java` loads the bridge through ZombieBuddy.
- `java/src/com/zao/ZAOAgent.java` logs bridge activity.
- `java/src/com/zao/bridge/ZAOBridge.java` owns and drives the turned body.
- `java/src/com/zao/bridge/ZAOBridgeBootstrap.java` exposes the bridge to Lua.
- `mod/42.20/media/java/ZAO.jar` is built and installed.
- `mod/mod.info` and `mod/42.20/mod.info` load the jar through ZombieBuddy.
- `tools/build_java.py` builds and installs the jar.
- `tools/check.sh` builds the Java bridge as part of the gate.
- `ARCHITECTURE.md` names the Java bridge.
- `SESSION_STATE.md` advances to this batch.
- `BATCH_LOG.md` gains the `[A28]` row.
- `tools/version_replay.py` classifies `[A28]`.

## Verification

`bash tools/check.sh` is clean, including the Java bridge build.
