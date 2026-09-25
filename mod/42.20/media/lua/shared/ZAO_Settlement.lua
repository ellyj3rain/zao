-- ZAO_Settlement.lua - a group of the turned that keeps a place.
--
-- Formation is real, rare, and whole (DR-006): a settlement comes to
-- exist only when turned bodies actually linger together at a place,
-- day after day, and the rare roll goes through. Nothing is placed.
-- What holds a formed settlement together is necessity (DR-021): the
-- members stay because they need it, and the necessity is reckoned
-- from what the members actually need - never set by hand. Success is
-- never encoded; whether a group holds or scatters is an outcome.

ZAO = ZAO or {}
ZAO.Settlement = ZAO.Settlement or {}
local Settlement = ZAO.Settlement

Settlement.groups = Settlement.groups or {}
Settlement.lingering = Settlement.lingering or {}

local MIN_LINGERING_BODIES = 3
local MIN_LINGERING_DAYS = 2

local function clamp01(value)
    value = tonumber(value) or 0.0
    if value < 0.0 then return 0.0 end
    if value > 1.0 then return 1.0 end
    return value
end

local function draw()
    if SAO and SAO.Rand and SAO.Rand.unit then
        local value = nil
        pcall(function() value = SAO.Rand.unit() end)
        if type(value) == "number" then return clamp01(value) end
    end
    local fallback = 0.0
    pcall(function() fallback = ZombRand(1000) / 1000.0 end)
    return clamp01(fallback)
end

function Settlement.form(groupId, place, necessity, kind,
        formationEvidence, needEvidence)
    if type(groupId) ~= "string" or type(place) ~= "table" then return nil end
    local group = {
        id = groupId,
        place = place,
        necessity = clamp01(necessity or 0.0),
        members = {},
        occupied = true,
        formedDay = place.day or nil,
        kind = kind or place.kind,
        formationEvidence = formationEvidence,
        needEvidence = needEvidence or {},
    }
    Settlement.groups[groupId] = group
    return group
end

function Settlement.join(groupId, personId)
    local group = Settlement.groups[groupId]
    if not group then return false end
    group.members[personId] = true
    return true
end

function Settlement.leave(groupId, personId)
    local group = Settlement.groups[groupId]
    if not group then return false end
    group.members[personId] = nil
    local count = 0
    for _ in pairs(group.members) do count = count + 1 end
    if count == 0 then
        group.occupied = false
    end
    return true
end

function Settlement.necessity(groupId, value)
    local group = Settlement.groups[groupId]
    if not group then return nil end
    if value ~= nil then
        group.necessity = clamp01(value)
    end
    return group.necessity
end

function Settlement.active()
    local active = {}
    for _, group in pairs(Settlement.groups) do
        if group.occupied then active[#active + 1] = group end
    end
    return active
end

-- A body standing somewhere is a fact. The controller notes each
-- claimed body's place each scan; when enough bodies share a place
-- across enough consecutive days, the rare formation roll happens.
-- Returns the formed group on the day the roll goes through.
local HOLDING_ACTIVITY = {
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

function Settlement.notePresence(placeKey, personId, day, kind, position,
        evidence)
    if type(placeKey) ~= "string" or type(personId) ~= "string" then
        return nil
    end
    day = tonumber(day) or 0
    kind = tostring(kind or "turned")
    if kind ~= "turned" and kind ~= "afflicted" and kind ~= "crossed" then
        return nil
    end
    if kind ~= "turned" then
        local activity = type(evidence) == "table"
            and tostring(evidence.activity or "") or ""
        if not (HOLDING_ACTIVITY[kind]
            and HOLDING_ACTIVITY[kind][activity]) then return nil end
    end
    local lingerKey = kind .. ":" .. placeKey

    local linger = Settlement.lingering[lingerKey]
    if not linger then
        linger = { currentDay = nil, currentCount = 0, members = {},
                   evidence = {},
                   streak = 0, kind = kind, placeKey = placeKey }
        Settlement.lingering[lingerKey] = linger
    end

    if linger.currentDay ~= day then
        -- The day turned over. Yesterday only counts toward the
        -- streak if enough bodies actually stood there.
        if linger.currentDay == day - 1
            and linger.currentCount >= MIN_LINGERING_BODIES then
            linger.streak = (tonumber(linger.streak) or 0) + 1
        else
            linger.streak = 0
        end
        linger.currentDay = day
        linger.currentCount = 0
        linger.members = {}
        linger.evidence = {}
    end

    -- A scan is not a body. Repeated calls for one person during the same day
    -- update position but cannot impersonate the three distinct participants
    -- required for formation.
    if not linger.members[personId] then
        linger.currentCount = (tonumber(linger.currentCount) or 0) + 1
        linger.members[personId] = true
    end
    if type(evidence) == "table" then
        linger.evidence[personId] = {
            version = tonumber(evidence.version) or 1,
            activity = tostring(evidence.activity or ""),
            activityRevision = tonumber(evidence.activityRevision) or 0,
            sinceHours = tonumber(evidence.sinceHours),
            observedAtHours = tonumber(evidence.observedAtHours),
        }
    end
    if type(position) == "table" then
        linger.position = {
            x = tonumber(position.x), y = tonumber(position.y),
            z = tonumber(position.z) or 0,
        }
    end

    if linger.currentCount < MIN_LINGERING_BODIES then return nil end
    if (tonumber(linger.streak) or 0) < MIN_LINGERING_DAYS - 1 then
        return nil
    end

    local groupId = kind .. "-" .. placeKey
    if Settlement.groups[groupId] then return nil end

    local policy = ZAO.Sandbox and ZAO.Sandbox.policy() or nil
    local odds = policy and tonumber(policy.settlementOdds) or 0.02
    if draw() >= clamp01(odds) then return nil end

    local formationEvidence = { version = 1, day = day, members = {} }
    for memberId, memberEvidence in pairs(linger.evidence or {}) do
        formationEvidence.members[memberId] = memberEvidence
    end
    local group = Settlement.form(groupId, {
        key = placeKey,
        day = day,
        kind = kind,
        x = linger.position and linger.position.x or nil,
        y = linger.position and linger.position.y or nil,
        z = linger.position and linger.position.z or nil,
    }, 0.0, kind, formationEvidence)
    if group then
        for memberId in pairs(linger.members) do
            Settlement.join(groupId, memberId)
        end
        Settlement.reckon(groupId)
        Settlement.lingering[lingerKey] = nil
        return group
    end
    return nil
end

-- Necessity follows from what the members need (DR-021). Living ZAO people are
-- reckoned by their shared execution owner so state-specific maintenance
-- cannot be replaced by SAO survivor hunger. Turned bodies retain the older
-- mutation-pressure path. Unknown dormant need preserves the prior reckoning.
function Settlement.reckon(groupId)
    local group = Settlement.groups[groupId]
    if not group then return nil end

    local total, count, memberCount = 0.0, 0, 0
    group.needEvidence = group.needEvidence or {}
    for personId in pairs(group.members) do
        memberCount = memberCount + 1
        local need, evidence = nil, nil
        local state = ZAO.Pathogen and ZAO.Pathogen.stateOf
            and ZAO.Pathogen.stateOf(tostring(personId)) or nil
        if state and (state.terminalState == "afflicted"
            or state.terminalState == "crossed") and ZAO.Driver
            and ZAO.Driver.settlementPressure then
            local body = ZAO.Controller and ZAO.Controller.controlled
                and ZAO.Controller.controlled[tostring(personId)] or nil
            pcall(function()
                need, evidence = ZAO.Driver.settlementPressure(
                    tostring(personId), body, state)
            end)
        elseif SAO and SAO.Pressure then
            pcall(function()
                need = math.max(
                    tonumber(SAO.Pressure.needs(personId)) or 0.0,
                    tonumber(SAO.Pressure.injury(personId)) or 0.0)
            end)
        end
        if type(need) == "number" then
            total = total + clamp01(need)
            count = count + 1
            group.needEvidence[tostring(personId)] = evidence or {
                version = 1,
                value = clamp01(need),
                terminalState = state and state.terminalState or "turned",
                source = "SAO.Pressure",
            }
        end
    end
    if count == 0 then
        -- No current observation is not proof that a still-membered group
        -- dissolved or that its needs became zero.
        if memberCount == 0 then group.occupied = false end
        return group.necessity
    end
    group.necessity = clamp01(total / count)
    return group.necessity
end

return Settlement
