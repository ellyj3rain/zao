-- ZAO_Predation - Crossed encounters with acute, evidenced outcomes.
--
-- Predatory pressure can motivate an encounter; it never proves fear, pain,
-- control, death, or sustenance.  A spoken threat must pass SAO's real hearing
-- boundary.  Fear relief follows public flight during that admitted encounter,
-- control follows an exact completed native handover, pain follows an actual
-- health delta, and death closes the live flow without pretending it supplied
-- any of those earlier results.  Eating remains a separate Diet transaction.

ZAO = ZAO or {}
ZAO.Predation = ZAO.Predation or {}
local Predation = ZAO.Predation
Predation.runtimeCombats = Predation.runtimeCombats or {}

local THREAT_RANGE = 6.0
local COMBAT_RANGE = 12.0
local OBSERVE_HOURS = 0.05
local FEAR_INTERVAL_HOURS = 0.015
local MAX_FEAR_RECEIPTS = 4

local function store()
    local root = ZAO.StateStore and ZAO.StateStore.store() or nil
    if not root then return nil end
    root.predationActions = root.predationActions or {}
    root.predationResults = root.predationResults or {}
    root.predationConsumedHandovers = root.predationConsumedHandovers or {}
    return root
end

local function bodyData(body)
    local data = nil
    if body then pcall(function() data = body:getModData() end) end
    return type(data) == "table" and data or nil
end

local function personBody(personId)
    return SAO and SAO.Communication and SAO.Communication.bodyFor
        and SAO.Communication.bodyFor(tostring(personId)) or nil
end

local function distance(a, b)
    local value = nil
    pcall(function()
        local dx, dy = a:getX() - b:getX(), a:getY() - b:getY()
        value = math.sqrt(dx * dx + dy * dy)
    end)
    return value
end

local function health(body)
    local value = nil
    pcall(function() value = tonumber(body:getHealth()) end)
    return type(value) == "number" and value == value and value or nil
end

local function dead(body)
    local value = false
    pcall(function() value = body:isDead() == true end)
    return value
end

local function targetName(body)
    local value = nil
    pcall(function() value = body:getUsername() end)
    return value and tostring(value) ~= "" and tostring(value) or nil
end

local function cancelRoute(action, reason, hours)
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(action.carrierId) or nil
    local route = state and state.driver and state.driver.route or nil
    if route and (route.kind == "predation-approach"
        or route.kind == "predation-pursuit") and ZAO.Driver
        and ZAO.Driver.cancelRoute then
        ZAO.Driver.cancelRoute(action.carrierId, state,
            reason or "predation-ended", hours)
    end
end

local function resetCombat(carrier)
    if SAOJavaBridge and SAOJavaBridge.resetCombat then
        pcall(function() SAOJavaBridge:resetCombat(carrier) end)
    end
end

local function archive(root, action, outcome, reason, hours, carrier)
    if not root or not action then return false end
    if not root.predationResults[action.token] then
        action.outcome = tostring(outcome or "interrupted")
        action.reason = reason and tostring(reason) or nil
        action.resolvedAtHours = tonumber(hours) or action.lastAtHours
            or action.startedAtHours or 0
        root.predationResults[action.token] = action
    end
    root.predationActions[action.carrierId] = nil
    Predation.runtimeCombats[action.token] = nil
    cancelRoute(action, "predation-" .. tostring(outcome), hours)
    resetCombat(carrier)
    return true
end

local function nextToken(root, carrierId, targetId)
    root.predationSequence = (tonumber(root.predationSequence) or 0) + 1
    return "predation:" .. tostring(carrierId) .. ":" .. tostring(targetId)
        .. ":" .. tostring(root.predationSequence)
end

local function begin(root, carrierId, targetId, hours)
    local action = {
        version = 1,
        token = nextToken(root, carrierId, targetId),
        carrierId = tostring(carrierId),
        targetId = tostring(targetId),
        phase = "approaching",
        startedAtHours = tonumber(hours) or 0,
        lastAtHours = tonumber(hours) or 0,
        fearReceipts = 0,
    }
    root.predationActions[action.carrierId] = action
    return action
end

local function route(action, carrier, target, hours, running)
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(action.carrierId) or nil
    if not state or not ZAO.Driver or not ZAO.Driver.routeTo then return false end
    local active, outcome = ZAO.Driver.routeTo(action.carrierId, carrier, state,
        action.phase == "observing" and "predation-pursuit"
            or "predation-approach",
        action.targetId, target:getX(), target:getY(), target:getZ(),
        running == true, hours)
    return active == true or outcome == "completed"
end

local function recordOutcome(action, kind, amount, suffix, hours, evidence)
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(action.carrierId) or nil
    if not state or not ZAO.Maintenance
        or not ZAO.Maintenance.recordPredatoryOutcome then return nil end
    return ZAO.Maintenance.recordPredatoryOutcome(action.carrierId, state,
        kind, amount, action.token .. ":" .. tostring(suffix), hours, evidence)
end

local function deliveredThreat(action, apart, hours)
    if not (SAO and SAO.Communication
        and SAO.Communication.deliverThreat) then return nil, "unavailable" end
    local sequence = SAO.Handover and SAO.Handover.currentSequence
        and SAO.Handover.currentSequence() or nil
    local receipt, reason = SAO.Communication.deliverThreat(action.carrierId,
        action.targetId, action.token, { proximity = apart,
            atHours = tonumber(hours) or 0 })
    if type(receipt) ~= "table" or receipt.delivered ~= true then
        return nil, reason or "not-delivered"
    end
    action.threatReceipt = receipt
    action.handoverAfterSequence = sequence
    action.phase = "observing"
    action.deliveredAtHours = tonumber(hours) or 0
    action.lastFlowAtHours = tonumber(hours) or 0
    return receipt
end

local function completedYield(root, action)
    if not (SAO and SAO.Handover and SAO.Handover.completedSince
        and action.handoverAfterSequence ~= nil) then return nil end
    return SAO.Handover.completedSince(action.handoverAfterSequence,
        action.targetId, action.carrierId, "yield",
        root.predationConsumedHandovers)
end

local function publicFlight(action, target)
    local response = SAO and SAO.Communication
        and SAO.Communication.observeThreatResponse
        and SAO.Communication.observeThreatResponse(action.targetId,
            action.carrierId, action.token) or nil
    if type(response) == "table" and response.kind == "flight" then
        return true, response
    end
    local running, sprinting = false, false
    pcall(function()
        running = target:isRunning() == true
        sprinting = target:isSprinting() == true
    end)
    if running or sprinting then
        return true, { kind = "flight", activity = sprinting and "sprint"
            or "run", observedAtHours = action.lastAtHours }
    end
    return false, response
end

local function beginCombat(action, carrier, target, hours)
    if not (SAOJavaBridge and SAOJavaBridge.beginCombatWithName) then
        return false, "combat-unavailable"
    end
    local name = targetName(target)
    if not name then return false, "target-name-unavailable" end
    local before = health(target)
    if before == nil then return false, "target-health-unavailable" end
    local ok, verdict = pcall(function()
        return SAOJavaBridge:beginCombatWithName(carrier, name, COMBAT_RANGE)
    end)
    verdict = ok and tostring(verdict or "") or "COMBAT_FAILED"
    if not verdict:find("COMBAT_STARTED", 1, true) then
        return false, verdict ~= "" and verdict or "combat-refused"
    end
    action.phase = "combat"
    action.combatStartedAtHours = tonumber(hours) or 0
    action.lastTargetHealth = before
    action.combatVerdict = verdict
    Predation.runtimeCombats[action.token] = true
    return true
end

local function tickCombat(root, action, carrier, target, hours)
    local before = health(target) or tonumber(action.lastTargetHealth)
    local ok, verdict = pcall(function() return SAOJavaBridge:tickCombat(carrier) end)
    verdict = ok and tostring(verdict or "") or "COMBAT_FAILED"
    local after = health(target)
    action.combatVerdict = verdict
    action.lastTargetHealth = after or before
    if before and after and after < before - 0.001 then
        local damage = before - after
        action.damage = (tonumber(action.damage) or 0) + damage
        if dead(target) or after <= 0 then
            recordOutcome(action, "death", 0, "death", hours, {
                targetId = action.targetId, healthBefore = before,
                healthAfter = after, damage = damage,
            })
            archive(root, action, "completed", "target-died", hours, carrier)
            return false, "death"
        end
        recordOutcome(action, "pain", math.min(0.24, 0.08 + damage / 250),
            "pain", hours, { targetId = action.targetId,
                healthBefore = before, healthAfter = after, damage = damage })
        archive(root, action, "completed", "actual-damage", hours, carrier)
        return false, "pain"
    end
    if dead(target) or verdict:find("COMBAT_SUCCEEDED", 1, true) then
        recordOutcome(action, "death", 0, "death", hours, {
            targetId = action.targetId, healthBefore = before,
            healthAfter = after,
        })
        archive(root, action, "completed", "target-died", hours, carrier)
        return false, "death"
    end
    if verdict:find("COMBAT_FAILED", 1, true) or verdict == "COMBAT_IDLE"
        or verdict == "NOT_A_SHELL" then
        archive(root, action, "failed", verdict, hours, carrier)
        return false, "failed"
    end
    return true, "combat"
end

function Predation.activeFor(carrierId)
    local root = store()
    return root and root.predationActions[tostring(carrierId)] or nil
end

function Predation.step(carrierId, carrier, targetId, target, hours)
    carrierId, targetId = tostring(carrierId or ""), tostring(targetId or "")
    hours = tonumber(hours) or 0
    local root = store()
    if not root or carrierId == "" or targetId == "" or not carrier then
        return false, "unavailable"
    end
    local action = root.predationActions[carrierId]
    if action and action.targetId ~= targetId then
        archive(root, action, "interrupted", "target-changed", hours, carrier)
        action = nil
    end
    target = target or personBody(targetId)
    if not target or dead(target) then
        if action then
            if target and dead(target) then
                recordOutcome(action, "death", 0, "death", hours,
                    { targetId = targetId })
            end
            archive(root, action, target and "completed" or "interrupted",
                target and "target-died" or "target-unavailable", hours,
                carrier)
        end
        return false, target and "death" or "target-unavailable"
    end
    if not action then action = begin(root, carrierId, targetId, hours) end
    action.lastAtHours = hours
    local apart = distance(carrier, target)
    if not apart then
        archive(root, action, "failed", "position-unavailable", hours, carrier)
        return false, "failed"
    end

    if action.phase == "approaching" then
        if apart > THREAT_RANGE then
            return route(action, carrier, target, hours, true), "approaching"
        end
        cancelRoute(action, "speech-range-reached", hours)
        local receipt, reason = deliveredThreat(action, apart, hours)
        if not receipt then
            -- Violence remains possible, but no fear/control credit can arise
            -- from a threat that was not actually heard.
            action.phase = "assault"
            action.threatFailure = reason
        else
            return true, "threatening"
        end
    end

    if action.phase == "observing" then
        local yielded = completedYield(root, action)
        if yielded then
            root.predationConsumedHandovers[tostring(yielded.id)] = true
            action.handoverReceiptId = yielded.id
            recordOutcome(action, "control", nil, "control", hours, {
                targetId = targetId, handoverReceiptId = yielded.id,
                itemId = yielded.itemId, itemType = yielded.itemType,
            })
            archive(root, action, "completed", "completed-yield", hours,
                carrier)
            return false, "control"
        end
        local fled, response = publicFlight(action, target)
        if fled and (tonumber(action.fearReceipts) or 0) < MAX_FEAR_RECEIPTS
            and hours - (tonumber(action.lastFlowAtHours) or hours)
                >= FEAR_INTERVAL_HOURS then
            action.fearReceipts = (tonumber(action.fearReceipts) or 0) + 1
            action.lastFlowAtHours = hours
            recordOutcome(action, "fear", nil,
                "fear:" .. tostring(action.fearReceipts), hours, {
                    targetId = targetId,
                    activity = response and response.activity or "flight",
                })
        end
        local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(carrierId) or nil
        local pressure = ZAO.Maintenance and ZAO.Maintenance.predatoryPressure
            and ZAO.Maintenance.predatoryPressure(state, hours) or 1
        if fled and pressure <= 0.10 then
            archive(root, action, "completed", "acute-fear-flow", hours,
                carrier)
            return false, "fear"
        end
        if hours - (tonumber(action.deliveredAtHours) or hours)
            < OBSERVE_HOURS then
            if apart > THREAT_RANGE then
                route(action, carrier, target, hours, true)
            end
            return true, fled and "pursuit" or "observing"
        end
        action.phase = "assault"
    end

    if action.phase == "assault" then
        if apart > COMBAT_RANGE then
            return route(action, carrier, target, hours, true), "pursuit"
        end
        cancelRoute(action, "combat-range-reached", hours)
        local started, reason = beginCombat(action, carrier, target, hours)
        if not started then
            archive(root, action, "failed", reason, hours, carrier)
            return false, "failed"
        end
        return true, "combat"
    elseif action.phase == "combat" then
        return tickCombat(root, action, carrier, target, hours)
    end
    archive(root, action, "failed", "unknown-phase", hours, carrier)
    return false, "failed"
end

function Predation.resumePending(hours)
    local root = store()
    if not root then return false end
    hours = tonumber(hours) or 0
    local pending = {}
    for _, action in pairs(root.predationActions) do
        pending[#pending + 1] = action
    end
    for _, action in ipairs(pending) do
        if action.phase == "combat"
            and Predation.runtimeCombats[action.token] ~= true then
            -- Java combat handles do not survive reload; the result cannot be
            -- invented.  Preserve the terminal interruption and allow a later
            -- decision to begin a new encounter.
            local carrier = personBody(action.carrierId)
            archive(root, action, "interrupted", "runtime-reconstructed",
                hours, carrier)
        end
    end
    return true
end

return Predation
