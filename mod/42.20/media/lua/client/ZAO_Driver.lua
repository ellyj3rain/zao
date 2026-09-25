-- ZAO_Driver - one execution owner for Afflicted and Crossed people.
--
-- Pathogen state selects a policy; it never selects a different controller.
-- SAO still owns identity, communication, source use, handover and locomotion
-- services. This module decides when a ZAO-owned person invokes those services
-- and records current work in ZAO's durable state so body handoff and reload do
-- not turn a missing runtime handle into idleness or completion.

ZAO = ZAO or {}
ZAO.Driver = ZAO.Driver or {}
local Driver = ZAO.Driver

local function dataOf(body)
    local data = nil
    if body then pcall(function() data = body:getModData() end) end
    return type(data) == "table" and data or nil
end

local function rowOf(state)
    state.driver = type(state.driver) == "table" and state.driver or {
        version = 1, revision = 0, currentActivity = "idle",
    }
    state.driver.version = 1
    return state.driver
end

local function rootStore()
    local root = ZAO.StateStore and ZAO.StateStore.store() or nil
    if not root then return nil end
    root.driverResults = root.driverResults or {}
    return root
end

local function personalSourceReservation(personId)
    if not (SAO and SAO.WorldSources
        and SAO.WorldSources.pendingActionFor) then return nil end
    local reservation = SAO.WorldSources.pendingActionFor(tostring(personId))
    if reservation and not reservation.unavailable
        and tostring(reservation.nativeUseOwner or "") == "ZAO.Diet" then
        return reservation
    end
    return nil
end

local function sourceActivity(reservation)
    local phase = reservation and tostring(reservation.phase or "") or ""
    if phase == "using" or phase == "native-complete" then return "feeding" end
    return "acquiring-food"
end

local function routeToken(personId, kind)
    local root = rootStore()
    if not root then return nil end
    root.driverSequence = (tonumber(root.driverSequence) or 0) + 1
    return "zao-route:" .. tostring(personId) .. ":" .. tostring(kind)
        .. ":" .. tostring(root.driverSequence)
end

local function finishRoute(personId, state, route, outcome, reason, hours)
    local root = rootStore()
    if root and route and route.token and not root.driverResults[route.token] then
        root.driverResults[route.token] = {
            version = 1,
            token = route.token,
            personId = tostring(personId),
            kind = route.kind,
            targetId = route.targetId,
            x = route.x, y = route.y, z = route.z,
            outcome = tostring(outcome or "interrupted"),
            reason = reason and tostring(reason) or nil,
            startedAtHours = route.startedAtHours,
            resolvedAtHours = tonumber(hours) or 0,
        }
    end
    if SAO and SAO.Locomotion then
        pcall(SAO.Locomotion.cancel, tostring(personId))
    end
    if state and state.driver and state.driver.route == route then
        state.driver.route = nil
    end
    return false, outcome, reason
end

-- One durable route shape is shared by Afflicted and Crossed policies. The
-- destination is selected by the state policy; the native SAO locomotion owner
-- performs it. A disposable locomotion job can be reconstructed from this row
-- after body handoff or reload, while the terminal receipt is minted once.
function Driver.routeTo(personId, body, state, kind, targetId,
        x, y, z, running, hours)
    if not (body and type(state) == "table" and SAO and SAO.Locomotion) then
        return false, "unavailable"
    end
    personId, kind = tostring(personId), tostring(kind or "move")
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not (x and y and z) then return false, "invalid-destination" end
    local row = rowOf(state)
    local route = row.route
    local same = route and route.kind == kind
        and tostring(route.targetId or "") == tostring(targetId or "")
        and math.abs((tonumber(route.x) or x) - x) <= 2.0
        and math.abs((tonumber(route.y) or y) - y) <= 2.0
        and (tonumber(route.z) or z) == z
    if route and not same then
        finishRoute(personId, state, route, "interrupted",
            "superseded-by-" .. kind, hours)
        route = nil
    end
    if not route then
        route = {
            version = 1,
            token = routeToken(personId, kind),
            kind = kind,
            targetId = targetId and tostring(targetId) or nil,
            x = x, y = y, z = z,
            running = running == true,
            startedAtHours = tonumber(hours) or 0,
        }
        row.route = route
    else
        route.x, route.y, route.z = x, y, z
        route.updatedAtHours = tonumber(hours) or 0
    end

    local job = SAO.Locomotion.jobs and SAO.Locomotion.jobs[personId] or nil
    if not job and not SAO.Locomotion.order(personId, body,
        route.x, route.y, route.z, route.running) then
        return finishRoute(personId, state, route, "failed",
            "native-route-refused", hours)
    end
    SAO.Locomotion.tick(personId)
    local status = tostring(SAO.Locomotion.status(personId) or "none")
    if string.sub(status, 1, 5) == "done:" then
        local result = string.sub(status, 6)
        local outcome = result == "arrived" and "completed" or "failed"
        return finishRoute(personId, state, route, outcome, result, hours)
    end
    return true, "moving", route
end

function Driver.cancelRoute(personId, state, reason, hours)
    local route = state and state.driver and state.driver.route or nil
    if not route then return false, "none" end
    return finishRoute(tostring(personId), state, route, "interrupted",
        reason or "policy-changed", hours)
end

function Driver.setActivity(state, activity, detail, hours, workRef)
    if type(state) ~= "table" then return nil end
    local row = rowOf(state)
    activity = string.lower(tostring(activity or "idle"))
    detail = detail and tostring(detail) or nil
    workRef = workRef and tostring(workRef) or nil
    if row.currentActivity ~= activity or row.detail ~= detail
        or row.workRef ~= workRef then
        row.revision = (tonumber(row.revision) or 0) + 1
        row.currentActivity = activity
        row.detail = detail
        row.workRef = workRef
        row.sinceHours = tonumber(hours) or row.sinceHours or 0
    end
    row.updatedAtHours = tonumber(hours) or row.updatedAtHours or 0
    return row
end

function Driver.currentActivity(personId, body, state)
    local personalSource = personalSourceReservation(personId)
    if personalSource then return sourceActivity(personalSource) end
    local rec = SAO and SAO.Identity and SAO.Identity.get(personId) or nil
    if rec and rec.worldSourceReservation then return "coordination" end
    local runtime = SAO and SAO.Controller
        and SAO.Controller.coordinationRuntime
        and SAO.Controller.coordinationRuntime[tostring(personId)] or nil
    if runtime and runtime.coordinationRoute then return "coordination" end
    local data = dataOf(body)
    if data and data.ZAOCrossedDriving then return "driving" end
    local exposure = ZAO.Exposure and ZAO.Exposure.activeFor
        and ZAO.Exposure.activeFor(personId) or nil
    if exposure then return "exposure" end
    local row = type(state) == "table" and state.driver or nil
    return row and tostring(row.currentActivity or "idle") or "idle"
end

local function stateOptions(personId, body, state, mind, now, hours)
    if not state then return {} end
    local provider = state.terminalState == "afflicted" and ZAO.Afflicted
        or state.terminalState == "crossed" and ZAO.Crossed or nil
    if not (provider and type(provider.options) == "function") then return {} end
    local ok, options = pcall(provider.options, body, personId, state, mind,
        now, hours)
    return ok and type(options) == "table" and options or {}
end

-- One arbitration rule orders options from either living state. Providers
-- describe state-specific opportunities and executors; they do not install a
-- second controller. Stable ids break equal scores so table iteration cannot
-- become personality.
function Driver.chooseOption(options)
    local best = nil
    for _, option in ipairs(type(options) == "table" and options or {}) do
        local score = type(option) == "table" and tonumber(option.score) or nil
        local id = type(option) == "table" and tostring(option.id or "") or ""
        if score and score == score and id ~= ""
            and (not best or score > best.score
                or score == best.score and id < tostring(best.id)) then
            option.score = score
            best = option
        end
    end
    return best
end

function Driver.intent(personId, body, state, mind, now, hours)
    local option = Driver.chooseOption(stateOptions(personId, body, state, mind,
        now, hours))
    if not option then return "idle", nil, nil end
    return tostring(option.activity or option.id), option.detail, option
end

function Driver.snapshot(personId, rec, body, state, mind)
    local terminal = state and tostring(state.terminalState or "") or "unknown"
    -- Representation is an execution prerequisite, not a person's retained
    -- capability. A dormant person may accept or refuse responsibility; the
    -- native work owner still waits for a body before performing anything.
    local canAct = body ~= nil and rec and rec.dead ~= true and mind
        and mind.execution and mind.execution.canMove == true
    local activity = Driver.currentActivity(personId, body, state)
    local physical = mind and mind.physical or nil
    local competingPressure = nil
    local competingPressureOwner = "unrepresented"
    if type(physical) == "table" then
        competingPressure = math.max(tonumber(physical.hunger) or 0,
            tonumber(physical.thirst) or 0,
            tonumber(physical.fatigue) or 0)
        competingPressureOwner = "SAO.Needs via ZAO.Mind"
    elseif state and state.driver
        and type(state.driver.settlementPressure) == "table" then
        competingPressure = tonumber(state.driver.settlementPressure.value)
        if competingPressure ~= nil then
            competingPressureOwner = "ZAO.Driver.settlementPressure<-SAO.Needs"
        end
    end
    if terminal == "crossed" and ZAO.Maintenance
        and ZAO.Maintenance.predatoryPressure then
        local predatory = ZAO.Maintenance.predatoryPressure(state,
            state and state.driver and state.driver.updatedAtHours or nil)
        if predatory ~= nil and (competingPressure == nil
            or predatory > competingPressure) then
            competingPressure = predatory
            competingPressureOwner = "ZAO.Maintenance.predatoryPressure"
        end
    end
    return {
        bodyOwner = "ZAO",
        executor = "ZAO.Driver",
        terminalState = terminal,
        represented = body ~= nil,
        currentActivity = activity,
        canAcquire = canAct == true,
        canCarry = canAct == true,
        canDeliver = canAct == true,
        canExecute = canAct == true,
        incapable = canAct ~= true,
        dead = rec and rec.dead == true or false,
        competingPressure = competingPressure,
        competingPressureAvailable = competingPressure ~= nil,
        inputOwners = {
            currentActivity = "ZAO.Driver",
            capabilities = "ZAO.Mind",
            terminalState = "ZAO.Pathogen",
            competingPressure = competingPressureOwner,
        },
    }
end

local SETTLEMENT_ACTIVITY = {
    afflicted = {
        gathered = true,
        ["holding-place"] = true,
        ["settling-ground"] = true,
    },
    crossed = {
        ["holding-with-kin"] = true,
        ["holding-home"] = true,
    },
}

-- Formation observes a state-specific act of holding ground, not mere body
-- proximity. This evidence is deliberately narrower than the full activity
-- vocabulary: travel toward a peer or home is not arrival, and idleness is not
-- assent to a settlement.
function Driver.settlementEvidence(state)
    if type(state) ~= "table" then return nil end
    local terminal = tostring(state.terminalState or "")
    local row = type(state.driver) == "table" and state.driver or nil
    local activity = row and tostring(row.currentActivity or "") or ""
    if not (SETTLEMENT_ACTIVITY[terminal]
        and SETTLEMENT_ACTIVITY[terminal][activity]) then return nil end
    return {
        version = 1,
        terminalState = terminal,
        activity = activity,
        activityRevision = tonumber(row.revision) or 0,
        sinceHours = tonumber(row.sinceHours),
        observedAtHours = tonumber(row.updatedAtHours),
    }
end

local function clamp01(value)
    value = tonumber(value) or 0
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

-- Necessity is read through the ZAO owner. Hunger is a physical pressure on
-- both living bodies; admitting it does not decide what either state eats.
-- State policy owns possible satisfiers. A dormant member retains its last
-- observed pressure instead of being silently treated as healthy.
function Driver.settlementPressure(personId, body, state)
    if type(state) ~= "table" then return nil end
    local terminal = tostring(state.terminalState or "")
    if terminal ~= "afflicted" and terminal ~= "crossed" then return nil end
    local row = rowOf(state)
    if not body then
        local prior = type(row.settlementPressure) == "table"
            and row.settlementPressure or nil
        return prior and tonumber(prior.value) or nil, prior
    end

    local needs = nil
    if SAO and SAO.Needs and SAO.Needs.read then
        pcall(function() needs = SAO.Needs.read(body) end)
    end
    local thirst = clamp01(needs and needs.thirst or 0)
    local fatigue = clamp01(needs and needs.fatigue or 0)
    local bleeding = 0
    if SAO and SAO.Needs and SAO.Needs.bleeding then
        pcall(function() bleeding = tonumber(SAO.Needs.bleeding(body)) or 0 end)
    end
    local injury = clamp01(bleeding * 0.25)
    local hunger = clamp01(needs and needs.hunger or 0)
    local value = math.max(thirst, fatigue, injury, hunger)
    local evidence = {
        version = 1,
        value = value,
        terminalState = terminal,
        thirst = thirst,
        fatigue = fatigue,
        injury = injury,
        hunger = hunger,
        satisfierOwner = terminal == "crossed" and "ZAO.Crossed"
            or "ZAO.Afflicted",
        observedAtHours = tonumber(row.updatedAtHours),
    }
    row.settlementPressure = evidence
    return value, evidence
end

local function queuedNativeAction(body)
    local queue = ISTimedActionQueue and ISTimedActionQueue.queues
        and ISTimedActionQueue.queues[body] or nil
    return queue and type(queue.queue) == "table" and #queue.queue > 0
end

local SOURCE_INTERRUPTER = {
    flee = true,
    combat = true,
    ["predation-active"] = true,
    ["exposure-active"] = true,
}

local function sourceInterrupter(options)
    local best = nil
    for _, option in ipairs(type(options) == "table" and options or {}) do
        local kind = type(option) == "table" and tostring(option.kind or "")
            or ""
        if SOURCE_INTERRUPTER[kind]
            and (not best or (tonumber(option.score) or 0)
                > (tonumber(best.score) or 0)) then
            best = option
        end
    end
    return best
end

-- A personal food action is still a SourceUse action: that owner advances the
-- exact route, transfer and receipt.  The shared ZAO driver only serializes it
-- against this person's other chosen behavior and reports current activity.
local function advancePersonalSource(personId, body, reservation)
    if not (SAO and SAO.SourceUse and SAO.Locomotion) then
        return false, "source-owner-unavailable"
    end
    local phase = tostring(reservation.phase or "")
    if phase == "approaching-place" or phase == "approaching-source" then
        SAO.Locomotion.tick(personId)
        local status = tostring(SAO.Locomotion.status(personId) or "none")
        if string.sub(status, 1, 5) ~= "done:" then
            return true, "acquiring-food"
        end
        local verdict = SAO.SourceUse.onMovementDone(personId, body, status)
        if verdict == "moving" or verdict == "using" then
            return true, "acquiring-food"
        end
        return false, "food-source-" .. tostring(verdict)
    end
    if phase == "transferring" or phase == "using"
        or phase == "native-complete" then
        local verdict = SAO.SourceUse.tick(personId, body)
        if verdict == "pending" then
            return true, sourceActivity(reservation)
        end
        return false, "food-source-" .. tostring(verdict)
    end
    SAO.SourceUse.interrupt(personId, body, "invalid-personal-source-phase")
    return false, "food-source-invalid"
end

local function endRest(body, row)
    if not row.resting then return end
    row.resting = nil
    pcall(function() SAOJavaBridge:setShellAsleep(body, false) end)
    pcall(function() body:setSitOnGround(false) end)
    if SAO and SAO.Gesture and SAO.Gesture.standUp then
        pcall(SAO.Gesture.standUp, body)
    end
end

local function continueRest(body, row, needs, hours)
    local cold = 0
    if SAO and SAO.Needs and SAO.Needs.cold then
        pcall(function() cold = tonumber(SAO.Needs.cold(body)) or 0 end)
    end
    if cold >= 1.5 or not needs or (tonumber(needs.fatigue) or 0) <= 0.2 then
        endRest(body, row)
        return false
    end
    pcall(function() body:setSitOnGround(true) end)
    pcall(function() SAOJavaBridge:setShellAsleep(body, true) end)
    local prior = tonumber(row.lastRestHours) or tonumber(hours) or 0
    local delta = math.max(0, (tonumber(hours) or prior) - prior)
    row.lastRestHours = tonumber(hours) or prior
    if delta > 0 then
        pcall(function() SAOJavaBridge:restRecoverTick(body, delta) end)
    end
    return true
end

-- Both living ZAO states retain water, fatigue and wound constraints. These
-- helpers expose native maintenance as options under their shared driver;
-- state-specific food and motivation remain with Diet/Afflicted/Crossed.
function Driver.humanPhysiologyOptions(personId, body, state, mind, hours)
    if not (body and type(state) == "table" and mind) then return {} end
    local row = rowOf(state)
    local rec = SAO and SAO.Identity and SAO.Identity.get(personId) or nil
    if rec and SAO.PhysicalFacts and SAO.PhysicalFacts.refreshBodyFacts then
        pcall(SAO.PhysicalFacts.refreshBodyFacts, rec, body, hours)
    end
    local needs = SAO and SAO.Needs and SAO.Needs.read
        and SAO.Needs.read(body) or nil

    local options = {}
    local prefix = tostring(state.terminalState or "zao")
    local preservation = mind and mind.disposition
        and tonumber(mind.disposition.selfPreservation) or 0
    local discipline = mind and mind.disposition
        and tonumber(mind.disposition.discipline) or 0
    if row.resting then
        options[#options + 1] = {
            id = prefix .. ":body:resting", kind = "body-rest-active",
            activity = "resting", score = 970, interruptsWork = true,
            owner = "ZAO.Driver.humanPhysiology",
            detail = "continuing chosen bodily rest",
        }
    end

    local bleeding = SAO and SAO.Needs and SAO.Needs.bleeding
        and tonumber(SAO.Needs.bleeding(body)) or 0
    if bleeding > 0 and (bleeding > 1 or preservation + discipline >= 0.25)
        and (tonumber(row.nextBandageAtHours) or -1) <= (tonumber(hours) or 0) then
        options[#options + 1] = {
            id = prefix .. ":body:bandage", kind = "body-bandage",
            activity = "treating", score = 68 + math.min(3, bleeding) * 8
                + preservation * 8 + discipline * 4,
            interruptsWork = bleeding > 1,
            owner = "ZAO.Driver.humanPhysiology",
            detail = "current bleeding and carried treatment",
        }
    end

    local thirst = needs and tonumber(needs.thirst) or 0
    local drinkAt = 0.35
    if SAO and SAO.Disposition and SAO.Disposition.drinkAt then
        pcall(function() drinkAt = SAO.Disposition.drinkAt(personId) end)
    end
    if thirst >= (tonumber(drinkAt) or 0.35) then
        local route = row.route
        if route and route.kind == "water" then
            options[#options + 1] = {
                id = prefix .. ":body:water-route:" .. tostring(route.token),
                kind = "body-water-route", activity = "seeking-water",
                score = 52 + thirst * 45, interruptsWork = thirst >= 0.75,
                owner = "ZAO.Driver.humanPhysiology", route = route,
                detail = "continuing chosen water route",
            }
        else
            options[#options + 1] = {
                id = prefix .. ":body:drink", kind = "body-drink",
                activity = "drinking", score = 52 + thirst * 45,
                interruptsWork = thirst >= 0.75,
                owner = "ZAO.Driver.humanPhysiology",
                detail = "human physiological thirst",
            }
        end
    end

    local fatigue = needs and tonumber(needs.fatigue) or 0
    local restAt = math.max(0.45, 0.7 - preservation * 0.2)
    if fatigue >= restAt and not row.resting then
        options[#options + 1] = {
            id = prefix .. ":body:rest", kind = "body-rest",
            activity = "resting", score = 42 + fatigue * 42,
            interruptsWork = fatigue >= 0.85,
            owner = "ZAO.Driver.humanPhysiology",
            detail = "human physiological fatigue",
        }
    end
    return options
end

function Driver.executeHumanPhysiology(option, personId, body, state, mind,
        hours)
    if not (type(option) == "table" and body and type(state) == "table") then
        return false, "unavailable"
    end
    local row = rowOf(state)
    local kind = tostring(option.kind or "")
    local needs = SAO and SAO.Needs and SAO.Needs.read
        and SAO.Needs.read(body) or nil
    if kind == "body-rest-active" then
        return continueRest(body, row, needs, hours), "resting"
    end
    if row.resting then endRest(body, row) end
    if kind == "body-bandage" then
        row.nextBandageAtHours = (tonumber(hours) or 0) + 0.05
        local treated = SAO and SAO.Needs and SAO.Needs.bandageSelf
            and SAO.Needs.bandageSelf(personId, body) or false
        if treated then
            Driver.cancelRoute(personId, state, "self-treatment", hours)
        end
        return treated == true, treated and "treating" or "treatment-unavailable"
    elseif kind == "body-drink" then
        local drank = SAO and SAO.Needs and SAO.Needs.drinkCarried
            and SAO.Needs.drinkCarried(personId, body) or false
        if drank then
            Driver.cancelRoute(personId, state, "drinking-carried-water", hours)
            return true, "drinking"
        end
        if (tonumber(row.nextWaterAtHours) or -1) > (tonumber(hours) or 0) then
            return false, "water-unavailable"
        end
        row.nextWaterAtHours = (tonumber(hours) or 0) + 0.1
        local wx, wy, wz = nil, nil, nil
        if SAO and SAO.Needs and SAO.Needs.findWater then
            wx, wy, wz = SAO.Needs.findWater(personId, body)
        end
        if not wx then return false, "water-unavailable" end
        local active, outcome = Driver.routeTo(personId, body, state,
            "water", nil, wx, wy, wz, false, hours)
        if active then return true, "seeking-water" end
        if outcome == "completed" and SAO.Needs.queueDrinkFrom
            and SAO.Needs.queueDrinkFrom(personId, body) then
            return true, "drinking"
        end
        return false, "water-unavailable"
    elseif kind == "body-water-route" and option.route then
        local route = option.route
        local active, outcome = Driver.routeTo(personId, body, state,
            "water", route.targetId, route.x, route.y, route.z, false, hours)
        if active then return true, "seeking-water" end
        if outcome == "completed" and SAO and SAO.Needs
            and SAO.Needs.queueDrinkFrom
            and SAO.Needs.queueDrinkFrom(personId, body) then
            return true, "drinking"
        end
        return false, "water-unavailable"
    elseif kind == "body-rest" then
        if row.route then
            Driver.cancelRoute(personId, state, "resting", hours)
        end
        row.resting = { startedAtHours = tonumber(hours) or 0 }
        row.lastRestHours = tonumber(hours) or 0
        pcall(function() body:setSitOnGround(true) end)
        pcall(function() SAOJavaBridge:setShellAsleep(body, true) end)
        return true, "resting"
    end
    return false, "unavailable"
end

function Driver.step(personId, body, state, mind, now, hours)
    if not (body and type(state) == "table" and mind and mind.execution) then
        return false, "unavailable"
    end
    personId = tostring(personId)
    local personalSource = personalSourceReservation(personId)
    if personalSource then
        local interrupter = sourceInterrupter(stateOptions(personId, body,
            state, mind, now, hours))
        if interrupter then
            local closed = SAO and SAO.SourceUse
                and SAO.SourceUse.closeForOwnershipTransfer
                and SAO.SourceUse.closeForOwnershipTransfer(personId, body,
                    "state-pressure:" .. tostring(interrupter.kind)) == true
            if not closed then
                local activity = sourceActivity(personalSource)
                Driver.setActivity(state, activity,
                    "exact source reconciliation still owns the body", hours)
                return true, activity
            end
        else
            local _, activity = advancePersonalSource(personId, body,
                personalSource)
            Driver.setActivity(state, activity,
                "SAO.SourceUse exact food action", hours,
                personalSource.id)
            -- A terminal receipt also consumes this pass.  Starting another
            -- behavior in the same tick would hide the observed completion.
            return true, activity
        end
    end
    if queuedNativeAction(body) then
        local activity = tostring(rowOf(state).currentActivity or "native-action")
        Driver.setActivity(state, activity, "existing native timed action", hours)
        return true, activity
    end
    local activity, detail, option = Driver.intent(personId, body, state, mind,
        now, hours)
    Driver.setActivity(state, activity, detail, hours,
        option and option.workRef or nil)

    local row = rowOf(state)
    if row.resting and (not option
        or option.owner ~= "ZAO.Driver.humanPhysiology") then
        endRest(body, row)
    end

    local coordinated = false
    if SAO and SAO.Controller and SAO.Controller.advanceExternalCoordination then
        local coordinationActivity = option and option.interruptsWork == true
            and activity or "idle"
        local ok, didWork = pcall(function()
            return SAO.Controller.advanceExternalCoordination(
                personId, body, "ZAO", coordinationActivity)
        end)
        coordinated = ok and didWork == true
    end
    if coordinated then
        Driver.setActivity(state, "coordination", "accepted scoped work",
            hours)
        return true, "coordination"
    end

    local committed, performed = false, activity
    if state.terminalState == "afflicted" and ZAO.Afflicted
        and ZAO.Afflicted.execute then
        local ok, didCommit, actual = pcall(ZAO.Afflicted.execute,
            option, body, personId, state, mind, now, hours)
        committed = ok and didCommit == true
        if ok and actual then performed = actual end
    elseif state.terminalState == "crossed" and ZAO.Crossed
        and ZAO.Crossed.execute then
        local ok, didCommit, actual = pcall(ZAO.Crossed.execute,
            option, body, personId, state, mind, now, hours)
        committed = ok and didCommit == true
        if ok and actual then performed = actual end
    end
    Driver.setActivity(state, performed or "idle", detail, hours)
    return committed, performed
end

return Driver
