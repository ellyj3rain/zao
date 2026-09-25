-- ZAO_Pathogen - the pathogen's event-driven state.
--
-- A body's form, performance, attributes, decay, and reversion are
-- produced by pathogen events and daily advancement. Nothing here is
-- derived from a person id or a clock at read time.

ZAO = ZAO or {}
ZAO.Pathogen = ZAO.Pathogen or {}
local Pathogen = ZAO.Pathogen

local function clamp01(value)
    value = tonumber(value) or 0.0
    if value < 0.0 then return 0.0 end
    if value > 1.0 then return 1.0 end
    return value
end

local function hasEntries(t)
    if type(t) ~= "table" then return false end
    for _ in pairs(t) do return true end
    return false
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

local function dial(name, derived)
    local policy = ZAO.Sandbox and ZAO.Sandbox.policy() or nil
    local value = policy and tonumber(policy[name]) or nil
    if value == nil then return derived end
    return clamp01(value)
end

local function capabilityOf(record)
    if SAO and SAO.Course and SAO.Course.constitutionOf
        and record and record.id then
        local constitution = nil
        pcall(function()
            constitution = SAO.Course.constitutionOf(record.id)
        end)
        if type(constitution) == "number" then
            return clamp01((constitution - 0.55) / 1.05)
        end
    end
    return 0.5
end

local function remember(state, event)
    state.history = state.history or {}
    state.history[#state.history + 1] = event
    if #state.history > 32 then
        table.remove(state.history, 1)
    end
end

-- Afflicted and Crossed have different pressures and actions, but the same
-- execution owner. This token identifies that durable ZAO driver independently
-- of the current terminal state, so an intentional Afflicted-to-Crossed change
-- cannot briefly return the human shell to SAO or create a second executor.
function Pathogen.ensureDriverToken(state, personId)
    if type(state) ~= "table" then return nil end
    local terminal = tostring(state.terminalState or "")
    if terminal ~= "afflicted" and terminal ~= "crossed" then return nil end
    personId = tostring(personId or state.personId or "")
    if personId == "" then return nil end
    local token = state.driverToken or state.crossedTransferToken
    if token == nil or tostring(token) == "" then
        local event = state.returnEvent and state.returnEvent.token or nil
        local basis = event or (tostring(state.startedDay or 0)
            .. ":" .. tostring(#(state.history or {}) + 1))
        token = "zao-person:" .. personId .. ":" .. tostring(basis)
    end
    state.driverToken = tostring(token)
    if terminal == "crossed" then
        state.crossedTransferToken = state.crossedTransferToken
            or state.driverToken
    end
    return state.driverToken
end

-- The course events the Java bridge keeps per person. These fire only
-- at the pathogen's own event boundary - begin and expose - which SAO
-- drives from real events (infection, death, turn, recovery).
local function courseEvent(verb, personId)
    if not ZAOJavaBridge then return end
    pcall(function() ZAOJavaBridge[verb](ZAOJavaBridge, personId) end)
end

-- Identity decay is episodic, never steady (DR-020). The turn already
-- fractured the memory; where an afflicted body loses more, an episode
-- takes depth from one or two axes, which axis varies per body by a
-- genuinely random draw, and the episode lands in the history.
local IDENTITY_AXES = {
    "aggression",
    "selfPreservation",
    "initiative",
    "discipline",
    "nerve",
    "perception",
    "verbs",
}

local function identityDecayEpisode(state, day)
    local policy = ZAO.Sandbox and ZAO.Sandbox.policy() or nil
    local odds = policy and tonumber(policy.identityDecayOdds) or 0.01
    local depth = policy and tonumber(policy.identityDecayDepth) or 0.10
    odds = clamp01(odds)
    depth = clamp01(depth)
    if draw() >= odds then return false end

    state.identityAxes = state.identityAxes or {}
    for _, axis in ipairs(IDENTITY_AXES) do
        if state.identityAxes[axis] == nil then
            state.identityAxes[axis] = 1.0
        end
    end

    local axesTouched = {}
    local count = draw() < 0.5 and 1 or 2
    for _ = 1, count do
        local pickAxis = clamp01(draw())
        if pickAxis >= 1.0 then pickAxis = 0.999999 end
        local axis = IDENTITY_AXES[
            math.floor(pickAxis * #IDENTITY_AXES) + 1]
        axesTouched[#axesTouched + 1] = axis
        state.identityAxes[axis] = clamp01(
            (tonumber(state.identityAxes[axis]) or 1.0) - depth)
    end

    remember(state, {
        type = "decay-episode",
        day = day,
        source = "identity-decay",
        axes = axesTouched,
        depth = depth,
    })
    return true
end

function Pathogen.begin(personId, terminalState, day, source, record, atHours)
    personId = tostring(personId or "")
    if personId == "" then return nil end

    local store = ZAO.StateStore and ZAO.StateStore.store() or nil
    if not store then return nil end

    local prior = store.people[personId]
    local state = prior or {}
    local eventDay = math.floor(tonumber(day) or 0)
    local eventAtHours = tonumber(atHours) or eventDay * 24.0
    if type(state.attributeMutations) ~= "table" then
        state.attributeMutations = {}
    end
    -- Accrued days belong to the previous state. The new terminal event
    -- takes effect today and cannot receive another day's growth today.
    if prior then Pathogen.advance(personId, eventDay) end
    state.lastAdvancedDay = math.max(
        tonumber(state.lastAdvancedDay) or eventDay, eventDay)
    -- Crossed is terminal (DR-022). The living county may later report
    -- death or recovery from its own course. Keep that event in history,
    -- but it cannot restart mutation or send a survival to the bridge.
    if prior and state.terminalState == "crossed" then
        Pathogen.ensureDriverToken(state, personId)
        if ZAO.Maintenance and ZAO.Maintenance.ensure then
            ZAO.Maintenance.ensure(state, eventAtHours)
        end
        state.source = tostring(source or "pathogen")
        remember(state, {
            type = "begin",
            day = eventDay,
            atHours = eventAtHours,
            source = state.source,
            eventTerminalState = tostring(terminalState or "living"),
            terminalState = state.terminalState,
            form = state.currentForm,
            performance = state.formPerformance,
            attributes = state.attributeMutations,
        })
        return state
    end
    state.personId = personId
    if terminalState == "dead" or terminalState == "turned" then
        state.deathSequence = record and (tonumber(record.deathSequence) or 0) or state.deathSequence
    end
    state.terminalState = tostring(terminalState or "living")
    state.decayState = state.terminalState

    if state.terminalState == "infected" then
        local policy = ZAO.Sandbox and ZAO.Sandbox.policy() or nil
        local crossedOdds = policy and tonumber(policy.crossedOdds) or 0.025
        if draw() < clamp01(crossedOdds) then
            state.terminalState = "crossed"
            state.decayState = "crossed"
        end
    end

    -- The course events, fired at the event boundary only. An
    -- infection feeds the course; a survival does; the per-infection
    -- variable that carries a body past death is the course's
    -- pass-death; a recovery is a survival.
    if state.terminalState == "crossed" then
        courseEvent("coursePassDeath", personId)
    elseif state.terminalState == "infected" then
        courseEvent("courseInfect", personId)
    elseif state.terminalState == "living" then
        courseEvent("courseSurvive", personId)
    end
    state.startedDay = tonumber(state.startedDay) or tonumber(day) or 0
    state.source = tostring(source or "pathogen")
    state.humanCapability = tonumber(state.humanCapability) or 1.0
    state.passiveDecay = tonumber(state.passiveDecay) or 0.0
    state.retainedAbility = tonumber(state.retainedAbility) or 0.0
    state.history = state.history or {}

    if state.terminalState == "crossed" then
        state.currentForm = "none"
        state.formPerformance = 0.0
        state.attributeMutations = {}
        state.crossedTransferToken = state.crossedTransferToken
            or ("crossed:" .. personId .. ":" .. tostring(eventDay)
                .. ":" .. tostring(#(state.history or {}) + 1))
    else
        local odds = ZAO.Forms.mutationOdds()
        local capability = capabilityOf(record)

        if state.currentForm == nil then
            if draw() < odds then
                state.currentForm = ZAO.Forms.pick("capability", draw())
                state.formPerformance =
                    ZAO.Forms.performanceFrom(draw(), capability)
            else
                state.currentForm = "none"
                state.formPerformance = 0.0
            end
        end

        if not hasEntries(state.attributeMutations) and draw() < odds then
            local name = ZAO.Forms.pick("attribute", draw())
            if name then
                state.attributeMutations[name] =
                    ZAO.Forms.performanceFrom(draw(), capability)
            end
        end
    end

    Pathogen.ensureDriverToken(state, personId)
    if ZAO.Maintenance and ZAO.Maintenance.ensure then
        ZAO.Maintenance.ensure(state, eventAtHours)
    end

    remember(state, {
        type = "begin",
        day = tonumber(day) or 0,
        atHours = eventAtHours,
        source = state.source,
        terminalState = state.terminalState,
        form = state.currentForm,
        performance = state.formPerformance,
        attributes = state.attributeMutations,
    })

    store.people[personId] = state
    if (state.terminalState == "afflicted" or state.terminalState == "crossed")
        and record and not record.dead and SAO and SAO.Body
        and (SAO.ZAOPersonTransfer or SAO.CrossedTransfer) then
        pcall(function()
            local body = SAO.Body.active[personId]
            if body then
                local transfer = SAO.ZAOPersonTransfer or SAO.CrossedTransfer
                transfer.begin(personId, body, state.driverToken,
                    eventAtHours, state.terminalState)
            end
        end)
    end
    return state
end

local function advanceDay(state, day)
    local odds = ZAO.Forms.mutationOdds()
    local growthRate = dial("growthRate", odds)
    local passiveRate = dial("passiveDecayRate", odds / 10.0)
    local reversionRate = dial("reversionOdds", odds / 10.0)
    local outlierEffect = dial("outlierEffect", odds / 5.0)

    if state.terminalState == "turned"
        or state.terminalState == "infected" then
        local capability = clamp01(state.humanCapability)
        local growth = growthRate * capability
            * (1.0 + clamp01(state.passiveDecay))

        if state.currentForm and state.currentForm ~= "none" then
            state.formPerformance =
                clamp01((tonumber(state.formPerformance) or 0.0) + growth)
        end

        local attributes = state.attributeMutations
        for name, performance in pairs(attributes) do
            state.attributeMutations[name] =
                clamp01((tonumber(performance) or 0.0) + growth)
        end

        state.humanCapability =
            clamp01((tonumber(state.humanCapability) or 1.0) - growth)
        state.passiveDecay =
            clamp01((tonumber(state.passiveDecay) or 0.0) + passiveRate)

        local performance = tonumber(state.formPerformance) or 0.0
        local risk = reversionRate * (1.20 - performance)
        if performance >= 0.90 or performance <= 0.10 then
            risk = risk + outlierEffect
        end

        if state.terminalState == "turned" and draw() < risk then
            if state.settlementGroup and ZAO.StateStore.leaveSettlement then
                ZAO.StateStore.leaveSettlement(state.personId,
                    state.settlementGroup)
                state.settlementGroup = nil
            end
            state.terminalState = "afflicted"
            state.returnSequence = (tonumber(state.returnSequence) or 0) + 1
            state.returnEvent = { token = "reversion:" .. tostring(state.returnSequence),
                day = day, deathSequence = state.deathSequence or 0 }
            state.decayState = "afflicted"
            state.retainedAbility = clamp01(1.0 - performance)
            state.formPerformance =
                clamp01(performance * state.retainedAbility)
            Pathogen.ensureDriverToken(state, state.personId)

            for name, attributePerformance in pairs(state.attributeMutations) do
                state.attributeMutations[name] = clamp01(
                    (tonumber(attributePerformance) or 0.0)
                    * state.retainedAbility)
            end

            remember(state, {
                type = "reversion",
                day = day,
                source = "pathogen",
                terminalState = state.terminalState,
                form = state.currentForm,
                performance = state.formPerformance,
                retainedAbility = state.retainedAbility,
            })
        end
    elseif state.terminalState == "afflicted" then
        state.passiveDecay =
            clamp01((tonumber(state.passiveDecay) or 0.0) + passiveRate)
        identityDecayEpisode(state, day)
    end

end

function Pathogen.advance(personId, day)
    personId = tostring(personId or "")
    local store = ZAO.StateStore and ZAO.StateStore.store() or nil
    local state = store and store.people[personId] or nil
    if not state then return false end

    Pathogen.ensureDriverToken(state, personId)

    day = math.floor(tonumber(day) or 0)
    local previous = tonumber(state.lastAdvancedDay) or tonumber(state.startedDay)
    if previous == nil then
        state.lastAdvancedDay = day
        return false
    end
    previous = math.floor(previous)
    if day <= previous then return false end
    if ZAO.Maintenance and ZAO.Maintenance.advanceState then
        -- Old saves and never-loaded people may not yet have a maintenance
        -- row. Their last pathogen day is the only evidenced lower bound;
        -- initialize there before advancing, not at the destination day.
        if type(state.maintenance) ~= "table"
            and ZAO.Maintenance.ensure then
            ZAO.Maintenance.ensure(state, previous * 24.0)
        end
        ZAO.Maintenance.advanceState(state, day * 24.0)
    end
    if state.terminalState == "crossed" then
        state.lastAdvancedDay = day
        return false
    end

    -- Unloaded bodies can return after several days. Each elapsed day
    -- takes the same nonlinear growth and draws as daily observation;
    -- reversion on one day changes what the following days advance.
    for elapsedDay = previous + 1, day do
        advanceDay(state, elapsedDay)
        state.lastAdvancedDay = elapsedDay
    end
    return true
end

function Pathogen.expose(personId, carrierState, day, actionResult)
    personId = tostring(personId or "")
    local store = ZAO.StateStore and ZAO.StateStore.store() or nil
    local state = store and store.people[personId] or nil
    if not state or type(carrierState) ~= "table" then return false end
    local kind = type(actionResult) == "table"
        and tostring(actionResult.kind or "") or ""
    local contact = kind == "crossed-blood-exposure"
    local weapon = kind == "crossed-blood-melee"
        or kind == "crossed-blood-projectile"
    if type(actionResult) ~= "table"
        or not (contact or weapon)
        or actionResult.completed ~= true
        or tostring(actionResult.targetId or "") ~= personId
        or tostring(actionResult.token or "") == "" then
        return false
    end
    local carrierId = tostring(actionResult.carrierId or "")
    if carrierState.personId ~= nil
        and tostring(carrierState.personId) ~= carrierId then
        return false
    end
    local token = tostring(actionResult.token)
    state.exposureTokens = state.exposureTokens or {}
    if state.exposureTokens[token] then return state.exposureTokens[token] end
    local action = contact and store.exposures
        and store.exposures[carrierId]
        or weapon and store.contaminationHits
        and store.contaminationHits[token] or nil
    if type(action) ~= "table" or action.token ~= token
        or action.kind ~= kind
        or action.phase ~= "resolving"
        or tostring(action.targetId or "") ~= personId then
        return false
    end
    if state.terminalState ~= "afflicted"
        or carrierState.terminalState ~= "crossed" then
        return false
    end

    local policy = ZAO.Sandbox and ZAO.Sandbox.policy() or nil
    local crossedOdds = policy and tonumber(policy.crossedOdds) or 0.025
    local susceptibility =
        policy and tonumber(policy.afflictedSusceptibility) or 5.0
    if susceptibility < 0.0 then susceptibility = 0.0 end
    local protection, protectionEvidence = 0, nil
    if ZAO.Maintenance and ZAO.Maintenance.exposureProtection then
        protection, protectionEvidence = ZAO.Maintenance.exposureProtection(
            state, tonumber(actionResult.atHours) or (tonumber(day) or 0) * 24)
    end
    protection = clamp01(protection)
    local risk = clamp01(crossedOdds * susceptibility * (1.0 - protection))
    local roll = draw()
    local converted = roll < risk
    local receipt = {
        token = token,
        kind = actionResult.kind,
        completed = true,
        carrierId = carrierId,
        targetId = personId,
        atHours = tonumber(actionResult.atHours),
        day = tonumber(day) or 0,
        risk = risk,
        nutritionProtection = protection,
        nutritionProtectionSource = protectionEvidence
            and protectionEvidence.sourceToken or nil,
        roll = roll,
        converted = converted,
    }
    state.exposureTokens[token] = receipt
    remember(state, {
        type = "intentional-exposure",
        day = receipt.day,
        atHours = receipt.atHours,
        source = "crossed-blood-action",
        carrierId = carrierId,
        token = token,
        risk = risk,
        roll = roll,
        converted = converted,
    })
    if not converted then return receipt end

    if state.settlementGroup and ZAO.StateStore.leaveSettlement then
        ZAO.StateStore.leaveSettlement(personId, state.settlementGroup)
        state.settlementGroup = nil
    end
    state.terminalState = "crossed"
    state.decayState = "crossed"
    state.currentForm = "none"
    state.formPerformance = 0.0
    state.attributeMutations = {}
    state.crossedTransferToken = state.crossedTransferToken or token
    Pathogen.ensureDriverToken(state, personId)
    if ZAO.Maintenance and ZAO.Maintenance.ensure then
        ZAO.Maintenance.ensure(state, tonumber(receipt.atHours)
            or (tonumber(day) or 0) * 24.0)
    end

    courseEvent("coursePassDeath", personId)

    remember(state, {
        type = "crossed",
        day = tonumber(day) or 0,
        atHours = receipt.atHours,
        source = "crossed-blood-action",
        carrierId = carrierId,
        token = token,
        terminalState = state.terminalState,
    })
    if SAO and SAO.Identity and SAO.Neuro and SAO.Neuro.recordTerminal then
        pcall(function()
            local rec = SAO.Identity.get(personId)
            if rec then SAO.Neuro.recordTerminal(rec, "crossed",
                receipt.atHours, "intentional-exposure") end
        end)
    end
    return receipt
end

function Pathogen.stateOf(personId)
    personId = tostring(personId or "")
    local store = ZAO.StateStore and ZAO.StateStore.store() or nil
    return store and store.people[personId] or nil
end

function Pathogen.historyOf(personId)
    local state = Pathogen.stateOf(personId)
    return state and state.history or {}
end

function Pathogen.attributeString(state)
    if type(state) ~= "table" then return "" end
    local parts = {}
    local attributes = type(state.attributeMutations) == "table"
        and state.attributeMutations or {}
    for name, performance in pairs(attributes) do
        parts[#parts + 1] = tostring(name) .. ":"
            .. string.format("%.4f", clamp01(performance))
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

function Pathogen.describe(personId)
    local state = Pathogen.stateOf(personId)
    if not state then return "no pathogen state" end
    local parts = {
        tostring(state.terminalState or "living"),
        tostring(state.currentForm or "none"),
        string.format("%.2f", tonumber(state.formPerformance) or 0.0),
    }
    local attributes = Pathogen.attributeString(state)
    if attributes ~= "" then
        parts[#parts + 1] = attributes
    end
    return table.concat(parts, " ")
end

return Pathogen
