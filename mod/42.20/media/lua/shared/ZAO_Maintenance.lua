-- ZAO_Maintenance - durable needs and evidenced relief for living ZAO people.
--
-- A need is not a behavior.  This owner advances Afflicted nutrition effects
-- and Crossed predatory pressure across loaded, dormant, and reload paths.
-- State policies may offer many ways to answer those pressures; only an exact
-- completed result recorded here changes them.

ZAO = ZAO or {}
ZAO.Maintenance = ZAO.Maintenance or {}
local Maintenance = ZAO.Maintenance

Maintenance.profile = Maintenance.profile or {
    version = 2,
    survivorHungerPerHour = 0.012,
    thirstPerHour = 0.020,
    predatoryPressurePerHour = 0.012,
    afflictedAlternativeRelief = 0.60,
    afflictedAlternativePenalty = 0.18,
    afflictedAlternativePenaltyHours = 24.0,
    maxHumanProtection = 0.75,
}

local function clamp01(value)
    value = tonumber(value) or 0
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function rootStore()
    local root = ZAO.StateStore and ZAO.StateStore.store() or nil
    if not root then return nil end
    root.maintenanceResults = root.maintenanceResults or {}
    return root
end

local function rowOf(state, atHours)
    if type(state) ~= "table" then return nil end
    local row = type(state.maintenance) == "table" and state.maintenance or {}
    state.maintenance = row
    row.version = 2
    row.receiptSequence = tonumber(row.receiptSequence) or 0
    if not finite(tonumber(row.lastAdvancedHours)) and finite(atHours) then
        row.lastAdvancedHours = atHours
    end
    if tostring(state.terminalState or "") == "crossed" then
        row.predatory = type(row.predatory) == "table" and row.predatory or {
            pressure = 0,
        }
        row.predatory.pressure = clamp01(row.predatory.pressure)
    elseif tostring(state.terminalState or "") == "afflicted" then
        row.nutrition = type(row.nutrition) == "table" and row.nutrition or {
            humanMeals = 0,
        }
    end
    return row
end

function Maintenance.ensure(state, atHours)
    return rowOf(state, tonumber(atHours))
end

function Maintenance.advanceState(state, atHours)
    atHours = tonumber(atHours)
    if type(state) ~= "table" or not finite(atHours) then return false end
    local row = rowOf(state, atHours)
    local previous = tonumber(row.lastAdvancedHours) or atHours
    if atHours <= previous then return true end
    local elapsed = atHours - previous
    if tostring(state.terminalState or "") == "crossed" then
        local predatory = row.predatory
        predatory.pressure = clamp01((tonumber(predatory.pressure) or 0)
            + elapsed * Maintenance.profile.predatoryPressurePerHour)
        predatory.lastAdvancedHours = atHours
    elseif tostring(state.terminalState or "") == "afflicted" then
        local nutrition = row.nutrition
        if tonumber(nutrition.alternativePenaltyUntilHours) ~= nil
            and atHours >= tonumber(nutrition.alternativePenaltyUntilHours) then
            nutrition.alternativePenalty = nil
            nutrition.alternativePenaltyUntilHours = nil
        end
        if type(nutrition.crossedProtection) == "table"
            and atHours >= (tonumber(nutrition.crossedProtection.untilHours)
                or -1) then
            nutrition.crossedProtection = nil
        end
    end
    row.lastAdvancedHours = atHours
    return true
end

local function stat(body, key)
    local value = nil
    pcall(function() value = body:getStats():get(key) end)
    return finite(tonumber(value)) and tonumber(value) or nil
end

local function setStat(body, key, value)
    return pcall(function() body:getStats():set(key, clamp01(value)) end)
end

-- The shell has just been restored with zero native elapsed time.  Advance
-- only the physiology owned by the terminal state; never auto-select food.
function Maintenance.advanceDormant(personId, state, body, elapsedHours,
        atHours)
    elapsedHours, atHours = tonumber(elapsedHours), tonumber(atHours)
    if tostring(personId or "") == "" or type(state) ~= "table" or not body
        or not finite(elapsedHours) or elapsedHours < 0 or not finite(atHours)
        or not CharacterStat then return false, "invalid-dormant-advance" end
    local terminal = tostring(state.terminalState or "")
    if terminal ~= "afflicted" and terminal ~= "crossed" then
        return false, "unsupported-terminal-state"
    end
    local row = rowOf(state, atHours - elapsedHours)
    Maintenance.advanceState(state, atHours)
    local hunger, thirst = stat(body, CharacterStat.HUNGER),
        stat(body, CharacterStat.THIRST)
    if hunger == nil or thirst == nil then return false, "stats-unavailable" end
    local nextHunger = hunger + elapsedHours
        * Maintenance.profile.survivorHungerPerHour
    local nextThirst = thirst + elapsedHours * Maintenance.profile.thirstPerHour
    if not setStat(body, CharacterStat.HUNGER, nextHunger)
        or not setStat(body, CharacterStat.THIRST, nextThirst) then
        return false, "stats-refused"
    end
    row.physiology = type(row.physiology) == "table" and row.physiology or {}
    row.physiology.lastAppliedHunger = clamp01(nextHunger)
    row.physiology.lastObservedThirst = clamp01(nextThirst)
    row.physiology.lastObservedAtHours = atHours
    row.physiology.lastDormantElapsedHours = elapsedHours
    return true, "state-owned-physiology-advanced"
end

-- Loaded native time moves both living states through the ordinary human shell.
-- ZAO observes that physiology without rewriting it. State-specific motives
-- and completed food consequences remain separate from caloric passage.
function Maintenance.observeLoaded(personId, state, body, atHours)
    atHours = tonumber(atHours)
    if type(state) ~= "table" or not body or not finite(atHours) then
        return false
    end
    Maintenance.advanceState(state, atHours)
    local row = rowOf(state, atHours)
    row.physiology = type(row.physiology) == "table" and row.physiology or {}
    local physiology = row.physiology
    if CharacterStat then
        physiology.lastObservedHunger = stat(body, CharacterStat.HUNGER)
        physiology.lastObservedThirst = stat(body, CharacterStat.THIRST)
    end
    physiology.lastObservedAtHours = atHours
    return true
end

function Maintenance.predatoryPressure(state, atHours)
    if type(state) ~= "table" or state.terminalState ~= "crossed" then
        return nil
    end
    if finite(tonumber(atHours)) then Maintenance.advanceState(state, atHours) end
    local row = rowOf(state, tonumber(atHours))
    return clamp01(row.predatory and row.predatory.pressure or 0)
end

local DEFAULT_RELIEF = {
    fear = 0.08,
    pain = 0.16,
    control = 0.24,
    consumption = 0.12,
    desecration = 0.10,
    death = 0.0,
}

function Maintenance.recordPredatoryOutcome(personId, state, kind, amount,
        token, atHours, evidence)
    personId, kind, token = tostring(personId or ""), tostring(kind or ""),
        tostring(token or "")
    atHours = tonumber(atHours) or 0
    local root = rootStore()
    if not root or personId == "" or token == "" or type(state) ~= "table"
        or state.terminalState ~= "crossed" then return nil end
    if root.maintenanceResults[token] then return root.maintenanceResults[token] end
    Maintenance.advanceState(state, atHours)
    local row = rowOf(state, atHours)
    local before = clamp01(row.predatory.pressure)
    local relief = clamp01(amount ~= nil and amount or DEFAULT_RELIEF[kind] or 0)
    local after = clamp01(before - relief)
    row.predatory.pressure = after
    row.predatory.lastOutcomeAtHours = atHours
    row.predatory.lastOutcomeKind = kind
    local receipt = {
        version = 1,
        token = token,
        personId = personId,
        terminalState = "crossed",
        kind = kind,
        completed = true,
        pressureBefore = before,
        relief = relief,
        pressureAfter = after,
        atHours = atHours,
        evidence = type(evidence) == "table" and evidence or {},
    }
    root.maintenanceResults[token] = receipt
    return receipt
end

function Maintenance.recordAfflictedMeal(personId, state, profile, token,
        atHours)
    personId, token = tostring(personId or ""), tostring(token or "")
    atHours = tonumber(atHours) or 0
    local root = rootStore()
    if not root or personId == "" or token == "" or type(state) ~= "table"
        or state.terminalState ~= "afflicted" or type(profile) ~= "table" then
        return nil
    end
    if root.maintenanceResults[token] then return root.maintenanceResults[token] end
    Maintenance.advanceState(state, atHours)
    local row = rowOf(state, atHours)
    local nutrition = row.nutrition
    local class = tostring(profile.class or "alternative")
    local receipt = {
        version = 1,
        token = token,
        personId = personId,
        terminalState = "afflicted",
        kind = "meal",
        foodClass = class,
        completed = true,
        atHours = atHours,
        donor = type(profile.donor) == "table" and profile.donor or nil,
    }
    if class == "human" then
        local donor = receipt.donor or {}
        local health = clamp01(donor.health)
        local survived = math.max(0, tonumber(donor.infectionsSurvived) or 0)
        local progress = clamp01(donor.immuneProgress)
        local adaptation = clamp01(survived * 0.20 + progress * 0.50)
        local protection = math.min(Maintenance.profile.maxHumanProtection,
            0.12 + health * 0.20 + adaptation * 0.43)
        local duration = 24.0 + adaptation * 72.0
        nutrition.humanMeals = (tonumber(nutrition.humanMeals) or 0) + 1
        nutrition.crossedProtection = {
            amount = protection,
            untilHours = atHours + duration,
            sourceToken = token,
            donorPersonId = donor.personId,
            donorHealth = health,
            donorAdaptation = adaptation,
        }
        nutrition.alternativePenalty = nil
        nutrition.alternativePenaltyUntilHours = nil
        receipt.crossedProtection = protection
        receipt.protectionUntilHours = atHours + duration
    elseif class == "protein" then
        nutrition.alternativePenalty = nil
        nutrition.alternativePenaltyUntilHours = nil
    else
        nutrition.alternativePenalty = Maintenance.profile.afflictedAlternativePenalty
        nutrition.alternativePenaltyUntilHours = atHours
            + Maintenance.profile.afflictedAlternativePenaltyHours
        receipt.performancePenalty = nutrition.alternativePenalty
        receipt.penaltyUntilHours = nutrition.alternativePenaltyUntilHours
    end
    nutrition.lastMeal = receipt
    root.maintenanceResults[token] = receipt
    return receipt
end

function Maintenance.afflictedPenalty(state, atHours)
    if type(state) ~= "table" or state.terminalState ~= "afflicted" then
        return 0
    end
    Maintenance.advanceState(state, tonumber(atHours) or 0)
    local row = rowOf(state, tonumber(atHours) or 0)
    return clamp01(row.nutrition and row.nutrition.alternativePenalty or 0)
end

function Maintenance.exposureProtection(state, atHours)
    if type(state) ~= "table" or state.terminalState ~= "afflicted" then
        return 0, nil
    end
    atHours = tonumber(atHours) or 0
    Maintenance.advanceState(state, atHours)
    local row = rowOf(state, atHours)
    local protection = row.nutrition and row.nutrition.crossedProtection or nil
    if type(protection) ~= "table" then return 0, nil end
    return clamp01(protection.amount), protection
end

return Maintenance
