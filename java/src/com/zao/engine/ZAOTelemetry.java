package com.zao.engine;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public final class ZAOTelemetry {
    private final List<String> events = new ArrayList<>();

    public void event(String event) {
        if (event != null && !event.isBlank()) {
            events.add(event);
        }
    }

    public List<String> events() {
        return Collections.unmodifiableList(events);
    }
}
