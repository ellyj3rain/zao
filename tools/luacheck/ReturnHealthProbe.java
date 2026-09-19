import java.nio.ByteBuffer;
import zombie.characters.BodyDamage.BodyDamage;
import zombie.characters.BodyDamage.BodyPart;
import zombie.characters.BodyDamage.BodyPartType;
import zombie.characters.CharacterStat;
import zombie.characters.IsoPlayer;
import zombie.characters.SurvivorDesc;
import zombie.characters.skills.PerkFactory;
import com.zao.engine.ZAOReturnHealth;

public final class ReturnHealthProbe {
    private static void check(boolean value, String message) {
        if (!value) throw new AssertionError(message);
    }

    private static IsoPlayer person() {
        SurvivorDesc descriptor = new SurvivorDesc();
        descriptor.getHumanVisual().setSkinTextureName("fixture");
        return new IsoPlayer(null, descriptor, 0, 0, 0, false);
    }

    private static void initializeEngine() throws Exception {
        zombie.core.random.RandStandard.INSTANCE.init();
        zombie.ZomboidFileSystem.instance.init();
        zombie.SoundManager.instance = new zombie.DummySoundManager();
        zombie.Lua.LuaManager.platform = new se.krka.kahlua.j2se.J2SEPlatform();
        zombie.Lua.LuaManager.env = zombie.Lua.LuaManager.platform.newTable();
        zombie.Lua.LuaEventManager.register(
            zombie.Lua.LuaManager.platform, zombie.Lua.LuaManager.env);
        SurvivorDesc.HairCommonColors.add(
            new zombie.core.ImmutableColor(.2f, .3f, .4f));
        zombie.core.skinnedmodel.population.HairStyles.instance =
            new zombie.core.skinnedmodel.population.HairStyles();
        zombie.core.skinnedmodel.population.BeardStyles.instance =
            new zombie.core.skinnedmodel.population.BeardStyles();
        PerkFactory.init();
    }

    private static IsoPlayer deathSnapshot() throws Exception {
        IsoPlayer source = person();
        BodyDamage damage = source.getBodyDamage();
        BodyPart wound = damage.getBodyPart(BodyPartType.Hand_R);
        wound.SetBitten(true, true);
        wound.setBiteTime(12.5f);
        wound.setBandaged(true, 4.25f, true, "fixture-bandage");
        wound.setFractureTime(17.0f);
        wound.setInfectedWound(true);
        wound.setWoundInfectionLevel(2.5f);
        wound.SetFakeInfected(true);
        damage.setInfected(true);
        damage.setIsFakeInfected(true);
        damage.setReduceFakeInfection(true);
        damage.setInfectionTime(1.0f);
        damage.setInfectionMortalityDuration(1.0f);
        source.getStats().set(CharacterStat.ZOMBIE_INFECTION, 100.0f);
        source.getStats().set(CharacterStat.ZOMBIE_FEVER, 91.0f);
        source.getStats().set(CharacterStat.HUNGER, .42f);
        source.getStats().set(CharacterStat.FATIGUE, .61f);
        source.getStats().set(CharacterStat.POISON, 3.0f);
        source.getXp().xpMap.put(PerkFactory.Perks.Aiming, 88.5f);
        source.setPerkLevelDebug(PerkFactory.Perks.Aiming, 2);
        damage.ReduceGeneralHealth(110.0f);
        damage.calculateOverallHealth();
        check(source.isDead(), "fatal source fixture remained alive");

        ByteBuffer body = ByteBuffer.allocate(1 << 20);
        damage.save(body); body.flip();
        ByteBuffer stats = ByteBuffer.allocate(8192);
        source.getStats().save(stats); stats.flip();
        ByteBuffer xp = ByteBuffer.allocate(1 << 20);
        source.getXp().save(xp); xp.flip();
        IsoPlayer restored = person();
        restored.getBodyDamage().load(body, 249);
        restored.getStats().load(stats, 249);
        restored.getXp().load(xp, 249);
        return restored;
    }

    public static void main(String[] args) throws Exception {
        initializeEngine();
        IsoPlayer restored = deathSnapshot();
        BodyPart wound = restored.getBodyDamage().getBodyPart(BodyPartType.Hand_R);
        // The engine owns serialization normalization.  The return operation
        // must preserve the native snapshot it receives, so compare against
        // the loaded values rather than the pre-save fixture arguments.
        boolean bitten = wound.bitten();
        float biteTime = wound.getBiteTime();
        boolean bandaged = wound.bandaged();
        float bandageLife = wound.getBandageLife();
        float fractureTime = wound.getFractureTime();
        boolean infectedWound = wound.isInfectedWound();
        float woundInfectionLevel = wound.getWoundInfectionLevel();
        check(ZAOReturnHealth.restore(restored), "return health restore refused");
        restored.getBodyDamage().calculateOverallHealth();
        float health = restored.getBodyDamage().getHealth();
        check(health >= 24.999f && health <= 25.01f && !restored.isDead(),
            "return health did not stop at critical viability: " + health);
        check(!restored.getBodyDamage().isInfected()
            && !restored.getBodyDamage().IsFakeInfected()
            && !wound.IsInfected() && !wound.IsFakeInfected(),
            "native lethal or fake Knox flags survived return");
        check(wound.bitten() == bitten && wound.getBiteTime() == biteTime
            && wound.bandaged() == bandaged && wound.getBandageLife() == bandageLife
            && wound.getFractureTime() == fractureTime
            && wound.isInfectedWound() == infectedWound
            && wound.getWoundInfectionLevel() == woundInfectionLevel,
            "wound state changed during return");
        check(restored.getStats().get(CharacterStat.HUNGER) == .42f
            && restored.getStats().get(CharacterStat.FATIGUE) == .61f
            && restored.getStats().get(CharacterStat.POISON) == 3.0f
            && restored.getStats().get(CharacterStat.ZOMBIE_INFECTION) == 0.0f
            && restored.getStats().get(CharacterStat.ZOMBIE_FEVER) == 0.0f
            && restored.getXp().getXP(PerkFactory.Perks.Aiming) == 88.5f
            && restored.getPerkLevel(PerkFactory.Perks.Aiming) == 2,
            "unrelated statistics or experience changed during return");

        zombie.iso.IsoCell cell = new zombie.iso.IsoCell(1, 1);
        zombie.iso.WorldReuserThread.instance.stop();
        java.lang.reflect.Field root =
            zombie.iso.areas.isoregion.IsoRegions.class.getDeclaredField("dataRoot");
        root.setAccessible(true);
        root.set(null, new zombie.iso.areas.isoregion.data.DataRoot());
        restored.setCurrentSquare(new zombie.iso.IsoGridSquare(null, null, 0, 0, 0));
        restored.getBodyDamage().Update();
        check(!restored.isDead() && !restored.getBodyDamage().isInfected(),
            "returned body died or reactivated Knox on next native update");
        System.out.println("PASS native afflicted health: viable and injured, "
            + "systemic state externalized, next health="
            + restored.getBodyDamage().getHealth());
    }
}
