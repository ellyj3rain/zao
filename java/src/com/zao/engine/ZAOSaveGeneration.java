package com.zao.engine;

import java.io.*;
import java.nio.ByteBuffer;
import java.nio.BufferOverflowException;
import java.nio.channels.FileChannel;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.*;
import se.krka.kahlua.vm.KahluaTable;
import se.krka.kahlua.vm.KahluaTableIterator;
import zombie.Lua.LuaManager;
import zombie.ZomboidFileSystem;
import zombie.network.GameClient;
import zombie.world.moddata.GlobalModData;

/**
 * Write-ahead generation for the one transaction which spans SAO GlobalModData
 * and the engine's ordinary/reanimated zombie files. The journal contains only
 * identities which have entered the Afflicted-return protocol. It is written
 * atomically before IsoCell starts any native save and replayed before
 * OnInitGlobalModData exposes the loaded tables to Lua.
 */
public final class ZAOSaveGeneration {
    private static final int MAGIC = 0x5a534731; // ZSG1
    private static final int VERSION = 1;
    private static final int WORLD_VERSION = 249;
    private static final int MAX_IDENTITIES = 65_536;
    private static final int MAX_PAYLOAD = 256 * 1024 * 1024;
    private static final int HEADER_SIZE = Integer.BYTES * 3 + Long.BYTES + 32;
    private static final String FILE = "zao_return_generation.bin";
    private static final String SAO_STORE = "SurvivorAwareness_Records";
    private static final String ZAO_STORE = "ZombieAwareness_State";
    private static final String MARKER = "returnSaveGeneration";

    private record Journal(long generation, KahluaTable root) { }
    private record Desired(boolean present, String phase, String token,
            String incarnation, String generation) { }

    private static final Map<String, Desired> DESIRED = new LinkedHashMap<>();

    private ZAOSaveGeneration() { }

    /** Runs at IsoCell.save entry, after OnSave and before any native surface. */
    public static synchronized void prepare() {
        if (GameClient.client) return;
        try {
            Path path = journalPath();
            long prior = Math.max(Math.max(marker(store(SAO_STORE)), marker(store(ZAO_STORE))),
                headerGeneration(path));
            if (prior == Long.MAX_VALUE) throw new IOException("Return generation exhausted");
            long generation = prior + 1;
            String text = Long.toString(generation);

            // Stamp and recapture held sources before the journal takes table
            // references. A later native writer therefore sees this generation
            // on any body it retains.
            ZAOReturnSourceStore.prepareGeneration(text);
            KahluaTable sao = store(SAO_STORE), zao = store(ZAO_STORE);
            sao.rawset(MARKER, text); zao.rawset(MARKER, text);

            KahluaTable root = snapshot(generation, sao, zao);
            ZAOReturnSourceStore.stampGeneration(ids(root), text);
            // Held bodies were already recaptured by prepareGeneration. This
            // second stamp only marks a resumed, source-absent native body.
            write(path, generation, root);
            installDesired(new Journal(generation, root));
        } catch (IOException | RuntimeException error) {
            throw new IllegalStateException("Return save generation preparation failed", error);
        }
    }

    /** Runs at GlobalModData.load exit, before OnInitGlobalModData. */
    public static synchronized void recover() {
        if (GameClient.client) {
            DESIRED.clear(); return;
        }
        Path path = journalPath();
        if (!Files.isRegularFile(path)) {
            DESIRED.clear();
            long sao = marker(store(SAO_STORE)), zao = marker(store(ZAO_STORE));
            if (sao != 0 || zao != 0)
                throw new IllegalStateException("Return save generation journal is missing");
            return;
        }
        try {
            Journal journal = read(path);
            long saoGeneration = marker(store(SAO_STORE));
            long zaoGeneration = marker(store(ZAO_STORE));
            long newestLoaded = Math.max(saoGeneration, zaoGeneration);
            if (newestLoaded > journal.generation)
                throw new IOException("Return journal predates loaded GlobalModData");
            // The journal is authoritative when the native/global write was
            // interrupted. Reapplying an equal completed generation is
            // idempotent and also validates its per-identity slices.
            apply(journal);
            installDesired(journal);
        } catch (IOException | RuntimeException error) {
            DESIRED.clear();
            throw new IllegalStateException("Return save generation recovery failed", error);
        }
    }

    static synchronized boolean authoritative(String id, KahluaTable record) {
        Desired desired = DESIRED.get(id);
        if (desired == null || !desired.present || record == null) return false;
        return Objects.equals(desired.phase, record.rawget("phase"))
            && Objects.equals(desired.token, record.rawget("token"))
            && Objects.equals(desired.incarnation, record.rawget("incarnation"))
            && Objects.equals(desired.generation, record.rawget("generation"));
    }

    static synchronized boolean desiresNoSource(String id) {
        Desired desired = DESIRED.get(id);
        return desired != null && !desired.present;
    }

    static synchronized String desiredGeneration(String id) {
        Desired desired = DESIRED.get(id);
        return desired == null ? null : desired.generation;
    }

    private static KahluaTable snapshot(long generation, KahluaTable sao, KahluaTable zao)
            throws IOException {
        KahluaTable root = table();
        root.rawset("version", (double)VERSION);
        root.rawset("generation", Long.toString(generation));
        KahluaTable ids = table(), records = table(), people = table();
        KahluaTable recovery = table(), sources = table();
        root.rawset("ids", ids); root.rawset("records", records);
        root.rawset("people", people); root.rawset("recovery", recovery);
        root.rawset("sources", sources);

        KahluaTable recordStore = optionalTable(sao.rawget("records"), "SAO records");
        KahluaTable sourceStore = optionalTable(zao.rawget("returnSources"), "ZAO return sources");
        if (recordStore != null) {
            KahluaTableIterator iterator = recordStore.iterator();
            while (iterator.advance()) {
                if (!(iterator.getKey() instanceof String id)
                        || !(iterator.getValue() instanceof KahluaTable record)) continue;
                if (Boolean.TRUE.equals(record.rawget("returnSaveTouched"))
                        || Boolean.TRUE.equals(record.rawget("afflictedReturn"))
                        || record.rawget("returnTransition") instanceof KahluaTable) addId(ids, id);
            }
        }
        if (sourceStore != null) {
            KahluaTableIterator iterator = sourceStore.iterator();
            while (iterator.advance()) {
                if (!(iterator.getKey() instanceof String id)
                        || !(iterator.getValue() instanceof KahluaTable record)
                        || !id.equals(record.rawget("personId")))
                    throw new IOException("Malformed return source journal input");
                addId(ids, id);
            }
        }
        if (ids.size() > MAX_IDENTITIES) throw new IOException("Return journal identity bound exceeded");

        KahluaTable zaoPeople = optionalTable(zao.rawget("people"), "ZAO people");
        KahluaTable zaoRecovery = optionalTable(zao.rawget("recovery"), "ZAO recovery");
        KahluaTableIterator iterator = ids.iterator();
        while (iterator.advance()) {
            String id = (String)iterator.getKey();
            records.rawset(id, value(recordStore, id));
            people.rawset(id, value(zaoPeople, id));
            recovery.rawset(id, value(zaoRecovery, id));
            sources.rawset(id, value(sourceStore, id));
        }
        validate(new Journal(generation, root));
        return root;
    }

    private static Set<String> ids(KahluaTable root) throws IOException {
        KahluaTable table = requiredTable(root.rawget("ids"), "journal ids");
        Set<String> result = new LinkedHashSet<>();
        KahluaTableIterator iterator = table.iterator();
        while (iterator.advance()) {
            if (!(iterator.getKey() instanceof String id) || !Boolean.TRUE.equals(iterator.getValue()))
                throw new IOException("Invalid return journal identity");
            result.add(id);
        }
        return result;
    }

    private static void addId(KahluaTable ids, String id) throws IOException {
        if (id.isBlank() || id.length() > 256) throw new IOException("Invalid return journal identity");
        if (ids.rawget(id) == null && ids.size() >= MAX_IDENTITIES)
            throw new IOException("Return journal identity bound exceeded");
        ids.rawset(id, Boolean.TRUE);
    }

    private static Object value(KahluaTable source, String id) {
        Object value = source == null ? null : source.rawget(id);
        return value == null ? Boolean.FALSE : value;
    }

    private static void apply(Journal journal) throws IOException {
        validate(journal);
        KahluaTable root = journal.root;
        KahluaTable sao = store(SAO_STORE), zao = store(ZAO_STORE);
        KahluaTable records = child(sao, "records");
        KahluaTable people = child(zao, "people");
        KahluaTable recovery = child(zao, "recovery");
        KahluaTable sources = child(zao, "returnSources");
        KahluaTable savedRecords = requiredTable(root.rawget("records"), "journal records");
        KahluaTable savedPeople = requiredTable(root.rawget("people"), "journal people");
        KahluaTable savedRecovery = requiredTable(root.rawget("recovery"), "journal recovery");
        KahluaTable savedSources = requiredTable(root.rawget("sources"), "journal sources");
        for (String id : ids(root)) {
            replace(records, id, savedRecords.rawget(id));
            replace(people, id, savedPeople.rawget(id));
            replace(recovery, id, savedRecovery.rawget(id));
            replace(sources, id, savedSources.rawget(id));
        }
        String generation = Long.toString(journal.generation);
        sao.rawset(MARKER, generation); zao.rawset(MARKER, generation);
    }

    private static void replace(KahluaTable target, String id, Object value) throws IOException {
        if (Boolean.FALSE.equals(value)) target.rawset(id, null);
        else if (value instanceof KahluaTable) target.rawset(id, value);
        else throw new IOException("Invalid return journal slice");
    }

    private static void installDesired(Journal journal) throws IOException {
        validate(journal);
        DESIRED.clear();
        KahluaTable sources = requiredTable(journal.root.rawget("sources"), "journal sources");
        for (String id : ids(journal.root)) {
            Object value = sources.rawget(id);
            if (Boolean.FALSE.equals(value)) {
                DESIRED.put(id, new Desired(false, null, null, null,
                    Long.toString(journal.generation)));
            } else {
                KahluaTable record = requiredTable(value, "journal source");
                DESIRED.put(id, new Desired(true, string(record, "phase"),
                    string(record, "token"), string(record, "incarnation"),
                    string(record, "generation")));
            }
        }
    }

    private static void validate(Journal journal) throws IOException {
        KahluaTable root = journal.root;
        if (!Double.valueOf(VERSION).equals(root.rawget("version"))
                || !Long.toString(journal.generation).equals(root.rawget("generation")))
            throw new IOException("Unsupported return journal version/generation");
        Set<String> ids = ids(root);
        if (ids.size() > MAX_IDENTITIES) throw new IOException("Return journal identity bound exceeded");
        for (String key : List.of("records", "people", "recovery", "sources")) {
            KahluaTable slice = requiredTable(root.rawget(key), "journal " + key);
            KahluaTableIterator iterator = slice.iterator();
            while (iterator.advance()) {
                if (!(iterator.getKey() instanceof String id) || !ids.contains(id)
                        || (!(iterator.getValue() instanceof KahluaTable)
                            && !Boolean.FALSE.equals(iterator.getValue())))
                    throw new IOException("Invalid return journal " + key + " slice");
            }
            for (String id : ids) if (slice.rawget(id) == null)
                throw new IOException("Incomplete return journal " + key + " slice");
        }
        KahluaTable records = requiredTable(root.rawget("records"), "journal records");
        KahluaTable sources = requiredTable(root.rawget("sources"), "journal sources");
        for (String id : ids) {
            Object record = records.rawget(id);
            if (record instanceof KahluaTable table && !id.equals(table.rawget("id")))
                throw new IOException("Journal person identity differs");
            Object source = sources.rawget(id);
            if (source instanceof KahluaTable table) {
                if (!id.equals(table.rawget("personId"))
                        || !Long.toString(journal.generation).equals(table.rawget("generation")))
                    throw new IOException("Journal source identity/generation differs");
                for (String key : List.of("phase", "token", "incarnation")) string(table, key);
            }
        }
    }

    private static void write(Path path, long generation, KahluaTable root) throws IOException {
        byte[] payload = encode(root);
        byte[] hash = sha256(payload);
        ByteArrayOutputStream bytes = new ByteArrayOutputStream(payload.length + 96);
        try (DataOutputStream out = new DataOutputStream(bytes)) {
            out.writeInt(MAGIC); out.writeInt(VERSION); out.writeLong(generation);
            out.writeInt(payload.length); out.write(hash); out.write(payload);
        }
        Files.createDirectories(path.getParent());
        Path temporary = path.resolveSibling(path.getFileName() + ".tmp-" + UUID.randomUUID());
        try {
            Files.write(temporary, bytes.toByteArray(), StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE);
            try (FileChannel channel = FileChannel.open(temporary, StandardOpenOption.WRITE)) { channel.force(true); }
            Files.move(temporary, path, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
        } finally { Files.deleteIfExists(temporary); }
    }

    private static Journal read(Path path) throws IOException {
        long fileSize = Files.size(path);
        if (fileSize < HEADER_SIZE + 1L || fileSize > HEADER_SIZE + (long)MAX_PAYLOAD)
            throw new IOException("Invalid return journal file size");
        byte[] bytes = Files.readAllBytes(path);
        try (DataInputStream in = new DataInputStream(new ByteArrayInputStream(bytes))) {
            if (in.readInt() != MAGIC || in.readInt() != VERSION)
                throw new IOException("Unsupported return journal header");
            long generation = in.readLong();
            if (generation <= 0) throw new IOException("Invalid return journal generation");
            int length = in.readInt();
            if (length < 1 || length > MAX_PAYLOAD || length > in.available() - 32)
                throw new IOException("Invalid return journal payload length");
            byte[] expected = in.readNBytes(32), payload = in.readNBytes(length);
            if (in.available() != 0 || !MessageDigest.isEqual(expected, sha256(payload)))
                throw new IOException("Return journal checksum/trailing bytes differ");
            KahluaTable root = table();
            ByteBuffer payloadIn = ByteBuffer.wrap(payload);
            root.load(payloadIn, WORLD_VERSION);
            if (payloadIn.hasRemaining()) throw new IOException("Trailing return journal table bytes");
            Journal journal = new Journal(generation, root); validate(journal); return journal;
        }
    }

    private static long headerGeneration(Path path) throws IOException {
        if (!Files.isRegularFile(path)) return 0;
        try (DataInputStream in = new DataInputStream(Files.newInputStream(path))) {
            if (in.readInt() != MAGIC || in.readInt() != VERSION)
                throw new IOException("Unsupported return journal header");
            long generation = in.readLong();
            if (generation <= 0) throw new IOException("Invalid return journal generation");
            return generation;
        }
    }

    private static byte[] encode(KahluaTable table) throws IOException {
        for (int size = 1024 * 1024; size <= MAX_PAYLOAD; size *= 2) {
            ByteBuffer buffer = ByteBuffer.allocate(size);
            try {
                table.save(buffer);
                return Arrays.copyOf(buffer.array(), buffer.position());
            } catch (BufferOverflowException overflow) {
                if (size == MAX_PAYLOAD) throw new IOException("Return journal payload exceeds bound", overflow);
            }
        }
        throw new IOException("Return journal payload exceeds bound");
    }

    private static byte[] sha256(byte[] value) {
        try { return MessageDigest.getInstance("SHA-256").digest(value); }
        catch (java.security.NoSuchAlgorithmException error) { throw new IllegalStateException(error); }
    }

    private static Path journalPath() {
        String override = System.getProperty("zao.returnGenerationDirectory");
        if (override != null && !override.isBlank()) return Path.of(override).resolve(FILE);
        return ZomboidFileSystem.instance.getFileInCurrentSave(FILE).toPath();
    }

    private static KahluaTable store(String name) {
        return GlobalModData.instance.getOrCreate(name);
    }

    private static KahluaTable child(KahluaTable parent, String key) throws IOException {
        Object value = parent.rawget(key);
        if (value == null) { KahluaTable table = table(); parent.rawset(key, table); return table; }
        return requiredTable(value, key);
    }

    private static KahluaTable table() {
        if (LuaManager.platform == null) throw new IllegalStateException("Lua table platform unavailable");
        return LuaManager.platform.newTable();
    }

    private static KahluaTable requiredTable(Object value, String name) throws IOException {
        if (!(value instanceof KahluaTable table)) throw new IOException("Invalid " + name);
        return table;
    }

    private static KahluaTable optionalTable(Object value, String name) throws IOException {
        if (value == null) return null;
        return requiredTable(value, name);
    }

    private static String string(KahluaTable table, String key) throws IOException {
        Object value = table.rawget(key);
        if (!(value instanceof String text) || text.isBlank() || text.length() > 256)
            throw new IOException("Invalid return journal " + key);
        return text;
    }

    private static long marker(KahluaTable store) {
        Object value = store.rawget(MARKER);
        if (value == null) return 0;
        if (!(value instanceof String text)) throw new IllegalStateException("Invalid return save generation marker");
        try {
            long parsed = Long.parseLong(text);
            if (parsed <= 0) throw new NumberFormatException();
            return parsed;
        } catch (NumberFormatException error) {
            throw new IllegalStateException("Invalid return save generation marker", error);
        }
    }
}
