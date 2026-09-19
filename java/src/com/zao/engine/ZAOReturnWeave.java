package com.zao.engine;

import java.lang.instrument.Instrumentation;
import net.bytebuddy.ByteBuddy;
import net.bytebuddy.agent.ByteBuddyAgent;
import net.bytebuddy.agent.builder.AgentBuilder;
import net.bytebuddy.asm.Advice;
import net.bytebuddy.description.type.TypeDescription;
import net.bytebuddy.dynamic.ClassFileLocator;
import net.bytebuddy.dynamic.DynamicType;
import net.bytebuddy.matcher.ElementMatchers;
import net.bytebuddy.pool.TypePool;
import net.bytebuddy.utility.JavaModule;
import net.bytebuddy.jar.asm.ClassReader;
import net.bytebuddy.jar.asm.ClassVisitor;
import net.bytebuddy.jar.asm.MethodVisitor;
import net.bytebuddy.jar.asm.Opcodes;

/** Native return guards; follows SAOBodyScaleWeave's installed Byte Buddy seam. */
public final class ZAOReturnWeave {
    private static final String ZOMBIE = "zombie.characters.IsoZombie";
    private static final String CELL = "zombie.iso.IsoCell";
    private static final String POPULATION = "zombie.popman.ZombiePopulationManager";
    private static final String CHUNK = "zombie.iso.IsoChunk";
    private static final String PRESERVED = "zombie.ReanimatedPlayers";
    private static final String HELPER = "com/zao/engine/ZAOReturnBody";
    private static final String STORE = "com/zao/engine/ZAOReturnSourceStore";
    private static final int REQUIRED = 1023;
    private static volatile int verifiedMask;
    private static volatile boolean installed;
    private static volatile String failure;

    private ZAOReturnWeave() { }

    public static final class Guard {
        @Advice.OnMethodEnter(skipOn = Advice.OnNonDefaultValue.class)
        public static boolean enter(@Advice.This Object body) {
            return ZAOReturnBody.hasHold(body);
        }
    }
    public static final class Reconstruct {
        @Advice.OnMethodEnter
        public static void enter(@Advice.This Object cell) {
            ZAOReturnBody.restoreLoadedHolds(cell);
        }
    }
    public static final class BeforeSave {
        @Advice.OnMethodEnter public static void enter() { ZAOReturnSourceStore.beforePopulationSave(); }
    }
    public static final class Virtualize {
        @Advice.OnMethodEnter(skipOn = Advice.OnNonDefaultValue.class)
        public static boolean enter(@Advice.Argument(0) zombie.characters.IsoZombie body) {
            return ZAOReturnSourceStore.virtualize(body);
        }
    }
    public static final class ChunkUnload {
        @Advice.OnMethodEnter public static void enter(@Advice.This Object chunk) {
            ZAOReturnSourceStore.beforeChunkUnload(chunk);
        }
    }
    public static final class PopulationUnload {
        @Advice.OnMethodEnter public static void enter(@Advice.Argument(0) Object chunk) {
            ZAOReturnSourceStore.beforeChunkUnload(chunk);
        }
    }
    public static final class PreservedLoad {
        @Advice.OnMethodExit public static void exit() { ZAOReturnSourceStore.restorePreservedMaterials(); }
    }

    public static boolean isAvailable() { return installed && failure == null && verifiedMask == REQUIRED; }
    public static String report() { return "return-hooks=" + verifiedMask + "/" + REQUIRED + ";installed=" + installed + ";error=" + failure; }

    public static synchronized void install() {
        if (isAvailable()) return;
        try {
            Instrumentation instrumentation = ByteBuddyAgent.install();
            // Force both targets to load before installation so retransform is
            // synchronous and readiness cannot mean merely registered advice.
            Class.forName(ZOMBIE, false, ClassLoader.getSystemClassLoader());
            Class.forName(CELL, false, ClassLoader.getSystemClassLoader());
            Class.forName(POPULATION, false, ClassLoader.getSystemClassLoader());
            Class.forName(CHUNK, false, ClassLoader.getSystemClassLoader());
            Class.forName(PRESERVED, false, ClassLoader.getSystemClassLoader());
            verifiedMask = 0; failure = null;
            new AgentBuilder.Default()
                .disableClassFormatChanges()
                .with(AgentBuilder.RedefinitionStrategy.RETRANSFORMATION)
                .with(AgentBuilder.TypeStrategy.Default.REDEFINE)
                .with(new AgentBuilder.Listener.Adapter() {
                    @Override public void onTransformation(TypeDescription type, ClassLoader loader,
                            JavaModule module, boolean loaded, DynamicType bytes) {
                        int mask = inspect(type.getName(), bytes.getBytes());
                        synchronized (ZAOReturnWeave.class) { verifiedMask |= mask; }
                    }
                    @Override public void onError(String name, ClassLoader loader, JavaModule module,
                            boolean loaded, Throwable error) { failure = name + ": " + error; }
                })
                .type(ElementMatchers.named(ZOMBIE).or(ElementMatchers.named(CELL))
                        .or(ElementMatchers.named(POPULATION)).or(ElementMatchers.named(CHUNK)).or(ElementMatchers.named(PRESERVED)))
                .transform((builder, type, loader, module, domain) -> decorate(builder, type.getName()))
                .installOn(instrumentation);
            installed = true;
            if (verifiedMask != REQUIRED) failure = "Required native method guards were not verified";
        } catch (Throwable error) {
            failure = String.valueOf(error);
        }
        System.out.println("[ZAO] " + report());
    }

    private static DynamicType.Builder<?> decorate(DynamicType.Builder<?> builder, String name) {
        if (ZOMBIE.equals(name)) {
            return builder.visit(Advice.to(Guard.class).on(ElementMatchers.named("preupdate")
                    .or(ElementMatchers.named("update")).or(ElementMatchers.named("postupdate"))
                    .and(ElementMatchers.takesArguments(0)).and(ElementMatchers.returns(void.class))));
        }
        if (CELL.equals(name)) return builder.visit(Advice.to(Reconstruct.class).on(ElementMatchers.named("ProcessRemoveItems")
                .and(ElementMatchers.takesArguments(java.util.Iterator.class)).and(ElementMatchers.returns(void.class))));
        if (CHUNK.equals(name)) return builder.visit(Advice.to(ChunkUnload.class).on(ElementMatchers.named("removeFromWorld")
                .and(ElementMatchers.takesArguments(0)).and(ElementMatchers.returns(void.class))));
        if (PRESERVED.equals(name)) return builder.visit(Advice.to(PreservedLoad.class).on(ElementMatchers.named("loadReanimatedPlayers")
                .and(ElementMatchers.takesArguments(java.nio.ByteBuffer.class)).and(ElementMatchers.returns(void.class))));
        return builder.visit(Advice.to(BeforeSave.class).on(ElementMatchers.named("beginSaveRealZombies").and(ElementMatchers.takesArguments(0))
                    .or(ElementMatchers.named("requestSaveCell").and(ElementMatchers.takesArguments(int.class, int.class)))))
                .visit(Advice.to(Virtualize.class).on(ElementMatchers.named("virtualizeZombie")
                    .and(ElementMatchers.takesArguments(zombie.characters.IsoZombie.class))))
                .visit(Advice.to(PopulationUnload.class).on(ElementMatchers.named("removeChunkFromWorld")
                    .and(ElementMatchers.takesArguments(zombie.iso.IsoChunk.class))))
                .visit(new PopulationSelection());
    }

    /** Two exact call sites, scoped to native population selection only. */
    private static final class PopulationSelection extends net.bytebuddy.asm.AsmVisitorWrapper.AbstractBase {
        @Override public ClassVisitor wrap(TypeDescription type, ClassVisitor visitor,
                net.bytebuddy.implementation.Implementation.Context context, TypePool pool,
                net.bytebuddy.description.field.FieldList<net.bytebuddy.description.field.FieldDescription.InDefinedShape> fields,
                net.bytebuddy.description.method.MethodList<?> methods, int writerFlags, int readerFlags) {
            return new ClassVisitor(Opcodes.ASM9, visitor) {
                int sites;
                @Override public MethodVisitor visitMethod(int access, String method, String desc, String signature, String[] exceptions) {
                    MethodVisitor delegate = super.visitMethod(access, method, desc, signature, exceptions);
                    boolean selector = ("beginSaveRealZombies".equals(method) && "()V".equals(desc))
                        || ("requestSaveCell".equals(method) && "(II)V".equals(desc));
                    if (!selector) return delegate;
                    return new MethodVisitor(Opcodes.ASM9, delegate) {
                        @Override public void visitMethodInsn(int opcode, String owner, String call, String descriptor, boolean itf) {
                            if (opcode == Opcodes.INVOKEVIRTUAL && "zombie/characters/IsoZombie".equals(owner)
                                    && "isReanimatedPlayer".equals(call) && "()Z".equals(descriptor)) {
                                sites++;
                                super.visitMethodInsn(Opcodes.INVOKESTATIC, STORE, "populationExcluded", "(Lzombie/characters/IsoZombie;)Z", false);
                            } else super.visitMethodInsn(opcode, owner, call, descriptor, itf);
                        }
                    };
                }
                @Override public void visitEnd() {
                    if (sites != 2) throw new IllegalStateException("Native population selection sites changed: " + sites);
                    super.visitEnd();
                }
            };
        }
    }

    /** Offline bytecode is inspected using the same exact method/call mask. */
    public static byte[] weave(String name, byte[] original) throws Exception {
        if (!ZOMBIE.equals(name) && !CELL.equals(name) && !POPULATION.equals(name) && !CHUNK.equals(name) && !PRESERVED.equals(name))
            throw new IllegalArgumentException("Unexpected return target");
        ClassFileLocator locator = new ClassFileLocator.Compound(ClassFileLocator.Simple.of(name, original),
                ClassFileLocator.ForClassLoader.ofSystemLoader(),
                ClassFileLocator.ForClassLoader.of(ZAOReturnWeave.class.getClassLoader()));
        TypeDescription type = TypePool.Default.of(locator).describe(name).resolve();
        byte[] bytes = decorate(new ByteBuddy().redefine(type, locator), name).make().getBytes();
        int expected = ZOMBIE.equals(name) ? 7 : CELL.equals(name) ? 8 : CHUNK.equals(name) ? 128 : PRESERVED.equals(name) ? 512 : 368;
        if (inspect(name, bytes) != expected) throw new IllegalStateException("Native return weave mask mismatch");
        return bytes;
    }

    public static int inspect(String name, byte[] bytes) {
        int[] result = {0};
        new ClassReader(bytes).accept(new ClassVisitor(Opcodes.ASM9) {
            @Override public MethodVisitor visitMethod(int access, String method, String desc,
                    String signature, String[] exceptions) {
                int bit = ZOMBIE.equals(name) && "()V".equals(desc)
                        ? switch (method) { case "preupdate" -> 1; case "update" -> 2; case "postupdate" -> 4; default -> 0; }
                        : CELL.equals(name) && "ProcessRemoveItems".equals(method)
                          && "(Ljava/util/Iterator;)V".equals(desc) ? 8
                        : CHUNK.equals(name) && "removeFromWorld".equals(method) && "()V".equals(desc) ? 128
                        : PRESERVED.equals(name) && "loadReanimatedPlayers".equals(method) && "(Ljava/nio/ByteBuffer;)V".equals(desc) ? 512
                        : POPULATION.equals(name) ? switch (method + desc) {
                            case "beginSaveRealZombies()V" -> 16;
                            case "requestSaveCell(II)V" -> 32;
                            case "virtualizeZombie(Lzombie/characters/IsoZombie;)V" -> 64;
                            case "removeChunkFromWorld(Lzombie/iso/IsoChunk;)V" -> 256;
                            default -> 0;
                        } : 0;
                return new MethodVisitor(Opcodes.ASM9) {
                    boolean selection, preparation;
                    @Override public void visitMethodInsn(int opcode, String owner, String call,
                            String descriptor, boolean isInterface) {
                        if (opcode == Opcodes.INVOKESTATIC && HELPER.equals(owner)
                                && ((bit == 8 && "restoreLoadedHolds".equals(call) && "(Ljava/lang/Object;)V".equals(descriptor))
                                || (bit != 0 && bit != 8 && "hasHold".equals(call) && "(Ljava/lang/Object;)Z".equals(descriptor))))
                            result[0] |= bit;
                        if (opcode == Opcodes.INVOKESTATIC && STORE.equals(owner)) {
                            if ((bit == 16 || bit == 32) && "populationExcluded".equals(call)
                                    && "(Lzombie/characters/IsoZombie;)Z".equals(descriptor)) selection = true;
                            if ((bit == 16 || bit == 32) && "beforePopulationSave".equals(call) && "()V".equals(descriptor)) preparation = true;
                            if (bit == 64 && "virtualize".equals(call) && "(Lzombie/characters/IsoZombie;)Z".equals(descriptor)) result[0] |= bit;
                            if ((bit == 128 || bit == 256) && "beforeChunkUnload".equals(call) && "(Ljava/lang/Object;)V".equals(descriptor)) result[0] |= bit;
                            if (bit == 512 && "restorePreservedMaterials".equals(call) && "()V".equals(descriptor)) result[0] |= bit;
                        }
                    }
                    @Override public void visitEnd() { if (selection && preparation) result[0] |= bit; }
                };
            }
        }, ClassReader.SKIP_DEBUG | ClassReader.SKIP_FRAMES);
        return result[0];
    }
}
