package com.zao.engine;

import java.util.Objects;
import zombie.characters.IsoGameCharacter;
import zombie.characters.IsoZombie;
import zombie.iso.IsoMovingObject;

public final class ZAOCrossedController {
    private final ZAOIdentity identity;
    private final ZAOPerception perception;
    private final ZAODisposition disposition;
    private final ZAOStanding standing;
    private final ZAOExecution execution;
    private final ZAOMutation mutation;
    private final ZAOSettlement settlement;
    private final ZAOTelemetry telemetry;
    private final ZAOSandboxPolicy policy;

    public ZAOCrossedController(ZAOIdentity identity,
                                ZAOPerception perception,
                                ZAODisposition disposition,
                                ZAOStanding standing,
                                ZAOExecution execution,
                                ZAOMutation mutation,
                                ZAOSettlement settlement,
                                ZAOTelemetry telemetry,
                                ZAOSandboxPolicy policy) {
        this.identity = Objects.requireNonNull(identity, "identity");
        this.perception = Objects.requireNonNull(perception, "perception");
        this.disposition = Objects.requireNonNull(disposition, "disposition");
        this.standing = Objects.requireNonNull(standing, "standing");
        this.execution = Objects.requireNonNull(execution, "execution");
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
            1.0f + (float) disposition.driveWeight() * 10.0f);
        if (target instanceof IsoGameCharacter character) {
            zombie.pathToCharacter(character);
        }
        telemetry.event("crossed-drive person=" + identity.id());
    }

    public boolean engagesDead() {
        return false;
    }

    public boolean organizesAroundForms() {
        return false;
    }

    public boolean personAgain() {
        return false;
    }
}
