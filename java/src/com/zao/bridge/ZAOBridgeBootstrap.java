package com.zao.bridge;

import com.zao.ZAOAgent;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.Collection;

public final class ZAOBridgeBootstrap {
    private static final String GLOBAL_NAME = "ZAOJavaBridge";
    private static final int STABLE_POLLS = 4;
    private static final long POLL_MS = 500L;

    private static Thread watchdog;

    private ZAOBridgeBootstrap() {
    }

    public static synchronized void start() {
        if (watchdog != null) {
            return;
        }
        watchdog = new Thread(ZAOBridgeBootstrap::run, "ZAO-LuaBridge");
        watchdog.setDaemon(true);
        watchdog.start();
        ZAOAgent.log("Lua bridge watchdog started");
    }

    private static void run() {
        Class<?> luaManager = null;
        Object stableEnv = null;
        Object stableExposer = null;
        int stableLoaded = -1;
        int polls = 0;
        Object exposedInto = null;
        Object resetForEnv = null;
        long lastFailLog = 0L;

        while (!Thread.currentThread().isInterrupted()) {
            try {
                Thread.sleep(POLL_MS);
                if (luaManager == null) {
                    luaManager = Class.forName(
                        "zombie.Lua.LuaManager", false, ClassLoader.getSystemClassLoader());
                }

                Object env = staticField(luaManager, "env");
                Object exposer = staticField(luaManager, "exposer");
                Object loaded = staticField(luaManager, "loaded");
                int loadedCount = loaded instanceof Collection<?> c ? c.size() : 0;

                if (env == null || exposer == null || loadedCount == 0) {
                    polls = 0;
                    continue;
                }
                if (env != stableEnv || exposer != stableExposer || loadedCount != stableLoaded) {
                    stableEnv = env;
                    stableExposer = exposer;
                    stableLoaded = loadedCount;
                    polls = 0;
                    continue;
                }
                polls++;
                if (polls < STABLE_POLLS) {
                    continue;
                }

                Object current = invoke(env, "rawget", new Class<?>[]{Object.class}, GLOBAL_NAME);
                if (env == exposedInto && current == ZAOBridge.INSTANCE) {
                    continue;
                }

                if (exposedInto != null && env != exposedInto && env != resetForEnv) {
                    ZAOBridge.INSTANCE.resetRuntimeForWorld();
                    resetForEnv = env;
                    ZAOAgent.log("runtime projections cleared for new Lua environment");
                }

                invoke(exposer, "setExposed", new Class<?>[]{Class.class}, ZAOBridge.class);
                invoke(exposer, "exposeLikeJava", new Class<?>[]{Class.class}, ZAOBridge.class);
                invoke(env, "rawset", new Class<?>[]{Object.class, Object.class},
                    GLOBAL_NAME, ZAOBridge.INSTANCE);

                Object check = invoke(env, "rawget", new Class<?>[]{Object.class}, GLOBAL_NAME);
                if (check == ZAOBridge.INSTANCE) {
                    exposedInto = env;
                    ZAOAgent.log("Lua bridge exposed global=" + GLOBAL_NAME);
                }
            } catch (InterruptedException interrupted) {
                Thread.currentThread().interrupt();
                return;
            } catch (Throwable throwable) {
                long now = System.currentTimeMillis();
                if (now - lastFailLog >= 5_000L) {
                    ZAOAgent.log("bridge exposure attempt failed: " + throwable);
                    lastFailLog = now;
                }
                polls = 0;
            }
        }
    }

    private static Object staticField(Class<?> type, String name) throws Exception {
        Field field = type.getField(name);
        return field.get(null);
    }

    private static Object invoke(Object target, String name, Class<?>[] sig, Object... args)
        throws Exception {
        Method method = target.getClass().getMethod(name, sig);
        method.setAccessible(true);
        return method.invoke(target, args);
    }
}
