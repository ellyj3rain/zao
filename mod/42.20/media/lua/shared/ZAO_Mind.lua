-- ZAO_Mind - a ZAO-owned view of the person's existing four pillars.
--
-- ZAO does not reconstruct a person from a species template. Perception,
-- Disposition and Standing remain the sister's person-owned stores; this
-- module reads those stores and applies only the pathogen's established
-- identity-axis survival. The returned table is a runtime decision view, not
-- another durable mind or planner.

ZAO = ZAO or {}
ZAO.Mind = ZAO.Mind or {}
local Mind = ZAO.Mind

local function axisSurvival(state, axis)
    local axes = state and type(state.identityAxes) == "table"
        and state.identityAxes or nil
    if not axes then return 1.0 end
    local value = tonumber(axes[axis])
    if value == nil then return 1.0 end
    if value < 0.0 then return 0.0 end
    if value > 1.0 then return 1.0 end
    return value
end

local function safe(call, fallback)
    local ok, value = pcall(call)
    if ok and value ~= nil then return value end
    return fallback
end

local function dispositionOf(id, record, state)
    local source = safe(function()
        return SAO and SAO.Disposition and SAO.Disposition.traits
            and SAO.Disposition.traits(id) or nil
    end, nil)
    if type(source) ~= "table" then
        source = type(record.traitEchoes) == "table" and record.traitEchoes or {}
    end
    local out = {}
    for key, value in pairs(source) do
        if type(value) == "number" then
            out[key] = value * axisSurvival(state, key)
        else
            out[key] = value
        end
    end
    for _, key in ipairs({ "aggression", "selfPreservation", "initiative",
            "discipline", "nerve", "compassion", "talkativeness" }) do
        if out[key] == nil then out[key] = 0 end
    end
    return out
end

local function standingOf(id, record)
    local group = safe(function()
        return SAO and SAO.Standing and SAO.Standing.groupOf
            and SAO.Standing.groupOf(id) or nil
    end, nil)
    local relations = safe(function()
        return SAO and SAO.Standing and SAO.Standing.relationsOf
            and SAO.Standing.relationsOf(id) or nil
    end, nil)
    local personalClaim = safe(function()
        return SAO and SAO.Standing and SAO.Standing.claimOf
            and SAO.Standing.claimOf(id) or nil
    end, nil)
    local groupClaim = safe(function()
        return group and SAO and SAO.Standing and SAO.Standing.groupClaimOf
            and SAO.Standing.groupClaimOf(group) or nil
    end, nil)
    return {
        group = group or record.diedInGroup or record.unitId,
        relations = type(relations) == "table" and relations or {},
        claims = { personal = personalClaim, group = groupClaim },
    }
end

local function needsOf(body)
    if not body then return nil end
    return safe(function()
        return SAO and SAO.Needs and SAO.Needs.read
            and SAO.Needs.read(body) or nil
    end, nil)
end

-- Fear remains another person's private state. A Crossed observer can react
-- only to conduct that is presently visible. Running and sprinting are public
-- body facts, so they provide a bounded distress signal without reading the
-- target's moodles, intentions or future state.
local function visibleDistress(other)
    local signal = 0
    pcall(function()
        if other.isSprinting and other:isSprinting() then
            signal = 1.0
        elseif other.isRunning and other:isRunning() then
            signal = 0.6
        end
    end)
    return signal
end

function Mind.of(record, hour, body)
    if type(record) ~= "table" then return nil end
    local id = tostring(record.id or "")
    if id == "" then return nil end
    local state = ZAO.State and ZAO.State.of and ZAO.State.of(record, hour)
        or ZAO.Pathogen and ZAO.Pathogen.stateOf
            and ZAO.Pathogen.stateOf(id) or nil
    if type(state) ~= "table" then return nil end

    local beliefs = safe(function()
        return SAO and SAO.Perception and SAO.Perception.beliefs
            and SAO.Perception.beliefs[id] or nil
    end, nil)
    if type(beliefs) ~= "table" then beliefs = {} end
    beliefs.people = type(beliefs.people) == "table" and beliefs.people or {}
    beliefs.zombies = type(beliefs.zombies) == "table" and beliefs.zombies or {}

    local verbsSurvival = axisSurvival(state, "verbs")
    local nutritionPenalty = ZAO.Maintenance
        and ZAO.Maintenance.afflictedPenalty
        and ZAO.Maintenance.afflictedPenalty(state, tonumber(hour) or 0) or 0
    return {
        personId = id,
        perception = {
            beliefs = beliefs,
            people = beliefs.people,
            zombies = beliefs.zombies,
            decay = state.decayState,
            survival = axisSurvival(state, "perception"),
            owner = "SAO.Perception",
        },
        disposition = dispositionOf(id, record, state),
        standing = standingOf(id, record),
        execution = {
            retainedVerbs = type(record.verbs) == "table" and record.verbs or {},
            canMove = state.terminalState ~= "dead" and verbsSurvival > 0.0,
            canTarget = state.terminalState ~= "dead" and verbsSurvival > 0.0,
            survival = verbsSurvival,
            performance = verbsSurvival * (1.0 - nutritionPenalty),
            nutritionPenalty = nutritionPenalty,
            owner = "ZAO.Driver+SAO native services",
        },
        physical = needsOf(body),
        pathogen = state,
        inputOwners = {
            perception = "SAO.Perception",
            disposition = "SAO.Disposition",
            standing = "SAO.Standing",
            execution = "ZAO.Driver+SAO native services",
            physical = body and "SAO.Needs" or "unrepresented",
            pathogen = "ZAO.Pathogen",
        },
    }
end

-- Return only people this actor privately observed and can still see. ZAO may
-- attach the currently visible pathogen state to that actor's belief after the
-- native sight recheck; no other actor gains it and a stale/told row cannot
-- become a target. The state lookup happens after sight, never before it.
function Mind.visiblePeople(mind, body, tick, range)
    if not (mind and body and mind.personId and mind.perception
        and type(mind.perception.people) == "table") then return {} end
    local id = tostring(mind.personId)
    local out = {}
    for key, belief in pairs(mind.perception.people) do
        local fresh = nil
        if SAO and SAO.Perception and SAO.Perception.freshObservedPerson then
            fresh = SAO.Perception.freshObservedPerson(id, key, tick)
        elseif type(belief) == "table" and belief.source == "observed"
            and not belief.dead and tonumber(belief.at)
            and tonumber(tick) and tonumber(tick) - tonumber(belief.at) <= 120 then
            fresh = belief
        end
        if fresh then
            local otherId = fresh.id and tostring(fresh.id) or nil
            if not otherId and SAO and SAO.Identity and SAO.Identity.idByName then
                otherId = SAO.Identity.idByName(key)
            end
            if not otherId and SAO and SAO.Standing
                and SAO.Standing.keyForObserved then
                otherId = SAO.Standing.keyForObserved(key)
            end
            if otherId and otherId ~= id then
                local other = SAO and SAO.Communication
                    and SAO.Communication.bodyFor
                    and SAO.Communication.bodyFor(otherId) or nil
                local seen = false
                if other and SAOJavaBridge and SAOJavaBridge.canSeePersonNow then
                    seen = safe(function()
                        return SAOJavaBridge:canSeePersonNow(body, other,
                            tonumber(range) or 30.0) == true
                    end, false)
                end
                if seen then
                    local dx, dy = other:getX() - body:getX(),
                        other:getY() - body:getY()
                    local targetState = ZAO.Pathogen and ZAO.Pathogen.stateOf
                        and ZAO.Pathogen.stateOf(otherId) or nil
                    fresh.zaoState = targetState
                        and tostring(targetState.terminalState or "") or "ordinary"
                    fresh.zaoStateObservedAt = tick
                    fresh.zaoVisibleDistress = visibleDistress(other)
                    local relationship = safe(function()
                        return SAO and SAO.Standing and SAO.Standing.trust
                            and SAO.Standing.trust(id, otherId) or 0
                    end, 0)
                    out[#out + 1] = {
                        id = tostring(otherId), key = key, body = other,
                        belief = fresh, distance = math.sqrt(dx * dx + dy * dy),
                        state = fresh.zaoState,
                        visibleDistress = fresh.zaoVisibleDistress,
                        relationship = tonumber(relationship) or 0,
                    }
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if a.distance ~= b.distance then return a.distance < b.distance end
        return a.id < b.id
    end)
    return out
end

return Mind
