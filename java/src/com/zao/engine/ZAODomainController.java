package com.zao.engine;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.WeakHashMap;
import zombie.characters.IsoGameCharacter;
import zombie.characters.IsoZombie;
import zombie.iso.IsoMovingObject;

public final class ZAODomainController implements ZAOClaimSurface {
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
    private final ZAOCrossedController crossedController;
    private final ZAOAfflictedController afflictedController;
    private ZAORecoveryInput recoveryInput;
    private final Map<IsoZombie, ZAOBodyState> owned =
        new WeakHashMap<>();

    public ZAODomainController(ZAOIdentity identity,
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
        this.crossedController = new ZAOCrossedController(
            identity, perception, disposition, standing, execution,
            mutation, settlement, telemetry, policy);
        this.afflictedController = new ZAOAfflictedController(
            identity, perception, disposition, standing, execution,
            course, mutation, settlement, telemetry, policy);
        this.execution.retain("move");
        this.execution.retain("path");
        this.execution.retain("target");
    }

    public ZAOBodyState claim(IsoZombie zombie, long hour) {
        if (zombie == null || !policy.enabled() || zombie.isDead()) {
            return null;
        }

        Object markedId = zombie.getModData().rawget("SAOPersonId");
        if (!(markedId instanceof String personId) || personId.isBlank()) {
            return null;
        }
        if (!personId.equals(identity.id())) {
            return null;
        }

        identity.turned(true);
        identity.dead(true);

        return apply(
            zombie,
            text(zombie.getModData().rawget("ZAOForm")),
            number(zombie.getModData().rawget("ZAOFormPerformance")),
            text(zombie.getModData().rawget("ZAOTerminalState")),
            text(zombie.getModData().rawget("ZAODecayState")),
            text(zombie.getModData().rawget("ZAOAttributes")));
    }

    public ZAOBodyState apply(
            IsoZombie zombie,
            String form,
            double formPerformance,
            String terminalState,
            String decayState,
            String attributes) {
        if (zombie == null || !policy.enabled()) {
            return null;
        }

        String boundedForm =
            form == null || form.isBlank() || "none".equals(form)
                ? "none" : form;
        double boundedPerformance = bounded(formPerformance);
        String boundedTerminal =
            terminalState == null || terminalState.isBlank()
                ? "turned" : terminalState;
        String boundedDecay =
            decayState == null || decayState.isBlank()
                ? "dormant" : decayState;
        String boundedAttributes = attributes == null ? "" : attributes;

        List<ZAOMutation.Mutation> visible = mutation.apply(
            boundedForm, boundedPerformance, boundedAttributes);
        ZAOBodyState state = new ZAOBodyState(
            boundedTerminal,
            boundedForm,
            boundedPerformance,
            boundedDecay,
            visible);

        applyStats(zombie, boundedForm, boundedPerformance);
        applyAttributes(zombie, boundedAttributes);
        writeState(zombie, state, boundedAttributes);
        owned.put(zombie, state);
        telemetry.event("apply person=" + identity.id()
            + " form=" + boundedForm
            + " performance=" + boundedPerformance
            + " terminal=" + boundedTerminal
            + " decay=" + boundedDecay
            + " attributes=" + boundedAttributes);
        return state;
    }

    public void drive(IsoZombie zombie, IsoMovingObject target, long hour) {
        ZAOBodyState state = stateOf(zombie);
        if (state == null || !policy.controller() || !execution.can("move")) {
            return;
        }
        if ("crossed".equals(state.terminalState())) {
            crossedController.drive(zombie, target);
            return;
        }
        if ("afflicted".equals(state.terminalState())) {
            afflictedController.drive(zombie, target);
            return;
        }
        if (target == null) {
            zombie.setUseless(true);
            return;
        }

        zombie.setUseless(false);
        zombie.setTarget(target);
        if (target instanceof IsoGameCharacter character) {
            zombie.pathToCharacter(character);
        } else {
            zombie.pathToLocationF(
                target.getX(), target.getY(), target.getZ());
        }
        telemetry.event("drive person=" + identity.id()
            + " form=" + state.currentForm());
    }

    public void release(IsoZombie zombie) {
        if (zombie == null || !owned.containsKey(zombie)) {
            return;
        }
        zombie.setTarget(null);
        zombie.setUseless(true);
        zombie.getModData().rawset("ZAOOwned", Boolean.FALSE);
        owned.remove(zombie);
        telemetry.event("release person=" + identity.id());
    }

    public ZAOBodyState stateOf(IsoZombie zombie) {
        return zombie == null ? null : owned.get(zombie);
    }

    @Override
    public boolean owns(Object body) {
        return body instanceof IsoZombie zombie && owned.containsKey(zombie);
    }

    @Override
    public String formOf(Object body) {
        ZAOBodyState state = body instanceof IsoZombie zombie
            ? owned.get(zombie) : null;
        return state == null ? null : state.currentForm();
    }

    @Override
    public double performanceOf(Object body) {
        ZAOBodyState state = body instanceof IsoZombie zombie
            ? owned.get(zombie) : null;
        return state == null ? 0.0 : state.formPerformance();
    }

    public ZAOIdentity identity() {
        return identity;
    }

    public ZAOPerception perception() {
        return perception;
    }

    public ZAODisposition disposition() {
        return disposition;
    }

    public ZAOStanding standing() {
        return standing;
    }

    public ZAOExecution execution() {
        return execution;
    }

    public ZAOCourse course() {
        return course;
    }

    public ZAOMutation mutation() {
        return mutation;
    }

    public ZAOSettlement settlement() {
        return settlement;
    }

    public ZAOTelemetry telemetry() {
        return telemetry;
    }

    public ZAOSandboxPolicy policy() {
        return policy;
    }

    /**
     * The seed of recovery facts, read from the body at claim. The
     * course itself is event-driven (DR-026): the pathogen's own
     * boundary on the Lua side fires the course events on the
     * person's shared course, so the seed only records the facts
     * here - it never re-fires what the boundary already fired.
     */
    public void recoveryInput(ZAORecoveryInput input) {
        this.recoveryInput = input;
        if (input != null) {
            identity.infectionsSurvived(
                identity.infectionsSurvived() + input.repeatInfections());
        }
    }

    public ZAORecoveryInput recoveryInput() {
        return recoveryInput;
    }

    private void writeState(
            IsoZombie zombie,
            ZAOBodyState state,
            String attributes) {
        zombie.getModData().rawset("ZAOOwned", Boolean.TRUE);
        zombie.getModData().rawset("ZAOForm", state.currentForm());
        zombie.getModData().rawset(
            "ZAOFormPerformance", state.formPerformance());
        zombie.getModData().rawset("ZAOTerminalState", state.terminalState());
        zombie.getModData().rawset("ZAODecayState", state.decayState());
        zombie.getModData().rawset("ZAOAttributes", attributes);
    }

    private void applyStats(
            IsoZombie zombie,
            String form,
            double performance) {
        int speed;
        int strength;
        int cognition;
        int memory;
        int sight;
        int hearing;

        switch (form) {
            case "Puker" -> {
                speed = IsoZombie.SPEED_FAST_SHAMBLER;
                strength = 2;
                cognition = 1;
                memory = 500;
                sight = 2;
                hearing = 2;
            }
            case "Husk" -> {
                speed = IsoZombie.SPEED_SHAMBLER;
                strength = 5;
                cognition = 0;
                memory = 25;
                sight = 1;
                hearing = 1;
            }
            case "Skitter" -> {
                speed = IsoZombie.SPEED_SPRINTER;
                strength = 1;
                cognition = 1;
                memory = 500;
                sight = 2;
                hearing = 3;
            }
            case "Wrecker" -> {
                speed = IsoZombie.SPEED_SHAMBLER;
                strength = 5;
                cognition = 1;
                memory = 1_250;
                sight = 1;
                hearing = 1;
            }
            case "Leaper" -> {
                speed = IsoZombie.SPEED_FAST_SHAMBLER;
                strength = 3;
                cognition = 1;
                memory = 800;
                sight = 3;
                hearing = 2;
            }
            case "Weeper" -> {
                speed = IsoZombie.SPEED_SHAMBLER;
                strength = 1;
                cognition = 1;
                memory = 1_250;
                sight = 3;
                hearing = 3;
            }
            default -> {
                return;
            }
        }

        zombie.speedType = speed;
        zombie.strength = scale(strength, performance);
        zombie.cognition = cognition;
        zombie.memory = scale(memory, performance);
        zombie.sight = sight;
        zombie.hearing = hearing;
    }

    private void applyAttributes(IsoZombie zombie, String attributes) {
        if (attributes == null || attributes.isBlank()) {
            return;
        }
        for (String part : attributes.split("\\|")) {
            int split = part.lastIndexOf(':');
            if (split <= 0 || split == part.length() - 1) {
                continue;
            }
            String name = part.substring(0, split);
            double performance;
            try {
                performance = bounded(
                    Double.parseDouble(part.substring(split + 1)));
            } catch (NumberFormatException exception) {
                continue;
            }
            if ("Speed".equals(name)) {
                if (performance > 0.75) {
                    zombie.speedType = IsoZombie.SPEED_SPRINTER;
                } else if (performance > 0.40) {
                    zombie.speedType = IsoZombie.SPEED_FAST_SHAMBLER;
                }
            } else if ("Strength".equals(name)) {
                zombie.strength = scale(zombie.strength, performance);
            } else if ("Hearing".equals(name)) {
                zombie.hearing = scale(zombie.hearing, performance);
            } else if ("Toughness".equals(name)) {
                // The one enumerated attribute the readiness-era
                // sweeps found without a consumer: toughness is what
                // it takes to put the body down, so the health rides
                // the same ±25% band every other attribute rides,
                // applied the day the body is claimed, never
                // retroactively.
                zombie.setHealth((float) (zombie.getHealth()
                    * (0.75 + 0.5 * bounded(performance))));
            }
        }
    }

    private static String text(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static double number(Object value) {
        if (value instanceof Number number) {
            return number.doubleValue();
        }
        if (value != null) {
            try {
                return Double.parseDouble(String.valueOf(value));
            } catch (NumberFormatException exception) {
                return 0.0;
            }
        }
        return 0.0;
    }

    private static double bounded(double value) {
        if (Double.isNaN(value) || value < 0.0) {
            return 0.0;
        }
        return Math.min(1.0, value);
    }

    private static int scale(int value, double performance) {
        double low = value * 0.75;
        double high = value * 1.25;
        return Math.max(1, (int) Math.round(
            low + (high - low) * bounded(performance)));
    }
}
