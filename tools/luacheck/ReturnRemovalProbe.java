import com.zao.engine.ZAOReturnBody;
import com.zao.engine.ZAOReturnWeave;
import java.lang.reflect.Field;
import java.util.List;
import zombie.MovingObjectUpdateScheduler;
import zombie.MovingObjectUpdateSchedulerUpdateBucket;
import zombie.ReanimatedPlayers;
import zombie.VirtualZombieManager;
import zombie.characters.IsoZombie;
import zombie.characters.SurvivorDesc;
import zombie.inventory.types.Food;
import zombie.inventory.types.InventoryContainer;
import zombie.iso.IsoCell;

/** Actual engine objects and native cleanup; no chunks, game, or saves. */
public final class ReturnRemovalProbe {
    private static IsoCell cell;
    private static void check(boolean value, String reason) {
        if (!value) throw new AssertionError(reason);
    }
    private static Field field(Class<?> owner, String name) throws Exception {
        Field result = owner.getDeclaredField(name); result.setAccessible(true); return result;
    }
    @SuppressWarnings("unchecked")
    private static List<IsoZombie> retained(boolean reanimated) throws Exception {
        return (List<IsoZombie>) (reanimated
            ? field(ReanimatedPlayers.class, "zombies").get(ReanimatedPlayers.instance)
            : field(VirtualZombieManager.class, "reusedThisFrame").get(VirtualZombieManager.instance));
    }
    private static IsoZombie body(String id, boolean reanimated) throws Exception {
        SurvivorDesc desc = new SurvivorDesc();
        desc.getHumanVisual().setSkinTextureName("fixture");
        IsoZombie body = new IsoZombie(null, desc, 0);
        // Native cleanup expects an animation player even without a rendered
        // model. Construct the real empty player; no cleanup method is mocked.
        var ctor = zombie.core.skinnedmodel.animation.AnimationPlayer.class.getDeclaredConstructor();
        ctor.setAccessible(true);
        field(zombie.characters.IsoGameCharacter.class, "animPlayer").set(body, ctor.newInstance());
        body.getModData().rawset("SAOPersonId", id);
        body.setReanimatedPlayer(reanimated);
        body.setUseless(false); body.ghost = false;
        body.setInvulnerable(false); body.setCollidable(true); body.setShootable(true);
        var square = new zombie.iso.IsoGridSquare(cell, null, 1, 1, 0);
        body.setCurrent(square); body.setMovingSquare(square);
        if (!square.getMovingObjects().contains(body)) square.getMovingObjects().add(body);
        cell.getZombieList().add(body); cell.getObjectList().add(body);
        return body;
    }
    private static void drain() {
        cell.getObjectList().removeAll(cell.getRemoveList()); cell.getRemoveList().clear();
        cell.getProcessItems().removeAll(cell.getProcessItemsRemove()); cell.getProcessItemsRemove().clear();
    }
    private static MovingObjectUpdateSchedulerUpdateBucket schedulerBucket() throws Exception {
        return ((MovingObjectUpdateSchedulerUpdateBucket[]) field(MovingObjectUpdateScheduler.class,
            "simulationLevels").get(MovingObjectUpdateScheduler.instance))[0];
    }
    private static java.lang.ref.WeakReference<IsoZombie> detachedFailure() throws Exception {
        IsoZombie body = body("gc-pending", false);
        check(ZAOReturnBody.hold(body, "gc-pending", "gc-token"), "GC source hold failed");
        Field imposter = field(IsoZombie.class, "imposter");
        Object original = imposter.get(body); imposter.set(body, null);
        check(!ZAOReturnBody.remove(body, "gc-pending", "gc-token"), "GC source failure not injected");
        imposter.set(body, original);
        body.removeFromSquare(); // Every native loaded owner is now gone.
        return new java.lang.ref.WeakReference<>(body);
    }
    @SuppressWarnings("unchecked")
    private static java.lang.ref.WeakReference<IsoZombie> isolatedPendingOwner() throws Exception {
        // Isolate ownership from unrelated native constructor registries. This
        // one GC-only object is uninitialized; all removal/save/update fixtures
        // above and below use real constructors and native methods unchanged.
        Field unsafeField = sun.misc.Unsafe.class.getDeclaredField("theUnsafe"); unsafeField.setAccessible(true);
        var unsafe = (sun.misc.Unsafe) unsafeField.get(null);
        IsoZombie body = (IsoZombie) unsafe.allocateInstance(IsoZombie.class);
        body.getModData().rawset("SAOPersonId", "isolated-pending");
        var type = Class.forName("com.zao.engine.ZAOReturnBody$Pending");
        var ctor = type.getDeclaredConstructor(IsoZombie.class, String.class, String.class); ctor.setAccessible(true);
        ((java.util.Map<Object, Object>) field(ZAOReturnBody.class, "PENDING").get(null))
                .put(body, ctor.newInstance(body, "isolated-pending", "isolated-token"));
        return new java.lang.ref.WeakReference<>(body);
    }
    private static void savedFailure() throws Exception {
        IsoZombie source = body("saved-pending", true);
        check(ZAOReturnBody.hold(source, "saved-pending", "saved-token"), "save source hold failed");
        Field imposter = field(IsoZombie.class, "imposter");
        Object original = imposter.get(source); imposter.set(source, null);
        check(!ZAOReturnBody.remove(source, "saved-pending", "saved-token"), "save source failure not injected");
        check(!retained(true).contains(source), "partial removal retained body for reuse/reinsertion");
        imposter.set(source, original);
        check(cell.getZombieList().contains(source), "failed reanimated source has no native save owner");
        java.nio.ByteBuffer bytes = java.nio.ByteBuffer.allocate(2 * 1024 * 1024);
        bytes.putInt(249); bytes.putInt(1); source.save(bytes); bytes.flip();
        // Save includes factory identity bytes, exactly as reanimated.bin does.
        source.removeFromSquare(); cell.getZombieList().remove(source);
        ((java.util.Map<?, ?>) field(ZAOReturnBody.class, "PENDING").get(null)).clear();
        var load = ReanimatedPlayers.class.getDeclaredMethod("loadReanimatedPlayers", java.nio.ByteBuffer.class);
        load.setAccessible(true); load.invoke(ReanimatedPlayers.instance, bytes);
        IsoZombie loaded = retained(true).get(retained(true).size() - 1);
        retained(true).remove(loaded); cell.getZombieList().add(loaded); // Simulate native loaded-list insertion.
        check("saved-token".equals(loaded.getModData().rawget("ZAOReturnToken")), "native load lost held token");
        check(loaded.getCurrentState() == zombie.ai.states.ZombieIdleState.instance(), "fixture did not exercise native idle reset");
        // These would execute native timers/actions without the installed hooks.
        float seen = loaded.timeSinceSeenFlesh;
        try { loaded.preupdate(); loaded.update(); loaded.postupdate(); }
        catch (Throwable error) { throw new AssertionError("loaded held source advanced before reconstruction", error); }
        check(loaded.timeSinceSeenFlesh == seen, "loaded held source advanced before reconstruction");
        Food pendingFood = (Food)ReturnSourceProbe.item("Food");
        loaded.getInventory().getItems().add(pendingFood); pendingFood.setContainer(loaded.getInventory());
        cell.addToProcessItems(pendingFood);
        // Reflectively enter the exact private native queue drain; advice must
        // reconstruct loaded holds before this drain and before ProcessItems.
        var drain = IsoCell.class.getDeclaredMethod("ProcessRemoveItems", java.util.Iterator.class);
        drain.setAccessible(true); drain.invoke(cell, new Object[]{null});
        check(!cell.getProcessItems().contains(pendingFood), "loaded held cargo not paused before processing");
        check(ZAOReturnBody.find("saved-pending") == loaded, "native-loaded pending source not rebound");
        var ctor = zombie.core.skinnedmodel.animation.AnimationPlayer.class.getDeclaredConstructor(); ctor.setAccessible(true);
        field(zombie.characters.IsoGameCharacter.class, "animPlayer").set(loaded, ctor.newInstance());
        check(ZAOReturnBody.remove(loaded, "saved-pending", "saved-token"), "native-loaded source removal failed");
    }
    private static void removal(boolean reanimated) throws Exception {
        String id = reanimated ? "returned-reanimated" : "returned-ordinary";
        String token = "transaction-" + id;
        IsoZombie body = body(id, reanimated);
        check(ZAOReturnBody.find(id) == body, "loaded body lookup failed");
        var bucket = schedulerBucket(); bucket.add(body);
        check(ZAOReturnBody.hold(body, id, token), "empty source did not hold");
        check(!cell.getObjectList().contains(body) && !bucket.getBucket(0).contains(body),
              "held source still scheduled");
        body.getStateMachine().update();
        MovingObjectUpdateScheduler.instance.startFrame();
        check(!bucket.getBucket(0).contains(body), "next frame rescheduled held source");
        check(ZAOReturnBody.find(id) == body, "held body lost identity");
        // Real native remove has already enqueued reuse/preservation when the
        // missing graphics fixture throws at imposter.destroy().
        Field imposter = field(IsoZombie.class, "imposter");
        Object original = imposter.get(body); imposter.set(body, null);
        check(!ZAOReturnBody.remove(body, id, token), "partial native removal acknowledged");
        check(!retained(reanimated).contains(body), "partial removal retained body for reuse/reinsertion");
        check(!ZAOReturnBody.resume(body, id, token), "partly removed source resumed");
        imposter.set(body, original);
        check(ZAOReturnBody.remove(body, id, token), "native removal retry failed");
        check(!retained(reanimated).contains(body), "terminal removal retained body for reuse/reinsertion");
        check(!cell.getZombieList().contains(body) && !cell.getObjectList().contains(body),
              "terminal body still loaded");
        check(ZAOReturnBody.remove(body, id, token), "repeated acknowledged removal failed");
        body.getModData().rawset("SAOPersonId", "a-different-person");
        cell.getZombieList().add(body); cell.getObjectList().add(body);
        check(!ZAOReturnBody.remove(body, id, token), "stale body identity accepted");
        check(cell.getZombieList().contains(body), "stale reference removed new person");
        cell.getZombieList().remove(body); cell.getObjectList().remove(body);
    }
    public static void main(String[] args) throws Exception {
        zombie.core.random.RandStandard.INSTANCE.init();
        zombie.ZomboidFileSystem.instance.init();
        zombie.SoundManager.instance = new zombie.DummySoundManager();
        zombie.Lua.LuaManager.platform = new se.krka.kahlua.j2se.J2SEPlatform();
        zombie.Lua.LuaManager.env = zombie.Lua.LuaManager.platform.newTable();
        zombie.Lua.LuaEventManager.register(zombie.Lua.LuaManager.platform, zombie.Lua.LuaManager.env);
        SurvivorDesc.HairCommonColors.add(new zombie.core.ImmutableColor(.2f, .3f, .4f));
        zombie.characters.SurvivorFactory.addFemaleForename("Fixture");
        zombie.characters.SurvivorFactory.addMaleForename("Fixture");
        zombie.characters.SurvivorFactory.addSurname("Person");
        zombie.core.skinnedmodel.population.HairStyles.instance = new zombie.core.skinnedmodel.population.HairStyles();
        zombie.core.skinnedmodel.population.BeardStyles.instance = new zombie.core.skinnedmodel.population.BeardStyles();
        cell = new IsoCell(1, 1);
        zombie.iso.WorldReuserThread.instance.stop();
        cell.setSafeToAdd(true);
        ReturnSourceProbe.setupItems();
        for (String name : new String[]{"zombie.characters.IsoZombie", "zombie.iso.IsoCell",
                "zombie.popman.ZombiePopulationManager", "zombie.iso.IsoChunk",
                "zombie.ReanimatedPlayers", "zombie.world.moddata.GlobalModData"}) {
            byte[] original;
            try (var stream = ClassLoader.getSystemResourceAsStream(name.replace('.', '/') + ".class")) {
                original = stream.readAllBytes();
            }
            byte[] changed = ZAOReturnWeave.weave(name, original);
            check(!java.util.Arrays.equals(original, changed), "offline native weave made no change");
            check(ZAOReturnWeave.inspect(name, changed) == (name.endsWith("IsoZombie") ? 7
                    : name.endsWith("IsoCell") ? 1032 : name.endsWith("IsoChunk") ? 128
                    : name.endsWith("ReanimatedPlayers") ? 512
                    : name.endsWith("GlobalModData") ? 2048 : 368), "offline native weave site mask");
            System.out.println("OFFLINE " + name + " mask=" + ZAOReturnWeave.inspect(name, changed)
                    + " sha256=" + java.util.HexFormat.of().formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(changed)));
        }
        ZAOReturnWeave.install();
        check(ZAOReturnBody.isAvailable(), "live fixture native guards unavailable");
        savedFailure();
        IsoZombie source = body("resume", false);
        check(ZAOReturnBody.isSupportedSource(source), "ordinary source capability remained restricted");
        InventoryContainer bag = (InventoryContainer)ReturnSourceProbe.item("Bag");
        Food food = (Food)ReturnSourceProbe.item("Food");
        bag.getInventory().getItems().add(food); food.setContainer(bag.getInventory());
        source.setPrimaryHandItem(bag); // Equipment outside root inventory.
        source.getCharacterActions().add(new zombie.characters.CharacterTimedActions.BaseAction(source));
        check(!ZAOReturnBody.hold(source, "resume", "first"), "active timed action accepted");
        check(source.getModData().rawget("ZAOReturnToken") == null, "busy refusal changed hold identity");
        source.getCharacterActions().clear();
        cell.addToProcessItems(food);
        check(!ZAOReturnBody.hold(source, "resume", "first"), "processing item acknowledged before drain");
        check(cell.getProcessItemsRemove().contains(food), "nested detached equipment was not paused");
        drain();
        check(ZAOReturnBody.hold(source, "resume", "first"), "drained source did not hold");
        check(!ZAOReturnBody.hold(source, "resume", "wrong-token"), "wrong hold token accepted");
        check(!ZAOReturnBody.remove(source, "resume", "wrong-token"), "wrong removal token accepted");
        check(ZAOReturnBody.resume(source, "resume", "first"), "pre-removal resume failed");
        check(!source.isUseless() && !source.ghost && source.isCollidable() && source.isShootable()
              && !source.isInvulnerable(), "resume failed to restore native flags");
        check(cell.getObjectList().contains(source) && cell.getProcessItems().contains(food),
              "resume failed to restore processing");
        cell.setSafeToAdd(false);
        check(!ZAOReturnBody.hold(source, "resume", "deferred"), "deferred object removal acknowledged early");
        drain();
        check(ZAOReturnBody.hold(source, "resume", "deferred"), "deferred hold failed after drain");
        // Simulate loss of transient Java bookkeeping while serialized markers
        // remain. Resume must recover saved flags without guessing new defaults.
        ((java.util.Map<?, ?>) field(ZAOReturnBody.class, "PENDING").get(null)).clear();
        check(ZAOReturnBody.resume(source, "resume", "deferred"), "durable hold flags did not resume");
        cell.setSafeToAdd(true); cell.getAddList().remove(source); cell.getObjectList().add(source);
        IsoZombie duplicate = body("resume", false);
        boolean refused = false;
        try { ZAOReturnBody.find("resume"); } catch (IllegalStateException expected) { refused = true; }
        check(refused, "duplicate loaded identity accepted");
        cell.getZombieList().remove(duplicate); cell.getObjectList().remove(duplicate);
        cell.getZombieList().remove(source); cell.getObjectList().remove(source);
        removal(false); removal(true);
        var isolated = isolatedPendingOwner();
        for (int i = 0; i < 8; i++) { System.gc(); Thread.sleep(10); }
        check(ZAOReturnBody.find("isolated-pending") != null && isolated.get() != null,
              "pending source lost after Lua reload and GC");
        ((java.util.Map<?, ?>) field(ZAOReturnBody.class, "PENDING").get(null)).remove(isolated.get());
        var reference = detachedFailure();
        for (int i = 0; i < 8; i++) { System.gc(); Thread.sleep(10); }
        IsoZombie rebound = ZAOReturnBody.find("gc-pending");
        check(rebound != null && rebound == reference.get(), "pending source lost after Lua reload and GC");
        check(ZAOReturnBody.remove(rebound, "gc-pending", "gc-token"), "GC-rebound removal failed");
        check(!((java.util.Map<?, ?>) field(ZAOReturnBody.class, "PENDING").get(null)).containsKey(rebound),
              "successful removal retained strong pending ownership");
        ReturnSourceProbe.codecAndStreaming(cell);
        check(ZAOReturnBody.find("unknown") == null, "missing loaded lookup");
        System.out.println("PASS native return hold/resume/removal, ordinary and reanimated, partial failure, identity and item controls");
    }
}
