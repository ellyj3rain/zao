package com.zao.engine;

public final class ZAOCourse {
    private int infectionsSurvived;
    private int resistanceThreshold;
    private int immunityThreshold;
    private boolean resistant;
    private boolean immune;
    private boolean infected;
    private boolean crossed;
    private boolean afflicted;

    public ZAOCourse(int resistanceThreshold, int immunityThreshold) {
        this.resistanceThreshold = Math.max(1, resistanceThreshold);
        this.immunityThreshold = Math.max(this.resistanceThreshold + 1, immunityThreshold);
    }

    public void infect() {
        infected = !immune;
    }

    public void survive() {
        infected = false;
        infectionsSurvived++;
        if (infectionsSurvived >= immunityThreshold) {
            immune = true;
            resistant = true;
        } else if (infectionsSurvived >= resistanceThreshold) {
            resistant = true;
        }
    }

    public void passDeath() {
        crossed = true;
        infected = false;
    }

    public void regress() {
        afflicted = true;
        crossed = false;
    }

    public boolean infected() {
        return infected;
    }

    public boolean resistant() {
        return resistant;
    }

    public boolean immune() {
        return immune;
    }

    public boolean crossed() {
        return crossed;
    }

    public boolean afflicted() {
        return afflicted;
    }

    public int infectionsSurvived() {
        return infectionsSurvived;
    }
}
