import java.nio.ByteBuffer;
import java.nio.file.Files;
import java.nio.file.Path;
import se.krka.kahlua.j2se.J2SEPlatform;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import se.krka.kahlua.vm.KahluaTable;
import se.krka.kahlua.vm.KahluaThread;

/** Installed-Kahlua proof for A36's ZAO reconstruction boundary. */
public final class ZAORuntimeReconstructionProbe {
    private static final J2SEPlatform PLATFORM = new J2SEPlatform();
    private static KahluaTable environment;
    private static KahluaThread thread;

    private static Object run(String source) throws Exception {
        return thread.call(LuaCompiler.loadstring(source, "zao-runtime", environment),
            null, null, null);
    }

    private static void load(Path root, String name) throws Exception {
        run(Files.readString(root.resolve(
            "mod/42.20/media/lua/shared/ZAO_" + name + ".lua")));
    }

    private static void initialize(Path root, KahluaTable stores) throws Exception {
        environment = PLATFORM.newEnvironment();
        thread = new KahluaThread(PLATFORM, environment);
        thread.debugOwnerThread = Thread.currentThread();
        zombie.Lua.LuaManager.platform = PLATFORM;
        environment.rawset("_stores", stores == null ? PLATFORM.newTable() : stores);
        run("""
            local function event()
                local slot = { handlers = {} }
                function slot.Add(fn) slot.handlers[#slot.handlers + 1] = fn end
                function slot.Remove(fn)
                    for index = #slot.handlers, 1, -1 do
                        if slot.handlers[index] == fn then table.remove(slot.handlers, index) end
                    end
                end
                function slot.fire()
                    local copy = {}
                    for index, fn in ipairs(slot.handlers) do copy[index] = fn end
                    for _, fn in ipairs(copy) do fn() end
                end
                function slot.count() return #slot.handlers end
                return slot
            end
            Events = { OnGameStart = event() }
            ModData = { getOrCreate = function(key)
                _stores[key] = _stores[key] or {}
                return _stores[key]
            end }
            ZAO = {}
            SAO = { Rand = { unit = function() return 1 end } }
            """);
        load(root, "Settlement");
        load(root, "StateStore");
    }

    private static KahluaTable serialize(KahluaTable source) throws Exception {
        ByteBuffer bytes = ByteBuffer.allocate(4 * 1024 * 1024);
        source.save(bytes);
        bytes.flip();
        KahluaTable restored = PLATFORM.newTable();
        restored.load(bytes, 249);
        return restored;
    }

    public static void main(String[] arguments) throws Exception {
        Path root = Path.of(arguments[0]);
        initialize(root, null);
        run("""
            local store = ModData.getOrCreate('ZombieAwareness_State')
            store.people = { p1 = { personId = 'p1', terminalState = 'afflicted' } }
            store.recovery = { p1 = { repeatInfections = 3 } }
            store.settlements = {
                g1 = { members = { p1 = true }, place = { key = 'first' }, necessity = 0.4 }
            }
            ZAO.Settlement.lingering.old = { currentDay = 4 }
            Events.OnGameStart.fire()
            assert(ZAO.Settlement.groups.g1.members.p1, 'first settlement did not reconstruct')
            assert(ZAO.Settlement.lingering.old == nil, 'formation observation survived rebuild')
            """);
        KahluaTable restored = serialize((KahluaTable) environment.rawget("_stores"));

        initialize(root, restored);
        run("""
            Events.OnGameStart.fire()
            assert(ZAO.Settlement.groups.g1.members.p1, 'serialized settlement did not reconstruct')
            local store = ModData.getOrCreate('ZombieAwareness_State')
            assert(store.people.p1.terminalState == 'afflicted'
                and store.recovery.p1.repeatInfections == 3,
                'durable pathogen/recovery facts changed in serialization')
            """);

        // A module reload replaces the named callback. Then a second world in
        // the same VM must replace, rather than merge, its settlement view.
        load(root, "StateStore");
        run("""
            assert(Events.OnGameStart.count() == 1, 'duplicate settlement callback')
            ZAO.Settlement.lingering.stale = { currentDay = 9 }
            _stores = { ZombieAwareness_State = {
                people = { p2 = { personId = 'p2', terminalState = 'crossed' } },
                recovery = { p2 = { repeatInfections = 1 } },
                settlements = {
                    g2 = { members = { p2 = true }, place = { key = 'second' }, necessity = 0.7 }
                },
                returnSources = { receipt = { personId = 'p2', token = 'keep' } },
            } }
            Events.OnGameStart.fire()
            assert(ZAO.Settlement.groups.g1 == nil, 'prior-world settlement crossed world')
            assert(ZAO.Settlement.groups.g2.members.p2, 'second settlement did not reconstruct')
            assert(ZAO.Settlement.lingering.stale == nil, 'prior-world formation state crossed world')
            assert(_stores.ZombieAwareness_State.returnSources.receipt.token == 'keep',
                'durable return authorization was touched by reconstruction')
            """);
        System.out.println("ZAO_RUNTIME_RECONSTRUCTION_OK");
    }
}
