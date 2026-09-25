-- ZAO_StateStore - durable pathogen, settlement, and recovery state.

ZAO = ZAO or {}
ZAO.StateStore = ZAO.StateStore or {}
local StateStore = ZAO.StateStore

local STORE_KEY = "ZombieAwareness_State"

function StateStore.store()
    local ok, store = pcall(function()
        return ModData.getOrCreate(STORE_KEY)
    end)
    if not ok or type(store) ~= "table" then return nil end
    store.people = store.people or {}
    store.brain = store.brain or {}
    store.exposures = store.exposures or {}
    store.exposureResults = store.exposureResults or {}
    store.driverResults = store.driverResults or {}
    store.butcherActions = store.butcherActions or {}
    store.butcherResults = store.butcherResults or {}
    store.dietActions = store.dietActions or {}
    store.dietResults = store.dietResults or {}
    store.contaminationPrep = store.contaminationPrep or {}
    store.contaminationPrepResults = store.contaminationPrepResults or {}
    store.contaminationHits = store.contaminationHits or {}
    store.contaminationResults = store.contaminationResults or {}
    store.maintenanceResults = store.maintenanceResults or {}
    store.predationActions = store.predationActions or {}
    store.predationResults = store.predationResults or {}
    store.settlements = store.settlements or {}
    store.recovery = store.recovery or {}
    return store
end

function StateStore.write(personId, state)
    if type(personId) ~= "string" or type(state) ~= "table" then
        return false
    end
    local store = StateStore.store()
    if not store then return false end

    local existing = store.people[personId] or {}
    local history = state.history or existing.history or {}
    local attributes = type(state.attributeMutations) == "table"
        and state.attributeMutations or {}
    if #history > 32 then
        for index = 1, #history - 32 do
            table.remove(history, 1)
        end
    end

    store.people[personId] = {
        personId = personId,
        terminalState = state.terminalState,
        currentForm = state.currentForm,
        formPerformance = state.formPerformance,
        decayState = state.decayState,
        settlementGroup = state.settlementGroup,
        attributeMutations = attributes,
        humanCapability = state.humanCapability,
        passiveDecay = state.passiveDecay,
        retainedAbility = state.retainedAbility,
        identityAxes = type(state.identityAxes) == "table"
            and state.identityAxes or nil,
        startedDay = state.startedDay,
        lastAdvancedDay = state.lastAdvancedDay,
        source = state.source,
        history = history,
        returnSequence = state.returnSequence or existing.returnSequence,
        returnEvent = state.returnEvent or existing.returnEvent,
        deathSequence = state.deathSequence or existing.deathSequence,
        exposureTokens = state.exposureTokens or existing.exposureTokens,
        -- One execution identity survives Afflicted/Crossed state changes.
        -- The historical Crossed token remains readable for old saves and
        -- sister versions, but is no longer the ownership model.
        driverToken = state.driverToken or existing.driverToken
            or state.crossedTransferToken or existing.crossedTransferToken,
        crossedTransferToken = state.crossedTransferToken
            or existing.crossedTransferToken,
        lastExposureAt = state.lastExposureAt or existing.lastExposureAt,
        driver = type(state.driver) == "table" and state.driver
            or existing.driver,
        maintenance = type(state.maintenance) == "table" and state.maintenance
            or existing.maintenance,
    }

    if state.settlementGroup then
        local group = store.settlements[state.settlementGroup]
        if type(group) ~= "table" then
            group = { members = {} }
            store.settlements[state.settlementGroup] = group
        end
        group.members = group.members or {}
        group.members[personId] = true
    end

    store.recovery[personId] = {
        antibody = state.antibody,
        cure = state.cure,
        repeatInfections = state.repeatInfections,
    }
    return true
end

function StateStore.read(personId)
    if type(personId) ~= "string" then return nil end
    local store = StateStore.store()
    if not store then return nil end
    return store.people[personId]
end

-- A reversion event licenses one return. A still-afflicted state alone must
-- not license another return after a later, unrelated death.
function StateStore.returnAuthorization(personId)
    local state = StateStore.read(personId)
    if not state or state.terminalState ~= "afflicted" then return nil end
    if not state.returnEvent then
        for index = #(state.history or {}), 1, -1 do
            local event = state.history[index]
            if event.type == "reversion" then
                state.returnEvent = { token = "legacy:" .. tostring(event.day)
                    .. ":" .. tostring(state.startedDay), day = event.day }
                break
            end
        end
    end
    return state.returnEvent
end

function StateStore.recoveryOf(personId)
    if type(personId) ~= "string" then return nil end
    local store = StateStore.store()
    if not store then return nil end
    return store.recovery[personId]
end

function StateStore.settlementOf(personId)
    if type(personId) ~= "string" then return nil end
    local store = StateStore.store()
    if not store then return nil end
    for groupId, group in pairs(store.settlements) do
        if type(group) == "table" and type(group.members) == "table"
            and group.members[personId] then
            return groupId
        end
    end
    return nil
end

function StateStore.leaveSettlement(personId, groupId)
    personId = tostring(personId or "")
    local store = StateStore.store()
    if not store or personId == "" then return false end
    groupId = groupId or StateStore.settlementOf(personId)
    if not groupId then return false end
    groupId = tostring(groupId)
    local group = store.settlements[groupId]
    if type(group) == "table" and type(group.members) == "table" then
        group.members[personId] = nil
    end
    local state = store.people[personId]
    if state and tostring(state.settlementGroup or "") == groupId then
        state.settlementGroup = nil
    end
    if ZAO.Settlement and ZAO.Settlement.leave then
        ZAO.Settlement.leave(groupId, personId)
    end
    return true
end

-- A formed settlement's own facts - the place it keeps and the
-- necessity its members' needs reckoned - persist with the members so
-- a reopened world restores what these bodies did, never a default.
function StateStore.writeSettlement(groupId, place, necessity)
    if type(groupId) ~= "string" then return false end
    local store = StateStore.store()
    if not store then return false end
    local group = store.settlements[groupId]
    if type(group) ~= "table" then
        group = { members = {} }
        store.settlements[groupId] = group
    end
    group.place = place or group.place or nil
    group.kind = type(place) == "table" and place.kind or group.kind
    local runtime = ZAO.Settlement and ZAO.Settlement.groups
        and ZAO.Settlement.groups[groupId] or nil
    if runtime and type(runtime.members) == "table" then
        for personId in pairs(runtime.members) do
            group.members[tostring(personId)] = true
        end
        group.formationEvidence = runtime.formationEvidence
            or group.formationEvidence
        group.needEvidence = runtime.needEvidence or group.needEvidence
    end
    if type(necessity) == "number" then
        group.necessity = necessity
    end
    return true
end

function StateStore.restoreSettlements()
    local store = StateStore.store()
    if not store or not ZAO.Settlement then return false end
    -- [A36] These are projections, not a second durable owner. Rebuilding in
    -- one Lua environment must first remove the preceding world's groups and
    -- its unfinished formation observations.
    for key in pairs(ZAO.Settlement.groups) do
        ZAO.Settlement.groups[key] = nil
    end
    for key in pairs(ZAO.Settlement.lingering) do
        ZAO.Settlement.lingering[key] = nil
    end
    for groupId, group in pairs(store.settlements) do
        local members = type(group) == "table"
            and type(group.members) == "table" and group.members
            or type(group) == "table" and group or {}
        if not ZAO.Settlement.groups[groupId] then
            ZAO.Settlement.form(
                groupId,
                type(group) == "table"
                    and type(group.place) == "table" and group.place
                    or {},
                type(group) == "table"
                    and tonumber(group.necessity) or 0.0,
                type(group) == "table" and group.kind or nil,
                type(group) == "table" and group.formationEvidence or nil,
                type(group) == "table" and group.needEvidence or nil)
        end
        for personId in pairs(members) do
            ZAO.Settlement.join(groupId, tostring(personId))
        end
    end
    return true
end

if StateStore.onGameStart then
    Events.OnGameStart.Remove(StateStore.onGameStart)
end
StateStore.onGameStart = function()
    StateStore.restoreSettlements()
end
Events.OnGameStart.Add(StateStore.onGameStart)

return StateStore
