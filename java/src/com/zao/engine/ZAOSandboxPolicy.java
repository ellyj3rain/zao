package com.zao.engine;

/**
 * The operator's dials (DR-019): crossed 2.5% per infection, afflicted
 * susceptibility 5x, resistance at 2 survived infections, immunity at
 * 5, mutation odds 10% or lower at baseline.
 *
 * <p>The record is immutable; the dials reach the Java side once, when
 * the Lua policy pushes them across the bridge, and the configured
 * holder keeps every controller built after that on the same dials.
 */
public record ZAOSandboxPolicy(boolean enabled, double mutationOdds,
                                boolean controller, boolean overlay,
                                double crossedOdds,
                                double afflictedSusceptibility,
                                int resistanceInfections,
                                int immunityInfections) {
    public ZAOSandboxPolicy {
        mutationOdds = Math.max(0.0, Math.min(1.0, mutationOdds));
        crossedOdds = Math.max(0.0, Math.min(1.0, crossedOdds));
        afflictedSusceptibility =
            Math.max(0.0, afflictedSusceptibility);
        resistanceInfections = Math.max(1, resistanceInfections);
        immunityInfections =
            Math.max(resistanceInfections + 1, immunityInfections);
    }

    public static ZAOSandboxPolicy defaults() {
        return new ZAOSandboxPolicy(
            true, 0.10, true, true, 0.025, 5.0, 2, 5);
    }

    private static volatile ZAOSandboxPolicy configured = defaults();

    /** The dials the Lua policy pushed, or the defaults until it does. */
    public static ZAOSandboxPolicy configured() {
        return configured;
    }

    public static void configure(ZAOSandboxPolicy policy) {
        configured = policy == null ? defaults() : policy;
    }
}