package com.zao.engine;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collections;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.WeakHashMap;
import zombie.MovingObjectUpdateScheduler;
import zombie.ReanimatedPlayers;
import zombie.VirtualZombieManager;
import zombie.ai.states.ZombieIdleState;
import zombie.characters.IsoZombie;
import zombie.inventory.InventoryItem;
import zombie.inventory.types.InventoryContainer;
import zombie.iso.IsoCell;
import zombie.iso.IsoGridSquare;
import zombie.iso.IsoMovingObject;
import zombie.iso.IsoWorld;
import zombie.pathfind.PolygonalMap2;
import zombie.pathfind.nativeCode.PathfindNative;

/**
 * Game-thread-only return transaction support for Build 42.20 / world 249.
 * Lua owns incoming timed-action checks, durable phase and material revalidation.
 * A held body remains identifiable in the zombie list, but leaves update queues.
 * Resume restores saved flags and processing, then restarts idle AI; target/path
 * intents are deliberately recalculated by the owning controller.
 *
 * Installed engine evidence: IsoZombie.removeFromWorld:4265-4300 queues reuse
 * before completing cleanup; VirtualZombieManager.RemoveZombie:796-814;
 * ReanimatedPlayers.removeReanimatedPlayerFromWorld:74-124 preserves live bodies.
 * Neither retention collection has a public terminal-forget method. Reflection
 * only removes this exact transaction body from those two private collections.
 * MovingObjectUpdateScheduler.startFrame:31-55 rebuilds from cell.objectList;
 * removeObject:173-174 removes every scheduling bucket. IsoMovingObject removal
 * is at 720-748. Native APIs remain responsible for their other cleanup.
 */
public final class ZAOReturnBody {
    private static final String TOKEN = "ZAOReturnToken";
    private static final String FLAGS = "ZAOReturnFlags";
    private static final String REMOVING = "ZAOReturnRemoving";
    private static final String REMOVED = "ZAOReturnRemoved";
    private static final int MAX_PENDING = 4096;
    private static final Map<IsoZombie, Pending> PENDING = new IdentityHashMap<>();
    private static final Map<IsoZombie, Pending> COMPLETED = new WeakHashMap<>();
    private static IsoCell pendingCell;
    private static final zombie.ai.State HELD_STATE = new ReturnHeldState();

    private static final class ReturnHeldState extends zombie.ai.State {
        ReturnHeldState() { super(false, false, false, false); }
    }

    private ZAOReturnBody() { }

    public static boolean isAvailable() { return ZAOReturnWeave.isAvailable(); }

    /** Gate new durable transfers; existing tokens still have native guards. */
    public static boolean isSupportedSource(IsoZombie body) {
        return isAvailable() && body != null;
    }

    /** Invoked by native advice without waiting for Lua bridge exposure. */
    public static boolean hasHold(Object value) {
        if (!(value instanceof IsoZombie body) || !body.hasModData()) return false;
        Object token = body.getModData().rawget(TOKEN);
        return token instanceof String text && !text.isBlank();
    }

    /** Native item-removal entry runs after streaming and before item updates. */
    public static void restoreLoadedHolds(Object value) {
        if (!(value instanceof IsoCell loaded) || loaded != IsoWorld.instance.currentCell) return;
        ZAOReturnSourceStore.reconcile(loaded);
        Set<IsoZombie> bodies = Collections.newSetFromMap(new IdentityHashMap<>());
        bodies.addAll(loaded.getZombieList());
        for (IsoMovingObject object : loaded.getObjectList()) if (object instanceof IsoZombie body) bodies.add(body);
        for (IsoMovingObject object : loaded.getAddList()) if (object instanceof IsoZombie body) bodies.add(body);
        for (IsoZombie body : bodies) {
            if (!hasHold(body)) continue;
            Object id = body.getModData().rawget("SAOPersonId");
            Object token = body.getModData().rawget(TOKEN);
            try {
                guardLoadedSource(body);
                if (!(id instanceof String personId)) throw new IllegalStateException("Held source lacks person identity");
                hold(body, personId, (String) token);
            } catch (RuntimeException error) { ZAOReturnSourceStore.automaticFailure(id, error); }
        }
    }

    /** Independent of checkpoint admission: refused bodies still cannot advance. */
    static void guardLoadedSource(IsoZombie body) {
        IsoCell loaded = cell();
        // Drain cargo even if AI reconstruction itself refuses this source.
        for (InventoryItem item : items(body)) loaded.addToProcessItemsRemove(item);
        loaded.getAddList().remove(body);
        if (loaded.isSafeToAdd()) loaded.getObjectList().remove(body);
        else loaded.getRemoveList().add(body);
        var scheduler = MovingObjectUpdateScheduler.instance;
        scheduler.removeObject(body);
        quiesce(body);
    }

    private static final class Pending {
        final String personId, token;
        final IsoCell cell;
        final Set<IsoGridSquare> squares = Collections.newSetFromMap(new IdentityHashMap<>());
        boolean nativeRemoved;
        boolean checkpointDetached;
        boolean nativePreserved;
        Pending(IsoZombie body, String id, String value) {
            personId = id; token = value; cell = cell();
            remember(body);
        }
        void remember(IsoZombie body) {
            if (body.getCurrentSquare() != null) squares.add(body.getCurrentSquare());
            if (body.getLastSquare() != null) squares.add(body.getLastSquare());
            if (body.getSquare() != null) squares.add(body.getSquare());
        }
    }

    private static final class Retention {
        static final Field PRESERVED = field(ReanimatedPlayers.class, "zombies");
        static final Field REUSE = field(VirtualZombieManager.class, "reusedThisFrame");
        private static Field field(Class<?> owner, String name) {
            try {
                Field field = owner.getDeclaredField(name);
                if (field.getType() != ArrayList.class) throw new IllegalStateException("Engine retention type changed");
                field.setAccessible(true);
                return field;
            } catch (ReflectiveOperationException error) {
                throw new IllegalStateException("Unsupported engine retention seam", error);
            }
        }
    }

    private static IsoCell cell() {
        if (IsoWorld.getWorldVersion() != 249) throw new IllegalStateException("Unsupported return world version");
        IsoCell cell = IsoWorld.instance.currentCell;
        if (pendingCell != cell) {
            PENDING.clear(); COMPLETED.clear(); pendingCell = cell;
        }
        if (cell == null) throw new IllegalStateException("No loaded cell; absence cannot be established");
        return cell;
    }

    private static void text(String value) {
        if (value == null || value.isBlank() || value.length() > 256)
            throw new IllegalArgumentException("Invalid return identity/token");
    }

    private static boolean identity(IsoZombie body, String id) {
        return body != null && id.equals(body.getModData().rawget("SAOPersonId"));
    }

    /** Null means no resolved authoritative owner, never proof of world absence. */
    public static IsoZombie find(String personId) {
        ZAOReturnSourceStore.reconcile(cell());
        ZAOReturnSourceStore.requireHealthy(personId);
        IsoZombie loaded = findLoaded(personId);
        if (loaded != null && heldPreserved(loaded) && !PENDING.containsKey(loaded)) {
            Pending pending = new Pending(loaded, personId, (String)loaded.getModData().rawget(TOKEN));
            readFlags(loaded);
            pending.checkpointDetached = true; pending.nativePreserved = true;
            if (PENDING.size() >= MAX_PENDING) throw new IllegalStateException("Pending source owner limit");
            PENDING.put(loaded, pending);
        }
        return loaded == null ? ZAOReturnSourceStore.resolveDetached(personId) : loaded;
    }

    /** Exact checkpoint/native preservation ownership, never a missing-square inference. */
    public static boolean isDormantSource(IsoZombie body) {
        Pending pending = PENDING.get(body);
        return pending != null && pending.cell == cell() && pending.checkpointDetached
            && !pending.nativeRemoved && detachedOwned(body, pending);
    }

    private static boolean heldPreserved(IsoZombie body) {
        return body != null && body.isReanimatedPlayer() && hasHold(body)
            && retention(Retention.PRESERVED, ReanimatedPlayers.instance).contains(body);
    }
    private static boolean detachedOwned(IsoZombie body, Pending pending) {
        return pending.nativePreserved ? heldPreserved(body) : ZAOReturnSourceStore.owns(body);
    }

    static void ownDecoded(IsoZombie body, String id, String token) {
        if (!identity(body, id) || !token.equals(body.getModData().rawget(TOKEN))
                || !ZAOReturnSourceStore.owns(body) || findLoaded(id) != null || PENDING.size() >= MAX_PENDING)
            throw new IllegalStateException("Cannot adopt detached checkpoint source");
        Pending pending = new Pending(body, id, token); pending.checkpointDetached = true;
        PENDING.put(body, pending); quiesce(body);
    }

    static Set<IsoZombie> loadedAndPending() {
        IsoCell cell = cell();
        Set<IsoZombie> candidates = Collections.newSetFromMap(new IdentityHashMap<>());
        candidates.addAll(cell.getZombieList());
        for (IsoZombie body : retention(Retention.PRESERVED, ReanimatedPlayers.instance))
            if (body.isReanimatedPlayer() && body.getModData().rawget("SAOPersonId") instanceof String) candidates.add(body);
        for (IsoMovingObject object : cell.getObjectList()) if (object instanceof IsoZombie body) candidates.add(body);
        for (IsoMovingObject object : cell.getAddList()) if (object instanceof IsoZombie body) candidates.add(body);
        for (var entry : PENDING.entrySet())
            if (entry.getValue().cell == cell && !entry.getValue().nativeRemoved) candidates.add(entry.getKey());
        return candidates;
    }

    static IsoZombie findLoaded(String personId) {
        text(personId);
        IsoZombie result = null;
        for (IsoZombie body : loadedAndPending()) {
            if (!identity(body, personId)) continue;
            if (result != null && result != body) throw new IllegalStateException("Duplicate loaded person body");
            result = body;
        }
        return result;
    }

    /** Returns false while native actions or deferred item/object removal remain. */
    public static boolean hold(IsoZombie body, String personId, String token) {
        text(personId); text(token);
        IsoCell cell = cell();
        // Resolve every unsupported seam before any source mutation.
        retention(Retention.PRESERVED, ReanimatedPlayers.instance);
        retention(Retention.REUSE, VirtualZombieManager.instance);
        if (!identity(body, personId) || body.isDead() || VirtualZombieManager.instance.isReused(body)) return false;
        Object existing = body.getModData().rawget(TOKEN);
        if (existing != null && !token.equals(existing)) return false;
        if (heldPreserved(body)) find(personId); // Rebind exact native persistence ownership first.
        Pending pending = PENDING.get(body);
        if (pending != null && pending.nativePreserved && !heldPreserved(body)) {
            if (body.getCurrentSquare() == null || !cell.getZombieList().contains(body)) return false;
            pending.nativePreserved = false; pending.checkpointDetached = false;
        }
        if (pending != null && (!pending.personId.equals(personId) || !pending.token.equals(token))) return false;
        if (pending == null && PENDING.size() >= MAX_PENDING) return false;
        if (body.getVehicle() != null || body.hasTimedActions()) return false;
        if (find(personId) != body) return false;
        if (existing == null) {
            body.getModData().rawset(FLAGS, flags(body));
            body.getModData().rawset(TOKEN, token);
        } else {
            readFlags(body); // A persisted token without its prior flags is not resumable.
        }
        if (pending == null) {
            pending = new Pending(body, personId, token);
            if (heldPreserved(body)) { pending.nativePreserved = true; pending.checkpointDetached = true; }
            PENDING.put(body, pending);
        }
        if (pending.cell != cell) return false;
        pending.remember(body);
        quiesce(body);
        cell.getAddList().remove(body);
        if (cell.isSafeToAdd()) cell.getObjectList().remove(body);
        else cell.getRemoveList().add(body);
        MovingObjectUpdateScheduler.instance.removeObject(body);
        boolean itemsStopped = true;
        for (InventoryItem item : items(body)) {
            cell.addToProcessItemsRemove(item);
            if (cell.getProcessItems().contains(item)) itemsStopped = false;
        }
        boolean ready = itemsStopped && !cell.getObjectList().contains(body) && !cell.getAddList().contains(body);
        if (ready) ZAOReturnSourceStore.checkpoint(body);
        return ready;
    }

    private static void quiesce(IsoZombie body) {
        body.getStateMachine().setLocked(false);
        body.getStateMachine().changeState(HELD_STATE, List.of(), true);
        body.getStateMachine().setLocked(true);
        // State exit callbacks may alter movement/collision; impose the hold
        // flags after those callbacks have finished.
        body.setUseless(true);
        body.ghost = true;
        body.setIgnoreMovement(true);
        body.setInvulnerable(true);
        body.setCollidable(false);
        body.setShootable(false);
        body.setMoving(false);
        body.setTarget(null);
        body.setThumpTarget(null);
        body.setEatBodyTarget(null, false);
        body.setPath2(null);
        body.getPathFindBehavior2().cancel();
        if (PathfindNative.useNativeCode) PathfindNative.instance.cancelRequest(body);
        else PolygonalMap2.instance.cancelRequest(body);
    }

    /** Only pre-removal refusal can resume. No saved attack/path continuation. */
    public static boolean resume(IsoZombie body, String personId, String token) {
        text(personId); text(token);
        ZAOReturnSourceStore.requireHealthy(personId);
        if (!identity(body, personId) || !token.equals(body.getModData().rawget(TOKEN))
                || body.getModData().rawget(REMOVING) != null || body.isDead()) return false;
        IsoCell cell = cell();
        Pending pending = PENDING.get(body);
        if (VirtualZombieManager.instance.isReused(body) || (pending != null && pending.cell != cell)) return false;
        if (pending != null && pending.checkpointDetached) {
            IsoGridSquare square = cell.getGridSquare((int)Math.floor(body.getX()), (int)Math.floor(body.getY()), (int)Math.floor(body.getZ()));
            if (square == null) return false;
            if (!detachedOwned(body, pending)) return false;
            body.setCurrent(square); body.setMovingSquare(square);
            if (!square.getMovingObjects().contains(body)) square.getMovingObjects().add(body);
            if (!cell.getZombieList().contains(body)) cell.getZombieList().add(body);
            if (pending.nativePreserved) retention(Retention.PRESERVED, ReanimatedPlayers.instance).remove(body);
            pending.nativePreserved = false;
            pending.checkpointDetached = false;
        }
        String flags = readFlags(body);
        body.getStateMachine().setLocked(false);
        body.getStateMachine().changeState(ZombieIdleState.instance(), List.of(), true);
        body.setUseless(flags.charAt(0) == '1'); body.ghost = flags.charAt(1) == '1';
        body.setIgnoreMovement(flags.charAt(2) == '1'); body.setInvulnerable(flags.charAt(3) == '1');
        body.setCollidable(flags.charAt(4) == '1'); body.setShootable(flags.charAt(5) == '1');
        cell.getRemoveList().remove(body);
        if (cell.isSafeToAdd()) cell.getObjectList().add(body); else cell.getAddList().add(body);
        for (InventoryItem item : items(body)) cell.addToProcessItems(item);
        ZAOReturnSourceStore.resumed(body);
        body.getModData().rawset(TOKEN, null); body.getModData().rawset(FLAGS, null);
        PENDING.remove(body);
        return true;
    }

    /** A false result retains the same source incarnation for a later retry. */
    public static boolean remove(IsoZombie body, String personId, String token) {
        return removePhysical(body, personId, token, true);
    }

    static boolean detachForStreaming(IsoZombie body) {
        String id = (String)body.getModData().rawget("SAOPersonId");
        String token = (String)body.getModData().rawget(TOKEN);
        return removePhysical(body, id, token, false);
    }

    private static boolean removePhysical(IsoZombie body, String personId, String token, boolean terminal) {
        text(personId); text(token);
        if (!identity(body, personId) || !token.equals(body.getModData().rawget(TOKEN))
                || VirtualZombieManager.instance.isReused(body)) return false;
        if (token.equals(body.getModData().rawget(REMOVED))) return absent(body, COMPLETED.get(body));
        if (!hold(body, personId, token)) return false;
        Pending pending = PENDING.get(body);
        body.getModData().rawset(REMOVING, token);
        boolean completed = false;
        try {
            if (pending.checkpointDetached) {
                if (!detachedOwned(body, pending)) return false;
                detachDecoded(body);
            } else {
                body.getEmitter().unregister();
                body.removeFromWorld();
                body.removeFromSquare();
            }
            completed = true;
        } catch (RuntimeException error) {
            // Native cleanup may have enqueued reuse before throwing. Never let
            // the manager reset this incarnation while the transaction retries.
            return false;
        } finally {
            quarantine(body);
            // A live reanimated body in zombieList is included by the native
            // reanimated.bin writer even when physical cleanup already removed
            // every update/square owner. Keep failed attempts saveable.
            if (!completed) preserveFailedSource(body, pending);
        }
        if (!completed || !absent(body, pending)) {
            preserveFailedSource(body, pending);
            return false;
        }
        pending.nativeRemoved = true;
        if (terminal) ZAOReturnSourceStore.retired(body);
        else ZAOReturnSourceStore.dormant(body);
        body.getModData().rawset(REMOVED, token);
        COMPLETED.put(body, pending);
        PENDING.remove(body);
        return true;
    }

    /** Unpublished native decoder objects never enter renderer or live AI.
     * Remove constructor/load registrations and any discarded loaded cargo.
     */
    static void detachDecoded(IsoZombie body) {
        IsoCell cell = cell();
        body.getEmitter().unregister();
        cell.getZombieList().remove(body); cell.getObjectList().remove(body);
        cell.getAddList().remove(body); cell.getRemoveList().remove(body);
        MovingObjectUpdateScheduler.instance.removeObject(body);
        stopSourceItems(body);
        body.removeFromSquare();
        quarantine(body);
        PENDING.remove(body);
    }

    static void stopSourceItems(IsoZombie body) {
        IsoCell cell = cell();
        for (InventoryItem item : items(body)) {
            cell.getProcessItems().remove(item); cell.getProcessItemsRemove().remove(item);
        }
    }

    private static void preserveFailedSource(IsoZombie body, Pending pending) {
        if (body.isReanimatedPlayer() && !body.isDead()
                && !pending.cell.getZombieList().contains(body)) {
            pending.cell.getZombieList().add(body);
        }
    }

    private static void quarantine(IsoZombie body) {
        retention(Retention.PRESERVED, ReanimatedPlayers.instance).removeIf(value -> value == body);
        retention(Retention.REUSE, VirtualZombieManager.instance).removeIf(value -> value == body);
    }

    private static boolean absent(IsoZombie body, Pending pending) {
        if (pending == null || pending.cell != cell()) return false;
        IsoCell cell = pending.cell;
        if (cell.getZombieList().contains(body) || cell.getObjectList().contains(body)
                || cell.getAddList().contains(body) || body.getCurrentSquare() != null) return false;
        for (IsoGridSquare square : pending.squares)
            if (square.getMovingObjects().contains(body) || square.getStaticMovingObjects().contains(body)) return false;
        if (retention(Retention.PRESERVED, ReanimatedPlayers.instance).contains(body)
                || retention(Retention.REUSE, VirtualZombieManager.instance).contains(body)) return false;
        MovingObjectUpdateScheduler.instance.removeObject(body);
        for (InventoryItem item : items(body)) if (cell.getProcessItems().contains(item)) return false;
        return true;
    }

    @SuppressWarnings("unchecked")
    private static List<IsoZombie> retention(Field field, Object owner) {
        try { return (List<IsoZombie>) field.get(owner); }
        catch (IllegalAccessException error) { throw new IllegalStateException("Engine retention inaccessible", error); }
    }

    private static String flags(IsoZombie body) {
        return "" + bit(body.isUseless()) + bit(body.ghost) + bit(body.getIgnoreMovement())
                + bit(body.isInvulnerable()) + bit(body.isCollidable()) + bit(body.isShootable());
    }
    private static char bit(boolean value) { return value ? '1' : '0'; }
    private static String readFlags(IsoZombie body) {
        Object value = body.getModData().rawget(FLAGS);
        if (!(value instanceof String flags) || !flags.matches("[01]{6}"))
            throw new IllegalStateException("Missing durable return hold flags");
        return flags;
    }

    /** Identity union includes equipment which vanilla keeps outside inventory. */
    private static Set<InventoryItem> items(IsoZombie body) {
        Set<InventoryItem> result = Collections.newSetFromMap(new IdentityHashMap<>());
        for (InventoryItem item : body.getInventory().getItems()) collect(item, result);
        collect(body.getPrimaryHandItem(), result); collect(body.getSecondaryHandItem(), result);
        for (int i = 0; i < body.getWornItems().size(); i++) collect(body.getWornItems().get(i).getItem(), result);
        for (int i = 0; i < body.getAttachedItems().size(); i++) collect(body.getAttachedItems().get(i).getItem(), result);
        return result;
    }
    private static void collect(InventoryItem item, Set<InventoryItem> result) {
        if (item == null || !result.add(item)) return;
        if (result.size() > 10000) throw new IllegalStateException("Return inventory exceeds bound");
        if (item instanceof InventoryContainer bag)
            for (InventoryItem child : bag.getInventory().getItems()) collect(child, result);
    }
}
