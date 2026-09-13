package com.zao.engine;

import java.util.Objects;
import zombie.characters.IsoGameCharacter;
import zombie.characters.IsoZombie;
import zombie.iso.IsoMovingObject;

public final class ZAOAfflictedController {
    private final ZAOIdentity identity;
    private final ZAOPerception perception;
    private final ZAODisposition disposition;
    private final ZAOStanding standing;
    private final ZAOExecution execution;
    private final ZAOCourse course;
    private final ZAOMutation mutation;
    private final ZAOSettlement settlement;
    private final ZAOTelemetry telemetry;
    private final ZAOSandboxPolicy policy;

    public ZAOAfflictedController(ZAOIdentity identity,
                                  ZAOPerception perception,
                                  ZAODisposition disposition,
                                  ZAOStanding standing,
                                  ZAOExecution execution,
                                  ZAOCourse course,
                                  ZAOMutation mutation,
                                  ZAOSettlement settlement,
                                  ZAOTelemetry telemetry,
                                  ZAOSandboxPolicy policy) {
        this.identity = Objects.requireNonNull(identity, "identity");
        this.perception = Objects.requireNonNull(perception, "perception");
        this.disposition = Objects.requireNonNull(disposition, "disposition");
        this.standing = Objects.requireNonNull(standing, "standing");
        this.execution = Objects.requireNonNull(execution, "execution");
        this.course = Objects.requireNonNull(course, "course");
        this.mutation = Objects.requireNonNull(mutation, "mutation");
        this.settlement = Objects.requireNonNull(settlement, "settlement");
        this.telemetry = Objects.requireNonNull(telemetry, "telemetry");
        this.policy = Objects.requireNonNull(policy, "policy");
    }

    public void drive(IsoZombie zombie, IsoMovingObject target) {
        if (zombie == null || target == null || !policy.controller()) {
            return;
        }
        zombie.setUseless(false);
        zombie.setTarget(target);
        zombie.setTargetSeenTime(
            0.5f + (float) disposition.driveWeight() * 5.0f);
        if (target instanceof IsoGameCharacter character) {
            zombie.pathToCharacter(character);
        }
        // Identity loss is episodic (DR-020) and belongs to the
        // pathogen's daily advance on the Lua side; a drive never
        // takes a slice of it.
        telemetry.event("afflicted-drive person=" + identity.id());
    }

    public boolean personAgain() {
        return true;
    }

    public boolean passivelyInfectious() {
        return true;
    }

    public double susceptibilityToCrossed() {
        return policy.afflictedSusceptibility();
    }

    public boolean canReturnFurther() {
        return false;
    }
}
