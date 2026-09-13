-- ZAO_Behaviors.lua - each form's signature capability, ZAO's own.
--
-- The capability shapes were studied from the mutants mod's public
-- behavior (CREDITS.md); every line here is this project's own
-- re-implementation on public engine APIs. The mutants mod's
-- displacement is animation-driven; ZAO owns no clips, so committed
-- movement phases use the engine's own pathing as the movement
-- substitute, and every engine call is wrapped so a surface that
-- differs across builds degrades to the form's stat block instead
-- of throwing. A form's performance scales every duration, distance,
-- and effect - the gradient is never a switch.

ZAO = ZAO or {}
ZAO.Behaviors = ZAO.Behaviors or {}
local Behaviors = ZAO.Behaviors

-- 60 ticks is about one second at speed one, the engine's own ratio.
local function perf(state)
    return math.max(0.0, math.min(1.0,
        tonumber(state and state.formPerformance) or 0.0))
end

local function ticksScaled(base, performance, span)
    -- Low performance takes longer to commit; high performance is
    -- quicker. span is the total spread across the gradient.
    return math.max(1, math.floor(
        base * (1.0 + (1.0 - performance) * (span or 0.5))))
end

local function distance(ax, ay, az, bx, by, bz)
    local dx, dy = ax - bx, ay - by
    local dz = (az - bz) * 3.0
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function dataOf(zombie)
    local ok, data = pcall(function() return zombie:getModData() end)
    if ok and type(data) == "table" then return data end
    return nil
end

local function hold(zombie)
    -- The movement hold: pathing to where it already stands. The
    -- engine's state machine stays in its own walk/idle loop, so
    -- nothing here fights the vanilla controller.
    pcall(function()
        zombie:pathToLocationF(
            zombie:getX(), zombie:getY(), zombie:getZ())
    end)
end

local function faceTarget(zombie, target)
    pcall(function()
        zombie:faceObject(target)
    end)
end

local function vocal(zombie)
    pcall(function() zombie:playVocals() end)
end

local function worldSound(x, y, z, radius, volume)
    pcall(function()
        getWorldSoundManager():addSound(nil, x, y, z, radius, volume)
    end)
end

local function bumpFall(zombie, target)
    -- The guaranteed knockdown, on the engine's own bump-fall
    -- variables. Whether the body is behind the victim decides the
    -- direction it is pushed.
    pcall(function()
        local behind = false
        pcall(function()
            local dx = zombie:getX() - target:getX()
            local dy = zombie:getY() - target:getY()
            behind = (dx * dx + dy * dy) > 0.0
                and zombie:getDir() ~= target:getDir()
        end)
        target:clearVariable("BumpFallType")
        target:setBumpType("stagger")
        target:setBumpDone(false)
        target:setBumpFall(true)
        target:setBumpedChr(zombie)
        target:setBumpFallType(
            behind and "pushedBehind" or "pushedFront")
        target:reportEvent("wasBumped")
    end)
end

local function crashDamage(zombie, target, performance)
    -- The crash: heavy damage to one or two body parts plus the
    -- knockdown. The engine's injury modifiers apply downstream.
    pcall(function()
        local damage = 45.0 + 15.0 * performance
        local bodyDamage = target:getBodyDamage()
        local parts = bodyDamage:getBodyParts()
        local count = math.min(parts:size(), 2)
        for i = 0, count - 1 do
            local part = parts:get(i)
            if part then part:AddDamage(damage) end
        end
    end)
    bumpFall(zombie, target)
end

local function squareAt(x, y, z)
    local ok, square = pcall(function()
        return getCell():getGridSquare(x, y, z)
    end)
    if ok and square then return square end
    return nil
end

local function destroyFaceThumpable(zombie, square)
    -- Barrier destruction, the project's own pass: a door is broken
    -- outright, a fence is bent or smashed, anything else thumpable
    -- is flattened with a force far past what a body could resist.
    -- Every probe is wrapped; a build whose surface differs falls
    -- back to the plain thump.
    if not square then return end

    pcall(function()
        for i = 0, square:getObjects():size() - 1 do
            local obj = square:getObjects():get(i)
            if obj then
                local broke = false
                pcall(function()
                    if instanceof(obj, "IsoDoor") then
                        obj:setHealth(0)
                        obj:Thump(zombie, 1)
                        broke = true
                    end
                end)
                if not broke then
                    pcall(function()
                        if obj.isBentFence and obj:isBentFence() then
                            obj:smashFence(zombie)
                            broke = true
                        elseif obj.bendFence then
                            obj:bendFence(zombie)
                            broke = true
                        end
                    end)
                end
                if not broke then
                    pcall(function()
                        if obj.Thump then
                            obj:Thump(zombie, 30000)
                            broke = true
                        end
                    end)
                end
                if broke then return end
            end
        end
    end)
end

-- One-time body shaping. The stat block runs on every drive tick, so
-- the one-time actuators carry their own flag.
local function once(data, flag)
    if data[flag] then return false end
    data[flag] = true
    return true
end

local function shapeOnce(zombie, data, state)
    local p = perf(state)
    if data.ZAOForm == "Husk" and once(data, "ZAOHuskShaped") then
        -- The one that does not go down: most of its shaping is the
        -- strength the stat block already carries; the health is
        -- the substance of it.
        pcall(function()
            local health = 2.0 + 4.0 * p
            if zombie:getHealth() < health then
                zombie:setHealth(health)
            end
        end)
    elseif data.ZAOForm == "Skitter"
        and once(data, "ZAOSkitterShaped") then
        -- The low body: crawls, turns hard, dies easy.
        pcall(function()
            zombie:setBecomeCrawler(false)
            zombie:setCanWalk(false)
            zombie:setCrawler(true)
            zombie:setCrawlerType(1)
            zombie:setOnFloor(true)
            zombie:setFallOnFront(true)
            zombie:setHealth(0.4 + 0.8 * p)
        end)
    elseif data.ZAOForm == "Wrecker"
        and once(data, "ZAOWreckerShaped") then
        pcall(function()
            local health = 2.0 + 3.0 * p
            if zombie:getHealth() < health then
                zombie:setHealth(health)
            end
        end)
    elseif data.ZAOForm == "Weeper"
        and once(data, "ZAOWeeperShaped") then
        pcall(function()
            local health = 2.0 + 3.0 * p
            if zombie:getHealth() < health then
                zombie:setHealth(health)
            end
        end)
    end
end

-- The puke's lingering hazard. The registry is runtime: the victim
-- carries the fact, and the pulse below reads it.
Behaviors.puked = Behaviors.puked or {}

local function pukeApply(zombie, target, performance, worldHours)
    if type(target) ~= "userdata" and type(target) ~= "table" then
        return
    end
    local okDirt = false
    pcall(function()
        local visual = target:getVisual()
        for index = 0, 11 do
            pcall(function()
                local part = BloodBodyPartType.FromIndex(index)
                if part then visual:setDirt(part, 0.55 + 0.2 * performance) end
            end)
        end
        okDirt = true
    end)
    if okDirt then
        pcall(function() target:syncVisuals() end)
    end
    Behaviors.puked[target] = {
        untilHours = worldHours + 3.0,
        nextPulseAt = 0,
    }
end

-- The pulse: the victim attracts the dead around them while the puke
-- lasts. Stage values ease down as it fades.
function Behaviors.pulsePuked(now, worldHours)
    for victim, effect in pairs(Behaviors.puked) do
        local ok, alive = pcall(function() return not victim:isDead() end)
        if not ok or not alive
            or worldHours > effect.untilHours then
            Behaviors.puked[victim] = nil
        else
            if now >= effect.nextPulseAt then
                local remaining = effect.untilHours - worldHours
                local radius, volume = 50, 50
                if remaining > 2.25 then
                    radius, volume = 150, 150
                elseif remaining > 1.5 then
                    radius, volume = 115, 115
                elseif remaining > 0.75 then
                    radius, volume = 80, 80
                end
                pcall(function()
                    worldSound(victim:getX(), victim:getY(),
                        victim:getZ(), radius, volume)
                end)
                effect.nextPulseAt = now + 180
            end
        end
    end
end

local function puker(zombie, state, target, now, worldHours)
    local data = dataOf(zombie)
    if not data then return end
    local p = perf(state)
    local zx, zy, zz = zombie:getX(), zombie:getY(), zombie:getZ()
    local tx, ty, tz = target:getX(), target:getY(), target:getZ()
    local dist = distance(zx, zy, zz, tx, ty, tz)

    local phase = data.ZAOPukerPhase
    if not phase then
        if dist > 6.0 then return end
        if now < (tonumber(data.ZAOPukerNextAt) or 0) then return end
        data.ZAOPukerPhase = "windup"
        data.ZAOPukerPhaseEnds = now + ticksScaled(80, p)
        hold(zombie)
        faceTarget(zombie, target)
        vocal(zombie)
        return
    end

    if phase == "windup" then
        hold(zombie)
        faceTarget(zombie, target)
        if now < (tonumber(data.ZAOPukerPhaseEnds) or 0) then return end
        data.ZAOPukerPhase = "release"
        data.ZAOPukerPhaseEnds = now + ticksScaled(60, p)
        data.ZAOPukerNextAt = now + 1800
        faceTarget(zombie, target)
        vocal(zombie)
        if dist <= 8.0 then
            pukeApply(zombie, target, p, worldHours)
            worldSound(tx, ty, tz, 150, 150)
        end
        return
    end

    if phase == "release" then
        hold(zombie)
        if now < (tonumber(data.ZAOPukerPhaseEnds) or 0) then return end
        data.ZAOPukerPhase = "recovery"
        data.ZAOPukerPhaseEnds = now + ticksScaled(40, p)
        return
    end

    -- recovery
    hold(zombie)
    if now >= (tonumber(data.ZAOPukerPhaseEnds) or 0) then
        data.ZAOPukerPhase = nil
        data.ZAOPukerPhaseEnds = nil
    end
end

local function skitter(zombie, state, target, now)
    -- The rush: turn hard, close fast, let the vanilla crawl bite do
    -- the work. The flanking stance is the controller's.
    pcall(function()
        zombie:setTurnDelta(1.0 + 9.0 * perf(state))
    end)
end

local function wrecker(zombie, state, target, now)
    local data = dataOf(zombie)
    if not data then return end
    local p = perf(state)
    local zx, zy, zz = zombie:getX(), zombie:getY(), zombie:getZ()
    local tx, ty, tz = target:getX(), target:getY(), target:getZ()
    local dist = distance(zx, zy, zz, tx, ty, tz)

    local phase = data.ZAOWreckerPhase
    if not phase then
        if dist > 5.0 then return end
        if now < (tonumber(data.ZAOWreckerNextAt) or 0) then return end
        data.ZAOWreckerPhase = "warn"
        data.ZAOWreckerPhaseEnds = now + ticksScaled(90, p)
        hold(zombie)
        faceTarget(zombie, target)
        vocal(zombie)
        return
    end

    if phase == "warn" then
        hold(zombie)
        faceTarget(zombie, target)
        if now < (tonumber(data.ZAOWreckerPhaseEnds) or 0) then return end
        data.ZAOWreckerPhase = "sprint"
        data.ZAOWreckerPhaseEnds = now + ticksScaled(240, p)
        data.ZAOWreckerNextAt = now + 600
        data.ZAOWreckerChargeFromX = zx
        data.ZAOWreckerChargeFromY = zy
        -- The committed line: straight past where the target stands.
        local dx, dy = tx - zx, ty - zy
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 0.1 then dx, dy, len = 1, 0, 1 end
        local reach = 10.0 * (0.6 + 0.4 * p)
        local gx = math.floor(zx + dx / len * reach)
        local gy = math.floor(zy + dy / len * reach)
        pcall(function()
            zombie:pathToLocationF(gx, gy, tz)
        end)
        vocal(zombie)
        return
    end

    if phase == "sprint" then
        local okCrash = false
        pcall(function()
            okCrash = zombie:isCollidedThisFrame()
                or zombie:isCollidedWithVehicle()
        end)

        -- The crash itself: heavy damage and the knockdown on the
        -- body it caught.
        if dist <= 1.5 then
            crashDamage(zombie, target, p)
            data.ZAOWreckerPhase = "crash-recovery"
            data.ZAOWreckerPhaseEnds = now + 30
            pcall(function()
                zombie:setFallOnFront(false)
                zombie:knockDown(false)
            end)
            return
        end

        -- The barrier it ran into: doors break, fences bend and
        -- smash, everything else is flattened.
        if okCrash then
            local faceX, faceY = math.floor(zx), math.floor(zy)
            pcall(function()
                if zombie:isCollidedN() then faceY = faceY - 1
                elseif zombie:isCollidedS() then faceY = faceY + 1
                elseif zombie:isCollidedW() then faceX = faceX - 1
                elseif zombie:isCollidedE() then faceX = faceX + 1
                else faceX, faceY = nil, nil end
            end)
            if faceX then
                destroyFaceThumpable(zombie, squareAt(faceX, faceY, zz))
            end
            data.ZAOWreckerPhase = "crash-recovery"
            data.ZAOWreckerPhaseEnds = now + 30
            pcall(function()
                zombie:setFallOnFront(false)
                zombie:knockDown(false)
            end)
            return
        end

        if now < (tonumber(data.ZAOWreckerPhaseEnds) or 0) then return end
        data.ZAOWreckerPhase = "recovery"
        data.ZAOWreckerPhaseEnds = now + ticksScaled(50, p)
        return
    end

    -- recovery and crash-recovery both stand the body back up
    hold(zombie)
    if now >= (tonumber(data.ZAOWreckerPhaseEnds) or 0) then
        data.ZAOWreckerPhase = nil
        data.ZAOWreckerPhaseEnds = nil
        pcall(function() zombie:setFallOnFront(true) end)
    end
end

local function leaper(zombie, state, target, now)
    local data = dataOf(zombie)
    if not data then return end
    local p = perf(state)
    local zx, zy, zz = zombie:getX(), zombie:getY(), zombie:getZ()
    local tx, ty, tz = target:getX(), target:getY(), target:getZ()
    local dist = distance(zx, zy, zz, tx, ty, tz)

    local phase = data.ZAOLeaperPhase
    if not phase then
        if dist > 3.0 then return end
        local inVehicle = false
        pcall(function() inVehicle = target:getVehicle() ~= nil end)
        if inVehicle then return end
        if now < (tonumber(data.ZAOLeaperNextAt) or 0) then return end
        data.ZAOLeaperPhase = "windup"
        data.ZAOLeaperPhaseEnds = now + ticksScaled(40, p)
        hold(zombie)
        faceTarget(zombie, target)
        vocal(zombie)
        return
    end

    if phase == "windup" then
        hold(zombie)
        faceTarget(zombie, target)
        if now < (tonumber(data.ZAOLeaperPhaseEnds) or 0) then return end
        data.ZAOLeaperPhase = "jump"
        data.ZAOLeaperPhaseEnds = now + ticksScaled(40, p)
        data.ZAOLeaperNextAt = now + 600
        -- The committed leap: straight at and past where the target
        -- stands, the pathing substitute for the airborne lunge.
        local dx, dy = tx - zx, ty - zy
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 0.1 then dx, dy, len = 1, 0, 1 end
        local gx = math.floor(tx + dx / len * 1.5)
        local gy = math.floor(ty + dy / len * 1.5)
        pcall(function()
            zombie:pathToLocationF(gx, gy, tz)
        end)
        return
    end

    if phase == "jump" then
        if dist <= 1.2 then
            bumpFall(zombie, target)
            data.ZAOLeaperPhase = "recovery"
            data.ZAOLeaperPhaseEnds = now + ticksScaled(30, p)
            return
        end
        if now < (tonumber(data.ZAOLeaperPhaseEnds) or 0) then return end
        data.ZAOLeaperPhase = "recovery"
        data.ZAOLeaperPhaseEnds = now + ticksScaled(30, p)
        return
    end

    -- recovery
    hold(zombie)
    if now >= (tonumber(data.ZAOLeaperPhaseEnds) or 0) then
        data.ZAOLeaperPhase = nil
        data.ZAOLeaperPhaseEnds = nil
    end
end

local function weeper(zombie, state, target, now)
    local data = dataOf(zombie)
    if not data then return end
    local p = perf(state)

    local dormant = false
    pcall(function() dormant = zombie:isSitAgainstWall() end)

    if not dormant then
        -- No one to weep for: sit against a wall and wait.
        if not target then
            local square = squareAt(
                math.floor(zombie:getX()),
                math.floor(zombie:getY()),
                math.floor(zombie:getZ()))
            local hasWall = false
            pcall(function()
                hasWall = square ~= nil
                    and square:getWallType() ~= 0
            end)
            if hasWall then
                pcall(function()
                    zombie:setX(math.floor(zombie:getX()) + 0.5)
                    zombie:setY(math.floor(zombie:getY()) + 0.5)
                    zombie:setSitAgainstWall(true)
                end)
                data.ZAOSitter = true
            end
            return
        end
        if data.ZAOSitter then data.ZAOSitter = nil end
        return
    end

    -- Dormant: the cry, when somebody living is close enough to
    -- hear it. Fear is the whole of what the cry does.
    if now < (tonumber(data.ZAOWeeperCryNextAt) or 0) then return end

    local listeners = {}
    local me = getSpecificPlayer(0)
    if me then listeners[#listeners + 1] = me end
    if SAO and SAO.Body and SAO.Body.active then
        for _, body in pairs(SAO.Body.active) do
            listeners[#listeners + 1] = body
        end
    end

    local wept = false
    for _, listener in ipairs(listeners) do
        local ok, alive = pcall(function()
            return not listener:isDead()
        end)
        local dist = 0
        pcall(function()
            dist = distance(
                zombie:getX(), zombie:getY(), zombie:getZ(),
                listener:getX(), listener:getY(), listener:getZ())
        end)
        if ok and alive and dist <= 20.0 then
            local panic = 10.0 * (1.0 - dist / 20.0) * (0.4 + 0.6 * p)
            local seen = true
            pcall(function()
                local square = squareAt(
                    math.floor(zombie:getX()),
                    math.floor(zombie:getY()),
                    math.floor(zombie:getZ()))
                seen = square ~= nil and square:isCouldSee(listener)
            end)
            if not seen then panic = panic * 0.6 end
            pcall(function()
                listener:getBodyDamage():IncreasePanic(panic)
            end)
            wept = true
        end
    end

    if wept then
        vocal(zombie)
        worldSound(zombie:getX(), zombie:getY(), zombie:getZ(), 60, 60)
        local cooldown = 180
        pcall(function() cooldown = ZombRand(180, 301) end)
        data.ZAOWeeperCryNextAt = now + math.floor(
            cooldown * (1.0 + (1.0 - p) * 0.5))
    end
end

-- The drive entry. The controller calls this every scan with the
-- body's state and its current target; each form commits only what
-- its own capability is. The return is the stance the controller
-- should take: "hold" keeps the body where the behavior put it.
function Behaviors.drive(zombie, state, target, now, worldHours)
    local data = dataOf(zombie)
    if not data then return nil end

    shapeOnce(zombie, data, state)

    local form = data.ZAOForm
    if form == "Puker" then
        if target then puker(zombie, state, target, now, worldHours) end
        if data.ZAOPukerPhase then return "hold" end
    elseif form == "Skitter" then
        if target then skitter(zombie, state, target, now) end
    elseif form == "Wrecker" then
        if target or data.ZAOWreckerPhase then
            wrecker(zombie, state, target, now)
        end
        if data.ZAOWreckerPhase then return "hold" end
    elseif form == "Leaper" then
        if target or data.ZAOLeaperPhase then
            leaper(zombie, state, target, now)
        end
        if data.ZAOLeaperPhase then return "hold" end
    elseif form == "Weeper" then
        weeper(zombie, state, target, now)
        if data.ZAOSitter then return "hold" end
    end
    return nil
end

-- The hit surface. One registration, two facts: the Weeper's dormant
-- body is not harmed by the hit that wakes it, and its active body
-- does not take the crit. Nothing else is intercepted.
Events.OnWeaponHitCharacter.Add(function(attacker, hit, weapon)
    local ok, data = pcall(function() return hit:getModData() end)
    if not ok or type(data) ~= "table" then return end
    if data.ZAOOwned ~= true then return end

    if data.ZAOForm == "Weeper" then
        local dormant = false
        pcall(function() dormant = hit:isSitAgainstWall() end)
        if dormant then
            pcall(function() hit:setAvoidDamage(true) end)
            data.ZAOSitter = nil
            pcall(function()
                hit:setSitAgainstWall(false)
                hit:setTarget(attacker)
                hit:pathToCharacter(attacker)
            end)
        else
            pcall(function() hit:setCriticalHit(false) end)
        end
    end
end)

return Behaviors