import com.zao.engine.*;
import java.lang.reflect.Field;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;
import se.krka.kahlua.vm.KahluaTable;
import zombie.ReanimatedPlayers;
import zombie.characters.IsoZombie;
import zombie.characters.SurvivorDesc;
import zombie.iso.IsoCell;
import zombie.iso.IsoGridSquare;
import zombie.world.moddata.GlobalModData;

/** Actual Kahlua journal plus native source fixtures for every mixed generation. */
public final class SaveGenerationProbe {
    private static IsoCell cell;
    private static boolean reuserStopped;

    private static void check(boolean value, String message) {
        if (!value) throw new AssertionError(message);
    }
    private static Field field(Class<?> owner, String name) throws Exception {
        Field field = owner.getDeclaredField(name); field.setAccessible(true); return field;
    }
    private static KahluaTable table() { return zombie.Lua.LuaManager.platform.newTable(); }
    private static KahluaTable child(KahluaTable parent, String key) {
        Object value = parent.rawget(key);
        if (value instanceof KahluaTable result) return result;
        KahluaTable result = table(); parent.rawset(key, result); return result;
    }
    private static KahluaTable sao() { return GlobalModData.instance.getOrCreate("SurvivorAwareness_Records"); }
    private static KahluaTable zao() { return GlobalModData.instance.getOrCreate("ZombieAwareness_State"); }
    private static KahluaTable source(String id) {
        return (KahluaTable)child(zao(), "returnSources").rawget(id);
    }
    @SuppressWarnings("unchecked")
    private static List<IsoZombie> preserved() throws Exception {
        return (List<IsoZombie>)field(ReanimatedPlayers.class, "zombies").get(ReanimatedPlayers.instance);
    }
    private static void newWorld(Path directory) throws Exception {
        System.setProperty("zao.returnGenerationDirectory", directory.toString());
        GlobalModData.instance = new GlobalModData();
        cell = new IsoCell(1, 1); cell.setSafeToAdd(true);
        if (!reuserStopped) {
            zombie.iso.WorldReuserThread.instance.stop(); reuserStopped = true;
        }
        ZAOReturnBody.resetRuntimeForWorld(); ZAOReturnSourceStore.resetRuntimeForWorld();
        preserved().clear();
    }
    private static void person(String id, String token) {
        KahluaTable records = child(sao(), "records"), record = table(), transition = table();
        record.rawset("id", id); record.rawset("dead", Boolean.TRUE);
        record.rawset("returnSaveTouched", Boolean.TRUE);
        transition.rawset("version", 1.0); transition.rawset("token", token);
        transition.rawset("phase", "captured"); record.rawset("returnTransition", transition);
        records.rawset(id, record);
        KahluaTable people = child(zao(), "people"), pathogen = table();
        pathogen.rawset("personId", id); pathogen.rawset("terminalState", "afflicted");
        people.rawset(id, pathogen); child(zao(), "recovery").rawset(id, table());
    }
    private static void detach(IsoZombie body) throws Exception {
        body.removeFromSquare(); cell.getZombieList().remove(body); cell.getObjectList().remove(body);
        cell.getAddList().remove(body); preserved().remove(body); ReturnSourceProbe.clearPending();
    }
    private static IsoZombie held(String id, String token, boolean reanimated) throws Exception {
        IsoZombie body = ReturnSourceProbe.body(cell, id, false); body.setReanimatedPlayer(reanimated);
        body.getInventory().getItems().add(ReturnSourceProbe.item("Weapon"));
        body.getInventory().getItems().get(0).setContainer(body.getInventory());
        check(ZAOReturnBody.hold(body, id, token), "fixture source did not hold");
        return body;
    }
    private static void oldGlobal(String id) {
        GlobalModData.instance = new GlobalModData();
        KahluaTable records = child(sao(), "records"), record = table();
        record.rawset("id", id); record.rawset("dead", Boolean.TRUE); records.rawset(id, record);
        child(zao(), "people"); child(zao(), "recovery"); child(zao(), "returnSources");
    }
    private static void heldPair(boolean nativeNew, boolean globalNew, int ordinal) throws Exception {
        Path directory = Files.createTempDirectory("zao-generation-pair-");
        newWorld(directory);
        String id = "generation-" + ordinal, token = "return-" + ordinal;
        person(id, token); IsoZombie original = held(id, token, false);
        ZAOSaveGeneration.prepare();
        String firstGeneration = (String)source(id).rawget("generation");
        if (ordinal == 1) {
            ZAOSaveGeneration.prepare();
            check(!firstGeneration.equals(source(id).rawget("generation")),
                "successive save boundary did not replace/increment the journal");
        }
        String generation = (String)source(id).rawget("generation");
        check(generation != null && generation.equals(original.getModData().rawget("ZAOReturnGeneration")),
            "generation was not shared by source record/body");
        detach(original);
        IsoZombie stale = null;
        if (!nativeNew) stale = ReturnSourceProbe.body(cell, id, false);
        if (!globalNew) oldGlobal(id);
        ZAOSaveGeneration.recover();
        IsoZombie resolved = ZAOReturnBody.find(id);
        check(resolved != null && resolved != stale && ZAOReturnBody.isDormantSource(resolved),
            "mixed generation did not reconstruct one held owner");
        check(generation.equals(source(id).rawget("generation"))
                && generation.equals(resolved.getModData().rawget("ZAOReturnGeneration")),
            "mixed generation did not converge on journal generation");
        KahluaTable record = (KahluaTable)child(sao(), "records").rawget(id);
        check(record.rawget("returnTransition") instanceof KahluaTable
                && "afflicted".equals(((KahluaTable)child(zao(), "people").rawget(id)).rawget("terminalState")),
            "mixed generation did not replay SAO/ZAO authority");
        check(stale == null || (!cell.getZombieList().contains(stale)
                && !cell.getObjectList().contains(stale)), "stale native generation remained loaded");
        check(ZAOReturnBody.remove(resolved, id, token), "mixed-generation owner did not remain completable");
        System.out.println("PAIR native=" + (nativeNew ? "new" : "old")
            + " global=" + (globalNew ? "new" : "old") + " PASS");
    }
    private static void missingReanimated() throws Exception {
        Path directory = Files.createTempDirectory("zao-generation-reanimated-");
        newWorld(directory); String id = "generation-reanimated", token = "return-reanimated";
        person(id, token); IsoZombie original = held(id, token, true);
        ZAOSaveGeneration.prepare(); detach(original); oldGlobal(id);
        ZAOSaveGeneration.recover();
        IsoZombie resolved = ZAOReturnBody.find(id);
        check(resolved != null && resolved.isReanimatedPlayer() && preserved().contains(resolved)
                && ZAOReturnBody.isDormantSource(resolved),
            "missing new reanimated file did not reconstruct preserved owner");
        check(ZAOReturnBody.remove(resolved, id, token), "replayed reanimated owner did not retire");
        System.out.println("PAIR missing reanimated native owner PASS");
    }
    private static void staleReanimated(boolean globalNew) throws Exception {
        Path directory = Files.createTempDirectory("zao-generation-reanimated-old-");
        newWorld(directory); String suffix = globalNew ? "new" : "old";
        String id = "generation-reanimated-old-" + suffix, token = "return-reanimated-" + suffix;
        person(id, token); IsoZombie current = held(id, token, true);
        ZAOSaveGeneration.prepare(); detach(current);
        IsoZombie stale = ReturnSourceProbe.body(cell, id, false); stale.setReanimatedPlayer(true);
        detach(stale); preserved().add(stale);
        if (!globalNew) oldGlobal(id);
        ZAOSaveGeneration.recover(); ZAOReturnSourceStore.restorePreservedMaterials();
        IsoZombie resolved = ZAOReturnBody.find(id);
        check(resolved != null && resolved != stale && resolved.isReanimatedPlayer()
                && preserved().contains(resolved) && !preserved().contains(stale),
            "old reanimated native generation was not replaced");
        check(ZAOReturnBody.remove(resolved, id, token), "replaced reanimated owner did not retire");
        System.out.println("PAIR reanimated native=old global=" + suffix + " PASS");
    }
    private static void retiredOverOldNative() throws Exception {
        Path directory = Files.createTempDirectory("zao-generation-retired-");
        newWorld(directory); String id = "generation-retired", token = "return-retired";
        person(id, token); IsoZombie original = held(id, token, false);
        check(ZAOReturnBody.remove(original, id, token), "retirement fixture did not complete");
        ZAOSaveGeneration.prepare();
        IsoZombie stale = ReturnSourceProbe.body(cell, id, false); oldGlobal(id);
        ZAOSaveGeneration.recover(); ZAOReturnSourceStore.reconcile(cell);
        check(ZAOReturnBody.find(id) == null && !cell.getZombieList().contains(stale)
                && "retired".equals(source(id).rawget("phase")),
            "retired journal did not remove prior native source");
        System.out.println("PAIR retired global over old native PASS");
    }
    private static void cancellationOverHeldNative() throws Exception {
        Path directory = Files.createTempDirectory("zao-generation-cancel-");
        newWorld(directory); String id = "generation-cancel", token = "return-cancel";
        person(id, token); IsoZombie body = held(id, token, false);
        String packed = ReturnSourceProbe.packed(source(id));
        check(ZAOReturnBody.resume(body, id, token), "cancellation fixture did not resume");
        ZAOSaveGeneration.prepare(); detach(body);
        IsoZombie oldHeld = ZAOReturnSourceSnapshot.restore(packed, cell);
        IsoGridSquare square = new IsoGridSquare(cell, null, 1, 1, 0);
        oldHeld.setCurrent(square); oldHeld.setMovingSquare(square); square.getMovingObjects().add(oldHeld);
        cell.getZombieList().add(oldHeld); cell.getObjectList().add(oldHeld);
        oldGlobal(id); ZAOSaveGeneration.recover(); ZAOReturnBody.restoreLoadedHolds(cell);
        check(oldHeld.getModData().rawget("ZAOReturnToken") == null
                && source(id) == null && cell.getZombieList().contains(oldHeld),
            "journaled cancellation recreated or retained the old hold");
        System.out.println("PAIR cancelled global over held native PASS");
    }
    private static void journalControls() throws Exception {
        Path missingDirectory = Files.createTempDirectory("zao-generation-missing-");
        newWorld(missingDirectory); person("generation-missing", "return-missing");
        held("generation-missing", "return-missing", false); ZAOSaveGeneration.prepare();
        Files.delete(missingDirectory.resolve("zao_return_generation.bin"));
        boolean refused = false;
        try { ZAOSaveGeneration.recover(); } catch (IllegalStateException expected) { refused = true; }
        check(refused, "missing current generation journal was accepted");
        System.out.println("CONTROL missing generation journal: REJECTED");

        Path corruptDirectory = Files.createTempDirectory("zao-generation-corrupt-");
        newWorld(corruptDirectory); person("generation-corrupt", "return-corrupt");
        held("generation-corrupt", "return-corrupt", false); ZAOSaveGeneration.prepare();
        Path journal = corruptDirectory.resolve("zao_return_generation.bin");
        byte[] bytes = Files.readAllBytes(journal); bytes[bytes.length - 1] ^= 1; Files.write(journal, bytes);
        refused = false;
        try { ZAOSaveGeneration.recover(); } catch (IllegalStateException expected) { refused = true; }
        check(refused, "corrupt generation journal was accepted");
        System.out.println("CONTROL corrupt generation journal: REJECTED");
    }

    public static void main(String[] arguments) throws Exception {
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
        ReturnSourceProbe.setupItems();
        int ordinal = 0;
        for (boolean nativeNew : new boolean[]{false, true})
            for (boolean globalNew : new boolean[]{false, true})
                heldPair(nativeNew, globalNew, ++ordinal);
        missingReanimated(); staleReanimated(false); staleReanimated(true);
        retiredOverOldNative(); cancellationOverHeldNative();
        journalControls();
        System.out.println("SAVE_GENERATION_OK");
    }
}
