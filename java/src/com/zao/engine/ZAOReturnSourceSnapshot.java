package com.zao.engine;

import java.io.*;
import java.nio.*;
import java.security.MessageDigest;
import java.util.*;
import zombie.characters.IsoZombie;
import zombie.inventory.InventoryItem;
import zombie.inventory.ItemContainer;
import zombie.inventory.types.InventoryContainer;
import zombie.iso.IsoCell;
import zombie.iso.IsoObject;
import zombie.iso.IsoWorld;
import zombie.scripting.objects.ItemBodyLocation;
import zombie.scripting.objects.ResourceLocation;

/** Native pending-source checkpoint, world 249. No living physiology or AI policy.
 * Native zombie bytes retain the engine's own fields; the checked material overlay
 * also retains actual equipment which is not in the root inventory. Decode never
 * publishes an object or registers its items for processing.
 */
public final class ZAOReturnSourceSnapshot {
    private static final int MAGIC = 0x5a525331, VERSION = 249;
    private static final int MAX = 16 * 1024 * 1024, SECTION = 8 * 1024 * 1024;
    private static final int ITEMS = 10000, SLOTS = 1024;
    private record Fact(int id, Integer parent, String type, String modData) { }
    private record Slot(String name, int id) { }
    private record Manifest(List<Integer> roots, Map<Integer, Fact> facts,
            Integer primary, Integer secondary, List<Slot> worn, List<Slot> attached) { }
    private record Data(String person, String incarnation, String token, float x, float y, float z,
            boolean reanimated, boolean fake, boolean wasFake, boolean forceFake, boolean usingWorn, int crawlerType,
            byte[][] sections, Manifest manifest) { }
    @FunctionalInterface private interface Writer { void write(ByteBuffer b) throws IOException; }
    private ZAOReturnSourceSnapshot() { }

    public static String capture(IsoZombie source) throws IOException {
        if (source == null || IsoWorld.getWorldVersion() != VERSION)
            throw new IOException("Unsupported pending source checkpoint");
        ItemContainer view = view(source);
        Manifest manifest = manifest(source, view);
        byte[][] sections = {
            nativeBytes(b -> source.save(b, false)),
            nativeBytes(b -> view.save(b)),
            nativeBytes(b -> source.getHumanVisual().save(b)),
            nativeBytes(b -> source.getItemVisuals().save(b)),
        };
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        try (DataOutputStream out = new DataOutputStream(bytes)) {
            out.writeInt(MAGIC); out.writeInt(VERSION);
            out.writeUTF(marker(source, "SAOPersonId"));
            out.writeUTF(marker(source, "ZAOReturnIncarnation"));
            out.writeUTF(marker(source, "ZAOReturnToken"));
            out.writeFloat(source.getX()); out.writeFloat(source.getY()); out.writeFloat(source.getZ());
            out.writeBoolean(source.isReanimatedPlayer());
            out.writeBoolean(source.isFakeDead()); out.writeBoolean(source.wasFakeDead());
            out.writeBoolean(source.isForceFakeDead()); out.writeBoolean(source.isUsingWornItems());
            out.writeInt(source.getCrawlerType());
            for (byte[] section : sections) { out.writeInt(section.length); out.write(section); }
            writeManifest(out, manifest);
            out.flush();
            if (bytes.size() + 32 > MAX) throw new IOException("Source checkpoint exceeds size bound");
            out.write(hash(bytes.toByteArray()));
        }
        String packed = Base64.getEncoder().encodeToString(bytes.toByteArray());
        parse(packed);
        return packed;
    }

    public static boolean validate(String packed) {
        try { parse(packed); return true; } catch (IOException | RuntimeException error) { return false; }
    }

    /** A failed restore always removes the unpublished native object's owners. */
    public static IsoZombie restore(String packed, IsoCell cell) throws IOException {
        Data data = parse(packed);
        IsoZombie body = null;
        try {
            ByteBuffer b = ByteBuffer.wrap(data.sections[0]);
            IsoObject object = IsoObject.factoryFromFileInput(cell, b);
            if (!(object instanceof IsoZombie)) throw new IOException("Source factory is not a zombie");
            body = (IsoZombie) object;
            body.load(b, VERSION, false); consumed(b);
            // Native load registers the body and resets idle state. The global
            // native token guards cover it until the caller imposes its hold.
            ZAOReturnBody.detachDecoded(body);
            body.setReanimatedPlayer(data.reanimated); // Restore the captured native form exactly.
            restoreMaterials(body, data);
            return body;
        } catch (IOException | RuntimeException error) {
            if (body != null) ZAOReturnBody.detachDecoded(body);
            throw error;
        }
    }

    /** Overlay only a verified existing native owner, without replacing it. */
    public static void restoreMaterials(IsoZombie body, String packed) throws IOException {
        restoreMaterials(body, parse(packed));
    }

    private static void restoreMaterials(IsoZombie body, Data data) throws IOException {
            if (!data.person.equals(marker(body, "SAOPersonId"))
                    || !data.incarnation.equals(marker(body, "ZAOReturnIncarnation"))
                    || !data.token.equals(marker(body, "ZAOReturnToken")) || body.isReanimatedPlayer() != data.reanimated)
                throw new IOException("Native source identity changed");
            ItemContainer inventory = new ItemContainer();
            ByteBuffer b = ByteBuffer.wrap(data.sections[1]);
            var loaded = inventory.load(b, VERSION); consumed(b);
            if (loaded == null || loaded.contains(null)) throw new IOException("Native source dropped an item");
            Map<Integer, InventoryItem> items = new LinkedHashMap<>();
            facts(inventory, items);
            // InventoryItem.load writes customName into ModData even when the
            // source table did not contain it. Restore the original native
            // table explicitly before comparing the material representation.
            for (var entry : items.entrySet()) {
                Fact expected = data.manifest.facts.get(entry.getKey());
                if (expected == null) throw new IOException("Unexpected source item");
                ByteBuffer table = ByteBuffer.wrap(Base64.getDecoder().decode(expected.modData));
                entry.getValue().getModData().wipe(); entry.getValue().getModData().load(table, VERSION); consumed(table);
            }
            Map<Integer, Fact> facts = facts(inventory, new LinkedHashMap<>());
            if (!facts.equals(data.manifest.facts)) throw new IOException("Source material identity/type/parent differs");
            ZAOReturnBody.stopSourceItems(body);
            body.setPrimaryHandItem(null); body.setSecondaryHandItem(null);
            body.clearWornItems(); body.clearAttachedItems(); body.setInventory(inventory);
            // Restore original root membership, not merely the union view.
            Set<Integer> roots = new HashSet<>(data.manifest.roots);
            inventory.getItems().removeIf(item -> {
                if (roots.contains(item.id)) return false;
                item.setContainer(null); return true;
            });
            for (Slot slot : data.manifest.worn) {
                ItemBodyLocation location = ItemBodyLocation.get(ResourceLocation.of(slot.name));
                if (location == null || body.getWornItems().getBodyLocationGroup().getLocation(location) == null)
                    throw new IOException("Source worn location unavailable");
                body.getWornItems().setItem(location, items.get(slot.id));
            }
            for (Slot slot : data.manifest.attached) {
                if (body.getAttachedItems().getGroup().getLocation(slot.name) == null)
                    throw new IOException("Source attached location unavailable");
                body.getAttachedItems().setItem(slot.name, items.get(slot.id));
            }
            body.setPrimaryHandItem(items.get(data.manifest.primary));
            body.setSecondaryHandItem(items.get(data.manifest.secondary));
            body.setFakeDead(data.fake); body.setWasFakeDead(data.wasFake); body.setForceFakeDead(data.forceFake);
            // setFakeDead(true) randomly changes crawler type in the engine.
            body.setCrawlerType(data.crawlerType);
            if (body.isUsingWornItems() != data.usingWorn) throw new IOException("Source visual ownership changed");
            b = ByteBuffer.wrap(data.sections[2]); body.getHumanVisual().load(b, VERSION); consumed(b);
            b = ByteBuffer.wrap(data.sections[3]); var visuals = body.getItemVisuals(); visuals.clear(); visuals.load(b, VERSION); consumed(b);
            body.setX(data.x); body.setY(data.y); body.setZ(data.z);
            if (!data.manifest.equals(manifest(body, view(body)))) throw new IOException("Source equipment/root restoration differs");
            IsoZombie decoded = body;
            byte[] roundtrip = nativeBytes(buffer -> view(decoded).save(buffer));
            if (!Arrays.equals(data.sections[1], roundtrip))
                throw new IOException("Source native material roundtrip differs at " + Arrays.mismatch(data.sections[1], roundtrip));
    }

    public static void preflight(String packed, IsoCell cell) throws IOException {
        IsoZombie decoded = restore(packed, cell);
        ZAOReturnBody.detachDecoded(decoded);
    }

    private static String marker(IsoZombie body, String key) throws IOException {
        Object value = body.getModData().rawget(key);
        if (!(value instanceof String text) || text.isBlank() || text.length() > 256)
            throw new IOException("Missing source marker " + key);
        return text;
    }
    private static ItemContainer view(IsoZombie body) throws IOException {
        ItemContainer view = new ItemContainer(); view.getItems().addAll(body.getInventory().getItems());
        List<InventoryItem> equipment = new ArrayList<>();
        equipment.add(body.getPrimaryHandItem()); equipment.add(body.getSecondaryHandItem());
        for (int i = 0; i < body.getWornItems().size(); i++) equipment.add(body.getWornItems().get(i).getItem());
        for (int i = 0; i < body.getAttachedItems().size(); i++) equipment.add(body.getAttachedItems().get(i).getItem());
        for (InventoryItem item : equipment) {
            if (item == null) continue;
            Map<Integer, InventoryItem> items = new LinkedHashMap<>(); facts(view, items);
            if (items.get(item.id) == item) continue;
            if (items.containsKey(item.id) || (item.getContainer() != null && item.getContainer() != body.getInventory()))
                throw new IOException("Conflicting source equipment ownership");
            view.getItems().add(item);
        }
        return view;
    }
    private static Manifest manifest(IsoZombie body, ItemContainer view) throws IOException {
        Map<Integer, InventoryItem> items = new LinkedHashMap<>();
        Map<Integer, Fact> facts = facts(view, items);
        List<Integer> roots = new ArrayList<>();
        for (InventoryItem item : body.getInventory().getItems()) roots.add(item.id);
        List<Slot> worn = new ArrayList<>(), attached = new ArrayList<>();
        for (int i = 0; i < body.getWornItems().size(); i++) {
            var entry = body.getWornItems().get(i); worn.add(new Slot(entry.getLocation().toString(), entry.getItem().id));
        }
        for (int i = 0; i < body.getAttachedItems().size(); i++) {
            var entry = body.getAttachedItems().get(i); attached.add(new Slot(entry.getLocation(), entry.getItem().id));
        }
        worn.sort(Comparator.comparing(Slot::name)); attached.sort(Comparator.comparing(Slot::name));
        return new Manifest(roots, facts, id(body.getPrimaryHandItem()), id(body.getSecondaryHandItem()), worn, attached);
    }
    private static Integer id(InventoryItem item) { return item == null ? null : item.id; }
    private static Map<Integer, Fact> facts(ItemContainer container, Map<Integer, InventoryItem> items) throws IOException {
        Map<Integer, Fact> result = new LinkedHashMap<>(); collect(container, null, 0, items, result); return result;
    }
    private static void collect(ItemContainer container, Integer parent, int depth,
            Map<Integer, InventoryItem> items, Map<Integer, Fact> result) throws IOException {
        if (container == null || depth > 64) throw new IOException("Source container depth invalid");
        for (InventoryItem item : container.getItems()) {
            if (item == null || items.size() >= ITEMS || items.put(item.id, item) != null)
                throw new IOException("Duplicate/cyclic/excess source item");
            result.put(item.id, new Fact(item.id, parent, item.getFullType(),
                    Base64.getEncoder().encodeToString(nativeBytes(b -> item.getModData().save(b)))));
            if (item instanceof InventoryContainer bag) collect(bag.getInventory(), item.id, depth + 1, items, result);
        }
    }
    private static void writeManifest(DataOutputStream out, Manifest m) throws IOException {
        out.writeInt(m.roots.size()); for (int id : m.roots) out.writeInt(id);
        out.writeInt(m.facts.size());
        for (Fact fact : m.facts.values()) {
            out.writeInt(fact.id); reference(out, fact.parent); out.writeUTF(fact.type);
            byte[] table = Base64.getDecoder().decode(fact.modData); out.writeInt(table.length); out.write(table);
        }
        reference(out, m.primary); reference(out, m.secondary);
        for (List<Slot> slots : List.of(m.worn, m.attached)) {
            if (slots.size() > SLOTS) throw new IOException("Excess source slots");
            out.writeInt(slots.size()); for (Slot slot : slots) { out.writeUTF(slot.name); out.writeInt(slot.id); }
        }
    }
    private static Manifest readManifest(DataInputStream in) throws IOException {
        List<Integer> roots = new ArrayList<>();
        for (int count = count(in.readInt(), ITEMS); count > 0; count--) roots.add(in.readInt());
        Map<Integer, Fact> facts = new LinkedHashMap<>();
        for (int count = count(in.readInt(), ITEMS); count > 0; count--) {
            int id = in.readInt(); Integer parent = reference(in); String type = in.readUTF();
            int length = count(in.readInt(), SECTION);
            if (length > in.available()) throw new IOException("Truncated source item table");
            Fact fact = new Fact(id, parent, type, Base64.getEncoder().encodeToString(in.readNBytes(length)));
            if (facts.put(id, fact) != null || fact.type.isBlank()) throw new IOException("Invalid source manifest");
        }
        if (new HashSet<>(roots).size() != roots.size()) throw new IOException("Duplicate source roots");
        for (int id : roots) if (!facts.containsKey(id) || facts.get(id).parent != null) throw new IOException("Invalid root reference");
        for (Fact fact : facts.values()) {
            Set<Integer> seen = new HashSet<>(); Integer parent = fact.parent;
            while (parent != null) {
                if (!facts.containsKey(parent) || parent == fact.id || !seen.add(parent) || seen.size() > 64)
                    throw new IOException("Invalid source parent chain");
                parent = facts.get(parent).parent;
            }
        }
        Integer primary = reference(in), secondary = reference(in);
        if ((primary != null && !facts.containsKey(primary)) || (secondary != null && !facts.containsKey(secondary)))
            throw new IOException("Invalid hand reference");
        List<Slot> worn = slots(in, facts), attached = slots(in, facts);
        return new Manifest(roots, facts, primary, secondary, worn, attached);
    }
    private static List<Slot> slots(DataInputStream in, Map<Integer, Fact> facts) throws IOException {
        List<Slot> result = new ArrayList<>(); Set<String> names = new HashSet<>();
        for (int count = count(in.readInt(), SLOTS); count > 0; count--) {
            String name = in.readUTF(); int id = in.readInt();
            if (name.isBlank() || !names.add(name) || !facts.containsKey(id)) throw new IOException("Invalid source slot");
            result.add(new Slot(name, id));
        }
        return result;
    }
    private static void reference(DataOutputStream out, Integer id) throws IOException {
        out.writeBoolean(id != null); if (id != null) out.writeInt(id);
    }
    private static Integer reference(DataInputStream in) throws IOException {
        int present = in.readUnsignedByte(); if (present > 1) throw new IOException("Invalid optional reference");
        return present == 0 ? null : in.readInt();
    }
    private static Data parse(String packed) throws IOException {
        if (packed == null || packed.length() > 4L * ((MAX + 2) / 3)) throw new IOException("Source encoding exceeds bound");
        byte[] bytes;
        try { bytes = Base64.getDecoder().decode(packed); } catch (IllegalArgumentException error) { throw new IOException("Invalid source encoding", error); }
        if (bytes.length < 64 || bytes.length > MAX) throw new IOException("Invalid source length");
        int end = bytes.length - 32;
        if (!MessageDigest.isEqual(hash(Arrays.copyOf(bytes, end)), Arrays.copyOfRange(bytes, end, bytes.length)))
            throw new IOException("Source checksum mismatch");
        try (DataInputStream in = new DataInputStream(new ByteArrayInputStream(bytes, 0, end))) {
            if (in.readInt() != MAGIC || in.readInt() != VERSION || IsoWorld.getWorldVersion() != VERSION)
                throw new IOException("Unsupported source version");
            String person = in.readUTF(), incarnation = in.readUTF(), token = in.readUTF();
            for (String value : List.of(person, incarnation, token))
                if (value.isBlank() || value.length() > 256) throw new IOException("Invalid source identity");
            float x = in.readFloat(), y = in.readFloat(), z = in.readFloat();
            if (!Float.isFinite(x) || !Float.isFinite(y) || !Float.isFinite(z)) throw new IOException("Invalid source location");
            boolean reanimated = bool(in), fake = bool(in), wasFake = bool(in), forceFake = bool(in), usingWorn = bool(in);
            int crawlerType = in.readInt();
            byte[][] sections = new byte[4][];
            for (int i = 0; i < sections.length; i++) {
                int length = count(in.readInt(), SECTION);
                if (length > in.available()) throw new IOException("Truncated source section");
                sections[i] = in.readNBytes(length);
            }
            Manifest m = readManifest(in); if (in.available() != 0) throw new IOException("Trailing source bytes");
            return new Data(person, incarnation, token, x, y, z, reanimated, fake, wasFake, forceFake, usingWorn, crawlerType, sections, m);
        }
    }
    private static boolean bool(DataInputStream in) throws IOException {
        int value = in.readUnsignedByte(); if (value > 1) throw new IOException("Invalid source flag"); return value == 1;
    }
    private static int count(int count, int max) throws IOException {
        if (count < 0 || count > max) throw new IOException("Invalid source count/length"); return count;
    }
    private static byte[] nativeBytes(Writer writer) throws IOException {
        for (int size = 16384; size <= SECTION; size *= 2) {
            ByteBuffer b = ByteBuffer.allocate(size);
            try { writer.write(b); return Arrays.copyOf(b.array(), b.position()); }
            catch (BufferOverflowException overflow) { if (size == SECTION) throw new IOException("Native source section exceeds bound", overflow); }
        }
        throw new IOException("Native source section exceeds bound");
    }
    private static byte[] hash(byte[] bytes) {
        try { return MessageDigest.getInstance("SHA-256").digest(bytes); }
        catch (java.security.NoSuchAlgorithmException error) { throw new IllegalStateException(error); }
    }
    private static void consumed(ByteBuffer buffer) throws IOException {
        if (buffer.hasRemaining()) throw new IOException("Native source section not fully consumed");
    }
}
