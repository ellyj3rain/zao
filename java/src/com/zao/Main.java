package com.zao;

import com.zao.bridge.ZAOBridgeBootstrap;

public final class Main {
    private Main() {
    }

    public static void main(String[] args) {
        ZAOAgent.log("loaded via ZombieBuddy java-mod path");
        com.zao.engine.ZAOReturnWeave.install();
        ZAOBridgeBootstrap.start();
    }
}
