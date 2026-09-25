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

local function clamp01(value)
    value = tonumber(value) or 0
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local function knownRecipients(personId, group, context)
    local addressed, seen = {}, {}
    local function admit(otherId, hostile, knownForm)
        otherId = tostring(otherId or "")
        if otherId ~= "" and otherId ~= tostring(personId)
            and hostile ~= true and tostring(knownForm or "") ~= "crossed"
            and not seen[otherId] then
            seen[otherId] = true
            addressed[#addressed + 1] = otherId
        end
    end
    for otherId in pairs(group and group.members or {}) do admit(otherId, false) end
    for _, contact in ipairs(type(context) == "table"
            and context.knownContacts or {}) do
        -- Only the actor's retained form knowledge may exclude a known
        -- Crossed threat here. Missing form remains unknown; ZAO must not
        -- consult the other person's current hidden pathogen state.
        admit(contact.id, contact.hostile, contact.form)
        if #addressed >= 3 then break end
    end
    table.sort(addressed)
    while #addressed > 3 do table.remove(addressed) end
    return addressed
end

local function afflictedProvisioningSituation(body, personId, state, mind,
        now, hours, context)
    if not (mind and ZAO.Driver and SAO and SAO.Organization) then
        return nil
    end
    local physical = mind.physical or {}
    local personalEvidence = body ~= nil and (physical.hunger ~= nil
        or physical.thirst ~= nil)
    local retained = state and state.driver
        and type(state.driver.settlementPressure) == "table"
        and state.driver.settlementPressure or nil
    if not personalEvidence and retained
        and retained.terminalState == "afflicted" then
        physical = retained
        personalEvidence = retained.hunger ~= nil or retained.thirst ~= nil
    end
    local hunger = personalEvidence and clamp01(physical.hunger) or 0
    local thirst = personalEvidence and clamp01(physical.thirst) or 0
    local groupId = state and state.settlementGroup or nil
    local group = groupId and ZAO.Settlement and ZAO.Settlement.groups
        and ZAO.Settlement.groups[groupId] or nil
    local settlementNeed = group and group.occupied
        and clamp01(group.necessity) or 0
    local groupHunger, groupThirst, observed = 0, 0, 0
    for _, evidence in pairs(group and group.needEvidence or {}) do
        if type(evidence) == "table" then
            groupHunger = groupHunger + clamp01(evidence.hunger)
            groupThirst = groupThirst + clamp01(evidence.thirst)
            observed = observed + 1
        end
    end
    if observed > 0 then
        groupHunger, groupThirst = groupHunger / observed, groupThirst / observed
    end
    -- The settlement's aggregate necessity can motivate attention, but only
    -- its recorded hunger/thirst evidence can name a provisioning category.
    -- Fatigue or injury never silently turns into a request for food.
    local foodPressure = math.max(hunger, groupHunger)
    local waterPressure = math.max(thirst, groupThirst)
    local category = waterPressure > foodPressure and "water" or "food"
    local pressure = math.max(foodPressure, waterPressure)
    local open = SAO.Organization.openMatter
        and SAO.Organization.openMatter(tostring(personId), "provisioning") or nil
    local evidenceAvailable = personalEvidence or observed > 0
    if evidenceAvailable and pressure <= 0.25 and open then
        return {
            id = "afflicted:provisioning:withdraw:" .. tostring(open.id),
            kind = "provisioning-withdraw",
            activity = "revising-provisioning", score = 76,
            interruptsWork = false,
            detail = "the evidenced provisioning pressure has passed",
        }
    end
    if not evidenceAvailable or pressure < 0.55 then return nil end

    local addressed = {}
    if body then
        local people = ZAO.Mind and ZAO.Mind.visiblePeople
            and ZAO.Mind.visiblePeople(mind, body, now, GATHER_RADIUS) or {}
        for _, person in ipairs(people) do
            if person.state ~= "crossed" and person.relationship > -0.35 then
                addressed[#addressed + 1] = person.id
                if #addressed >= 3 then break end
            end
        end
    else
        addressed = knownRecipients(personId, group, context)
    end
    if #addressed == 0 then return nil end

    local record = SAO.Identity and SAO.Identity.get(personId) or nil
    local x = body and body:getX() or record and (record.homeX or record.x)
    local y = body and body:getY() or record and (record.homeY or record.y)
    local z = body and body:getZ() or record and (record.homeZ or record.z)
    if group and group.place and tonumber(group.place.x)
        and tonumber(group.place.y) then
        x, y, z = group.place.x, group.place.y, group.place.z or z or 0
    end
    if not (tonumber(x) and tonumber(y)) then return nil end
    z = tonumber(z) or 0
    x, y, z = math.floor(x), math.floor(y), math.floor(z)
    local band = math.max(1, math.min(4, math.floor(pressure * 4) + 1))
    local intentKey = table.concat({ category, tostring(x), tostring(y),
        tostring(z), tostring(band) }, ":")
    local proposal = {
        intentKey = intentKey,
        purpose = "provisioning under current necessity",
        destinationRequired = true,
        destination = { minX = x - 2, minY = y - 2,
            maxX = x + 2, maxY = y + 2, z = z },
        requiredCapabilities = { acquire = true, carry = true, deliver = true },
        responsePolicy = "first-completion",
        expiresAtHours = (tonumber(hours) or 0) + 6,
        scope = { action = "deliver-material", category = category,
            quantity = 1 },
    }
    local shouldAct = ZAO.Driver.matterNeedsAction(personId, "provisioning",
        intentKey, addressed, hours, 2)
    if not shouldAct then return nil end
    return {
        id = "afflicted:provisioning:" .. intentKey,
        kind = "provisioning-matter",
        activity = "requesting-provisioning",
        score = 38 + pressure * 45
            + (tonumber(mind.disposition.talkativeness) or 0) * 4,
        interruptsWork = false,
        detail = "current personal or held-ground necessity",
        organizationId = groupId or mind.standing and mind.standing.group,
        proposal = proposal,
        addressedIds = addressed,
        privateEvidence = {
            source = group and "settlement-necessity"
                or body and "personal-necessity"
                or "retained-personal-necessity",
            needOwner = body and "ZAO.Driver<-SAO.Needs"
                or "ZAO.Driver.settlementPressure<-SAO.Needs",
            foodPressure = foodPressure, waterPressure = waterPressure,
            settlementNecessity = settlementNeed,
            observedAtHours = body and tonumber(hours)
                or retained and tonumber(retained.observedAtHours) or nil,
        },
    }
end

-- Representation-neutral entry used by the shared execution adapter. Missing
-- body evidence cannot manufacture hunger or thirst; a bodyless request needs
-- the driver's retained exact pressure or settlement-owned need evidence.
function Afflicted.originateMatter(personId, body, state, mind, context, hours)
    local option = afflictedProvisioningSituation(body, personId, state, mind,
        nil, hours, context)
    if not option then return nil, "no-afflicted-situation" end
    if option.kind == "provisioning-withdraw" then
        local open = SAO.Organization.openMatter(tostring(personId),
            "provisioning")
        local withdrawn, status = ZAO.Driver.withdrawMatter(personId,
            "provisioning", "necessity-resolved", {
                owner = "ZAO.Afflicted", atHours = tonumber(hours) or 0,
            })
        return open, withdrawn and "withdrawn" or status
    end
    local _, status, process = ZAO.Driver.performMatter(personId,
        "provisioning", option.organizationId, option.proposal,
        option.addressedIds, option.privateEvidence, hours)
    return process, status
end

-- ZAO chooses from the current person's own activity, capability, relations
-- and pressures after SAO has proved reception.  The context contains no
-- diagnosis or diet label; Organization remains the response owner.
function Afflicted.appraiseMatter(personId, body, state, mind, processView,
        base, hours)
    local activity = string.lower(tostring(base.currentActivity or "dormant"))
    local relationship = tonumber(base.relationship) or 0
    local ownNeed = tonumber(base.ownNeed)
    local needAvailable = ownNeed ~= nil
    ownNeed = ownNeed or 0
    local prior = processView and processView.response or nil
    local hostile = base.contest == true or relationship <= -0.45
    local dead = base.dead == true
    local executionAvailable = not (base.constraints
        and base.constraints.executionOwnerAvailable == false)
    local represented = body ~= nil and not (base.constraints
        and base.constraints.represented == false)
    local missingExecutionEvidence = not executionAvailable or not represented
    local incapable = not missingExecutionEvidence and not dead
        and (base.incapable == true or base.canExecute == false)
    local destinationKnown = base.destinationKnown == true
    local disposition = mind and mind.disposition or {}
    local choice, terms = nil, {}
    if prior and prior.response == "accept" and (hostile or dead or incapable) then
        choice = "withdraw"
    elseif hostile then
        choice = "contest"
    elseif dead or incapable then
        choice = "decline"
    elseif missingExecutionEvidence then
        -- Absence of the current ZAO-owned body or execution snapshot is not
        -- evidence of incapacity.  Preserve a revisable answer until the
        -- execution owner can report the actor's actual capability.
        choice = "defer"
    elseif activity ~= "idle" and activity ~= "dormant"
        and activity ~= "holding-place" and activity ~= "gathered" then
        choice = "defer"
    elseif not needAvailable then
        choice = "defer"
    elseif not destinationKnown then
        choice, terms = "counter-propose", { requireDestination = true }
    elseif ownNeed >= 0.80 then
        choice, terms = "qualify", { afterOwnNeed = true, quantity = 1 }
    elseif relationship >= 0.25
        or (tonumber(disposition.compassion) or 0)
            + (tonumber(disposition.discipline) or 0) >= 0.75 then
        choice = "accept"
    elseif relationship <= -0.15 then
        choice = "decline"
    else
        choice, terms = "counter-propose", { quantity = 1,
            requireDestination = true }
    end
    return {
        owner = "ZAO.Driver.appraisal", executor = "ZAO.Driver",
        bodyOwner = "ZAO", currentActivity = activity,
        canAcquire = base.canAcquire == true,
        canCarry = base.canCarry == true,
        canDeliver = base.canDeliver == true,
        canExecute = base.canExecute == true,
        incapable = incapable or dead, dead = dead,
        contest = hostile, ownNeed = ownNeed,
        relationship = relationship, destinationKnown = destinationKnown,
        choice = choice, terms = terms,
        reconsider = prior and prior.response == "defer"
            and choice ~= "defer" or false,
        interests = { relationship = relationship,
            compassion = tonumber(disposition.compassion) or 0,
            discipline = tonumber(disposition.discipline) or 0 },
        constraints = { represented = represented,
            currentActivity = activity,
            executionOwnerAvailable = executionAvailable,
            ownNeedAvailable = needAvailable },
        inputOwners = { currentActivity = "ZAO.Driver",
            capabilities = "ZAO.Mind", ownNeed = base.inputOwners
                and base.inputOwners.ownNeed or "ZAO.Driver",
            relationship = "SAO.Standing", interests = "SAO.Disposition",
            constraints = "ZAO.Driver" },
    }
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
    local provisioning = afflictedProvisioningSituation(body, personId, state,
        mind, now, hours, nil)
    if provisioning then options[#options + 1] = provisioning end
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
    if option.kind == "provisioning-matter" then
        local committed, result = ZAO.Driver.performMatter(personId,
            "provisioning", option.organizationId, option.proposal,
            option.addressedIds, option.privateEvidence, hours)
        return committed == true, committed and "requesting-provisioning"
            or tostring(result or "idle")
    elseif option.kind == "provisioning-withdraw" then
        local withdrawn = ZAO.Driver.withdrawMatter(personId, "provisioning",
            "necessity-resolved", { owner = "ZAO.Driver" })
        return withdrawn == true, withdrawn and "revising-provisioning" or "idle"
    elseif string.sub(tostring(option.kind), 1, 5) == "diet-"
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
