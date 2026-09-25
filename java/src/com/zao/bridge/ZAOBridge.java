package com.zao.bridge;

import com.zao.ZAOAgent;
import com.zao.engine.ZAOBodyState;
import com.zao.engine.ZAOControllerStore;
import com.zao.engine.ZAODomainController;
import com.zao.engine.ZAOSandboxPolicy;
import zombie.WorldSoundManager;
import zombie.characters.BodyDamage.BodyDamage;
import zombie.characters.BodyDamage.BodyPart;
import zombie.characters.CharacterStat;
import zombie.characters.IsoGameCharacter;
import zombie.characters.IsoPlayer;
import zombie.characters.IsoZombie;
import zombie.iso.IsoMovingObject;

public final class ZAOBridge {
    public static final ZAOBridge INSTANCE = new ZAOBridge();

    private final ZAOControllerStore controllers = new ZAOControllerStore();

    private ZAOBridge() {
    }

    /** Clear process-resident projections while retaining ModData owners. */
    void resetRuntimeForWorld() {
        controllers.resetRuntimeForWorld();
        com.zao.engine.ZAOReturnBody.resetRuntimeForWorld();
        com.zao.engine.ZAOReturnSourceStore.resetRuntimeForWorld();
    }

    public String version() {
        return "0.1.5.4-pre-alpha";
    }

    /**
     * The dials cross here, once, before the first bridge use. The
     * Lua policy pushes what the sandbox options read; until it does,
     * the defaults hold. Thresholds arrive as the engine's own numbers
     * and are rounded to the course's integers.
     */
    public boolean configure(
            boolean enabled,
            double mutationOdds,
            boolean controller,
            boolean overlay,
            double crossedOdds,
            double afflictedSusceptibility,
            double resistanceInfections,
            double immunityInfections) {
        try {
            ZAOSandboxPolicy.configure(new ZAOSandboxPolicy(
                enabled,
                mutationOdds,
                controller,
                overlay,
                crossedOdds,
                afflictedSusceptibility,
                (int) Math.round(Math.max(1.0, resistanceInfections)),
                (int) Math.round(Math.max(1.0, immunityInfections))));
            ZAOAgent.log("bridge configured crossedOdds=" + crossedOdds
                + " susceptibility=" + afflictedSusceptibility
                + " resistance=" + (int) Math.round(resistanceInfections)
                + " immunity=" + (int) Math.round(immunityInfections));
            return true;
        } catch (Throwable throwable) {
            ZAOAgent.log("configure threw: " + throwable);
            return false;
        }
    }

    /**
     * The course events, fired by the pathogen's own event boundary
     * on the Lua side: an infection feeds the course, a survival
     * counts toward resistance and immunity, the per-infection
     * variable that carries a body past death is the course's
     * pass-death. Each event lands on the person's one shared course.
     */
    public boolean courseInfect(Object personId) {
        try {
            String id = String.valueOf(personId);
            controllers.courseFor(id).infect();
            ZAOAgent.log("course infect person=" + id);
            return true;
        } catch (Throwable throwable) {
            ZAOAgent.log("courseInfect threw: " + throwable);
            return false;
        }
    }

    public boolean courseSurvive(Object personId) {
        try {
            String id = String.valueOf(personId);
            controllers.courseFor(id).survive();
            ZAOAgent.log("course survive person=" + id);
            return true;
        } catch (Throwable throwable) {
            ZAOAgent.log("courseSurvive threw: " + throwable);
            return false;
        }
    }

    public boolean coursePassDeath(Object personId) {
        try {
            String id = String.valueOf(personId);
            controllers.courseFor(id).passDeath();
            ZAOAgent.log("course passDeath person=" + id);
            return true;
        } catch (Throwable throwable) {
            ZAOAgent.log("coursePassDeath threw: " + throwable);
            return false;
        }
    }

    public boolean isZombie(Object object) {
        return object instanceof IsoZombie;
    }

    public Object findReturnBody(String personId) {
        return com.zao.engine.ZAOReturnBody.find(personId);
    }

    public boolean supportsReturnBody(Object object) {
        return object instanceof IsoZombie zombie
            && com.zao.engine.ZAOReturnBody.isSupportedSource(zombie);
    }

    public boolean isDormantReturnSource(Object object) {
        return object instanceof IsoZombie zombie
            && com.zao.engine.ZAOReturnBody.isDormantSource(zombie);
    }

    public boolean holdReturnBody(Object object, String personId, String token) {
        return object instanceof IsoZombie zombie
            && com.zao.engine.ZAOReturnBody.hold(zombie, personId, token);
    }

    public boolean resumeReturnBody(Object object, String personId, String token) {
        return object instanceof IsoZombie zombie
            && com.zao.engine.ZAOReturnBody.resume(zombie, personId, token);
    }

    public boolean removeReturnBody(Object object, String personId, String token) {
        if (!(object instanceof IsoZombie zombie)) return false;
        boolean removed = com.zao.engine.ZAOReturnBody.remove(zombie, personId, token);
        if (removed) {
            // Terminal removal has already cleared native AI and ownership.
            controllers.remove(zombie);
        }
        return removed;
    }

    public boolean restoreReturnHealth(Object object) {
        try {
            return object instanceof zombie.characters.IsoPlayer person
                && com.zao.engine.ZAOReturnHealth.restore(person);
        } catch (Throwable throwable) {
            ZAOAgent.log("restoreReturnHealth threw: " + throwable);
            return false;
        }
    }

    public boolean owns(Object object) {
        try {
            if (!(object instanceof IsoZombie zombie)) {
                return false;
            }
            ZAODomainController controller = controllers.get(zombie);
            return controller != null && controller.owns(zombie);
        } catch (Throwable throwable) {
            ZAOAgent.log("owns threw: " + throwable);
            return false;
        }
    }

    public String formOf(Object object) {
        try {
            if (!(object instanceof IsoZombie zombie)) {
                return null;
            }
            ZAODomainController controller = controllers.get(zombie);
            return controller == null ? null : controller.formOf(zombie);
        } catch (Throwable throwable) {
            ZAOAgent.log("formOf threw: " + throwable);
            return null;
        }
    }

    public double performanceOf(Object object) {
        try {
            if (!(object instanceof IsoZombie zombie)) {
                return 0.0;
            }
            ZAODomainController controller = controllers.get(zombie);
            return controller == null ? 0.0 : controller.performanceOf(zombie);
        } catch (Throwable throwable) {
            ZAOAgent.log("performanceOf threw: " + throwable);
            return 0.0;
        }
    }

    public void apply(
            Object object,
            String form,
            double performance,
            String terminalState,
            String decayState,
            String attributes) {
        try {
            if (!(object instanceof IsoZombie zombie)) {
                return;
            }
            if (zombie.getModData().rawget("ZAOReturnToken") != null) return;
            ZAODomainController controller = controllers.ensure(zombie);
            if (controller != null) {
                controller.apply(
                    zombie,
                    form,
                    performance,
                    terminalState,
                    decayState,
                    attributes);
            }
        } catch (Throwable throwable) {
            ZAOAgent.log("apply threw: " + throwable);
        }
    }

    public void drive(
            Object object,
            Object targetObject,
            String form,
            double performance,
            String terminalState,
            String decayState,
            String attributes) {
        try {
            if (!(object instanceof IsoZombie zombie)
                || !(targetObject instanceof IsoMovingObject target)) {
                return;
            }
            if (zombie.getModData().rawget("ZAOReturnToken") != null) return;
            ZAODomainController controller = controllers.ensure(zombie);
            if (controller != null) {
                controller.apply(
                    zombie,
                    form,
                    performance,
                    terminalState,
                    decayState,
                    attributes);
                controller.drive(zombie, target, 0);
            }
        } catch (Throwable throwable) {
            ZAOAgent.log("drive threw: " + throwable);
        }
    }

    /**
     * The crossed use the dead ([MUTATION.md], [A32]): the body makes
     * noise on the engine's own world-sound channel - the same channel
     * zombie hearing consumes - and every dead thing in radius comes
     * toward it. A shout's worth by default; the caller scales the
     * radius from the body's own drives. The dead are a tool and the
     * channel is the county's; nothing is synthesized.
     */
    public boolean noise(Object object, int radius, int volume) {
        try {
            if (!(object instanceof IsoGameCharacter character)) {
                return false;
            }
            WorldSoundManager.instance.addSound(
                character,
                (int) character.getX(),
                (int) character.getY(),
                (int) character.getZ(),
                radius,
                volume);
            ZAOAgent.log("noise r=" + radius + " v=" + volume);
            return true;
        } catch (Throwable throwable) {
            ZAOAgent.log("noise threw: " + throwable);
            return false;
        }
    }

    /**
     * Read the body's native hunger pressure without selecting a food for it.
     * Crossed policy owns the eligible diet; this bridge only exposes the same
     * physical signal the engine advances on every living human shell.
     */
    public double hunger(Object object) {
        try {
            if (!(object instanceof IsoGameCharacter character)
                || character.getStats() == null) {
                return -1.0;
            }
            return character.getStats().get(CharacterStat.HUNGER);
        } catch (Throwable throwable) {
            ZAOAgent.log("hunger threw: " + throwable);
            return -1.0;
        }
    }

    /**
     * Let contaminated Crossed blood enter through an injury that the actual
     * weapon hit produced. This never manufactures a wound and never treats a
     * zombie/mutant representation as a living human. Native transmission and
     * mortality settings remain authoritative through generateZombieInfection.
     */
    public String applyCrossedBlood(Object object) {
        try {
            if (!(object instanceof IsoPlayer person) || person.isDead()) {
                return "REFUSED:not-living-human";
            }
            BodyDamage damage = person.getBodyDamage();
            if (damage == null || damage.getBodyParts() == null) {
                return "REFUSED:no-body-damage";
            }
            BodyPart selected = null;
            int selectedIndex = -1;
            for (int index = 0; index < damage.getBodyParts().size(); index++) {
                BodyPart part = damage.getBodyParts().get(index);
                if (part == null || part.IsInfected()) continue;
                boolean open = part.bitten() || part.scratched()
                    || part.deepWounded() || part.isDeepWounded()
                    || part.isCut() || part.haveBullet() || part.bleeding()
                    || part.HasInjury();
                if (open) {
                    selected = part;
                    selectedIndex = index;
                    break;
                }
            }
            if (selected == null) return "REFUSED:no-injury";
            selected.generateZombieInfection(100);
            return (selected.IsInfected() || damage.isInfected()
                    ? "APPLIED:" : "RESISTED:") + selectedIndex;
        } catch (Throwable throwable) {
            ZAOAgent.log("applyCrossedBlood threw: " + throwable);
            return "REFUSED:exception:" + throwable.getClass().getSimpleName();
        }
    }

    public void release(Object object) {
        try {
            if (!(object instanceof IsoZombie zombie)) {
                return;
            }
            ZAODomainController controller = controllers.get(zombie);
            if (controller != null) {
                controller.release(zombie);
            }
            controllers.remove(zombie);
        } catch (Throwable throwable) {
            ZAOAgent.log("release threw: " + throwable);
        }
    }

    public String stats(Object object) {
        try {
            if (!(object instanceof IsoZombie zombie)) {
                return "";
            }
            ZAODomainController controller = controllers.get(zombie);
            ZAOBodyState state = controller == null ? null : controller.stateOf(zombie);
            if (state == null) {
                return "unowned";
            }
            return "form=" + state.currentForm()
                + "|performance=" + state.formPerformance()
                + "|terminal=" + state.terminalState()
                + "|decay=" + state.decayState()
                + "|attributes=" + zombie.getModData().rawget("ZAOAttributes")
                + "|speed=" + zombie.speedType
                + "|strength=" + zombie.strength
                + "|cognition=" + zombie.cognition
                + "|memory=" + zombie.memory
                + "|sight=" + zombie.sight
                + "|hearing=" + zombie.hearing;
        } catch (Throwable throwable) {
            ZAOAgent.log("stats threw: " + throwable);
            return "";
        }
    }
}
