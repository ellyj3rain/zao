import com.zao.engine.*;
import java.lang.reflect.*;
import java.nio.ByteBuffer;
import java.util.*;
import zombie.characters.IsoZombie;
import zombie.characters.SurvivorDesc;
import zombie.inventory.InventoryItem;
import zombie.inventory.types.*;
import zombie.iso.*;
import zombie.scripting.ScriptManager;
import zombie.scripting.objects.*;
import zombie.world.*;
import se.krka.kahlua.vm.KahluaTable;

/** Native pending-source codec and completed-save/stream fixtures. No real save. */
public final class ReturnSourceProbe {
    static int id = 10000;
    static final Dictionary dictionary = new Dictionary();
    static final Map<String, Item> definitions = new HashMap<>();
    static final class Info extends ItemInfo {
        Info(Item item, short registry) {
            name = item.getName(); moduleName = "R1"; fullType = "R1." + name;
            registryId = registry; isLoaded = true; scriptItem = item; entityScript = item; modId = "fixture";
        }
    }
    static final class Dictionary extends DictionaryData {
        void put(Item item, short id) {
            Info info = new Info(item, id); itemIdToInfoMap.put(id, info); itemTypeToInfoMap.put(info.getFullType(), info);
        }
        ItemInfo remove(short id) { return itemIdToInfoMap.remove(id); }
        void restore(short id, ItemInfo info) { itemIdToInfoMap.put(id, info); }
    }
    static Field field(Class<?> owner, String name) throws Exception {
        Field field = owner.getDeclaredField(name); field.setAccessible(true); return field;
    }
    static void setupItems() throws Exception {
        field(WorldDictionary.class, "data").set(null, dictionary);
        ScriptModule module = new ScriptModule(); module.name = "R1";
        ScriptManager.instance.moduleMap.put("R1", module);
        String[] names = {"Bag", "Food", "Weapon"};
        ItemType[] types = {ItemType.CONTAINER, ItemType.FOOD, ItemType.WEAPON};
        for (int i = 0; i < names.length; i++) {
            Item item = new Item(); item.setModule(module); item.setName(names[i]); item.displayName = names[i];
            item.setItemType(types[i]); item.setRegistry_id((short)(i + 100));
            module.items.getScriptMap().put(names[i], item); dictionary.put(item, (short)(i + 100)); definitions.put(names[i], item);
        }
    }
    static InventoryItem item(String name) {
        InventoryItem item = definitions.get(name).InstanceItem(null, false); item.id = id++; return item;
    }
    static void check(boolean value, String message) { if (!value) throw new AssertionError(message); }
    static KahluaTable store() {
        return (KahluaTable) zombie.world.moddata.GlobalModData.instance.get("ZombieAwareness_State").rawget("returnSources");
    }
    static KahluaTable record(String id) { return (KahluaTable)store().rawget(id); }
    static String packed(KahluaTable record) throws Exception {
        var method = ZAOReturnSourceStore.class.getDeclaredMethod("packed", KahluaTable.class); method.setAccessible(true);
        return (String)method.invoke(null, record);
    }
    static IsoZombie body(IsoCell cell, String id, boolean fake) throws Exception {
        SurvivorDesc desc = new SurvivorDesc(); desc.getHumanVisual().setSkinTextureName("fixture");
        IsoZombie body = new IsoZombie(null, desc, 0);
        animation(body);
        body.getModData().rawset("SAOPersonId", id);
        body.setX(1); body.setY(1); body.setZ(0); body.setWasFakeDead(fake); body.setFakeDead(fake); body.setCrawlerType(7);
        var square = new IsoGridSquare(cell, null, 1, 1, 0);
        body.setCurrent(square); body.setMovingSquare(square); square.getMovingObjects().add(body);
        cell.getZombieList().add(body); cell.getObjectList().add(body);
        return body;
    }
    static void animation(IsoZombie body) throws Exception {
        var ctor = zombie.core.skinnedmodel.animation.AnimationPlayer.class.getDeclaredConstructor(); ctor.setAccessible(true);
        field(zombie.characters.IsoGameCharacter.class, "animPlayer").set(body, ctor.newInstance());
    }
    static void clearPending() throws Exception {
        ((Map<?,?>)field(ZAOReturnBody.class, "PENDING").get(null)).clear();
        ((Map<?,?>)field(ZAOReturnBody.class, "COMPLETED").get(null)).clear();
    }
    static void clearFixtureFailure(String id) throws Exception {
        // Only undo this probe's deliberate in-memory corruption. Production
        // keeps an unavailable source quarantined until a fresh world load.
        ((Map<?,?>)field(ZAOReturnSourceStore.class, "FAILURES").get(null)).remove(id);
        field(ZAOReturnSourceStore.class, "globalFailure").set(null, null);
    }
    public static final class NativeSaveBoundary extends Error { }
    public static void stopBeforeNativeSave(int count) { throw new NativeSaveBoundary(); }
    public static void stopBeforeChunkServices(zombie.MapCollisionData data, IsoChunk chunk) { throw new NativeSaveBoundary(); }
    public static void skipNativeChunk(int x, int y, boolean loaded) { }
    public static void rejectNativeZombie(float x, float y, float z, byte dir, int outfit, int state, int px, int py) {
        throw new AssertionError("held source reached native population virtualization");
    }
    static void chunkBoundaries(IsoCell cell) throws Exception {
        var instrumentation = net.bytebuddy.agent.ByteBuddyAgent.install();
        var transformer = new java.lang.instrument.ClassFileTransformer() {
            @Override public byte[] transform(Module module, ClassLoader loader, String name,
                    Class<?> redefining, java.security.ProtectionDomain domain, byte[] bytes) {
                boolean outer = name.equals("zombie/iso/IsoChunk"), population = name.equals("zombie/popman/ZombiePopulationManager");
                if (!outer && !population) return null;
                var writer = new net.bytebuddy.jar.asm.ClassWriter(0);
                new net.bytebuddy.jar.asm.ClassReader(bytes).accept(new net.bytebuddy.jar.asm.ClassVisitor(net.bytebuddy.jar.asm.Opcodes.ASM9, writer) {
                    @Override public net.bytebuddy.jar.asm.MethodVisitor visitMethod(int access, String method, String desc, String signature, String[] exceptions) {
                        var delegate = super.visitMethod(access, method, desc, signature, exceptions);
                        if (!(outer && method.equals("removeFromWorld")) && !(population && method.equals("removeChunkFromWorld"))) return delegate;
                        return new net.bytebuddy.jar.asm.MethodVisitor(net.bytebuddy.jar.asm.Opcodes.ASM9, delegate) {
                            @Override public void visitMethodInsn(int opcode, String owner, String call, String descriptor, boolean itf) {
                                if (outer && owner.equals("zombie/MapCollisionData") && call.equals("removeChunkFromWorld"))
                                    super.visitMethodInsn(net.bytebuddy.jar.asm.Opcodes.INVOKESTATIC, "ReturnSourceProbe", "stopBeforeChunkServices", "(Lzombie/MapCollisionData;Lzombie/iso/IsoChunk;)V", false);
                                else if (population && owner.equals(name) && call.equals("n_loadChunk"))
                                    super.visitMethodInsn(opcode, "ReturnSourceProbe", "skipNativeChunk", descriptor, false);
                                else if (population && owner.equals(name) && call.equals("n_addZombie"))
                                    super.visitMethodInsn(opcode, "ReturnSourceProbe", "rejectNativeZombie", descriptor, false);
                                else super.visitMethodInsn(opcode, owner, call, descriptor, itf);
                            }
                        };
                    }
                }, 0); return writer.toByteArray();
            }
        };
        instrumentation.addTransformer(transformer, true);
        instrumentation.retransformClasses(IsoChunk.class, zombie.popman.ZombiePopulationManager.class);
        try {
            for (boolean outer : new boolean[]{true, false}) {
                String id = "chunk-source-" + outer;
                IsoZombie source = body(cell, id, true);
                source.setX(17); source.setY(9); source.removeFromSquare();
                IsoChunk chunk = new IsoChunk(cell); chunk.wx = 2; chunk.wy = 1; chunk.loaded = true;
                var square = new IsoGridSquare(cell, null, 17, 9, 0); chunk.setSquare(1, 1, 0, square);
                source.setCurrent(square); source.setMovingSquare(square); square.getMovingObjects().add(source);
                check(ZAOReturnBody.hold(source, id, "chunk-token"), "chunk source did not hold");
                if (outer) {
                    boolean stopped = false;
                    try { chunk.removeFromWorld(); } catch (NativeSaveBoundary expected) { stopped = true; }
                    check(stopped, "outer chunk service boundary missing");
                } else zombie.popman.ZombiePopulationManager.instance.removeChunkFromWorld(chunk);
                check("heldDormant".equals(record(id).rawget("phase")) && !square.getMovingObjects().contains(source)
                        && !cell.getZombieList().contains(source), "chunk unload did not detach exact held owner");
                clearPending();
                IsoZombie detached = ZAOReturnBody.find(id);
                check(ZAOReturnBody.isDormantSource(detached), "chunk checkpoint did not supply dormant owner");
                check(ZAOReturnBody.remove(detached, id, "chunk-token"), "chunk checkpoint retirement failed");
            }
        } finally {
            instrumentation.removeTransformer(transformer);
            instrumentation.retransformClasses(IsoChunk.class, zombie.popman.ZombiePopulationManager.class);
        }
    }
    static void selectors(IsoZombie held, IsoZombie unheld) throws Exception {
        var manager = zombie.popman.ZombiePopulationManager.instance;
        Class<?> type = manager.getClass();
        var queue = (Queue<?>)field(type, "pendingSaveCells").get(null); queue.clear();
        manager.requestSaveCell(0, 0);
        Object pending = queue.poll();
        var selected = (List<?>)field(pending.getClass(), "aliveZombies").get(pending);
        check(selected.size() == 1, "cell-save selector included held source or lost ordinary source");
        // Execute the actual full-save selector, stopping at its first JNI
        // boundary. No native population store or save file is touched.
        var instrumentation = net.bytebuddy.agent.ByteBuddyAgent.install();
        var transformer = new java.lang.instrument.ClassFileTransformer() {
            @Override public byte[] transform(Module module, ClassLoader loader, String name,
                    Class<?> redefining, java.security.ProtectionDomain domain, byte[] bytes) {
                if (!name.equals("zombie/popman/ZombiePopulationManager")) return null;
                var writer = new net.bytebuddy.jar.asm.ClassWriter(0);
                new net.bytebuddy.jar.asm.ClassReader(bytes).accept(new net.bytebuddy.jar.asm.ClassVisitor(net.bytebuddy.jar.asm.Opcodes.ASM9, writer) {
                    @Override public net.bytebuddy.jar.asm.MethodVisitor visitMethod(int access, String method, String desc, String signature, String[] exceptions) {
                        var delegate = super.visitMethod(access, method, desc, signature, exceptions);
                        if (!method.equals("beginSaveRealZombies") || !desc.equals("()V")) return delegate;
                        return new net.bytebuddy.jar.asm.MethodVisitor(net.bytebuddy.jar.asm.Opcodes.ASM9, delegate) {
                            @Override public void visitMethodInsn(int opcode, String owner, String call, String descriptor, boolean itf) {
                                if (owner.equals(name) && call.equals("n_beginSaveRealZombies") && descriptor.equals("(I)V"))
                                    super.visitMethodInsn(opcode, "ReturnSourceProbe", "stopBeforeNativeSave", descriptor, false);
                                else super.visitMethodInsn(opcode, owner, call, descriptor, itf);
                            }
                        };
                    }
                }, 0);
                return writer.toByteArray();
            }
        };
        instrumentation.addTransformer(transformer, true); instrumentation.retransformClasses(type);
        try {
            boolean stopped = false;
            try { manager.beginSaveRealZombies(); } catch (NativeSaveBoundary expected) { stopped = true; }
            check(stopped, "native save boundary was not intercepted");
            var save = (List<?>)field(type, "saveRealZombieHack").get(manager);
            check(save.size() == 1 && save.contains(unheld) && !save.contains(held), "full-save selector included held source or lost ordinary source");
            save.clear();
        } finally { instrumentation.removeTransformer(transformer); instrumentation.retransformClasses(type); }
    }
    @SuppressWarnings("unchecked")
    static void preservedSources(IsoCell cell) throws Exception {
        var manager = zombie.ReanimatedPlayers.instance;
        var preserved = (List<IsoZombie>)field(zombie.ReanimatedPlayers.class, "zombies").get(manager);
        var load = zombie.ReanimatedPlayers.class.getDeclaredMethod("loadReanimatedPlayers", ByteBuffer.class); load.setAccessible(true);
        for (boolean alreadyHeld : new boolean[]{true, false}) {
            String id = "native-preserved-" + alreadyHeld, token = "preserved-token";
            IsoZombie source = body(cell, id, false); source.setReanimatedPlayer(true); source.setX(50); source.setY(50);
            InventoryItem cargo = item("Weapon"); source.getInventory().getItems().add(cargo); cargo.setContainer(source.getInventory());
            source.setPrimaryHandItem(cargo);
            if (alreadyHeld) check(ZAOReturnBody.hold(source, id, token), "preserved source pre-save hold failed");
            ByteBuffer bytes = ByteBuffer.allocate(2 * 1024 * 1024); bytes.putInt(249); bytes.putInt(1); source.save(bytes); bytes.flip();
            source.removeFromSquare(); cell.getZombieList().remove(source); cell.getObjectList().remove(source); cell.getAddList().remove(source);
            clearPending();
            load.invoke(manager, bytes);
            IsoZombie loaded = preserved.get(preserved.size() - 1);
            check(loaded != source && loaded.isReanimatedPlayer() && loaded.getCurrentSquare() == null
                    && !cell.getZombieList().contains(loaded) && !cell.getObjectList().contains(loaded), "native preserved loader fixture failed");
            InventoryItem nativeCargo = loaded.getInventory().getItems().stream().filter(item -> item.id == cargo.id).findFirst().orElseThrow();
            nativeCargo.setCondition(4); // A later outside edit must not be overwritten during lookup.
            check(ZAOReturnBody.find(id) == loaded, "native preserved source lookup missing");
            check(nativeCargo == loaded.getInventory().getItems().stream().filter(item -> item.id == cargo.id).findFirst().orElseThrow()
                    && nativeCargo.getCondition() == 4, "later native material edit overwritten");
            if (!alreadyHeld) check(loaded.getModData().rawget("ZAOReturnToken") == null && !ZAOReturnBody.isDormantSource(loaded),
                    "unheld native source adopted during read-only lookup");
            check(ZAOReturnBody.hold(loaded, id, token) && ZAOReturnBody.isDormantSource(loaded), "native preserved ownership did not hold offscreen");
            check(loaded.getInventory().getItems().stream().anyMatch(item -> item.id == cargo.id), "preserved current cargo lost");
            if (alreadyHeld) check(loaded.getPrimaryHandItem() != null && loaded.getPrimaryHandItem().id == cargo.id,
                    "held reanimated equipment overlay lost");
            else check(loaded.getPrimaryHandItem() == null, "unheld historical equipment invented");
            check(!ZAOReturnBody.resume(loaded, id, token) && preserved.contains(loaded), "unloaded native source resumed or lost ownership");
            // Cancellation refusal and another complete native serialization
            // still leave exactly the same authoritative kind of owner.
            ByteBuffer again = ByteBuffer.allocate(2 * 1024 * 1024); again.putInt(249); again.putInt(1); loaded.save(again); again.flip();
            preserved.remove(loaded); clearPending(); load.invoke(manager, again);
            IsoZombie reloaded = ZAOReturnBody.find(id);
            check(reloaded != null && reloaded != loaded && ZAOReturnBody.isDormantSource(reloaded), "preserved cancellation reload lost ownership");
            ByteBuffer duplicate = again.duplicate(); duplicate.rewind(); load.invoke(manager, duplicate);
            IsoZombie extra = preserved.get(preserved.size() - 1);
            boolean duplicateRefused = false;
            try { ZAOReturnBody.find(id); } catch (IllegalStateException expected) { duplicateRefused = true; }
            check(duplicateRefused, "duplicate preserved identity accepted"); preserved.remove(extra); clearFixtureFailure(id);
            check(!ZAOReturnBody.remove(reloaded, id, "wrong-token") && preserved.contains(reloaded), "wrong preserved token retired source");
            check(ZAOReturnBody.remove(reloaded, id, token), "preserved offscreen source removal failed");
            check(!preserved.contains(reloaded) && ZAOReturnBody.find(id) == null, "preserved terminal source remained owned");
            check(ZAOReturnBody.remove(reloaded, id, token), "preserved repeated removal failed");
        }
        System.out.println("PASS native preserved reanimated lookup, authorized hold, cancellation reload and offscreen retirement");
    }
    static void codecAndStreaming(IsoCell cell) throws Exception {
        for (boolean fake : new boolean[]{false, true}) {
            String id = fake ? "checkpoint-fake" : "checkpoint-ordinary";
            IsoZombie source = body(cell, id, fake);
            source.getModData().rawset("fixtureLargeData", "v".repeat(28000));
            InventoryContainer bag = (InventoryContainer)item("Bag"); Food food = (Food)item("Food");
            bag.getInventory().getItems().add(food); food.setContainer(bag.getInventory()); food.setHungChange(-.31f);
            food.getModData().rawset("fixtureProvenance", "nested-current-state");
            source.setPrimaryHandItem(bag); source.setSecondaryHandItem(bag);
            InventoryItem weapon = item("Weapon"); weapon.setCondition(7);
            source.getInventory().getItems().add(weapon); weapon.setContainer(source.getInventory());
            source.getHumanVisual().setSkinTextureName("preserved-skin");
            check(ZAOReturnBody.hold(source, id, "checkpoint-token"), "ordinary checkpoint hold failed");
            String packed = packed(record(id));
            check(packed.length() > 32767, "large source fixture did not exercise native string bound");
            check(ZAOReturnSourceSnapshot.validate(packed), "checkpoint structural validation failed");
            IsoZombie decoded = ZAOReturnSourceSnapshot.restore(packed, cell);
            check(!decoded.isReanimatedPlayer() && decoded.wasFakeDead() == fake && decoded.isFakeDead() == fake,
                    "source native form changed");
            check(decoded.getCrawlerType() == 7, "fake-dead restore changed crawler type");
            check(decoded.getPrimaryHandItem() == decoded.getSecondaryHandItem()
                    && decoded.getPrimaryHandItem().id == bag.id
                    && !decoded.getInventory().getItems().contains(decoded.getPrimaryHandItem()), "detached equipment ownership changed");
            check(decoded.getInventory().getItems().size() == 1 && decoded.getInventory().getItems().get(0).getCondition() == 7,
                    "ordinary inventory native state changed");
            Food restoredFood = (Food)((InventoryContainer)decoded.getPrimaryHandItem()).getInventory().getItems().get(0);
            check(restoredFood.getHungChange() == -.31f && !cell.getProcessItems().contains(restoredFood), "source nested state/processing changed");
            check("preserved-skin".equals(field(zombie.core.skinnedmodel.visual.HumanVisual.class, "skinTextureName").get(decoded.getHumanVisual())), "source visual changed");
            ItemInfo missing = dictionary.remove((short)101);
            boolean refused = false;
            try { ZAOReturnSourceSnapshot.restore(packed, cell); } catch (Exception expected) { refused = true; }
            finally { dictionary.restore((short)101, missing); }
            check(refused, "missing nested item accepted");
            byte[] damaged = Base64.getDecoder().decode(packed); damaged[12] ^= 1;
            check(!ZAOReturnSourceSnapshot.validate(Base64.getEncoder().encodeToString(damaged)), "corrupt checkpoint accepted");
            // Exact Kahlua table serialization used by GlobalModData, in memory.
            ByteBuffer tableBytes = ByteBuffer.allocate(8 * 1024 * 1024); store().save(tableBytes); tableBytes.flip();
            KahluaTable restoredStore = zombie.Lua.LuaManager.platform.newTable();
            try { restoredStore.load(tableBytes, 249); }
            catch (Throwable error) { throw new AssertionError("source checkpoint table serialization corrupted", error); }
            check(tableBytes.remaining() == 0, "source checkpoint table serialization corrupted");
            check(packed.equals(packed((KahluaTable)restoredStore.rawget(id))), "source checkpoint table serialization corrupted");
            Object incarnation = record(id).rawget("incarnation");
            record(id).rawset("incarnation", "different-body-incarnation");
            boolean identityRefused = false;
            try { ZAOReturnBody.find(id); } catch (IllegalStateException expected) { identityRefused = true; }
            finally { record(id).rawset("incarnation", incarnation); clearFixtureFailure(id); }
            check(identityRefused, "checkpoint incarnation mismatch accepted");
            check(ZAOReturnSourceStore.populationExcluded(source), "ordinary held source enters native population");
            IsoZombie unheld = body(cell, id + "-unheld", false);
            check(!ZAOReturnSourceStore.populationExcluded(unheld), "ordinary unheld lifecycle changed");
            selectors(source, unheld);
            cell.getZombieList().remove(unheld); cell.getObjectList().remove(unheld); unheld.removeFromSquare();
            // The actual transformed native entry must skip n_addZombie entirely.
            zombie.popman.ZombiePopulationManager.instance.virtualizeZombie(source);
            check("heldDormant".equals(record(id).rawget("phase")), "native virtualization lost source checkpoint");
            check(!cell.getZombieList().contains(source) && !cell.getObjectList().contains(source), "streamed source still physically loaded");
            clearPending();
            zombie.world.moddata.GlobalModData.instance.get("ZombieAwareness_State").rawset("returnSources", restoredStore);
            check(cell.getGridSquare(1, 1, 0) == null, "fixture source square unexpectedly loaded");
            var square = new IsoGridSquare(cell, null, 1, 1, 0);
            IsoChunk chunk = new IsoChunk(cell); chunk.wx = 0; chunk.wy = 0; chunk.loaded = true;
            chunk.setSquare(1, 1, 0, square);
            var map = cell.chunkMap[0];
            field(IsoChunkMap.class, "xMinTiles").setInt(map, 0);
            field(IsoChunkMap.class, "yMinTiles").setInt(map, 0);
            int chunkX = -map.getWorldXMinTiles() / 8, chunkY = -map.getWorldYMinTiles() / 8;
            int offset = IsoChunkMap.chunkGridWidth * chunkY + chunkX;
            ((IsoChunk[])field(IsoChunkMap.class, "chunksSwapA").get(map))[offset] = chunk;
            ((IsoChunk[])field(IsoChunkMap.class, "chunksSwapB").get(map))[offset] = chunk;
            check(cell.getGridSquare(1, 1, 0) == square, "fixture loaded-square cache missing");
            var drain = IsoCell.class.getDeclaredMethod("ProcessRemoveItems", java.util.Iterator.class); drain.setAccessible(true);
            drain.invoke(cell, new Object[]{null});
            IsoZombie rebound = ZAOReturnBody.find(id);
            check(rebound != null && rebound != source && rebound.getPrimaryHandItem().id == bag.id,
                    "completed-save source reconstruction failed");
            check(rebound.wasFakeDead() == fake && !rebound.isReanimatedPlayer(), "reloaded source promoted native form");
            float seen = rebound.timeSinceSeenFlesh; rebound.preupdate(); rebound.update(); rebound.postupdate();
            check(rebound.timeSinceSeenFlesh == seen, "reconstructed source advanced");
            drain.invoke(cell, new Object[]{null});
            check(ZAOReturnBody.find(id) == rebound, "stream reconciliation duplicated source");
            animation(rebound);
            check(ZAOReturnBody.remove(rebound, id, "checkpoint-token"), "reconstructed ordinary terminal removal failed");
            clearPending(); drain.invoke(cell, new Object[]{null});
            check(ZAOReturnBody.find(id) == null && "retired".equals(record(id).rawget("phase")), "retired source reconstructed");
            chunk.setSquare(1, 1, 0, null);
        }
        IsoZombie dormant = body(cell, "dormant-destination", true);
        InventoryItem carried = item("Weapon"); dormant.setPrimaryHandItem(carried);
        check(ZAOReturnBody.hold(dormant, "dormant-destination", "dormant-token"), "dormant source initial hold failed");
        zombie.popman.ZombiePopulationManager.instance.virtualizeZombie(dormant); clearPending();
        IsoZombie detached = ZAOReturnBody.find("dormant-destination");
        check(detached != null && detached != dormant && ZAOReturnBody.isDormantSource(detached)
                && detached.getCurrentSquare() == null && !cell.getZombieList().contains(detached)
                && !cell.getObjectList().contains(detached) && detached.getPrimaryHandItem().id == carried.id,
                "checkpoint-backed dormant source did not resolve unpublished");
        check(!ZAOReturnBody.isDormantSource(dormant), "missing square claimed dormant authority");
        check(!ZAOReturnBody.resume(detached, "dormant-destination", "dormant-token"), "unloaded detached source resumed native AI");
        check(ZAOReturnBody.hold(detached, "dormant-destination", "dormant-token"), "detached source rehold failed");
        check(ZAOReturnBody.remove(detached, "dormant-destination", "dormant-token"), "checkpoint-backed dormant retirement failed");
        clearPending();
        check(ZAOReturnBody.find("dormant-destination") == null, "dormant retirement tombstone lost");
        chunkBoundaries(cell);
        preservedSources(cell);
        mixedFailures(cell);
        System.out.println("PASS native ordinary/fake-dead source checkpoint and completed-save streaming");
    }

    @SuppressWarnings("unchecked")
    static void mixedFailures(IsoCell cell) throws Exception {
        var preserved = (List<IsoZombie>)field(zombie.ReanimatedPlayers.class, "zombies").get(zombie.ReanimatedPlayers.instance);
        var load = zombie.ReanimatedPlayers.class.getDeclaredMethod("loadReanimatedPlayers", ByteBuffer.class); load.setAccessible(true);
        String badId = "mixed-missing-item", goodId = "mixed-good", flagsId = "mixed-bad-flags";
        IsoZombie bad = body(cell, badId, false), good = body(cell, goodId, false);
        bad.setReanimatedPlayer(true); good.setReanimatedPlayer(true);
        bad.setPrimaryHandItem(item("Food")); good.setPrimaryHandItem(item("Weapon"));
        int goodHand = good.getPrimaryHandItem().id;
        check(ZAOReturnBody.hold(bad, badId, "mixed-token") && ZAOReturnBody.hold(good, goodId, "mixed-token"), "mixed source hold failed");
        String originalBad = packed(record(badId));
        ByteBuffer bytes = ByteBuffer.allocate(4 * 1024 * 1024); bytes.putInt(249); bytes.putInt(2);
        bad.save(bytes); good.save(bytes); bytes.flip();
        for (IsoZombie source : List.of(bad, good)) {
            source.removeFromSquare(); cell.getZombieList().remove(source); cell.getObjectList().remove(source); cell.getAddList().remove(source);
        }
        clearPending();
        ItemInfo missing = dictionary.remove((short)101);
        try { load.invoke(zombie.ReanimatedPlayers.instance, bytes); }
        catch (InvocationTargetException error) { throw new AssertionError("bad checkpoint escaped native registry callback", error); }
        finally { dictionary.restore((short)101, missing); }
        IsoZombie failed = preserved.stream().filter(b -> badId.equals(b.getModData().rawget("SAOPersonId"))).findFirst().orElseThrow();
        IsoZombie valid;
        try { valid = ZAOReturnBody.find(goodId); }
        catch (RuntimeException error) { throw new AssertionError("bad checkpoint prevented other native overlay", error); }
        check(valid != null && valid.getPrimaryHandItem() != null && valid.getPrimaryHandItem().id == goodHand,
                "bad checkpoint prevented other native overlay");
        boolean refused = false;
        try { ZAOReturnBody.find(badId); } catch (IllegalStateException expected) { refused = true; }
        check(refused && ZAOReturnBody.hasHold(failed) && originalBad.equals(packed(record(badId))), "failed checkpoint identity remained accessible");
        // A valid held body, a failed overlay owner, an invalid indexed record,
        // and a separate hold-reconstruction failure share one native drain.
        cell.getZombieList().add(failed); cell.getZombieList().add(valid);
        IsoZombie badFlags = body(cell, flagsId, false);
        check(ZAOReturnBody.hold(badFlags, flagsId, "flags-token"), "flags fixture hold failed");
        badFlags.getModData().rawset("ZAOReturnFlags", "invalid");
        Food failedFood = (Food)item("Food"), validFood = (Food)item("Food"), flagsFood = (Food)item("Food"), normal = (Food)item("Food");
        IsoZombie[] owners = {failed, valid, badFlags}; Food[] foods = {failedFood, validFood, flagsFood};
        for (int i = 0; i < owners.length; i++) {
            owners[i].getInventory().getItems().add(foods[i]); foods[i].setContainer(owners[i].getInventory()); cell.addToProcessItems(foods[i]);
        }
        cell.addToProcessItems(normal); store().rawset("mixed-malformed", "invalid-record");
        var drain = IsoCell.class.getDeclaredMethod("ProcessRemoveItems", java.util.Iterator.class); drain.setAccessible(true);
        try { drain.invoke(cell, new Object[]{null}); }
        catch (InvocationTargetException error) { throw new AssertionError("bad source escaped native item callback", error); }
        for (Food food : foods) check(!cell.getProcessItems().contains(food), "failed held cargo still processes");
        try { check(cell.getProcessItems().contains(normal) && ZAOReturnBody.find(goodId) == valid, "bad checkpoint blocked unrelated native processing"); }
        catch (RuntimeException error) { throw new AssertionError("bad checkpoint blocked unrelated native processing", error); }
        var process = IsoCell.class.getDeclaredMethod("ProcessItems", java.util.Iterator.class); process.setAccessible(true);
        process.invoke(cell, new Object[]{null});
        check(cell.getProcessItemsRemove().contains(normal), "unrelated native item update did not run");
        refused = false;
        try { ZAOReturnBody.find(flagsId); } catch (IllegalStateException expected) { refused = true; }
        check(refused, "failed hold reconstruction remained accessible");
        refused = false;
        try { ZAOReturnBody.resume(failed, badId, "mixed-token"); } catch (IllegalStateException expected) { refused = true; }
        check(refused && preserved.contains(failed), "failed native overlay source resumed");
        check(originalBad.equals(packed(record(badId))), "failed source checkpoint was overwritten");
        System.out.println("PASS mixed native source failures isolated; failed owners held and refused, valid owners and unrelated items continue");
    }
}
