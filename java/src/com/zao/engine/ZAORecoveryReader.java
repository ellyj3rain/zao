package com.zao.engine;

import zombie.characters.IsoZombie;

/**
 * Recovery facts, read from where the Lua side actually keeps them.
 *
 * <p>The Lua controller writes each claimed body's recovery onto the
 * body itself (ZAOAntibody, ZAOCure, ZAORepeatInfections), read from
 * the sister's record - the antibodies mod's own table lives on
 * players, never on a body, so the old reads of Antibodies/Cured/
 * InfectionsSurvived never matched anything. A recovery seeds the
 * Java course once, at claim; the course events keep it current
 * after that.
 */
public final class ZAORecoveryReader {
    private ZAORecoveryReader() {
    }

    public static ZAORecoveryInput read(IsoZombie zombie) {
        if (zombie == null) {
            return new ZAORecoveryInput(false, false, 0);
        }

        Object antibody = zombie.getModData().rawget("ZAOAntibody");
        Object cure = zombie.getModData().rawget("ZAOCure");
        Object infections = zombie.getModData()
            .rawget("ZAORepeatInfections");

        int repeatInfections = infections instanceof Number number
            ? number.intValue() : 0;
        return new ZAORecoveryInput(
            antibody instanceof Boolean value && value,
            cure instanceof Boolean cured && cured,
            repeatInfections
        );
    }
}