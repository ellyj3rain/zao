package com.zao.engine;

import java.io.IOException;
import java.util.*;
import se.krka.kahlua.vm.KahluaTable;
import zombie.Lua.LuaManager;
import zombie.characters.IsoZombie;
import zombie.iso.IsoCell;
import zombie.iso.IsoChunk;
import zombie.iso.IsoGridSquare;
import zombie.iso.IsoWorld;
import zombie.world.moddata.GlobalModData;

/** Pending-source ownership across the native population files and GlobalModData.
 * ZAOSaveGeneration supplies the pre-native write-ahead generation; this table
 * supplies the per-incarnation snapshot and native reconciliation. The table
 * holds no Java objects. SAO retains domain transaction authority.
 */
public final class ZAOReturnSourceStore {
    private static final String STORE = "ZombieAwareness_State", KEY = "returnSources";
    private static final String GENERATION = "ZAOReturnGeneration";
    private static final int MAX_SOURCES = 4096;
    // GameWindow.StringUTF stores a signed-short byte length. Base64 is ASCII.
    private static final int STRING_PART = 16000;
    private static final int MAX_PACKED = 4 * ((16 * 1024 * 1024 + 2) / 3);
    private static final Map<IsoZombie, String> MATERIALS = new WeakHashMap<>();
    private static final Map<String, RuntimeException> FAILURES = new LinkedHashMap<>();
    private static IsoCell failureCell;
    private static RuntimeException globalFailure;
    private static boolean nativeRestoreActive;
    private static boolean reconciling;
    private ZAOReturnSourceStore() { }

    /**
     * Drop native receipts from preceding cells while leaving the durable
     * returnSources table untouched. Same-cell Lua reload retains material
     * receipts because native reanimated inventory may only be restored at
     * its load boundary.
     */
    public static void resetRuntimeForWorld() {
        IsoCell cell = IsoWorld.instance == null ? null : IsoWorld.instance.currentCell;
        MATERIALS.entrySet().removeIf(entry -> cell == null
            || entry.getKey() == null || entry.getKey().getCell() != cell);
        if (failureCell != cell) {
            FAILURES.clear();
            globalFailure = null;
            failureCell = cell;
        }
        nativeRestoreActive = false;
        reconciling = false;
    }

    private static void failureWorld() {
        if (failureCell != IsoWorld.instance.currentCell) {
            FAILURES.clear(); globalFailure = null; failureCell = IsoWorld.instance.currentCell;
        }
    }
    /** Automatic callbacks retain a failed identity until a fresh world load.
     * A partly restored physical source must never become a new checkpoint. */
    static void automaticFailure(Object id, RuntimeException error) {
        failureWorld();
        if (id instanceof String text && FAILURES.containsKey(text)) return;
        if (id instanceof String text && !text.isBlank() && text.length() <= 256 && FAILURES.size() < MAX_SOURCES) {
            if (FAILURES.putIfAbsent(text, error) == null)
                System.err.println("[ZAO] Pending source refused: " + text + ": " + error.getMessage());
        } else if (globalFailure == null) {
            globalFailure = error;
            System.err.println("[ZAO] Pending source index refused: " + error.getMessage());
        }
    }
    static void requireHealthy(String id) {
        failureWorld();
        RuntimeException error = globalFailure != null ? globalFailure : FAILURES.get(id);
        if (error != null) throw new IllegalStateException("Pending source unavailable: " + id, error);
        KahluaTable record = entry(id);
        if (record != null && !id.equals(record.rawget("personId")))
            throw new IllegalStateException("Malformed return source index");
    }

    private static KahluaTable entries() {
        KahluaTable store = GlobalModData.instance.getOrCreate(STORE);
        Object value = store.rawget(KEY);
        if (value == null) { value = LuaManager.platform.newTable(); store.rawset(KEY, value); }
        if (!(value instanceof KahluaTable table)) throw new IllegalStateException("Invalid return source store");
        return table;
    }
    private static String marker(IsoZombie body, String key) {
        Object value = body.getModData().rawget(key);
        if (!(value instanceof String text) || text.isBlank() || text.length() > 256)
            throw new IllegalStateException("Invalid source marker " + key);
        return text;
    }
    private static KahluaTable entry(String id) {
        Object value = entries().rawget(id);
        if (value == null) return null;
        if (!(value instanceof KahluaTable table)) throw new IllegalStateException("Invalid source checkpoint entry");
        return table;
    }
    private static KahluaTable fragments(String value) {
        if (value.length() > MAX_PACKED) throw new IllegalStateException("Source payload exceeds bound");
        KahluaTable parts = LuaManager.platform.newTable();
        int count = (value.length() + STRING_PART - 1) / STRING_PART;
        parts.rawset("count", (double)count); parts.rawset("length", (double)value.length());
        for (int index = 0; index < count; index++)
            parts.rawset((double)(index + 1), value.substring(index * STRING_PART, Math.min(value.length(), (index + 1) * STRING_PART)));
        return parts;
    }
    private static String packed(KahluaTable record) {
        Object value = record.rawget("packed");
        // Short single-string checkpoints created by the earlier development
        // format remain readable; new writes always use safe native fragments.
        if (value instanceof String text && text.length() <= 32767) return text;
        if (!(value instanceof KahluaTable parts) || !(parts.rawget("length") instanceof Double length)
                || !(parts.rawget("count") instanceof Double count) || length < 1 || length > MAX_PACKED
                || length != Math.rint(length) || count < 1 || count > (MAX_PACKED + STRING_PART - 1) / STRING_PART
                || count != Math.rint(count)) throw new IllegalStateException("Invalid source fragments");
        StringBuilder result = new StringBuilder(length.intValue());
        for (int index = 1; index <= count.intValue(); index++) {
            Object part = parts.rawget((double)index);
            if (!(part instanceof String text) || text.isEmpty() || text.length() > STRING_PART)
                throw new IllegalStateException("Invalid source fragment");
            result.append(text);
            if (result.length() > length.intValue()) throw new IllegalStateException("Source fragments exceed declared length");
        }
        if (result.length() != length.intValue()) throw new IllegalStateException("Truncated source fragments");
        return result.toString();
    }
    private static boolean same(KahluaTable record, IsoZombie body) {
        return record != null && Objects.equals(record.rawget("incarnation"), body.getModData().rawget("ZAOReturnIncarnation"))
            && Objects.equals(record.rawget("token"), body.getModData().rawget("ZAOReturnToken"));
    }

    private static boolean sameGeneration(KahluaTable record, IsoZombie body) {
        Object generation = record == null ? null : record.rawget("generation");
        return generation == null || Objects.equals(generation, body.getModData().rawget(GENERATION));
    }

    public static boolean owns(IsoZombie body) {
        if (body == null || !ZAOReturnBody.hasHold(body)) return false;
        KahluaTable record = entry(marker(body, "SAOPersonId"));
        return same(record, body) && ("heldLoaded".equals(record.rawget("phase")) || "heldDormant".equals(record.rawget("phase")));
    }

    /** Resolve only an existing checkpoint; this does not infer world absence. */
    static IsoZombie resolveDetached(String id) {
        KahluaTable record = entry(id);
        if (record == null || "retired".equals(record.rawget("phase"))) return null;
        checkedRecord(record);
        // Ordinarily a native reanimated checkpoint is only an overlay on the
        // engine registry. A current write-ahead generation is stronger: if a
        // partial native save omitted that registry owner, its checked snapshot
        // reconstructs the same incarnation into the preserved registry.
        boolean nativeReanimated = Boolean.TRUE.equals(record.rawget("nativeReanimated"));
        if (nativeReanimated && !ZAOSaveGeneration.authoritative(id, record)) return null;
        IsoZombie source = null;
        try {
            source = ZAOReturnSourceSnapshot.restore(packed(record), IsoWorld.instance.currentCell);
            checkedIdentity(record, source);
            MATERIALS.put(source, packed(record));
            if (nativeReanimated)
                ZAOReturnBody.ownPreservedDecoded(source, id, (String)record.rawget("token"));
            else ZAOReturnBody.ownDecoded(source, id, (String)record.rawget("token"));
            record.rawset("phase", "heldDormant");
            return source;
        } catch (IOException | RuntimeException error) {
            if (source != null) ZAOReturnBody.detachDecoded(source);
            throw new IllegalStateException("Detached checkpoint source refused", error);
        }
    }

    private static void checkedRecord(KahluaTable record) {
        Object version = record.rawget("version");
        if ((!Double.valueOf(1).equals(version) && !Double.valueOf(2).equals(version))
                || (!"heldLoaded".equals(record.rawget("phase")) && !"heldDormant".equals(record.rawget("phase"))))
            throw new IllegalStateException("Unsupported source entry version/phase");
        if (Double.valueOf(2).equals(version)
                && (!(record.rawget("generation") instanceof String generation) || generation.isBlank()))
            throw new IllegalStateException("Missing source save generation");
        for (String key : List.of("personId", "token", "incarnation"))
            if (!(record.rawget(key) instanceof String text) || text.isBlank() || text.length() > 256)
                throw new IllegalStateException("Invalid source entry identity");
        for (String key : List.of("x", "y", "z"))
            if (!(record.rawget(key) instanceof Double number) || !Double.isFinite(number))
                throw new IllegalStateException("Invalid source entry location");
    }
    private static void checkedIdentity(KahluaTable record, IsoZombie source) {
        if (!same(record, source) || !record.rawget("personId").equals(source.getModData().rawget("SAOPersonId"))
                || (Double)record.rawget("x") != (double)source.getX()
                || (Double)record.rawget("y") != (double)source.getY()
                || (Double)record.rawget("z") != (double)source.getZ()
                || !Objects.equals(record.rawget("nativeReanimated"), source.isReanimatedPlayer()))
            throw new IllegalStateException("Source checkpoint index differs from payload");
    }

    private static void restoreNativeMaterials(KahluaTable record, IsoZombie body) {
        if (MATERIALS.containsKey(body)) return;
        if (body.isReanimatedPlayer() && !nativeRestoreActive)
            throw new IllegalStateException("Native reanimated material restore missed load boundary");
        checkedIdentity(record, body);
        try {
            String packed = packed(record);
            ZAOReturnSourceSnapshot.restoreMaterials(body, packed);
            MATERIALS.put(body, packed);
        } catch (IOException error) { throw new IllegalStateException("Native held source material restore refused", error); }
    }

    /** Runs at native registry-load exit, before outside callbacks can mutate
     * the loaded source. Later reconciliation never overwrites current items. */
    public static void restorePreservedMaterials() {
        nativeRestoreActive = true;
        try {
            for (IsoZombie body : ZAOReturnBody.loadedAndPending()) {
                if (!body.isReanimatedPlayer() || !ZAOReturnBody.hasHold(body)) continue;
                Object id = body.getModData().rawget("SAOPersonId");
                try {
                    requireHealthy(marker(body, "SAOPersonId"));
                    KahluaTable record = entry((String)id);
                    if (record != null && !"retired".equals(record.rawget("phase"))) {
                        if ((!same(record, body) || !sameGeneration(record, body))
                                && ZAOSaveGeneration.authoritative((String)id, record)) {
                            ZAOReturnBody.discardGenerationBody(body);
                            resolveDetached((String)id);
                        } else restoreNativeMaterials(record, body);
                    }
                } catch (RuntimeException error) {
                    automaticFailure(id, error);
                    try { ZAOReturnBody.guardLoadedSource(body); }
                    catch (RuntimeException guardError) { automaticFailure(id, guardError); }
                }
            }
        } finally { nativeRestoreActive = false; }
    }

    /** Capture before excluding the source from a native population owner. */
    public static void checkpoint(IsoZombie body) {
        if (!ZAOReturnBody.hasHold(body)) return;
        String id = marker(body, "SAOPersonId"), token = marker(body, "ZAOReturnToken");
        requireHealthy(id);
        if (body.getModData().rawget("ZAOReturnIncarnation") == null)
            body.getModData().rawset("ZAOReturnIncarnation", UUID.randomUUID().toString());
        String incarnation = marker(body, "ZAOReturnIncarnation");
        KahluaTable previous = entry(id);
        if (previous != null && "retired".equals(previous.rawget("phase"))) {
            if (Objects.equals(previous.rawget("incarnation"), incarnation) || Objects.equals(previous.rawget("token"), token))
                throw new IllegalStateException("Retired source cannot be recaptured");
            // A distinct native incarnation and a distinct authorized event can
            // replace the completed checkpoint for this person. Lua validates
            // that event; neither a reused handle nor the old token suffices.
            previous = null;
        } else if (previous != null && !same(previous, body)) throw new IllegalStateException("Conflicting pending source incarnation");
        try {
            if (previous != null) restoreNativeMaterials(previous, body);
            String packed = ZAOReturnSourceSnapshot.capture(body);
            if (previous != null && packed.equals(packed(previous))) return;
            ZAOReturnSourceSnapshot.preflight(packed, IsoWorld.instance.currentCell);
            if (previous == null && records().size() >= MAX_SOURCES) throw new IllegalStateException("Return source store full");
            KahluaTable next = LuaManager.platform.newTable();
            Object generation = body.getModData().rawget(GENERATION);
            next.rawset("version", generation instanceof String ? 2.0 : 1.0);
            next.rawset("personId", id); next.rawset("incarnation", incarnation);
            next.rawset("token", token); next.rawset("packed", fragments(packed));
            if (generation instanceof String) next.rawset("generation", generation);
            next.rawset("nativeReanimated", body.isReanimatedPlayer());
            next.rawset("phase", previous != null && "heldDormant".equals(previous.rawget("phase")) ? "heldDormant" : "heldLoaded");
            next.rawset("x", (double) body.getX()); next.rawset("y", (double) body.getY()); next.rawset("z", (double) body.getZ());
            entries().rawset(id, next);
            MATERIALS.put(body, packed);
        } catch (IOException error) { throw new IllegalStateException("Pending source checkpoint refused", error); }
    }

    /** Scoped replacement for native population selection, never a flag write. */
    public static boolean populationExcluded(IsoZombie body) {
        if (body.isReanimatedPlayer()) return true;
        if (!ZAOReturnBody.hasHold(body)) return false;
        if (!same(entry(marker(body, "SAOPersonId")), body))
            throw new IllegalStateException("Population exclusion lacks checkpoint ownership");
        return true;
    }

    /** Runs before native iteration; preflight itself creates then detaches a
     * temporary native body, so it must never run inside a live list iterator. */
    public static void beforePopulationSave() {
        for (IsoZombie body : ZAOReturnBody.loadedAndPending()) checkpoint(body);
    }

    /** Stamp every pending native owner before ZAOSaveGeneration snapshots it. */
    static void prepareGeneration(String generation) {
        for (KahluaTable record : records()) {
            Object phase = record.rawget("phase");
            if (!"heldLoaded".equals(phase) && !"heldDormant".equals(phase)) continue;
            String id = (String)record.rawget("personId");
            IsoZombie body = ZAOReturnBody.find(id);
            if (body == null) throw new IllegalStateException("Pending source has no generation owner: " + id);
            body.getModData().rawset(GENERATION, generation);
        }
        refreshGeneration(generation);
    }

    /** Include a resumed ordinary source in the native side of the generation. */
    static void stampGeneration(Set<String> ids, String generation) {
        for (IsoZombie body : ZAOReturnBody.loadedAndPending()) {
            Object id = body.getModData().rawget("SAOPersonId");
            if (id instanceof String personId && ids.contains(personId))
                body.getModData().rawset(GENERATION, generation);
        }
    }

    /** Recheckpoint held bodies after all generation markers are installed. */
    static void refreshGeneration(String generation) {
        beforePopulationSave();
        for (KahluaTable record : records()) {
            record.rawset("version", 2.0);
            record.rawset("generation", generation);
        }
    }

    public static void dormant(IsoZombie body) {
        if (body.isReanimatedPlayer()) return;
        KahluaTable record = entry(marker(body, "SAOPersonId"));
        if (!same(record, body)) throw new IllegalStateException("Missing source detach checkpoint");
        record.rawset("phase", "heldDormant");
    }
    public static void retired(IsoZombie body) {
        KahluaTable record = entry(marker(body, "SAOPersonId"));
        if (!same(record, body)) throw new IllegalStateException("Missing source retirement checkpoint");
        record.rawset("phase", "retired");
    }
    public static void resumed(IsoZombie body) {
        String id = marker(body, "SAOPersonId"); KahluaTable record = entry(id);
        if (record != null && !same(record, body)) throw new IllegalStateException("Conflicting resume checkpoint");
        // Cancellation returns to the pre-existing ordinary lifecycle. This
        // namespace does not claim general offscreen person preservation.
        entries().rawset(id, null);
        MATERIALS.remove(body);
    }

    /** Direct virtualization and chunk unload share the same physical receipt. */
    public static boolean virtualize(IsoZombie body) {
        if (body.isReanimatedPlayer() || !ZAOReturnBody.hasHold(body)) return false;
        checkpoint(body);
        if (!ZAOReturnBody.detachForStreaming(body)) throw new IllegalStateException("Held source streaming detach incomplete");
        return true;
    }
    public static void beforeChunkUnload(Object value) {
        if (!(value instanceof IsoChunk chunk)) return;
        IsoCell cell = IsoWorld.instance.currentCell;
        if (cell == null) return;
        for (IsoZombie body : ZAOReturnBody.loadedAndPending()) {
            if (ZAOReturnBody.hasHold(body)
                    && (int)Math.floor(body.getX() / 8f) == chunk.wx
                    && (int)Math.floor(body.getY() / 8f) == chunk.wy) {
                if (body.isReanimatedPlayer()) checkpoint(body); else virtualize(body);
            }
        }
    }

    private static List<KahluaTable> records() {
        List<KahluaTable> result = new ArrayList<>();
        var iterator = entries().iterator();
        while (iterator.advance()) {
            if (!(iterator.getKey() instanceof String id) || !(iterator.getValue() instanceof KahluaTable record)
                    || !id.equals(record.rawget("personId"))) throw new IllegalStateException("Malformed return source index");
            result.add(record);
            if (result.size() > MAX_SOURCES) throw new IllegalStateException("Return source store exceeds bound");
        }
        return result;
    }

    /** Called synchronously before native item processing, including streaming.
     * doLoadGridsquare may run before currentCell assignment during initial load;
     * this common pre-processing seam therefore owns actual reconstruction.
     */
    public static void reconcile(Object value) {
        if (reconciling || !(value instanceof IsoCell cell) || cell != IsoWorld.instance.currentCell) return;
        reconciling = true;
        try {
            var iterator = entries().iterator();
            int count = 0;
            while (iterator.advance()) {
                Object key = iterator.getKey();
                try {
                    if (++count > MAX_SOURCES) throw new IllegalStateException("Return source store exceeds bound");
                    if (!(key instanceof String index) || !(iterator.getValue() instanceof KahluaTable record)
                            || !index.equals(record.rawget("personId"))) throw new IllegalStateException("Malformed return source index");
                    requireHealthy(index);
                    Object phase = record.rawget("phase");
                    IsoZombie loaded = ZAOReturnBody.findLoaded(index);
                    if ("retired".equals(phase)) {
                        if (loaded != null && ZAOSaveGeneration.authoritative(index, record))
                            ZAOReturnBody.discardGenerationBody(loaded);
                        continue;
                    }
                    checkedRecord(record);
                    String id = (String)record.rawget("personId"), token = (String)record.rawget("token");
                    if (loaded != null) {
                        if (!same(record, loaded) || !sameGeneration(record, loaded)) {
                            if (!ZAOSaveGeneration.authoritative(id, record))
                                throw new IllegalStateException("Loaded source incarnation/generation differs");
                            ZAOReturnBody.discardGenerationBody(loaded);
                            loaded = null;
                        }
                    }
                    if (loaded != null) {
                        restoreNativeMaterials(record, loaded);
                        continue;
                    }
                    if (Boolean.TRUE.equals(record.rawget("nativeReanimated"))) {
                        if (ZAOSaveGeneration.authoritative(id, record)) resolveDetached(id);
                        continue;
                    }
                    int x = (int)Math.floor((Double)record.rawget("x")), y = (int)Math.floor((Double)record.rawget("y"));
                    int z = (int)Math.floor((Double)record.rawget("z"));
                    IsoGridSquare square = cell.getGridSquare(x, y, z);
                    if (square == null) continue; // Unloaded has a durable owner, not an absence receipt.
                    IsoZombie restored = null;
                    try {
                        restored = ZAOReturnSourceSnapshot.restore(packed(record), cell);
                        checkedIdentity(record, restored);
                        restored.setCurrent(square); restored.setMovingSquare(square);
                        if (!square.getMovingObjects().contains(restored)) square.getMovingObjects().add(restored);
                        if (!cell.getZombieList().contains(restored)) cell.getZombieList().add(restored);
                        if (!ZAOReturnBody.hold(restored, id, token)) throw new IllegalStateException("Reconstructed source did not hold");
                        entry(id).rawset("phase", "heldLoaded");
                    } catch (IOException | RuntimeException error) {
                        if (restored != null) ZAOReturnBody.detachDecoded(restored);
                        throw new IllegalStateException("Pending source reconstruction refused", error);
                    }
                } catch (RuntimeException error) { automaticFailure(key, error); }
            }
        } catch (RuntimeException error) { automaticFailure(null, error); }
        finally { reconciling = false; }
    }
}
