package com.zao.engine;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

public final class ZAOMutation {
    public enum Kind {
        CAPABILITY,
        ATTRIBUTE
    }

    public record Mutation(String name, Kind kind, double performance) {
    }

    private final List<Mutation> mutations = new ArrayList<>();

    public List<Mutation> apply(
            String form,
            double formPerformance,
            String attributes) {
        mutations.clear();

        String boundedForm = form == null || form.isBlank()
            || "none".equals(form) ? null : form;
        if (boundedForm != null) {
            mutations.add(new Mutation(
                boundedForm, Kind.CAPABILITY, bounded(formPerformance)));
        }

        if (attributes != null && !attributes.isBlank()) {
            for (String part : attributes.split("\\|")) {
                int split = part.lastIndexOf(':');
                if (split <= 0 || split == part.length() - 1) {
                    continue;
                }
                String name = part.substring(0, split);
                double performance;
                try {
                    performance = Double.parseDouble(
                        part.substring(split + 1));
                } catch (NumberFormatException exception) {
                    continue;
                }
                if (!name.isBlank()) {
                    mutations.add(new Mutation(
                        name, Kind.ATTRIBUTE, bounded(performance)));
                }
            }
        }

        return Collections.unmodifiableList(mutations);
    }

    public List<Mutation> mutations() {
        return Collections.unmodifiableList(mutations);
    }

    public boolean stacks(Mutation mutation) {
        Objects.requireNonNull(mutation, "mutation");
        return mutations.stream().noneMatch(existing ->
            existing.name().equals(mutation.name())
                && existing.kind() == mutation.kind());
    }

    private static double bounded(double value) {
        if (Double.isNaN(value) || value < 0.0) {
            return 0.0;
        }
        return Math.min(1.0, value);
    }
}
