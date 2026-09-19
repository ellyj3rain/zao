-- ZAO_State - the pathogen state surface.
--
-- This module reads the state the pathogen produced. It never rolls a
-- form and never derives one from a person id or clock.

ZAO = ZAO or {}
ZAO.State = ZAO.State or {}
local State = ZAO.State

function State.terminalOf(record, saved)
    local savedTerminal = saved and saved.terminalState or nil
    if savedTerminal == "crossed" or savedTerminal == "afflicted" then
        return savedTerminal
    end
    if record.turnedDormant then
        return "turned"
    elseif record.dead then
        return "dead"
    elseif record.knoxInfected then
        return "infected"
    end
    return "living"
end

function State.decayOf(record, saved)
    local savedDecay = saved and saved.decayState or nil
    if savedDecay then
        return savedDecay
    end
    if record.turnedDormant then
        return "dormant"
    elseif record.dead then
        return "dead"
    elseif record.knoxInfected then
        return "course"
    end
    return "living"
end

function State.formOf(record, saved)
    return saved and saved.currentForm or "none"
end

function State.performanceOf(record, saved)
    return saved and tonumber(saved.formPerformance) or 0.0
end

function State.of(record, hour)
    if type(record) ~= "table" then return nil end
    local saved = ZAO.StateStore
        and ZAO.StateStore.read(record.id) or nil
    local attributes = saved
        and type(saved.attributeMutations) == "table"
        and saved.attributeMutations or {}

    local state = {
        infected = record.knoxInfected,
        immuneProgress = record.immuneProgress,
        infectionSpanHours = record.infectionSpanHours,
        biteDeathAtHours = record.biteDeathAtHours,
        dead = record.dead,
        deathCause = record.deathCause,
        diedAtHours = record.diedAtHours,
        diedInGroup = record.diedInGroup,
        turnedDormant = record.turnedDormant,
        currentForm = State.formOf(record, saved),
        formPerformance = State.performanceOf(record, saved),
        decayState = State.decayOf(record, saved),
        terminalState = State.terminalOf(record, saved),
        attributeMutations = attributes,
        humanCapability = saved and saved.humanCapability or 1.0,
        passiveDecay = saved and saved.passiveDecay or 0.0,
        retainedAbility = saved and saved.retainedAbility or 0.0,
        identityAxes = saved
            and type(saved.identityAxes) == "table"
            and saved.identityAxes or {},
        history = saved and saved.history or {},
        source = saved and saved.source or nil,
        startedDay = saved and saved.startedDay or nil,
        lastAdvancedDay = saved and saved.lastAdvancedDay or nil,
        lastEvent = saved and saved.history
            and saved.history[#saved.history] or nil,
        settlementGroup = saved and saved.settlementGroup
            or record.diedInGroup or record.unitId,
        hour = hour,
    }

    if state.currentForm ~= "none" then
        state.visibleForms = {
            {
                form = state.currentForm,
                performance = state.formPerformance,
            },
        }
    else
        state.visibleForms = {}
    end

    return state
end

function State.visibleForms(record, hour)
    local state = State.of(record, hour)
    return state and state.visibleForms or {}
end

function State.attributeString(state)
    return ZAO.Pathogen and ZAO.Pathogen.attributeString(state) or ""
end

return State
