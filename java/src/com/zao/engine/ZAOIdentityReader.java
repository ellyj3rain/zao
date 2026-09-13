package com.zao.engine;

import zombie.characters.IsoZombie;

public final class ZAOIdentityReader {
    private ZAOIdentityReader() {
    }

    public static ZAOIdentity read(IsoZombie zombie) {
        Object id = zombie.getModData().rawget("SAOPersonId");
        if (!(id instanceof String personId) || personId.isBlank()) {
            return null;
        }

        Object name = zombie.getModData().rawget("SAOPersonName");
        ZAOIdentity identity = new ZAOIdentity(
            personId,
            name instanceof String personName && !personName.isBlank()
                ? personName : personId
        );

        identity.dead(readBoolean(
            zombie.getModData().rawget("SAOPersonDead"), true));
        identity.turned(readBoolean(
            zombie.getModData().rawget("SAOPersonTurned"), true));
        identity.afflicted(readBoolean(
            zombie.getModData().rawget("SAOPersonAfflicted"), false));
        identity.crossed(readBoolean(
            zombie.getModData().rawget("SAOPersonCrossed"), false));

        Object infections = zombie.getModData()
            .rawget("SAOPersonInfectionsSurvived");
        if (infections instanceof Number number) {
            identity.infectionsSurvived(number.intValue());
        }
        return identity;
    }

    private static boolean readBoolean(Object value, boolean fallback) {
        return value instanceof Boolean bool ? bool : fallback;
    }
}
