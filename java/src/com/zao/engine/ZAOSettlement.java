package com.zao.engine;

import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Objects;
import java.util.Set;

public final class ZAOSettlement {
    private String group;
    private double necessity;
    private final Set<String> members = new LinkedHashSet<>();

    public void form(String group, double necessity) {
        this.group = Objects.requireNonNull(group, "group");
        this.necessity = bound(necessity);
    }

    public void join(String person) {
        members.add(Objects.requireNonNull(person, "person"));
    }

    public void leave(String person) {
        members.remove(person);
        if (members.isEmpty()) {
            group = null;
            necessity = 0.0;
        }
    }

    public void necessity(double necessity) {
        this.necessity = bound(necessity);
    }

    public String group() {
        return group;
    }

    public double necessity() {
        return necessity;
    }

    public Set<String> members() {
        return Collections.unmodifiableSet(members);
    }

    private static double bound(double value) {
        return Math.max(0.0, Math.min(1.0, value));
    }
}
