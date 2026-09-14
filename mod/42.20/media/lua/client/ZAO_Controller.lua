-- ZAO_Controller - ZAO owns the turned body.
--
-- A body is claimed only when the engine presents it. The pathogen
-- state is read from the store, advanced once per day, and written
-- back to the body. No form is invented from a person id.
--
-- A body the sister never ran still counts (DR-011): the county's
-- preexisting dead get a derived record minted once from where they
-- stand, and from there the same pathogen governs them. A settlement
-- is never placed (DR-006): the controller only notes where turned
-- bodies actually linger, and the rare formation roll is the
-- settlement's own. A recovery is lawful only where the pathogen was
-- still a course - survival never resurrects a dead or turned body.
-- [A33] A reverted body whose person the sister has re-adopted is
-- laid down when her registry says the person stands in the county
-- again: removal, never a kill - the death already ran.

ZAO = ZAO or {}
ZAO.Controller = ZAO.Controller or {}
local Ctl = ZAO.Controller

Ctl.nextScanAt = 0
Ctl.controlled = Ctl.controlled or {}
Ctl.derivedSeq = Ctl.derivedSeq or 0
Ctl.lastReckonDay = nil

local SCAN_INTERVAL = 20
local CONTROL_RADIUS = 30.0

local function log(msg)
    if ZAO.Log and ZAO.Log.line then ZAO.Log.line("CTL", msg) end
end

local function objectList()
    local cell = getCell()
    if not cell then return nil end
    local ok, list = pcall(function() return cell:getObjectListForLua() end)
    if not ok or not list then return nil end
    return list
end

-- The crossed work on the afflicted (g6): a crossed body's target
-- selection prefers the afflicted, whose fear rises through the
-- sister's existing pressure chain. The dead are ignored unless the
-- operator's dial says otherwise.
local function nearestTarget(zx, zy, preferAfflicted, engageDead)
    local best, bestD = nil, nil

    local function consider(target, afflicted)
        if not target then return end
        local ok, d = pcall(function()
            local dx, dy = target:getX() - zx, target:getY() - zy
            return math.sqrt(dx * dx + dy * dy)
        end)
        if ok and d then
            -- The afflicted stand closer in the crossed body's
            -- reckoning; the fear-work does the rest.
            if preferAfflicted and afflicted then d = d * 0.5 end
            if d <= CONTROL_RADIUS and (not bestD or d < bestD) then
                best, bestD = target, d
            end
        end
    end

    if SAO and SAO.Body and SAO.Body.active then
        for id, body in pairs(SAO.Body.active) do
            local rec = SAO.Identity and SAO.Identity.get(id) or nil
            if rec and (not rec.dead or engageDead) then
                local afflicted = false
                if preferAfflicted and ZAO.Pathogen then
                    pcall(function()
                        local state = ZAO.Pathogen.stateOf(id)
                        afflicted = state ~= nil
                            and state.terminalState == "afflicted"
                    end)
                end
                consider(body, afflicted)
            end
        end
    end

    local me = getSpecificPlayer(0)
    if me then consider(me, false) end

    return best
end

local function terminalFromRecord(rec)
    if rec.turnedDormant then return "turned" end
    if rec.dead then return "dead" end
    if rec.knoxInfected then return "infected" end
    return "living"
end

local function ensurePathogenState(personId, rec, day)
    if not (ZAO.Pathogen and ZAO.StateStore) then return nil end

    local saved = ZAO.StateStore.read(personId)
    local recordTerminal = terminalFromRecord(rec)
    local savedTerminal = saved and saved.terminalState or nil
    local livePathogenTerminal =
        savedTerminal == "afflicted" or savedTerminal == "crossed"

    if not saved then
        if recordTerminal ~= "living" then
            return ZAO.Pathogen.begin(
                personId, recordTerminal, day, "body-claim", rec)
        end
        return nil
    end

    if not livePathogenTerminal and savedTerminal ~= recordTerminal
        and recordTerminal ~= "living" then
        ZAO.Pathogen.begin(
            personId, recordTerminal, day, "state-change", rec)
    end

    ZAO.Pathogen.advance(personId, day)
    return ZAO.StateStore.read(personId)
end

-- Where a body stands is a fact (DR-006). A building the county
-- already knows is the place key; the open county falls back to the
-- ground it stands on.
local function placeKeyOf(zombie)
    local x, y = zombie:getX(), zombie:getY()
    local key = nil
    if SAO and SAO.Places and SAO.Places.at then
        pcall(function()
            local place = SAO.Places.at(x, y)
            if place and place.id then
                key = "building-" .. tostring(place.id)
            end
        end)
    end
    if not key then
        key = "open-"
            .. math.floor(tonumber(x) / 10.0)
            .. "-" .. math.floor(tonumber(y) / 10.0)
    end
    return key
end

-- One reckoning per day for every active settlement: necessity
-- follows from what the members need, and what was reckoned persists
-- with the group so a reopened world restores it, never a default.
local function dailyReckon(day)
    if not (ZAO.Settlement and ZAO.StateStore) then return end
    if Ctl.lastReckonDay == day then return end
    Ctl.lastReckonDay = day
    for _, group in ipairs(ZAO.Settlement.active()) do
        ZAO.Settlement.reckon(group.id)
        ZAO.StateStore.writeSettlement(
            group.id, group.place, group.necessity)
    end
end

local function driveForm(zombie, state, target, now, hours)
    local form = state.currentForm
    local performance = tonumber(state.formPerformance) or 0.0
    local terminal = state.terminalState
    local decay = state.decayState
    local attributes = ZAO.Pathogen
        and ZAO.Pathogen.attributeString(state) or ""

    if ZAOJavaBridge then
        pcall(function()
            ZAOJavaBridge:apply(
                zombie, form, performance, terminal, decay, attributes)
        end)
    end

    -- The form's own capability runs first; a committed phase holds
    -- the body where the behavior put it and the walk never fights
    -- the phase.
    local stance = nil
    if ZAO.Behaviors and ZAO.Behaviors.drive then
        pcall(function()
            stance = ZAO.Behaviors.drive(
                zombie, state, target, now, hours)
        end)
    end
    if stance == "hold" then return end
    if not target then return end

    if ZAOJavaBridge then
        pcall(function()
            ZAOJavaBridge:drive(
                zombie, target, form, performance,
                terminal, decay, attributes)
        end)
        return
    end

    pcall(function() zombie:setTarget(target) end)
    pcall(function()
        zombie:setTargetSeenTime(1.0 + performance * 10.0)
    end)

    if form == "Puker" then
        -- Outside any committed phase the Puker keeps its distance;
        -- the capability closes the rest.
        local zx, zy = zombie:getX(), zombie:getY()
        local tx, ty = target:getX(), target:getY()
        local dx, dy = zx - tx, zy - ty
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 0.1 then dx, dy, len = 1, 0, 1 end
        local holdDistance = 5.0 + (1.0 - performance) * 3.0
        local gx = math.floor(tx + dx / len * holdDistance)
        local gy = math.floor(ty + dy / len * holdDistance)
        pcall(function() zombie:pathToLocationF(gx, gy, target:getZ()) end)
    elseif form == "Skitter" then
        -- The low body comes at an angle; the crawler's own speed
        -- and the vanilla crawl bite do the work.
        local tx, ty = target:getX(), target:getY()
        local unit = 0.5
        if SAO.Rand and SAO.Rand.unit then
            pcall(function() unit = SAO.Rand.unit() end)
        end
        local angle = unit * math.pi * 2.0
        local gx = math.floor(tx + math.cos(angle) * 3.0)
        local gy = math.floor(ty + math.sin(angle) * 3.0)
        pcall(function() zombie:pathToLocationF(gx, gy, target:getZ()) end)
    else
        pcall(function() zombie:pathToCharacter(target) end)
    end
end

function Ctl.tick(now)
    local policy = ZAO.Sandbox and ZAO.Sandbox.policy() or nil
    if policy and (not policy.enabled or not policy.controller) then
        return
    end
    if policy and not policy.mind then
        return
    end
    if now < Ctl.nextScanAt then return end
    Ctl.nextScanAt = now + SCAN_INTERVAL

    -- The dials reach the Java side once, before the first use.
    if policy and ZAO.Sandbox and ZAO.Sandbox.pushToBridge then
        pcall(function() ZAO.Sandbox.pushToBridge() end)
    end

    local list = objectList()
    if not list then return end

    local hour = 0
    pcall(function() hour = SAO.History.countyHours() end)
    local day = math.floor((tonumber(hour) or 0) / 24.0)
    local hours = tonumber(hour) or 0.0

    dailyReckon(day)
    if ZAO.Behaviors and ZAO.Behaviors.pulsePuked then
        pcall(function() ZAO.Behaviors.pulsePuked(now, hours) end)
    end

    for i = 1, list:size() do
        local obj = list:get(i - 1)
        local okZombie, isZombie = pcall(function()
            return instanceof(obj, "IsoZombie")
        end)
        if okZombie and isZombie and obj then
            local ok, data = pcall(function() return obj:getModData() end)
            if ok and data and not obj:isDead() then
                local personId, rec = nil, nil
                if data.SAOPersonId then
                    personId = tostring(data.SAOPersonId)
                    rec = SAO.Identity
                        and SAO.Identity.get(personId) or nil
                    -- The sister's record is this body's truth; a
                    -- claimed id with no record is not ours to derive.
                    if not rec then personId = nil end
                else
                    -- The county's own dead (DR-011): a body the
                    -- sister never ran gets one derived record, minted
                    -- once and persisted with the body.
                    if not data.ZAODerivedId then
                        Ctl.derivedSeq = Ctl.derivedSeq + 1
                        data.ZAODerivedId = "derived-"
                            .. tostring(Ctl.derivedSeq)
                            .. "-" .. tostring(math.floor(obj:getX()))
                            .. "-" .. tostring(math.floor(obj:getY()))
                    end
                    personId = tostring(data.ZAODerivedId)
                end

                if personId and ZAO.Pathogen and ZAO.StateStore then
                    data.ZAOOwned = true

                    local state = nil
                    local mind = nil
                    if rec then
                        ensurePathogenState(personId, rec, day)
                        state = ZAO.State.of(rec, hour)
                        mind = ZAO.Mind
                            and ZAO.Mind.of(rec, hour) or nil

                        -- Recovery is lawful only where the pathogen
                        -- was still a course. Survival keeps the state
                        -- the pathogen already changed; it never
                        -- resurrects a dead or turned body.
                        local recovery = nil
                        if not policy or policy.recovery then
                            recovery = ZAO.Recovery
                                and ZAO.Recovery.of(rec) or nil
                            if recovery
                                and (recovery.antibody or recovery.cure)
                                and state.terminalState == "infected" then
                                state.terminalState = "afflicted"
                                state.decayState = "afflicted"
                            end
                        end
                        state.antibody =
                            recovery and recovery.antibody or false
                        state.cure = recovery and recovery.cure or false
                        state.repeatInfections = recovery
                            and recovery.repeatInfections or 0
                        -- The body carries its own recovery facts for
                        -- the Java course to seed from at claim.
                        data.ZAOAntibody = state.antibody
                        data.ZAOCure = state.cure
                        data.ZAORepeatInfections =
                            state.repeatInfections
                    else
                        local saved = ZAO.StateStore.read(personId)
                        if not saved then
                            ZAO.Pathogen.begin(
                                personId, "turned", day, "derived", nil)
                        else
                            ZAO.Pathogen.advance(personId, day)
                        end
                        state = ZAO.Pathogen.stateOf(personId)
                    end

                    -- [A33] The corpse is laid down when the county
                    -- holds the person again. A reverted body whose
                    -- person the sister has re-adopted (a live body
                    -- stands in her registry) is no longer ours to
                    -- drive: the release is a fact-reading, not a
                    -- decision - the same law the sister's return
                    -- follows ([C116]: the pathogen licensed the
                    -- reversion, the adoption followed the state),
                    -- and the laying-down is removal, never a kill -
                    -- the person's death already ran its funnel, and
                    -- no death event fires here. The despawn pair is
                    -- the sister's own idiom (F-008), and her law
                    -- "never removeFromWorld a corpse" holds on her
                    -- side: this is the turned body this repo owns,
                    -- and it goes only because its person stands in
                    -- the county as themselves.
                    local released = false
                    if state and state.terminalState == "afflicted"
                        and SAO.Body and SAO.Body.get(personId) then
                        Ctl.controlled[personId] = nil
                        pcall(function() obj:removeFromWorld() end)
                        pcall(function() obj:removeFromSquare() end)
                        released = true
                        log(personId
                            .. " laid down - the county holds them again")
                    end

                    if state and not released then
                        -- Membership is a formation event or a
                        -- restored one, never a placement. A group
                        -- that no longer holds is left behind.
                        local groupId = state.settlementGroup
                        if groupId and ZAO.Settlement
                            and ZAO.Settlement.groups then
                            local group = ZAO.Settlement.groups[groupId]
                            if group and group.occupied then
                                ZAO.Settlement.join(groupId, personId)
                            else
                                state.settlementGroup = nil
                            end
                        end

                        -- Where turned bodies linger, formation is
                        -- possible. Nothing is placed. The crossed
                        -- linger too ([A32], [MUTATION.md]: some
                        -- crossed groups settle, and which one a
                        -- group does is what its drives did) - the
                        -- same roll, never another placement.
                        if (not policy or policy.settlement)
                            and ZAO.Settlement
                            and (state.terminalState == "turned"
                                or state.terminalState == "crossed") then
                            local formed = ZAO.Settlement.notePresence(
                                placeKeyOf(obj), personId, day)
                            if formed then
                                state.settlementGroup = formed.id
                                ZAO.StateStore.writeSettlement(
                                    formed.id, formed.place,
                                    formed.necessity)
                                log("settlement formed: " .. formed.id)
                            end
                        end

                        Ctl.controlled[personId] = obj

                        data.ZAOForm = state.currentForm
                        data.ZAOFormPerformance = state.formPerformance
                        data.ZAOTerminalState = state.terminalState
                        data.ZAODecayState = state.decayState
                        data.ZAOAttributes = ZAO.Pathogen
                            and ZAO.Pathogen.attributeString(state) or ""

                        if ZAO.StateStore then
                            ZAO.StateStore.write(personId, state)
                        end

                        if mind then
                            data.ZAOMindAggression =
                                mind.disposition.aggression
                            data.ZAOMindNerve = mind.disposition.nerve
                            data.ZAOMindCanMove =
                                mind.execution.canMove
                        end

                        if state.currentForm ~= "none"
                            and (not mind or mind.execution.canMove) then
                            local preferAfflicted =
                                state.terminalState == "crossed"
                            local engageDead = policy ~= nil
                                and policy.crossedEngageDead == true
                            local target = nearestTarget(
                                obj:getX(), obj:getY(),
                                preferAfflicted, engageDead)

                            -- The crossed are executed ([A32]): the
                            -- pass consumes the mind and commits
                            -- deliberate movement; where it commits,
                            -- the ordinary walk stands down for the
                            -- scan. The hunt's ground is stamped as
                            -- plain coordinates so a kin body can
                            -- share the same hunt without any engine
                            -- object crossing bodies.
                            local committed = false
                            if state.terminalState == "crossed"
                                and mind
                                and mind.execution.canMove
                                and ZAO.Crossed
                                and ZAO.Crossed.decide then
                                local okCrossed, didCommit = pcall(
                                    function()
                                        return ZAO.Crossed.decide(
                                            obj, personId, state, mind,
                                            target, now, hours)
                                    end)
                                committed = okCrossed
                                    and didCommit == true
                                if target then
                                    data.ZAOCrossedHuntX = target:getX()
                                    data.ZAOCrossedHuntY = target:getY()
                                else
                                    data.ZAOCrossedHuntX = nil
                                    data.ZAOCrossedHuntY = nil
                                end
                            end

                            if not committed then
                                driveForm(obj, state, target, now, hours)
                            end
                        end
                    end
                end
            end
        end
    end
end

Events.OnTick.Add(function()
    local ok, now = pcall(function() return SAO.Controller.tick() end)
    if ok and now then
        pcall(function() ZAO.Controller.tick(now) end)
    end
end)

return ZAO.Controller