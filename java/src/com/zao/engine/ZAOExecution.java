package com.zao.engine;

import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Objects;
import java.util.Set;

public final class ZAOExecution {
    private final Set<String> verbs = new LinkedHashSet<>();

    public void retain(String verb) {
        verbs.add(Objects.requireNonNull(verb, "verb"));
    }

    public void forget(String verb) {
        verbs.remove(verb);
    }

    public boolean can(String verb) {
        return verbs.contains(verb);
    }

    public Set<String> verbs() {
        return Collections.unmodifiableSet(verbs);
    }

    public void decay(int count) {
        if (count <= 0) {
            return;
        }
        int removed = 0;
        var iterator = verbs.iterator();
        while (iterator.hasNext() && removed < count) {
            iterator.next();
            iterator.remove();
            removed++;
        }
    }
}
