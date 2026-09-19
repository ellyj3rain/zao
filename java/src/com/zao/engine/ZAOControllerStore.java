package com.zao.engine;

import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;
import java.util.WeakHashMap;
import zombie.characters.IsoZombie;

public final class ZAOControllerStore {
    private final Map<IsoZombie, ZAODomainController> controllers =
        new WeakHashMap<>();

    /**
     * One course per person, shared with the bridge. The pathogen's
     * event boundary on the Lua side fires the course events by person
     * id; the controller that drives the body reads the same course
     * object, so a course event and a drive never see two courses.
     */
    private final Map<String, ZAOCourse> courses =
        new ConcurrentHashMap<>();

    /** The course a person carries, created on first need. */
    public ZAOCourse courseFor(String personId) {
        if (personId == null || personId.isBlank()) {
            return new ZAOCourse(2, 5);
        }
        ZAOSandboxPolicy policy = ZAOSandboxPolicy.configured();
        return courses.computeIfAbsent(personId, id ->
            new ZAOCourse(
                policy.resistanceInfections(),
                policy.immunityInfections()));
    }

    public ZAODomainController ensure(IsoZombie zombie) {
        Objects.requireNonNull(zombie, "zombie");
        ZAODomainController existing = controllers.get(zombie);
        if (existing != null) {
            return existing;
        }

        ZAOIdentity identity = ZAOIdentityReader.read(zombie);
        if (identity == null) {
            return null;
        }

        ZAORecoveryInput recovery = ZAORecoveryReader.read(zombie);
        ZAOCourse course = courseFor(identity.id());
        Object terminal = zombie.getModData().rawget("ZAOTerminalState");
        course.restore(recovery.repeatInfections(),
            terminal == null ? null : String.valueOf(terminal));

        ZAODomainController controller = new ZAODomainController(
            identity,
            new ZAOPerception(),
            new ZAODisposition(0.5, 0.5, 0.5, 0.5, 0.5),
            new ZAOStanding(),
            new ZAOExecution(),
            course,
            new ZAOMutation(),
            new ZAOSettlement(),
            new ZAOTelemetry(),
            ZAOSandboxPolicy.configured()
        );
        controller.recoveryInput(recovery);
        controller.claim(zombie, 0);
        controllers.put(zombie, controller);
        return controller;
    }

    public ZAODomainController get(IsoZombie zombie) {
        return zombie == null ? null : controllers.get(zombie);
    }

    public void remove(IsoZombie zombie) {
        if (zombie != null) {
            controllers.remove(zombie);
        }
    }

    public int size() {
        return controllers.size();
    }

    /** Controllers and courses are projections of one loaded world. */
    public void resetRuntimeForWorld() {
        controllers.clear();
        courses.clear();
    }
}
