package com.zao.engine;

import zombie.characters.BodyDamage.BodyDamage;
import zombie.characters.BodyDamage.BodyPart;
import zombie.characters.BodyDamage.BodyPartType;
import zombie.characters.CharacterStat;
import zombie.characters.IsoPlayer;

/**
 * Restores a returned afflicted person to a critical but viable condition.
 *
 * <p>The native death snapshot has already combined Knox loss and ordinary
 * trauma in body-part health. The engine exposes no attribution that could
 * remove only the Knox share. Return therefore reverses only enough of that
 * aggregate loss to make the body stably alive. Wounds, treatment state,
 * fractures, ordinary wound infection, statistics and experience remain the
 * captured person's own. ZAO's afflicted record, rather than native lethal
 * infection flags, owns the systemic-dormant pathogen state after return.</p>
 */
public final class ZAOReturnHealth {
    public static final float MINIMUM_RETURN_HEALTH = 25.0f;
    private static final float EPSILON = 0.001f;

    private ZAOReturnHealth() {}

    public static boolean restore(IsoPlayer person) {
        if (person == null || person.getBodyDamage() == null
                || person.getStats() == null) return false;
        BodyDamage damage = person.getBodyDamage();
        if (damage.getBodyParts() == null || damage.getBodyParts().isEmpty()) return false;

        for (BodyPart part : damage.getBodyParts()) {
            if (part == null || !Float.isFinite(part.getHealth())) return false;
            part.SetInfected(false);
            part.SetFakeInfected(false);
        }
        damage.setInfected(false);
        damage.setIsFakeInfected(false);
        damage.setReduceFakeInfection(false);
        damage.setInfectionTime(-1.0f);
        damage.setInfectionMortalityDuration(-1.0f);
        person.getStats().reset(CharacterStat.ZOMBIE_INFECTION);
        person.getStats().reset(CharacterStat.ZOMBIE_FEVER);

        damage.calculateOverallHealth();
        liftTo(damage, MINIMUM_RETURN_HEALTH);
        damage.calculateOverallHealth();
        if (!Float.isFinite(damage.getHealth())
                || damage.getHealth() + EPSILON < MINIMUM_RETURN_HEALTH
                || person.isDead() || damage.isInfected()
                || damage.IsFakeInfected()) return false;
        for (BodyPart part : damage.getBodyParts()) {
            if (part.IsInfected() || part.IsFakeInfected()) return false;
        }
        return true;
    }

    /**
     * Reverses aggregate loss using the same body-part weights that native
     * overall-health calculation consumes. The iterative pass handles parts
     * that reach their native ceiling without erasing relative trauma.
     */
    private static void liftTo(BodyDamage damage, float target) {
        for (int pass = 0; pass < damage.getBodyParts().size() + 1; pass++) {
            damage.calculateOverallHealth();
            float remaining = target - damage.getHealth();
            if (remaining <= EPSILON) return;

            int available = 0;
            for (BodyPart part : damage.getBodyParts()) {
                if (part.getHealth() < 100.0f - EPSILON) available++;
            }
            if (available == 0) return;

            float share = remaining / available;
            float gained = 0.0f;
            for (int index = 0; index < damage.getBodyParts().size(); index++) {
                BodyPart part = damage.getBodyParts().get(index);
                if (part.getHealth() >= 100.0f - EPSILON) continue;
                float modifier = BodyPartType.getDamageModifyer(index);
                if (!Float.isFinite(modifier) || modifier <= 0.0f) return;
                float before = part.getHealth();
                part.SetHealth(Math.min(100.0f, before + share / modifier));
                gained += (part.getHealth() - before) * modifier;
            }
            if (gained <= EPSILON) return;
        }
    }
}
