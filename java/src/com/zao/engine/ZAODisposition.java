package com.zao.engine;

public final class ZAODisposition {
    private double aggression;
    private double selfPreservation;
    private double initiative;
    private double discipline;
    private double nerve;

    public ZAODisposition(double aggression, double selfPreservation,
                           double initiative, double discipline, double nerve) {
        this.aggression = bound(aggression);
        this.selfPreservation = bound(selfPreservation);
        this.initiative = bound(initiative);
        this.discipline = bound(discipline);
        this.nerve = bound(nerve);
    }

    public double aggression() {
        return aggression;
    }

    public double selfPreservation() {
        return selfPreservation;
    }

    public double initiative() {
        return initiative;
    }

    public double discipline() {
        return discipline;
    }

    public double nerve() {
        return nerve;
    }

    public void decay(double amount) {
        aggression = bound(aggression - amount);
        selfPreservation = bound(selfPreservation - amount);
        initiative = bound(initiative - amount);
        discipline = bound(discipline - amount);
        nerve = bound(nerve - amount);
    }

    public double driveWeight() {
        return aggression * 0.3 + initiative * 0.25 + nerve * 0.2
            + discipline * 0.15 + selfPreservation * 0.1;
    }

    private static double bound(double value) {
        return Math.max(0.0, Math.min(1.0, value));
    }
}
