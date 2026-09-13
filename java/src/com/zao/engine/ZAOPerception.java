package com.zao.engine;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

public final class ZAOPerception {
    public record Belief(String key, double x, double y, long tick,
                         String source, double confidence) {
    }

    private final Map<String, Belief> beliefs = new LinkedHashMap<>();

    public void admit(String key, double x, double y, long tick,
                      String source, double confidence) {
        Objects.requireNonNull(key, "key");
        Objects.requireNonNull(source, "source");
        double bounded = Math.max(0.0, Math.min(1.0, confidence));
        Belief next = new Belief(key, x, y, tick, source, bounded);
        Belief old = beliefs.get(key);
        if (old == null || old.tick() <= tick || old.confidence() <= bounded) {
            beliefs.put(key, next);
        }
    }

    public void decay(long nowTick, long horizon) {
        beliefs.values().removeIf(belief -> nowTick - belief.tick() > horizon);
    }

    public Belief nearest(double x, double y) {
        Belief best = null;
        double bestDistance = Double.MAX_VALUE;
        for (Belief belief : beliefs.values()) {
            double dx = belief.x() - x;
            double dy = belief.y() - y;
            double distance = dx * dx + dy * dy;
            if (distance < bestDistance) {
                bestDistance = distance;
                best = belief;
            }
        }
        return best;
    }

    public List<Belief> beliefs() {
        return Collections.unmodifiableList(new ArrayList<>(beliefs.values()));
    }

    public void clear() {
        beliefs.clear();
    }
}
