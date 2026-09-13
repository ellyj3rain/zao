package com.zao.engine;

import java.util.Objects;

public final class ZAOIdentity {
    private final String id;
    private String name;
    private boolean dead;
    private boolean turned;
    private boolean afflicted;
    private boolean crossed;
    private int infectionsSurvived;

    public ZAOIdentity(String id, String name) {
        this.id = Objects.requireNonNull(id, "id");
        this.name = Objects.requireNonNull(name, "name");
    }

    public String id() {
        return id;
    }

    public String name() {
        return name;
    }

    public void name(String name) {
        this.name = Objects.requireNonNull(name, "name");
    }

    public boolean dead() {
        return dead;
    }

    public void dead(boolean dead) {
        this.dead = dead;
    }

    public boolean turned() {
        return turned;
    }

    public void turned(boolean turned) {
        this.turned = turned;
    }

    public boolean afflicted() {
        return afflicted;
    }

    public void afflicted(boolean afflicted) {
        this.afflicted = afflicted;
    }

    public boolean crossed() {
        return crossed;
    }

    public void crossed(boolean crossed) {
        this.crossed = crossed;
    }

    public int infectionsSurvived() {
        return infectionsSurvived;
    }

    public void infectionsSurvived(int infectionsSurvived) {
        this.infectionsSurvived = Math.max(0, infectionsSurvived);
    }

    public void surviveInfection() {
        infectionsSurvived++;
    }
}
