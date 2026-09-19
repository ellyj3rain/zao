import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.Map;

/** Process-singleton and course reconstruction proof for A36. */
public final class ZAORuntimeResetProbe {
    @SuppressWarnings({"rawtypes", "unchecked"})
    private static Map map(Object owner, String name) throws Exception {
        Field field = owner.getClass().getDeclaredField(name);
        field.setAccessible(true);
        return (Map) field.get(owner);
    }

    public static void main(String[] ignored) throws Exception {
        Class<?> bridgeType = Class.forName("com.zao.bridge.ZAOBridge");
        Object bridge = bridgeType.getField("INSTANCE").get(null);
        Field storeField = bridgeType.getDeclaredField("controllers");
        storeField.setAccessible(true);
        Object store = storeField.get(bridge);
        Map controllers = map(store, "controllers");
        Map courses = map(store, "courses");
        controllers.put(new Object(), new Object());
        courses.put("prior-world", new Object());
        Method reset = bridgeType.getDeclaredMethod("resetRuntimeForWorld");
        reset.setAccessible(true);
        reset.invoke(bridge);
        if (!controllers.isEmpty() || !courses.isEmpty()) {
            throw new AssertionError("controller/course map crossed world");
        }

        Class<?> courseType = Class.forName("com.zao.engine.ZAOCourse");
        Object course = courseType.getConstructor(int.class, int.class).newInstance(2, 5);
        Method restore = courseType.getMethod("restore", int.class, String.class);
        restore.invoke(course, 3, "afflicted");
        if (!((Boolean) courseType.getMethod("resistant").invoke(course))
                || (Boolean) courseType.getMethod("immune").invoke(course)
                || !((Boolean) courseType.getMethod("afflicted").invoke(course))
                || (Integer) courseType.getMethod("infectionsSurvived").invoke(course) != 3) {
            throw new AssertionError("durable recovery did not reconstruct course mirror");
        }
        restore.invoke(course, 5, "crossed");
        if (!((Boolean) courseType.getMethod("immune").invoke(course))
                || !((Boolean) courseType.getMethod("crossed").invoke(course))
                || (Boolean) courseType.getMethod("afflicted").invoke(course)) {
            throw new AssertionError("durable terminal state did not reconstruct course mirror");
        }
        System.out.println("ZAO_RUNTIME_RESET_OK");
    }
}
