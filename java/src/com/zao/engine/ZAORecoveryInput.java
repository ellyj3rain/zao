package com.zao.engine;

public record ZAORecoveryInput(boolean antibody, boolean cure,
                               int repeatInfections) {
    public ZAORecoveryInput {
        repeatInfections = Math.max(0, repeatInfections);
    }
}
