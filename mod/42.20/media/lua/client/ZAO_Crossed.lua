-- ZAO_Crossed.lua - the crossed are executed through the person's own
-- machinery ([A32], built from the rulings [A11]/[A12] carry).
--
-- The mind is already built (ZAO_Mind.lua): perception, disposition,
-- standing, execution, each scaled by the episodic identity decay the
-- pathogen state carries. What the rulings name and the runtime lacked
-- is the pass that CONSUMES it. A crossed body keeps cognition and
-- every capability ([MUTATION.md]); what is gone is humanity, and the
-- strips are omissions, never gates: nothing here consults trust for a
-- target, nothing protects anybody, and the noise-is-a-debt objection
-- a living person can hold is simply not asked - the crossed take the
-- loudest runner in the yard and consider the dead a tool.
--
-- This pass runs once per scan from the controller, between the mind
-- stamps and the form walk. It commits deliberate movement only:
-- where it returns true the ordinary walk stands down for the scan
-- (a live drive); where it returns nil the hunt continues as it
-- always ran. Every figure below is a named judgment on the engine's
-- own scales, the same law the sister's [B7] cold thresholds follow;
-- play receipts tune them.

ZAO = ZAO or {}
ZAO.Crossed = ZAO.Crossed or {}
local Crossed = ZAO.Crossed

-- The dead are drawn by the engine's own world-sound channel: a
-- shout's worth of volume on a radius the body's aggression sets.
local NOISE_MIN_DIST = 10.0     -- closer than this the walk does the work
local NOISE_VOLUME = 50
local NOISE_COOLDOWN_HOURS = 6.0

local ORGANISE_RADIUS = 15.0   -- kin within this cohere; beyond it they drift

local DRIVE_ORDER_RANGE = 40.0  -- closer than this they walk
local DRIVE_COOLDOWN_HOURS = 24.0
local CLAIM_RADIUS = 15         -- the sister's own re-find circle

local function log(msg)
    if ZAO.Log and ZAO.Log.line then ZAO.Log.line("XED", msg) end
end

local function dataOf(zombie)
    local ok, data = pcall(function() return zombie:getModData() end)
    if ok and type(data) == "table" then return data end
    return nil
end

local function distance(zx, zy, tx, ty)
    local dx, dy = zx - tx, zy - ty
    return math.sqrt(dx * dx + dy * dy)
end

-- The kin a crossed body organises with: other crossed bodies the
-- controller owns, whose person died in the same group or ran in the
-- same unit. The group is the dead person's own fact ([MUTATION.md]
-- standing); no group is invented here.
local function kinOf(personId, group, zx, zy)
    local kin = {}
    local controlled = ZAO.Controller and ZAO.Controller.controlled
        or nil
    if not (controlled and SAO.Identity and SAO.Identity.get) then
        return kin
    end
    for otherId, body in pairs(controlled) do
        if otherId ~= personId and body then
            local okRec, rec = pcall(
                function() return SAO.Identity.get(otherId) end)
            if okRec and rec then
                local okGroup = pcall(function()
                    local otherGroup = rec.diedInGroup
                        or rec.unitId
                    if otherGroup ~= group then return end
                    local state = ZAO.Pathogen and
                        ZAO.Pathogen.stateOf(otherId) or nil
                    if not (state
                        and state.terminalState == "crossed") then
                        return
                    end
                    local d = distance(zx, zy,
                        body:getX(), body:getY())
                    table.insert(kin, {
                        id = otherId, body = body, dist = d,
                    })
                end)
                if not okGroup then
                    pcall(function() return body:getX() end)
                end
            end
        end
    end
    table.sort(kin, function(a, b) return a.dist < b.dist end)
    return kin
end

-- While a drive the crossed ordered is live, the pass ticks it the
-- same way the sister's driver is ticked: one verdict per call, the
-- terminal verdicts end the trip. The Java side owns the loop ([C82]);
-- Lua orders and reads.
local function driveTick(zombie, data, hours)
    if not SAOJavaBridge then
        data.ZAOCrossedDriving = nil
        return false
    end
    local ok, verdict = pcall(function()
        return SAOJavaBridge:tickDrive(zombie)
    end)
    if not ok or verdict == nil then
        data.ZAOCrossedDriving = nil
        return false
    end
    verdict = tostring(verdict)
    if verdict == "Succeeded" then
        data.ZAOCrossedDriving = nil
        data.ZAOCrossedDriveAt = hours
        log("parked at "
            .. string.format("%.1f,%.1f", zombie:getX(), zombie:getY()))
        return false
    end
    if verdict == "IDLE" or verdict:find("DRIVE_", 1, true) then
        data.ZAOCrossedDriving = nil
        data.ZAOCrossedDriveAt = hours
        return false
    end
    return true
end

-- The person's vocabulary, read from the mind's own retained verbs
-- ([A13]: the crossed are the named consumer of the sister's driving
-- map). The map is the sister's half and this is ours: the call is
-- made, and the verdict is honored. A map that will not take a
-- crossed body yet answers NOT_A_SHELL and the body walks - the
-- honest fallback, the same law the sister's own goers follow.
local function tryDrive(zombie, data, mind, gx, gy, hours)
    local verbs = mind.execution.retainedVerbs or {}
    local canDrive = false
    for _, verb in pairs(verbs) do
        if verb == "drive" then canDrive = true end
    end
    if not canDrive then return false end

    local group = mind.standing.group
    local car = nil
    pcall(function()
        car = SAO.Standing.roadworthy(tostring(group or ""), nil)
    end)
    if not car then return false end

    -- [C115]'s dial crosses here for the same reason it crosses in
    -- the sister's order: Java cannot read SandboxVars.
    local sv = SandboxVars and SandboxVars.SurvivorAwareness or nil
    local cap = (sv and tonumber(sv.DriveSpeedCap)) or 30.0

    local ok, verdict = pcall(function()
        return SAOJavaBridge:driveBegin(
            zombie, CLAIM_RADIUS,
            tostring(car.name or "car"),
            math.floor(gx), math.floor(gy), cap)
    end)
    verdict = ok and tostring(verdict) or "no-bridge"
    if verdict:find("DRIVE_STARTED", 1, true) then
        data.ZAOCrossedDriving = true
        log("ordered the " .. tostring(car.name or "car"):gsub("^Base%.", "")
            .. " for " .. tostring(group))
        return true
    end
    if verdict:find("NOT_A_SHELL", 1, true) then
        -- The sister's widening is her half of the seam ([A13]);
        -- named in both records. Until it lands, the crossed walk,
        -- and the decline is logged once per body, never per scan.
        if not data.ZAOCrossedShellDeclined then
            data.ZAOCrossedShellDeclined = true
            log("the map would not take the body - walking")
        end
        data.ZAOCrossedDriveAt = hours
    end
    return false
end

-- One deliberate action per scan, from the mind's own pillars. The
-- hunt is the controller's and continues; what this pass adds is
-- everything a person's drives do with the hunt: gather the dead and
-- point them, share a kin's target, cohere with kin, go home, take
-- the car.
--
-- Returns true when the scan's movement is committed (driveForm
-- stands down); nil otherwise.
function Crossed.decide(zombie, personId, state, mind, target, now, hours)
    if not (zombie and mind and mind.execution) then return nil end
    local data = dataOf(zombie)
    if not data then return nil end

    local disposition = mind.disposition
    local standing = mind.standing

    -- A live drive is ticked and held; nothing fights the wheels.
    if data.ZAOCrossedDriving then
        return driveTick(zombie, data, hours)
    end

    local zx, zy = zombie:getX(), zombie:getY()

    -- Afflicted people are approached through the intentional blood action.
    -- They never fall through to the form/zombie pursuit that can consume a
    -- human target merely because the engine represented the carrier as dead.
    if target and ZAO.Exposure and ZAO.Pathogen then
        local targetId = nil
        pcall(function()
            local tdata = target:getModData()
            targetId = tdata and tdata.SAOPersonId or nil
        end)
        local targetState = targetId and ZAO.Pathogen.stateOf(targetId) or nil
        if targetState and targetState.terminalState == "afflicted" then
            local committed = false
            pcall(function()
                committed = ZAO.Exposure.step(zombie, personId, state,
                    target, targetId, now, hours) == true
            end)
            if not committed then
                pcall(function()
                    zombie:setTarget(nil)
                    zombie:pathToCharacter(target)
                end)
            end
            return true
        end
    end

    -- Use the dead: with a target beyond the walk's reach and the
    -- drives for it, the body shouts on the engine's world-sound
    -- channel and the county's dead come toward it - then the
    -- ordinary pursuit carries them where the body is going
    -- ([MUTATION.md]: a horde is something to point at somebody
    -- else). Decay does the tuning for free: the disposition bars
    -- are already scaled by axis survival.
    if target then
        local dist = nil
        pcall(function()
            dist = distance(zx, zy, target:getX(), target:getY())
        end)
        local lastNoise = tonumber(data.ZAOCrossedNoiseAt) or -999.0
        if dist and dist >= NOISE_MIN_DIST
            and (hours - lastNoise) >= NOISE_COOLDOWN_HOURS
            and (disposition.aggression + disposition.initiative) >= 1.0
            and ZAOJavaBridge then
            local radius = 8 + math.floor(disposition.aggression * 12)
            local ok = false
            pcall(function()
                ok = ZAOJavaBridge:noise(zombie, radius, NOISE_VOLUME)
            end)
            if ok then
                data.ZAOCrossedNoiseAt = hours
                log("gathered the dead, radius " .. tostring(radius))
            end
        end
    end

    -- Work together: a kin's hunt is shared. The kin's target is
    -- stamped by the controller as plain ground coordinates, so no
    -- engine object crosses bodies; the body walks at the same
    -- ground its kin is walking at.
    if not target then
        local kin = kinOf(personId, standing.group, zx, zy)
        for _, entry in ipairs(kin) do
            if entry.dist <= ORGANISE_RADIUS then
                local okK, kdata = pcall(
                    function() return entry.body:getModData() end)
                if okK and kdata and kdata.ZAOCrossedHuntX then
                    pcall(function()
                        zombie:pathToLocationF(
                            math.floor(kdata.ZAOCrossedHuntX),
                            math.floor(kdata.ZAOCrossedHuntY),
                            zombie:getZ())
                    end)
                    return nil
                end
            end
        end

        -- Organise: kin drift. No target, no shared hunt - the body
        -- closes with its own kind.
        for _, entry in ipairs(kin) do
            if entry.dist <= ORGANISE_RADIUS then
                pcall(function()
                    zombie:pathToCharacter(entry.body)
                end)
                return nil
            end
        end

        -- Hold ground: the person's own home is the space they
        -- decided was valuable, and it is a durable fact of the
        -- record. A body with the discipline for it goes home;
        -- where crossed bodies linger (here or anywhere), the
        -- settlement roll is the controller's, and a crossed group
        -- holding a place is the formation the rulings let emerge.
        local record = nil
        pcall(function()
            record = SAO.Identity.get(personId)
        end)
        if record and record.homeX and record.homeY
            and disposition.discipline >= 0.5 then
            local d = distance(zx, zy, record.homeX, record.homeY)
            if d > 3.0 then
                -- The person's vocabulary again: a far home is a
                -- trip, and a body that retains the drive verb and
                -- finds a runner in the dead group's yard takes the
                -- car - with the restraint stripped, the loudest
                -- runner in the pool is simply the one that runs.
                if d >= DRIVE_ORDER_RANGE
                    and (hours - (tonumber(data.ZAOCrossedDriveAt)
                        or -999.0)) >= DRIVE_COOLDOWN_HOURS then
                    local committed = tryDrive(
                        zombie, data, mind, record.homeX, record.homeY,
                        hours)
                    if committed then return true end
                else
                    pcall(function()
                        zombie:pathToLocationF(
                            math.floor(record.homeX),
                            math.floor(record.homeY),
                            zombie:getZ())
                    end)
                end
                return nil
            end
        end
    else
        -- The hunt is on and the target is far: the same vocabulary
        -- serves it. A body that retains the drive verb takes the
        -- car at the target's ground.
        local dist = nil
        pcall(function()
            dist = distance(zx, zy, target:getX(), target:getY())
        end)
        if dist and dist >= DRIVE_ORDER_RANGE
            and (hours - (tonumber(data.ZAOCrossedDriveAt)
                or -999.0)) >= DRIVE_COOLDOWN_HOURS then
            local tx, ty = target:getX(), target:getY()
            return tryDrive(zombie, data, mind, tx, ty, hours)
        end
    end

    return nil
end

return Crossed
