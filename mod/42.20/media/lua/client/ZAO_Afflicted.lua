-- ZAO_Afflicted - Afflicted policy under the shared ZAO person driver.
--
-- Afflicted remain living people with their own identity and relationships.
-- This provider implements established Afflicted-specific opportunities under
-- the one ZAO driver. It does not claim to be a complete Afflicted life model;
-- unbuilt maintenance actions remain missing producers rather than being filled
-- with survivor or Crossed assumptions.

ZAO = ZAO or {}
ZAO.Afflicted = ZAO.Afflicted or {}
local Afflicted = ZAO.Afflicted

local FEAR_RADIUS = 24.0
local FLEE_DISTANCE = 12.0
local GATHER_RADIUS = 40.0
local ARRIVAL_DISTANCE = 3.0

local function exposureCarrier(personId)
    local root = ZAO.StateStore and ZAO.StateStore.store() or nil
    for carrierId, action in pairs(root and root.exposures or {}) do
        if type(action) == "table"
            and tostring(action.targetId or "") == tostring(personId)
            and action.phase ~= "interrupted" then
            return tostring(carrierId), ZAO.Controller
                and ZAO.Controller.controlled
                and ZAO.Controller.controlled[tostring(carrierId)] or nil
        end
    end
    return nil, nil
end

function Afflicted.threatFor(body, personId, mind, now)
    local carrierId, carrier = exposureCarrier(personId)
    if carrier then return carrierId, carrier, "active-exposure" end
    local bestId, bestBody, bestDistance = nil, nil, nil
    local people = ZAO.Mind and ZAO.Mind.visiblePeople
        and ZAO.Mind.visiblePeople(mind, body, now, FEAR_RADIUS) or {}
    for _, person in ipairs(people) do
        if person.state == "crossed"
            and (not bestDistance or person.distance < bestDistance) then
            bestId, bestBody, bestDistance = person.id, person.body,
                person.distance
        end
    end
    return bestId, bestBody, bestDistance and "observed-crossed" or nil
end

local function groupless(personId)
    if not (SAO and SAO.Standing and SAO.Standing.groupOf) then return false end
    local group = nil
    pcall(function() group = SAO.Standing.groupOf(personId) end)
    return group == nil
end

function Afflicted.nearestPeer(body, personId, mind, now)
    if not groupless(personId) or not (mind and mind.perception)
        or (tonumber(mind.perception.survival) or 0) <= 0 then return nil end
    local bestId, bestBody, bestDistance = nil, nil, nil
    local people = ZAO.Mind and ZAO.Mind.visiblePeople
        and ZAO.Mind.visiblePeople(mind, body, now, GATHER_RADIUS) or {}
    for _, person in ipairs(people) do
        if person.state == "afflicted" and person.distance <= GATHER_RADIUS
            and (not bestDistance or person.distance < bestDistance) then
            bestId, bestBody, bestDistance = person.id, person.body,
                person.distance
        end
    end
    return bestId, bestBody, bestDistance
end

local function settlementDestination(state)
    local groupId = state and state.settlementGroup or nil
    local group = groupId and ZAO.Settlement and ZAO.Settlement.groups
        and ZAO.Settlement.groups[groupId] or nil
    local place = group and group.occupied and group.place or nil
    if place and tonumber(place.x) and tonumber(place.y) then
        return groupId, place
    end
    return nil, nil
end

local function outcastDestination(personId, mind)
    if not groupless(personId) or not (mind and mind.perception)
        or (tonumber(mind.perception.survival) or 0) <= 0 then return nil end
    if not (SAO and SAO.Standing and SAO.Standing.outcastDriftDestination) then
        return nil
    end
    local candidate = nil
    pcall(function()
        candidate = SAO.Standing.outcastDriftDestination(personId)
    end)
    return candidate
end

function Afflicted.options(body, personId, state, mind, now, hours)
    local options = {}
    if ZAO.Diet and ZAO.Diet.options then
        local ok, foodOptions = pcall(ZAO.Diet.options, personId, body, state,
            mind, hours)
        if ok and type(foodOptions) == "table" then
            for _, option in ipairs(foodOptions) do options[#options + 1] = option end
        end
    end
    if ZAO.Driver and ZAO.Driver.humanPhysiologyOptions then
        local ok, bodyOptions = pcall(ZAO.Driver.humanPhysiologyOptions,
            personId, body, state, mind, hours)
        if ok and type(bodyOptions) == "table" then
            for _, option in ipairs(bodyOptions) do options[#options + 1] = option end
        end
    end
    local threatId, threat = Afflicted.threatFor(body, personId, mind, now)
    local route = state and state.driver and state.driver.route or nil
    if threatId then
        options[#options + 1] = {
            id = "afflicted:flee:" .. tostring(threatId),
            kind = "flee",
            activity = "flee", score = 100
                + (tonumber(mind.disposition.selfPreservation) or 0) * 20
                - (tonumber(mind.disposition.nerve) or 0) * 5,
            detail = "observed Crossed " .. tostring(threatId),
            interruptsWork = true, targetId = threatId, target = threat,
        }
    end
    local settlementId = settlementDestination(state)
    if settlementId then
        options[#options + 1] = {
            id = "afflicted:settlement:" .. tostring(settlementId),
            kind = "settlement",
            activity = "gather", score = 35
                + (tonumber(mind.disposition.discipline) or 0) * 10,
            detail = "evidenced Afflicted ground", interruptsWork = false,
            targetId = settlementId,
        }
    end
    local peerId, peer, peerDistance = Afflicted.nearestPeer(
        body, personId, mind, now)
    if peerId then
        options[#options + 1] = {
            id = "afflicted:gather:" .. tostring(peerId),
            kind = "gather",
            activity = "gather", score = 30
                + (tonumber(mind.disposition.initiative) or 0) * 10,
            detail = "observed Afflicted peer", interruptsWork = false,
            targetId = peerId, target = peer, distance = peerDistance,
        }
    end
    local destination = outcastDestination(personId, mind)
    if destination then
        options[#options + 1] = {
            id = "afflicted:ground:" .. tostring(destination.id),
            kind = "ground",
            activity = "seek-unheld-place", score = 20
                + (tonumber(mind.disposition.initiative) or 0) * 10,
            detail = "privately known unheld ground", interruptsWork = false,
            destination = destination,
        }
    end
    if route then
        options[#options + 1] = {
            id = "afflicted:route:" .. tostring(route.token),
            kind = "route", activity = tostring(route.kind or "moving"),
            score = route.kind == "flee" and 95 or 28,
            detail = "continuing a previously chosen route",
            interruptsWork = route.kind == "flee", route = route,
        }
    end
    return options
end

function Afflicted.execute(option, body, personId, state, mind, now, hours)
    personId = tostring(personId)
    if type(option) ~= "table" then return false, "idle" end
    local route = state.driver and state.driver.route or nil
    if string.sub(tostring(option.kind), 1, 5) == "diet-"
        or option.kind == "butcher-human" then
        if ZAO.Diet and ZAO.Diet.step then
            local ok, committed, activity = pcall(ZAO.Diet.step,
                personId, body, state, mind, hours, option)
            return ok and committed == true, ok and activity or "idle"
        end
        return false, "idle"
    elseif option.owner == "ZAO.Driver.humanPhysiology" then
        if ZAO.Driver and ZAO.Driver.executeHumanPhysiology then
            return ZAO.Driver.executeHumanPhysiology(option, personId, body,
                state, mind, hours)
        end
        return false, "unavailable"
    elseif option.kind == "route" and option.route then
        local chosen = option.route
        local active = ZAO.Driver and ZAO.Driver.routeTo(personId, body, state,
            chosen.kind, chosen.targetId, chosen.x, chosen.y, chosen.z,
            chosen.running, hours)
        return active == true, active and tostring(chosen.kind or "moving")
            or "route-ended"
    end
    if option.kind == "flee" then
        local threatId, threat = option.targetId, option.target
        if not threat then
            if route and route.kind == "flee" and ZAO.Driver then
            local active = ZAO.Driver.routeTo(personId, body, state,
                "flee", route.targetId, route.x, route.y, route.z,
                true, hours)
            return active == true, active and "flee" or "idle"
            end
            return false, "idle"
        end
        if not (SAO and SAO.Locomotion and mind.execution.canMove) then
            return false, "flee"
        end
        local bx, by, bz = body:getX(), body:getY(), math.floor(body:getZ())
        local tx, ty = threat:getX(), threat:getY()
        local dx, dy = bx - tx, by - ty
        local length = math.sqrt(dx * dx + dy * dy)
        if length < 0.1 then dx, dy, length = 1.0, 0.0, 1.0 end
        local gx = math.floor(bx + dx / length * FLEE_DISTANCE)
        local gy = math.floor(by + dy / length * FLEE_DISTANCE)
        local active = ZAO.Driver and ZAO.Driver.routeTo(personId, body, state,
            "flee", threatId, gx, gy, bz,
            mind.disposition and mind.disposition.nerve < 0.5, hours)
        return active == true, "flee"
    end

    if not (SAO and SAO.Locomotion and mind.execution.canMove) then
        return false, "idle"
    end

    if option.kind == "settlement" then
        local settlementId, place = settlementDestination(state)
        if place then
            local dx, dy = body:getX() - place.x, body:getY() - place.y
            if math.sqrt(dx * dx + dy * dy) > ARRIVAL_DISTANCE then
                local active = ZAO.Driver.routeTo(personId, body, state,
                    "afflicted-settlement", settlementId, place.x, place.y,
                    place.z or body:getZ(), false, hours)
                return active == true, active and "gather" or "holding-place"
            end
            if route then ZAO.Driver.cancelRoute(personId, state,
                "settlement-reached", hours) end
            return false, "holding-place"
        end
    end

    if option.kind == "gather" then
        local peerId, peer, peerDistance = option.targetId, option.target,
            option.distance
        if peer and peerDistance and peerDistance > ARRIVAL_DISTANCE then
            local active = ZAO.Driver.routeTo(personId, body, state,
                "afflicted-gather", peerId, peer:getX(), peer:getY(),
                peer:getZ(), false, hours)
            return active == true, active and "gather" or "idle"
        elseif peer then
            if route then ZAO.Driver.cancelRoute(personId, state,
                "peer-reached", hours) end
            return false, "gathered"
        end
    end

    if option.kind == "ground" then
        local candidate = option.destination or outcastDestination(personId, mind)
        local destination = candidate and candidate.place or nil
        if destination then
            local active, outcome = ZAO.Driver.routeTo(personId, body, state,
                "afflicted-outcast", candidate.id, destination.cx,
                destination.cy, body:getZ(), false, hours)
            if active then return true, "seek-unheld-place" end
            if outcome == "completed" and SAO.Standing.completeOutcastDrift then
                local settled = false
                pcall(function()
                    settled = SAO.Standing.completeOutcastDrift(
                        personId, body, candidate) == true
                end)
                return settled, settled and "settling-ground" or "idle"
            end
        end
        return false, "idle"
    end
    return false, "idle"
end

return Afflicted
