-- ZAO_Controller - ZAO owns turned bodies and drives living Afflicted/Crossed.
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
Ctl.rejectedCrossedBodies = Ctl.rejectedCrossedBodies or {}

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

-- Legacy turned/form pursuit remains an engine-body query. Living Afflicted
-- and Crossed never enter this path; their shared driver reads actor-private
-- Perception through ZAO.Mind.
local function nearestTurnedTarget(source, zx, zy, engageDead)
    local best, bestD = nil, nil
    local seen = {}

    local function consider(target)
        if not target or target == source or seen[target] then return end
        seen[target] = true
        local ok, d = pcall(function()
            local dx, dy = target:getX() - zx, target:getY() - zy
            return math.sqrt(dx * dx + dy * dy)
        end)
        if ok and d then
            if d <= CONTROL_RADIUS and (not bestD or d < bestD) then
                best, bestD = target, d
            end
        end
    end

    if SAO and SAO.Identity and SAO.Body then
        for id, rec in pairs(SAO.Identity.all()) do
            if rec and (not rec.dead or engageDead) then
                id = tostring(id)
                local body = SAO.Body.active and SAO.Body.active[id] or nil
                body = body or SAO.Body.foreign and SAO.Body.foreign[id] or nil
                local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(id) or nil
                -- A Crossed person is kin, never prey. Afflicted remain a
                -- distinct eligible recruit and are handled by Exposure.
                if not state or state.terminalState ~= "crossed" then
                    consider(body)
                end
            end
        end
    end

    local me = getSpecificPlayer(0)
    if me then consider(me) end

    return best
end

local function terminalFromRecord(rec)
    if rec.turnedDormant then return "turned" end
    if rec.dead then return "dead" end
    if rec.knoxInfected then return "infected" end
    return "living"
end

local function ensurePathogenState(personId, rec, day, observedTurned)
    if not (ZAO.Pathogen and ZAO.StateStore) then return nil end

    local saved = ZAO.StateStore.read(personId)
    local recordTerminal = terminalFromRecord(rec)
    if rec.dead and observedTurned then recordTerminal = "turned" end
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
local function placeKeyOf(body)
    local x, y = body:getX(), body:getY()
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

-- Formation records every actual participant, not only whichever body made
-- the final presence observation. Each person's state and the group projection
-- are committed before a later scan or reload can split them apart.
local function persistFormation(group)
    if not (group and ZAO.StateStore and ZAO.Pathogen) then return false end
    for memberId in pairs(group.members or {}) do
        local memberState = ZAO.Pathogen.stateOf(tostring(memberId))
        if memberState and (not group.kind
            or memberState.terminalState == group.kind) then
            memberState.settlementGroup = group.id
            ZAO.StateStore.write(tostring(memberId), memberState)
        end
    end
    return ZAO.StateStore.writeSettlement(group.id,
        group.place, group.necessity)
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

-- Explicit source ownership for the sister's durable return transaction.
-- The native finder verifies loaded identity, independently of scan order.
function Ctl.returnSource(personId)
    if not ZAOJavaBridge then error("return bridge unavailable") end
    return ZAOJavaBridge:findReturnBody(personId)
end

function Ctl.canReturnSource(body)
    return ZAOJavaBridge and ZAOJavaBridge:supportsReturnBody(body) == true
end

function Ctl.returnSourceDormant(personId, body, token)
    local rec = SAO.Identity.get(personId)
    local p = rec and rec.returnTransition
    if not p or p.token ~= token then error("return ownership mismatch") end
    return ZAOJavaBridge:isDormantReturnSource(body) == true
end

function Ctl.holdReturn(personId, body, token)
    local rec = SAO.Identity.get(personId)
    local p = rec and rec.returnTransition
    local event = ZAO.StateStore.returnAuthorization(personId)
    if not p or p.token ~= token or not event or event.token ~= p.event then return false end
    Ctl.controlled[personId] = body
    return ZAOJavaBridge:holdReturnBody(body, personId, token) == true
end

function Ctl.removeReturn(personId, body, token)
    local rec = SAO.Identity.get(personId)
    local p = rec and rec.returnTransition
    if not p or p.token ~= token or not p.packed then return false end
    if ZAOJavaBridge:removeReturnBody(body, personId, token) ~= true then return false end
    Ctl.controlled[personId] = nil
    return true
end

-- The native body holds the saved injuries. ZAO owns the biological event:
-- native lethal Knox flags are cleared, enough aggregate body-part health is
-- restored for a critical but stable life, and the afflicted state remains
-- the authoritative systemic-dormant infection record.
function Ctl.restoreReturnHealth(rec, body, eventToken)
    if not (rec and body and ZAOJavaBridge and ZAO.StateStore) then return false end
    local personId = tostring(rec.id or "")
    local p = rec.returnTransition
    local authorization = ZAO.StateStore.returnAuthorization(personId)
    local state = ZAO.StateStore.read(personId)
    if personId == "" or not p or p.event ~= eventToken
        or not authorization or authorization.token ~= eventToken
        or not state or state.terminalState ~= "afflicted" then
        return false
    end
    local ok, data = pcall(function() return body:getModData() end)
    if not ok or not data or tostring(data.SAOPersonId or "") ~= personId
        or data.SAOReturnToken ~= p.token then return false end
    return ZAOJavaBridge:restoreReturnHealth(body) == true
end

function Ctl.cancelReturn(personId, body, token)
    local rec = SAO.Identity.get(personId)
    local p = rec and rec.returnTransition
    if not p or p.token ~= token or p.sourceRemoved then return false end
    local data = body:getModData()
    if data.ZAOReturnToken == nil then
        if tostring(data.SAOPersonId) ~= personId or Ctl.returnSource(personId) ~= body then return false end
    elseif ZAOJavaBridge:resumeReturnBody(body, personId, token) ~= true then return false end
    Ctl.controlled[personId] = body
    return true
end

-- A living Afflicted or Crossed transition keeps the IsoPlayer shell and all
-- of its equipment. SAO exposes the shell and shared services through
-- Body.foreign; ZAO.Driver is the sole behavioral controller from this point.
function Ctl.acceptExternal(personId, body, token, terminalState)
    personId = tostring(personId or "")
    local rec = SAO and SAO.Identity and SAO.Identity.get(personId) or nil
    if not rec or rec.bodyOwner ~= "ZAO"
        or tostring(rec.bodyOwnerToken or "") ~= tostring(token or "") then
        return false
    end
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(personId) or nil
    local terminal = state and tostring(state.terminalState or "")
        or tostring(terminalState or "")
    if terminal ~= "afflicted" and terminal ~= "crossed" then return false end
    if state and ZAO.Pathogen.ensureDriverToken then
        local driverToken = ZAO.Pathogen.ensureDriverToken(state, personId)
        if driverToken and tostring(driverToken) ~= tostring(token or "") then
            return false
        end
    end
    if body then
        Ctl.controlled[personId] = body
        local data = nil
        pcall(function() data = body:getModData() end)
        if data then
            data.ZAOOwned = true
            data.ZAOTerminalState = terminal
        end
    end
    return true
end

local function externalActivity(personId, body)
    local rec = SAO and SAO.Identity and SAO.Identity.get(personId) or nil
    if rec and rec.worldSourceReservation then return "coordination" end
    local runtime = SAO and SAO.Controller
        and SAO.Controller.coordinationRuntime
        and SAO.Controller.coordinationRuntime[personId] or nil
    if runtime and runtime.coordinationRoute then return "coordination" end
    local data = nil
    if body then pcall(function() data = body:getModData() end) end
    if data and data.ZAOCrossedDriving then return "driving" end
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(personId) or nil
    if ZAO.Driver and ZAO.Driver.currentActivity then
        return ZAO.Driver.currentActivity(personId, body, state)
    end
    return "idle"
end

local executionAdapter = {}

function executionAdapter.bodyFor(personId, rec)
    personId = tostring(personId or "")
    if not rec or rec.bodyOwner ~= "ZAO" or not SAO or not SAO.Body
        or not SAO.Body.foreign then return nil end
    local body = SAO.Body.foreign[personId]
    if not body or Ctl.controlled[personId] ~= body then return nil end
    return body
end

function executionAdapter.snapshot(personId, rec)
    local body = executionAdapter.bodyFor(personId, rec)
    local hour = 0
    pcall(function() hour = SAO.History.countyHours() end)
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(tostring(personId)) or nil
    if state and ZAO.Maintenance and ZAO.Maintenance.advanceState then
        pcall(ZAO.Maintenance.advanceState, state, tonumber(hour) or 0)
    end
    local mind = ZAO.Mind and ZAO.Mind.of(rec, hour, body) or nil
    if ZAO.Driver and ZAO.Driver.snapshot then
        return ZAO.Driver.snapshot(tostring(personId), rec, body, state, mind)
    end
    local canAct = body ~= nil and rec.dead ~= true and mind
        and mind.execution and mind.execution.canMove == true
    return {
        bodyOwner = "ZAO",
        executor = "ZAO.Controller",
        represented = body ~= nil,
        currentActivity = externalActivity(tostring(personId), body),
        canAcquire = canAct == true,
        canCarry = canAct == true,
        canDeliver = canAct == true,
        canExecute = canAct == true,
        incapable = canAct ~= true,
        dead = rec.dead == true,
    }
end

function executionAdapter.advanceDormant(personId, rec, body, elapsedHours,
        atHours)
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(tostring(personId))
        or nil
    if not state or not ZAO.Maintenance
        or not ZAO.Maintenance.advanceDormant then
        return false, "maintenance-owner-unavailable"
    end
    return ZAO.Maintenance.advanceDormant(tostring(personId), state, body,
        elapsedHours, atHours)
end

-- Reception remains with the threatened ZAO person. The state-specific
-- provider decides what follows on its next pass; no private appraisal is
-- returned to the sender.
function executionAdapter.receiveThreat(personId, fromId, threatToken, evidence)
    personId, fromId, threatToken = tostring(personId or ""),
        tostring(fromId or ""), tostring(threatToken or "")
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(personId) or nil
    if not state or (state.terminalState ~= "afflicted"
        and state.terminalState ~= "crossed") then return false, "unanswered" end
    state.driver = type(state.driver) == "table" and state.driver or {}
    local atHours = 0
    pcall(function() atHours = SAO.History.countyHours() end)
    state.driver.receivedThreat = {
        version = 1,
        token = threatToken,
        fromId = fromId,
        receivedAtHours = tonumber(atHours) or 0,
        channel = "spoken",
    }
    if SAO and SAO.Standing and SAO.Standing.setHostile then
        pcall(SAO.Standing.setHostile, personId, fromId, true)
    end
    return true, "received"
end

function executionAdapter.observeThreatResponse(personId, fromId, threatToken)
    personId, fromId, threatToken = tostring(personId or ""),
        tostring(fromId or ""), tostring(threatToken or "")
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(personId) or nil
    local event = state and state.driver and state.driver.receivedThreat or nil
    if not event or tostring(event.token or "") ~= threatToken
        or tostring(event.fromId or "") ~= fromId then return nil end
    local rec = SAO and SAO.Identity and SAO.Identity.get(personId) or nil
    local body = executionAdapter.bodyFor(personId, rec)
    local activity = ZAO.Driver and ZAO.Driver.currentActivity
        and ZAO.Driver.currentActivity(personId, body, state) or "idle"
    local kind = activity == "flee" and "flight"
        or activity == "combat" and "resistance" or nil
    if not kind then return nil end
    local atHours = 0
    pcall(function() atHours = SAO.History.countyHours() end)
    return {
        version = 1,
        token = threatToken,
        personId = personId,
        sourceId = fromId,
        kind = kind,
        activity = activity,
        observedAtHours = tonumber(atHours) or 0,
    }
end

local function registerExecutionAdapter()
    if SAO and SAO.Communication
        and SAO.Communication.registerExecutionOwner then
        SAO.Communication.registerExecutionOwner("ZAO", executionAdapter)
    end
end

-- An identity-bearing IsoZombie is never the living shell retained by a
-- Crossed conversion. Reject it before claim, pathogen advancement,
-- settlement admission, persistence, or deliberate action. This repairs an
-- ownership defect; it does not invent a migration or mortality transition.
local function rejectZAOPersonZombie(personId, rec, returnHeld)
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf
        and ZAO.Pathogen.stateOf(personId) or nil
    local livingZAOState = state and (state.terminalState == "afflicted"
        or state.terminalState == "crossed")
    local rejected = not returnHeld and (rec and rec.bodyOwner == "ZAO"
        or livingZAOState)
    if not rejected then return false end
    Ctl.controlled[personId] = nil
    if not Ctl.rejectedCrossedBodies[personId] then
        Ctl.rejectedCrossedBodies[personId] = true
        log("rejected IsoZombie for living Afflicted/Crossed identity "
            .. personId)
    end
    return true
end

local function processExternalPeople(now, hours, day, policy)
    if not (SAO and SAO.Identity and SAO.Body and ZAO.Pathogen) then return end
    local player = nil
    pcall(function() player = getSpecificPlayer(0) end)
    for personId, rec in pairs(SAO.Identity.all()) do
        if rec.bodyOwner == "ZAO" then
            personId = tostring(personId)
            local state = ZAO.Pathogen.stateOf(personId)
            if state and (state.terminalState == "afflicted"
                or state.terminalState == "crossed") then
                local body = SAO.Body.foreign[personId]
                local deadBody = false
                if body then
                    local dead = false
                    pcall(function() dead = body:isDead() == true end)
                    if dead then
                        deadBody = true
                        if SAO.Controller and SAO.Controller.observeExternalDeath then
                            pcall(function()
                                SAO.Controller.observeExternalDeath(
                                    personId, body, "ZAO")
                            end)
                        end
                        Ctl.controlled[personId] = nil
                        -- A failed hand-back remains in Body.foreign so the
                        -- next tick can retry.  The corpse is never driven.
                        body = nil
                    end
                end
                local distanceToPlayer = nil
                if not deadBody and player then
                    pcall(function()
                        local dx = (body and body:getX() or rec.x) - player:getX()
                        local dy = (body and body:getY() or rec.y) - player:getY()
                        distanceToPlayer = math.sqrt(dx * dx + dy * dy)
                    end)
                end
                if not deadBody and not body and distanceToPlayer
                    and distanceToPlayer <= CONTROL_RADIUS * 2.0 then
                    pcall(function()
                        body = SAO.Body.materializeExternal(rec, "ZAO",
                            rec.bodyOwnerToken)
                    end)
                elseif not deadBody and body and distanceToPlayer
                    and distanceToPlayer > CONTROL_RADIUS * 3.0
                    and SAO.Body.canTransfer(body) then
                    local slept = SAO.Body.hibernateExternal(rec, body, "ZAO",
                        rec.bodyOwnerToken)
                    if slept then
                        Ctl.controlled[personId] = nil
                        body = nil
                    end
                end
                if not deadBody and body then
                    Ctl.controlled[personId] = body
                    pcall(function()
                        rec.x, rec.y, rec.z = body:getX(), body:getY(), body:getZ()
                        local health = tonumber(body:getHealth())
                        if health and health == health and health > 0 then
                            rec.lastLivingHealth = math.max(0,
                                math.min(1, health / 100.0))
                        end
                    end)
                    local data = nil
                    pcall(function() data = body:getModData() end)
                    if data then
                        data.ZAOOwned = true
                        data.ZAOTerminalState = state.terminalState
                        data.ZAOForm = state.currentForm or "none"
                    end
                    if ZAO.Settlement then
                        local groupId = state.settlementGroup
                        local group = groupId and ZAO.Settlement.groups
                            and ZAO.Settlement.groups[groupId] or nil
                        if group and group.occupied then
                            ZAO.Settlement.join(groupId, personId)
                        elseif groupId then
                            state.settlementGroup = nil
                        end
                    end
                    -- ZAO-owned living people acquire their own current sight
                    -- before deliberation. The driver consumes that private
                    -- store; it never receives a controller-wide nearest body.
                    if SAO.Perception and SAO.Perception.observe then
                        pcall(function()
                            SAO.Perception.observe(personId, body, now, false)
                        end)
                    end
                    if ZAO.Maintenance and ZAO.Maintenance.observeLoaded then
                        pcall(ZAO.Maintenance.observeLoaded, personId, state,
                            body, hours)
                    end
                    local mind = ZAO.Mind
                        and ZAO.Mind.of(rec, hours, body) or nil
                    if mind and ZAO.Driver and ZAO.Driver.step then
                        pcall(ZAO.Driver.step, personId, body, state, mind,
                            now, hours)
                    elseif state.terminalState == "crossed" and mind
                        and mind.execution and mind.execution.canMove
                        and ZAO.Crossed and ZAO.Crossed.decide then
                        pcall(ZAO.Crossed.decide, body, personId, state, mind,
                            nil, now, hours)
                    end
                    -- A living ZAO settlement follows a performed holding act,
                    -- not repeated scans of a nearby body. The driver supplies
                    -- the terminal-specific activity evidence after executing
                    -- this scan; formation then records every distinct actor.
                    if ZAO.Settlement and (not policy or policy.settlement)
                        and ZAO.Driver and ZAO.Driver.settlementEvidence then
                        local evidence = ZAO.Driver.settlementEvidence(state)
                        local formed = evidence and ZAO.Settlement.notePresence(
                            placeKeyOf(body), personId, day,
                            state.terminalState, {
                                x = body:getX(), y = body:getY(),
                                z = body:getZ(),
                            }, evidence) or nil
                        if formed then
                            state.settlementGroup = formed.id
                            persistFormation(formed)
                            log(state.terminalState
                                .. " settlement formed: " .. formed.id)
                        end
                    end
                    ZAO.StateStore.write(personId, state)
                else
                    Ctl.controlled[personId] = nil
                end
            end
        end
    end
end

-- Compatibility seam for the A38 probes and saved diagnostic harnesses. The
-- implementation now processes every ZAO-owned living person.
local processExternalCrossed = processExternalPeople

function Ctl.tick(now)
    registerExecutionAdapter()
    if SAO and SAO.AfflictedReturn then SAO.AfflictedReturn.resumePending() end
    if SAO and SAO.CrossedTransfer then SAO.CrossedTransfer.resumePending() end
    if ZAO.Exposure and ZAO.Exposure.resumePending then
        ZAO.Exposure.resumePending()
    end
    if ZAO.Predation and ZAO.Predation.resumePending then
        ZAO.Predation.resumePending()
    end
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

    local hour = 0
    pcall(function() hour = SAO.History.countyHours() end)
    local day = math.floor((tonumber(hour) or 0) / 24.0)
    local hours = tonumber(hour) or 0.0

    dailyReckon(day)
    if ZAO.Behaviors and ZAO.Behaviors.pulsePuked then
        pcall(function() ZAO.Behaviors.pulsePuked(now, hours) end)
    end
    processExternalPeople(now, hours, day, policy)

    local list = objectList()
    if not list then return end

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

                local returnHeld = data.ZAOReturnToken ~= nil
                    or rec and rec.returnTransition ~= nil
                local representationRejected = personId
                    and rejectZAOPersonZombie(personId, rec, returnHeld) or false
                returnHeld = not representationRejected and returnHeld
                if returnHeld and personId then Ctl.controlled[personId] = obj end
                if personId and ZAO.Pathogen and ZAO.StateStore and not returnHeld
                    and not representationRejected then
                    data.ZAOOwned = true

                    local state = nil
                    local mind = nil
                    if rec then
                        ensurePathogenState(personId, rec, day, true)
                        state = ZAO.State.of(rec, hour)
                        mind = ZAO.Mind
                            and ZAO.Mind.of(rec, hour, obj) or nil

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

                    if state then
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
                            and state.terminalState == "turned" then
                            local formed = ZAO.Settlement.notePresence(
                                placeKeyOf(obj), personId, day, "turned", {
                                    x = obj:getX(), y = obj:getY(),
                                    z = obj:getZ(),
                                })
                            if formed then
                                state.settlementGroup = formed.id
                                persistFormation(formed)
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
                            local engageDead = policy ~= nil
                                and policy.crossedEngageDead == true
                            local target = nearestTurnedTarget(
                                obj, obj:getX(), obj:getY(), engageDead)
                            driveForm(obj, state, target, now, hours)
                        end
                    end
                end
            end
        end
    end
end

registerExecutionAdapter()

Events.OnTick.Add(function()
    local ok, now = pcall(function() return SAO.Controller.tick() end)
    if ok and now then
        pcall(function() ZAO.Controller.tick(now) end)
    end
end)

return ZAO.Controller
