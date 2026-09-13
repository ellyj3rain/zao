package com.zao.engine;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

public final class ZAOStanding {
    private String group;
    private final Set<String> claims = new LinkedHashSet<>();
    private final Map<String, Double> trust = new LinkedHashMap<>();

    public void join(String group) {
        this.group = Objects.requireNonNull(group, "group");
    }

    public void leave() {
        group = null;
        claims.clear();
    }

    public String group() {
        return group;
    }

    public void claim(String claim) {
        claims.add(Objects.requireNonNull(claim, "claim"));
    }

    public void unclaim(String claim) {
        claims.remove(claim);
    }

    public Set<String> claims() {
        return Collections.unmodifiableSet(claims);
    }

    public void trust(String person, double value) {
        trust.put(person, Math.max(0.0, Math.min(1.0, value)));
    }

    public double trust(String person) {
        return trust.getOrDefault(person, 0.0);
    }

    public void decayTrust(double amount) {
        trust.replaceAll((person, value) -> Math.max(0.0, value - amount));
    }
}
