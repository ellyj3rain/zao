-- ZAO_Exposure - intentional Crossed blood exposure of an Afflicted person.
--
-- Proximity can offer a target; it never rolls conversion.  A live Crossed
-- body must approach, hold contact through a visible action interval, and
-- complete an exact-once result.  Breaking range, losing either body, changing
-- ownership, or becoming busy interrupts the action.  The Afflicted target is
-- explicitly removed from zombie attack targeting: this is coercive exposure,
-- not feeding.

ZAO = ZAO or {}
ZAO.Exposure = ZAO.Exposure or {}
local Exposure = ZAO.Exposure

local CONTACT_RANGE = 1.45
local BREAK_RANGE = 2.25
local CONTACT_HOURS = 0.025
local RETRY_HOURS = 24.0

local function store()
    local root = ZAO.StateStore and ZAO.StateStore.store() or nil
    if not root then return nil end
    root.exposures = root.exposures or {}
    root.exposureResults = root.exposureResults or {}
    return root
end

local function bodyData(body)
    local data = nil
    pcall(function() data = body:getModData() end)
    return type(data) == "table" and data or nil
end

local function personBody(personId)
    personId = tostring(personId or "")
    if SAO and SAO.Communication and SAO.Communication.bodyFor then
        local body = SAO.Communication.bodyFor(personId)
        if body then return body end
    end
    if SAO and SAO.Body then
        return SAO.Body.foreign and SAO.Body.foreign[personId]
            or SAO.Body.active and SAO.Body.active[personId] or nil
    end
    return nil
end

local function ensureCrossedOwnership(personId, target, hours)
    local rec = SAO and SAO.Identity and SAO.Identity.get(personId) or nil
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(personId) or nil
    local token = state and (state.driverToken or state.crossedTransferToken)
    if not (rec and state and state.terminalState == "crossed" and token) then
        return false, "crossed-driver-unavailable"
    end
    if rec.bodyOwner == "ZAO" then
        if tostring(rec.bodyOwnerToken or "") ~= tostring(token) then
            return false, "zao-driver-token-mismatch"
        end
        if ZAO.Controller and ZAO.Controller.acceptExternal then
            ZAO.Controller.acceptExternal(personId, target, token, "crossed")
        end
        return true, "already-zao-owned"
    end
    local transfer = SAO and (SAO.ZAOPersonTransfer or SAO.CrossedTransfer)
    if not (transfer and transfer.begin) then
        return false, "transfer-seam-unavailable"
    end
    return transfer.begin(personId, target, token, hours, "crossed")
end

-- Weapon-borne blood uses the same conversion/ownership boundary after its
-- own native hit receipt completes. The action journals remain separate; only
-- this idempotent transfer operation is shared.
Exposure.ensureCrossedOwnership = ensureCrossedOwnership

local function distance(a, b)
    local value = nil
    pcall(function()
        local dx, dy = a:getX() - b:getX(), a:getY() - b:getY()
        value = math.sqrt(dx * dx + dy * dy)
    end)
    return value
end

local function clearMarks(action, carrier, target)
    local cdata, tdata = bodyData(carrier), bodyData(target)
    if cdata and cdata.ZAOExposureToken == action.token then
        cdata.ZAOExposureToken = nil
        cdata.ZAOExposurePhase = nil
        cdata.ZAOExposureTarget = nil
    end
    if tdata and tdata.ZAOExposureThreat == action.token then
        tdata.ZAOExposureThreat = nil
    end
end

local function archive(root, action, phase, reason, hours)
    local carrierState = ZAO.Pathogen
        and ZAO.Pathogen.stateOf(action.carrierId) or nil
    local route = carrierState and carrierState.driver
        and carrierState.driver.route or nil
    if route and route.kind == "exposure" and ZAO.Driver
        and ZAO.Driver.cancelRoute then
        ZAO.Driver.cancelRoute(action.carrierId, carrierState,
            "exposure-" .. tostring(phase), hours)
    end
    action.phase = phase
    action.reason = reason
    action.resolvedAtHours = hours
    root.exposureResults[action.token] = action
    root.exposures[action.carrierId] = nil
end

local function interrupt(root, action, carrier, target, reason, hours)
    clearMarks(action, carrier, target)
    archive(root, action, "interrupted", reason, hours)
    return false
end

local function begin(root, carrierId, targetId, hours)
    root.exposureSequence = (tonumber(root.exposureSequence) or 0) + 1
    local token = "blood:" .. tostring(carrierId) .. ":"
        .. tostring(targetId) .. ":" .. tostring(root.exposureSequence)
    local action = {
        version = 1,
        token = token,
        kind = "crossed-blood-exposure",
        carrierId = tostring(carrierId),
        targetId = tostring(targetId),
        phase = "approaching",
        startedAtHours = hours,
        lastAtHours = hours,
    }
    root.exposures[action.carrierId] = action
    return action
end

local function complete(root, action, carrierState, carrier, target, hours)
    action.phase = "resolving"
    action.lastAtHours = hours
    local result = {
        token = action.token,
        kind = action.kind,
        completed = true,
        carrierId = action.carrierId,
        targetId = action.targetId,
        atHours = hours,
    }
    local receipt = ZAO.Pathogen.expose(action.targetId, carrierState,
        math.floor(hours / 24.0), result)
    if type(receipt) ~= "table" then
        return interrupt(root, action, carrier, target,
            "pathogen-refused-result", hours)
    end
    action.receipt = receipt
    if receipt.converted then
        local moved, reason = ensureCrossedOwnership(
            action.targetId, target, hours)
        if not moved then
            action.phase = "transfer-pending"
            action.reason = reason
            return true
        end
        clearMarks(action, carrier, target)
        archive(root, action, "converted", "transferred", hours)
        return true
    end
    carrierState.lastExposureAt = carrierState.lastExposureAt or {}
    carrierState.lastExposureAt[action.targetId] = hours
    clearMarks(action, carrier, target)
    archive(root, action, "resisted", "pathogen-roll", hours)
    return true
end

function Exposure.step(carrier, carrierId, carrierState, target, targetId,
        now, hours)
    if not (carrier and target and type(carrierState) == "table") then return false end
    carrierId, targetId = tostring(carrierId or ""), tostring(targetId or "")
    hours = tonumber(hours) or 0.0
    if carrierId == "" or targetId == "" then return false end
    local root = store()
    if not root then return false end

    local action = root.exposures[carrierId]
    if action and action.targetId ~= targetId then
        local priorTarget = personBody(action.targetId)
        interrupt(root, action, carrier, priorTarget, "target-changed", hours)
        action = nil
    end
    if action and action.phase == "transfer-pending" then
        local moved, reason = ensureCrossedOwnership(targetId, target, hours)
        if moved then
            clearMarks(action, carrier, target)
            archive(root, action, "converted", "transferred", hours)
        else
            action.reason = reason or "transfer-pending"
        end
        return true
    end

    local targetState = ZAO.Pathogen and ZAO.Pathogen.stateOf(targetId) or nil
    local targetRec = SAO and SAO.Identity and SAO.Identity.get(targetId) or nil
    if not targetState or targetState.terminalState ~= "afflicted"
        or not targetRec or targetRec.dead
        or not SAO.Body or personBody(targetId) ~= target
        or (targetRec.bodyOwner ~= nil and targetRec.bodyOwner ~= "ZAO")
        or not SAO.Body.canTransfer(target) then
        if action then
            return interrupt(root, action, carrier, target,
                "target-unavailable", hours)
        end
        return false
    end

    local prior = carrierState.lastExposureAt
        and tonumber(carrierState.lastExposureAt[targetId]) or nil
    if not action and prior and hours - prior < RETRY_HOURS then return false end
    if not action then action = begin(root, carrierId, targetId, hours) end
    action.lastAtHours = hours

    local cdata, tdata = bodyData(carrier), bodyData(target)
    if cdata then
        cdata.ZAOExposureToken = action.token
        cdata.ZAOExposurePhase = action.phase
        cdata.ZAOExposureTarget = targetId
    end
    if tdata then tdata.ZAOExposureThreat = action.token end

    -- Exposure is distinct from feeding. Zombie-shaped legacy carriers have
    -- their ordinary attack target cleared only while this action owns the body.
    pcall(function() carrier:setTarget(nil) end)

    local apart = distance(carrier, target)
    if not apart then
        return interrupt(root, action, carrier, target,
            "position-unavailable", hours)
    end
    if action.phase == "approaching" then
        if apart > CONTACT_RANGE then
            local active, outcome = false, "unavailable"
            if ZAO.Driver and ZAO.Driver.routeTo then
                active, outcome = ZAO.Driver.routeTo(carrierId, carrier,
                    carrierState, "exposure", targetId, target:getX(),
                    target:getY(), target:getZ(), true, hours)
            end
            if active ~= true and outcome ~= "completed" then
                local route = carrierState.driver and carrierState.driver.route
                    or nil
                if not route then
                    return interrupt(root, action, carrier, target,
                        "approach-route-refused", hours)
                end
            end
            return true
        end
        local route = carrierState.driver and carrierState.driver.route or nil
        if route and route.kind == "exposure" and ZAO.Driver
            and ZAO.Driver.cancelRoute then
            ZAO.Driver.cancelRoute(carrierId, carrierState,
                "contact-reached", hours)
        end
        action.phase = "contact"
        action.contactAtHours = hours
    elseif action.phase == "contact" and apart > BREAK_RANGE then
        return interrupt(root, action, carrier, target,
            "contact-broken", hours)
    end

    pcall(function() carrier:faceThisObject(target) end)
    pcall(function() target:faceThisObject(carrier) end)
    if cdata then cdata.ZAOExposurePhase = action.phase end
    if hours - (tonumber(action.contactAtHours) or hours) < CONTACT_HOURS then
        return true
    end
    return complete(root, action, carrierState, carrier, target, hours)
end

function Exposure.activeFor(carrierId)
    local root = store()
    return root and root.exposures[tostring(carrierId)] or nil
end

-- Conversion and body transfer are separate durable phases.  A treatment,
-- inventory action, or save boundary may temporarily keep SAO's shell busy
-- after the pathogen result has committed.  Retry from the action journal;
-- target selection no longer sees this person as Afflicted after conversion.
function Exposure.resumePending(hours)
    local root = store()
    if not root then return false end
    if hours == nil and SAO and SAO.History then
        pcall(function() hours = SAO.History.countyHours() end)
    end
    hours = tonumber(hours) or 0.0
    local complete = true
    for _, action in pairs(root.exposures) do
        if action.phase == "transfer-pending" then
            local carrier = ZAO.Controller and ZAO.Controller.controlled
                and ZAO.Controller.controlled[action.carrierId] or nil
            local rec = SAO and SAO.Identity
                and SAO.Identity.get(action.targetId) or nil
            local target = personBody(action.targetId)
            if not rec then
                clearMarks(action, carrier, target)
                archive(root, action, "interrupted", "target-missing", hours)
            elseif rec.dead then
                clearMarks(action, carrier, target)
                archive(root, action, "converted", "target-died-before-transfer",
                    hours)
            else
                local moved, reason = ensureCrossedOwnership(
                    action.targetId, target, hours)
                if moved then
                    clearMarks(action, carrier, target)
                    archive(root, action, "converted", "transferred", hours)
                else
                    action.reason = reason or "transfer-pending"
                    action.lastAtHours = hours
                    complete = false
                end
            end
        end
    end
    return complete
end

return Exposure
