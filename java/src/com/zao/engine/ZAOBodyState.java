package com.zao.engine;

import java.util.List;

public record ZAOBodyState(String terminalState, String currentForm,
                           double formPerformance, String decayState,
                           List<ZAOMutation.Mutation> visibleForms) {
}
