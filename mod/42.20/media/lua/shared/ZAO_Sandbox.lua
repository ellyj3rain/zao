-- ZAO_Sandbox - the sandbox policy reader.
--
-- Every dial declared in media/sandbox-options.txt is read here once
-- and shaped into the policy the rest of ZAO consumes. The defaults
-- are the operator's (DR-019): crossed 2.5% per infection, afflicted
-- susceptibility 5x, resistance at 2 survived infections, immunity at
-- 5, mutation odds 10% or lower at baseline, identity decay rare and
-- mild. Growth runs at the baseline odds; the two slow processes at a
-- tenth of it; the outlier correction at a fifth (the registry's
-- extrapolation rule).

ZAO = ZAO or {}
ZAO.Sandbox = ZAO.Sandbox or {}
local Sandbox = ZAO.Sandbox

local function clamp01(value)
    value = tonumber(value) or 0.0
    if value < 0.0 then return 0.0 end
    if value > 1.0 then return 1.0 end
    return value
end

local function clampMin(value, minimum)
    value = tonumber(value) or minimum
    if value < minimum then return minimum end
    return value
end

local function readNumber(options, name, derived)
    local value = options and tonumber(options[name]) or nil
    if value == nil then return derived end
    return value
end

function Sandbox.policy()
    local options = SandboxVars and SandboxVars.ZombieAwareness or nil
    local mutationOdds = clamp01(readNumber(options, "MutationOdds", 0.10))

    local crossedOdds = clamp01(readNumber(options, "CrossedOdds", 0.025))
    local susceptibility =
        clampMin(readNumber(options, "AfflictedSusceptibility", 5.0), 0.0)

    -- The four advancement dials default from the operator's baseline
    -- odds per the registry's extrapolation rule.
    local growthRate = clamp01(
        readNumber(options, "GrowthRate", mutationOdds))
    local passiveDecayRate = clamp01(
        readNumber(options, "PassiveDecayRate", mutationOdds / 10.0))
    local reversionOdds = clamp01(
        readNumber(options, "ReversionOdds", mutationOdds / 10.0))
    local outlierEffect = clamp01(
        readNumber(options, "OutlierEffect", mutationOdds / 5.0))

    -- Identity decay is episodic and rare by default (DR-020).
    local identityDecayOdds = clamp01(
        readNumber(options, "IdentityDecayOdds", 0.01))
    local identityDecayDepth = clamp01(
        readNumber(options, "IdentityDecayDepth", 0.10))

    local resistanceInfections = math.floor(clampMin(
        readNumber(options, "ResistanceInfections", 2), 1))
    local immunityInfections = math.floor(clampMin(
        readNumber(options, "ImmunityInfections", 5), 1))
    if immunityInfections <= resistanceInfections then
        immunityInfections = resistanceInfections + 1
    end

    local formWeights = {}
    for _, name in ipairs(ZAO and ZAO.Forms
        and ZAO.Forms.CAPABILITY or {}) do
        formWeights[name] = clampMin(
            readNumber(options, "FormWeight" .. name, 1.0), 0.0)
    end

    return {
        enabled = options == nil or options.Enable ~= false,
        mutationOdds = mutationOdds,
        crossedOdds = crossedOdds,
        afflictedSusceptibility = susceptibility,
        controller = options == nil or options.Controller ~= false,
        overlay = options == nil or options.Overlay ~= false,
        mind = options == nil or options.Mind ~= false,
        settlement = options == nil or options.Settlement ~= false,
        recovery = options == nil or options.Recovery ~= false,
        growthRate = growthRate,
        passiveDecayRate = passiveDecayRate,
        reversionOdds = reversionOdds,
        outlierEffect = outlierEffect,
        identityDecayOdds = identityDecayOdds,
        identityDecayDepth = identityDecayDepth,
        resistanceInfections = resistanceInfections,
        immunityInfections = immunityInfections,
        crossedEngageDead =
            options ~= nil and options.CrossedEngageDead == true,
        settlementOdds = clamp01(
            readNumber(options, "SettlementOdds", 0.02)),
        formWeights = formWeights,
    }
end

-- Push the policy across the Java bridge so the bridge's course and
-- its policy read the same dials the Lua side does. Called on game
-- start and before any bridge drive.
Sandbox.pushedToBridge = false

function Sandbox.pushToBridge()
    if Sandbox.pushedToBridge or not ZAOJavaBridge then
        return Sandbox.pushedToBridge
    end
    local policy = Sandbox.policy()
    local ok = pcall(function()
        ZAOJavaBridge:configure(
            policy.enabled,
            policy.mutationOdds,
            policy.controller,
            policy.overlay,
            policy.crossedOdds,
            policy.afflictedSusceptibility,
            policy.resistanceInfections,
            policy.immunityInfections)
    end)
    if ok then Sandbox.pushedToBridge = true end
    return Sandbox.pushedToBridge
end

Events.OnGameStart.Add(function()
    Sandbox.pushedToBridge = false
    Sandbox.pushToBridge()
end)

return Sandbox