-- ZAO_ExecutionOwner - registered SAO adapter for every ZAO-owned living person.
--
-- This registration is representation-neutral. Loaded play and dormant county
-- execution ask the same ZAO policy owner for current capability, pressure and
-- actor-private appraisal; a missing human shell remains an observation gap
-- and never becomes proof of incapacity or a second body model.

ZAO = ZAO or {}
ZAO.ExecutionOwner = ZAO.ExecutionOwner or {}
local Owner = ZAO.ExecutionOwner

local function bodyFor(personId, rec)
    personId = tostring(personId or "")
    local controlled = ZAO.Controller and ZAO.Controller.controlled or nil
    if not rec or rec.bodyOwner ~= "ZAO" or not controlled
        or not (SAO and SAO.Body and SAO.Body.foreign) then return nil end
    local body = SAO.Body.foreign[personId]
    if not body or controlled[personId] ~= body then return nil end
    return body
end

local function externalActivity(personId, body, state)
    local rec = SAO and SAO.Identity and SAO.Identity.get(personId) or nil
    if rec and rec.worldSourceReservation then return "coordination" end
    local runtime = SAO and SAO.Controller
        and SAO.Controller.coordinationRuntime
        and SAO.Controller.coordinationRuntime[personId] or nil
    if runtime and runtime.coordinationRoute then return "coordination" end
    local data = nil
    if body then pcall(function() data = body:getModData() end) end
    if data and data.ZAOCrossedDriving then return "driving" end
    if ZAO.Driver and ZAO.Driver.currentActivity then
        return ZAO.Driver.currentActivity(personId, body, state)
    end
    local row = state and state.driver or nil
    return row and tostring(row.currentActivity or "idle") or "idle"
end

local adapter = Owner.adapter or {}
Owner.adapter = adapter

function adapter.bodyFor(personId, rec)
    return bodyFor(personId, rec)
end

function adapter.snapshot(personId, rec)
    personId = tostring(personId or "")
    local body = bodyFor(personId, rec)
    local hour = 0
    pcall(function() hour = SAO.History.countyHours() end)
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(personId) or nil
    if state and ZAO.Maintenance and ZAO.Maintenance.advanceState then
        pcall(ZAO.Maintenance.advanceState, state, tonumber(hour) or 0)
    end
    local mind = ZAO.Mind and ZAO.Mind.of(rec, hour, body) or nil
    if ZAO.Driver and ZAO.Driver.snapshot then
        return ZAO.Driver.snapshot(personId, rec, body, state, mind)
    end
    local canAct = body ~= nil and rec and rec.dead ~= true and mind
        and mind.execution and mind.execution.canMove == true
    local pressure, pressureOwner = nil, "unrepresented"
    if mind and type(mind.physical) == "table" then
        pressure = math.max(tonumber(mind.physical.hunger) or 0,
            tonumber(mind.physical.thirst) or 0,
            tonumber(mind.physical.fatigue) or 0)
        pressureOwner = "SAO.Needs via ZAO.Mind"
    elseif state and state.driver
        and type(state.driver.settlementPressure) == "table" then
        pressure = tonumber(state.driver.settlementPressure.value)
        if pressure ~= nil then
            pressureOwner = "ZAO.Driver.settlementPressure<-SAO.Needs"
        end
    end
    if state and state.terminalState == "crossed" and ZAO.Maintenance
        and ZAO.Maintenance.predatoryPressure then
        local predatory = ZAO.Maintenance.predatoryPressure(state, hour)
        if predatory ~= nil and (pressure == nil or predatory > pressure) then
            pressure, pressureOwner = predatory,
                "ZAO.Maintenance.predatoryPressure"
        end
    end
    return {
        bodyOwner = "ZAO", executor = "ZAO.Driver",
        terminalState = state and state.terminalState or "unknown",
        represented = body ~= nil,
        currentActivity = externalActivity(personId, body, state),
        canAcquire = canAct == true, canCarry = canAct == true,
        canDeliver = canAct == true, canExecute = canAct == true,
        incapable = canAct ~= true, dead = rec and rec.dead == true or false,
        competingPressure = pressure,
        competingPressureAvailable = pressure ~= nil,
        inputOwners = { currentActivity = "ZAO.Driver",
            capabilities = "ZAO.Mind", terminalState = "ZAO.Pathogen",
            competingPressure = pressureOwner },
    }
end

-- Organization freezes the response after SAO proves acquisition. This
-- adapter supplies only current ZAO-owned policy inputs and cannot create a
-- commitment, reveal the pathogen label in the accepted envelope or bypass
-- the recipient's state-specific provider.
function adapter.appraiseMatter(personId, rec, processView, baseContext)
    personId = tostring(personId or "")
    local body = bodyFor(personId, rec)
    local hours = 0
    pcall(function() hours = SAO.History.countyHours() end)
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(personId) or nil
    local provider = state and state.terminalState == "afflicted"
        and ZAO.Afflicted or state and state.terminalState == "crossed"
        and ZAO.Crossed or nil
    if not (state and provider and type(provider.appraiseMatter) == "function") then
        return nil
    end
    local mind = ZAO.Mind and ZAO.Mind.of(rec, hours, body) or nil
    if not mind then return nil end
    return provider.appraiseMatter(personId, body, state, mind, processView,
        type(baseContext) == "table" and baseContext or {}, hours)
end

function adapter.advanceDormant(personId, rec, body, elapsedHours, atHours)
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(tostring(personId))
        or nil
    if not state or not ZAO.Maintenance
        or not ZAO.Maintenance.advanceDormant then
        return false, "maintenance-owner-unavailable"
    end
    return ZAO.Maintenance.advanceDormant(tostring(personId), state, body,
        elapsedHours, atHours)
end

function adapter.receiveThreat(personId, fromId, threatToken, evidence)
    personId, fromId, threatToken = tostring(personId or ""),
        tostring(fromId or ""), tostring(threatToken or "")
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(personId) or nil
    if not state or (state.terminalState ~= "afflicted"
        and state.terminalState ~= "crossed") then return false, "unanswered" end
    state.driver = type(state.driver) == "table" and state.driver or {}
    local atHours = 0
    pcall(function() atHours = SAO.History.countyHours() end)
    state.driver.receivedThreat = {
        version = 1, token = threatToken, fromId = fromId,
        receivedAtHours = tonumber(atHours) or 0, channel = "spoken",
    }
    if SAO and SAO.Standing and SAO.Standing.setHostile then
        pcall(SAO.Standing.setHostile, personId, fromId, true)
    end
    return true, "received"
end

function adapter.observeThreatResponse(personId, fromId, threatToken)
    personId, fromId, threatToken = tostring(personId or ""),
        tostring(fromId or ""), tostring(threatToken or "")
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(personId) or nil
    local event = state and state.driver and state.driver.receivedThreat or nil
    if not event or tostring(event.token or "") ~= threatToken
        or tostring(event.fromId or "") ~= fromId then return nil end
    local rec = SAO and SAO.Identity and SAO.Identity.get(personId) or nil
    local body = bodyFor(personId, rec)
    local activity = externalActivity(personId, body, state)
    local kind = activity == "flee" and "flight"
        or activity == "combat" and "resistance" or nil
    if not kind then return nil end
    local atHours = 0
    pcall(function() atHours = SAO.History.countyHours() end)
    return { version = 1, token = threatToken, personId = personId,
        sourceId = fromId, kind = kind, activity = activity,
        observedAtHours = tonumber(atHours) or 0 }
end

function Owner.register()
    if not (SAO and SAO.Communication
        and SAO.Communication.registerExecutionOwner) then return false end
    return SAO.Communication.registerExecutionOwner("ZAO", adapter)
end

Owner.register()

return Owner
