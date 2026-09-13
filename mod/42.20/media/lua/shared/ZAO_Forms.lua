-- ZAO_Forms - the enumerated mutation candidates.
--
-- The six capability forms are the source port. The four attribute
-- mutations are the ordinary turned body's own abilities. Both are
-- gradients, not switches; a body can carry one of each.

ZAO = ZAO or {}
ZAO.Forms = ZAO.Forms or {}
local Forms = ZAO.Forms

Forms.CAPABILITY = {
    "Puker",
    "Husk",
    "Skitter",
    "Wrecker",
    "Leaper",
    "Weeper",
}

Forms.ATTRIBUTE = {
    "Speed",
    "Strength",
    "Toughness",
    "Hearing",
}

Forms.DEFAULT_MUTATION_ODDS = 0.10

function Forms.mutationOdds()
    local policy = ZAO.Sandbox and ZAO.Sandbox.policy() or nil
    local odds = policy and tonumber(policy.mutationOdds)
        or Forms.DEFAULT_MUTATION_ODDS
    if odds < 0.0 then odds = 0.0 end
    if odds > 1.0 then odds = 1.0 end
    return odds
end

function Forms.candidates(kind)
    if kind == "attribute" then
        return Forms.ATTRIBUTE
    end
    return Forms.CAPABILITY
end

-- The form-direction roll is uniform across the gradient at baseline;
-- the sandbox may weight it (DR-022). Weights of 1 everywhere reduce
-- to the uniform index pick.
function Forms.pick(kind, draw)
    local candidates = Forms.candidates(kind)
    if #candidates == 0 then return nil end
    draw = tonumber(draw) or 0.0
    if draw < 0.0 then draw = 0.0 end
    if draw >= 1.0 then draw = 0.999999 end

    if kind ~= "capability" then
        local index = math.floor(draw * #candidates) + 1
        if index < 1 then index = 1 end
        if index > #candidates then index = #candidates end
        return candidates[index]
    end

    local policy = ZAO.Sandbox and ZAO.Sandbox.policy() or nil
    local weights = policy and policy.formWeights or nil
    if type(weights) ~= "table" then weights = nil end

    local total = 0.0
    local live = {}
    for _, name in ipairs(candidates) do
        local weight = 1.0
        if weights then
            weight = tonumber(weights[name]) or 1.0
        end
        if weight < 0.0 then weight = 0.0 end
        if weight > 0.0 then
            live[#live + 1] = { name = name, weight = weight }
            total = total + weight
        end
    end
    if total <= 0.0 or #live == 0 then return nil end

    local point = draw * total
    local walked = 0.0
    for _, entry in ipairs(live) do
        walked = walked + entry.weight
        if point < walked then return entry.name end
    end
    return live[#live].name
end

function Forms.performanceFrom(draw, capability)
    draw = tonumber(draw) or 0.0
    capability = tonumber(capability) or 0.5
    if draw < 0.0 then draw = 0.0 end
    if draw > 1.0 then draw = 1.0 end
    if capability < 0.0 then capability = 0.0 end
    if capability > 1.0 then capability = 1.0 end
    return draw * capability
end

return Forms
