-- ZAO_Diet - state-specific sustenance actions and human-origin provenance.
--
-- Crossed keep ordinary human physiology, so ordinary food can satisfy hunger.
-- Human flesh is preferred where sustenance, mutilation and domination can
-- coincide; that preference is motivational, not a biological-only diet.
-- Afflicted people are not a Crossed food source.  Intentional exposure and
-- other violence remain separate actions.  Afflicted retain their own food
-- policy, including the individual possibility of human-origin food.

require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISEatFoodAction"
require "TimedActions/ISAddItemInRecipe"

ZAO = ZAO or {}
ZAO.Diet = ZAO.Diet or {}
local Diet = ZAO.Diet

Diet.compatibilityPredicates = Diet.compatibilityPredicates or {}
Diet.runtimeActions = Diet.runtimeActions or {}

local FOOD_TYPE = "ZombieAwareness.HumanFlesh"
local HUNGER_THRESHOLD = 0.20
local CORPSE_REACH = 1.6
local FLESH_PIECES = 4

local function rootStore()
    local root = ZAO.StateStore and ZAO.StateStore.store() or nil
    if not root then return nil end
    root.butcherActions = root.butcherActions or {}
    root.butcherResults = root.butcherResults or {}
    root.dietActions = root.dietActions or {}
    root.dietResults = root.dietResults or {}
    return root
end

local function bodyData(body)
    local data = nil
    if body then pcall(function() data = body:getModData() end) end
    return type(data) == "table" and data or nil
end

local function terminalOf(personId, body)
    personId = tostring(personId or "")
    local state = ZAO.Pathogen and ZAO.Pathogen.stateOf(personId) or nil
    if personId == "" or body == nil or not state
        or not ZAO.Controller or not ZAO.Controller.controlled
        or ZAO.Controller.controlled[personId] ~= body then return nil, state end
    local terminal = tostring(state.terminalState or "")
    if terminal ~= "afflicted" and terminal ~= "crossed" then return nil, state end
    return terminal, state
end

local function crossed(personId, body)
    return terminalOf(personId, body) == "crossed"
end

local function zaoLiving(personId, body)
    local terminal = terminalOf(personId, body)
    return terminal == "afflicted" or terminal == "crossed"
end

local function corpseToken(corpse)
    local data = bodyData(corpse)
    if not data then return nil end
    if data.ZAOHumanCorpseToken then
        return tostring(data.ZAOHumanCorpseToken)
    end
    local id, x, y, z = -1, 0, 0, 0
    pcall(function() id = corpse:getObjectIDAsLong() end)
    pcall(function()
        x, y, z = math.floor(corpse:getX()), math.floor(corpse:getY()),
            math.floor(corpse:getZ())
    end)
    data.ZAOHumanCorpseToken = "human-corpse:" .. tostring(id) .. ":"
        .. tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
    return data.ZAOHumanCorpseToken
end

local function corpseProfile(corpse, data, personId, state)
    local rec = personId and SAO and SAO.Identity
        and SAO.Identity.get(personId) or nil
    local terminal = state and tostring(state.terminalState or "")
        or data and tostring(data.ZAOTerminalState or "") or "ordinary"
    if terminal == "" or terminal == "living" then terminal = "ordinary" end
    return {
        personId = personId,
        terminalState = terminal,
        form = state and state.currentForm or data and data.ZAOForm or "none",
        health = rec and tonumber(rec.lastLivingHealth) or nil,
        infectionsSurvived = rec and tonumber(rec.infectionsSurvived) or 0,
        immuneProgress = rec and tonumber(rec.immuneProgress) or 0,
    }
end

function Diet.corpseEligible(corpse)
    if not corpse then return false, "missing-corpse" end
    local zombie, animal = true, true
    local ok = pcall(function()
        zombie = corpse:isZombie() == true
        animal = corpse:isAnimal() == true
    end)
    if not ok then return false, "not-a-corpse" end
    if zombie then return false, "zombie" end
    if animal then return false, "animal" end
    local data = bodyData(corpse)
    if not data then return false, "no-corpse-data" end
    if data.ZAOButchered then return false, "already-butchered" end
    local personId = data.SAOPersonId and tostring(data.SAOPersonId) or nil
    local state = personId and ZAO.Pathogen
        and ZAO.Pathogen.stateOf(personId) or nil
    local terminal = state and tostring(state.terminalState or "")
        or tostring(data.ZAOTerminalState or "")
    if terminal == "crossed" then return false, "crossed" end
    if terminal ~= "afflicted" and (state
        and tostring(state.currentForm or "none") ~= "none"
        or data.ZAOForm and data.ZAOForm ~= "none") then
        return false, "unowned-mutant-source"
    end
    return true, corpseToken(corpse), corpseProfile(corpse, data, personId,
        state)
end

function Diet.corpseEligibleFor(personId, body, corpse)
    local terminal = terminalOf(personId, body)
    if not terminal then return false, "unowned-eater" end
    local eligible, token, donor = Diet.corpseEligible(corpse)
    if not eligible then return false, token end
    if terminal == "crossed" and donor
        and donor.terminalState == "afflicted" then
        return false, "afflicted-not-food", donor
    end
    return true, token, donor
end

local function usableCuttingWeapon(item)
    local ok, answer = pcall(function()
        return item and instanceof(item, "HandWeapon")
            and not item:isBroken()
            and item:hasTag(ItemTag.SHARP_KNIFE)
    end)
    return ok and answer == true
end

local function cuttingWeapon(body)
    local held = body and body:getPrimaryHandItem() or nil
    if usableCuttingWeapon(held) then return held end
    local item = nil
    pcall(function()
        item = body:getInventory():getFirstEvalRecurse(usableCuttingWeapon)
    end)
    return item
end

function Diet.registerHumanFoodPredicate(owner, predicate)
    if type(owner) ~= "string" or owner == ""
        or type(predicate) ~= "function" then return false end
    Diet.compatibilityPredicates[owner] = predicate
    return true
end

function Diet.isHumanFood(item)
    if not item then return false end
    local fullType = nil
    pcall(function() fullType = tostring(item:getFullType()) end)
    if fullType == FOOD_TYPE then return true end
    local extras = nil
    pcall(function() extras = item:getExtraItems() end)
    if extras then
        for index = 0, extras:size() - 1 do
            if tostring(extras:get(index)) == FOOD_TYPE then return true end
        end
    end
    for _, predicate in pairs(Diet.compatibilityPredicates) do
        local ok, eligible = pcall(predicate, item)
        if ok and eligible == true then return true end
    end
    return false
end

local function copyDonor(donor)
    if type(donor) ~= "table" then return nil end
    return {
        personId = donor.personId and tostring(donor.personId) or nil,
        terminalState = tostring(donor.terminalState or "unknown"),
        form = tostring(donor.form or "none"),
        health = tonumber(donor.health),
        infectionsSurvived = tonumber(donor.infectionsSurvived) or 0,
        immuneProgress = tonumber(donor.immuneProgress) or 0,
    }
end

local function legacyDonor(data)
    if type(data) ~= "table" or not data.ZAOHumanOrigin then return nil end
    return {
        personId = data.ZAODonorPersonId
            and tostring(data.ZAODonorPersonId) or nil,
        terminalState = tostring(data.ZAODonorTerminalState or "unknown"),
        form = tostring(data.ZAODonorForm or "none"),
        health = tonumber(data.ZAODonorHealth),
        infectionsSurvived = tonumber(data.ZAODonorInfectionsSurvived) or 0,
        immuneProgress = tonumber(data.ZAODonorImmuneProgress) or 0,
    }
end

local function donorsFromItem(item)
    local data = bodyData(item)
    if not data then return {} end
    local donors = {}
    if type(data.ZAOHumanDonors) == "table" then
        for _, donor in ipairs(data.ZAOHumanDonors) do
            local copied = copyDonor(donor)
            if copied then donors[#donors + 1] = copied end
        end
    end
    if #donors == 0 then
        local donor = legacyDonor(data)
        if donor then donors[1] = donor end
    end
    return donors
end

local function donorFromItem(item)
    local donors = donorsFromItem(item)
    for _, donor in ipairs(donors) do
        if donor.terminalState == "afflicted" then return donor end
    end
    return donors[1]
end

local function containsAfflictedHuman(item)
    local data = bodyData(item)
    if data and data.ZAOContainsAfflictedHuman == true then return true end
    for _, donor in ipairs(donorsFromItem(item)) do
        if donor.terminalState == "afflicted" then return true end
    end
    return false
end

-- Classification follows native Food composition and provenance. Display
-- names never define the diet, so modded food participates automatically.
function Diet.foodProfile(item)
    if not item then return nil end
    local food = false
    pcall(function() food = instanceof(item, "Food") == true end)
    if not food then return nil end
    local profile = { class = "alternative", human = Diet.isHumanFood(item) }
    pcall(function()
        profile.proteins = math.max(0, tonumber(item:getProteins()) or 0)
        profile.lipids = math.max(0, tonumber(item:getLipids()) or 0)
        profile.carbohydrates = math.max(0,
            tonumber(item:getCarbohydrates()) or 0)
        profile.calories = math.max(0, tonumber(item:getCalories()) or 0)
        profile.hungerChange = tonumber(item:getHungerChange()) or 0
        local milk = item:getMilkType()
        profile.dairy = milk ~= nil and tostring(milk) ~= ""
    end)
    if profile.human then
        local donors = donorsFromItem(item)
        profile.class = "human"
        profile.donor = donorFromItem(item)
        profile.donors = donors
        profile.humanSourceKnown = #donors > 0
        for _, donor in ipairs(donors) do
            if donor.terminalState ~= "ordinary"
                and donor.terminalState ~= "afflicted" then
                profile.humanSourceKnown = false
            end
        end
        profile.containsAfflictedHuman = containsAfflictedHuman(item)
    elseif profile.dairy then
        profile.class = "dairy"
    elseif (profile.proteins or 0) >= 4
        or (profile.proteins or 0) > (profile.carbohydrates or 0) * 0.5 then
        profile.class = "protein"
    end
    return profile
end

function Diet.profileAllowed(terminal, profile)
    terminal = tostring(terminal or "")
    if type(profile) ~= "table" or profile.class == "dairy" then
        return false, "food-not-admitted"
    end
    if terminal == "crossed" and profile.human
        and profile.containsAfflictedHuman == true then
        return false, "afflicted-not-food"
    end
    if terminal == "crossed" and profile.human
        and profile.humanSourceKnown ~= true then
        return false, "human-source-unknown"
    end
    if terminal ~= "crossed" and terminal ~= "afflicted" then
        return false, "unsupported-terminal-state"
    end
    return true, "admitted"
end

local function donorKey(donor)
    donor = type(donor) == "table" and donor or {}
    return tostring(donor.personId or "") .. "|"
        .. tostring(donor.terminalState or "unknown") .. "|"
        .. tostring(donor.form or "none")
end

-- Evolved recipes retain native ingredient-type provenance, but that list does
-- not retain the particular donor.  Copy the source-owned donor records onto
-- the resulting dish when the exact ingredient is actually added so cooking
-- cannot turn Afflicted flesh into an anonymous Crossed food source.
function Diet.propagateHumanProvenance(resultItem, sourceItem, suppliedProfile)
    local profile = suppliedProfile or Diet.foodProfile(sourceItem)
    local resultData = bodyData(resultItem)
    if not (resultData and profile and profile.human == true) then return false end
    local donors, seen = donorsFromItem(resultItem), {}
    for _, donor in ipairs(donors) do seen[donorKey(donor)] = true end
    local sourceDonors = type(profile.donors) == "table"
        and profile.donors or {}
    if #sourceDonors == 0 and type(profile.donor) == "table" then
        sourceDonors = { profile.donor }
    end
    for _, donor in ipairs(sourceDonors) do
        local copied, key = copyDonor(donor), donorKey(donor)
        if copied and not seen[key] then
            donors[#donors + 1] = copied
            seen[key] = true
        end
    end
    resultData.ZAOHumanOrigin = resultData.ZAOHumanOrigin
        or "evolved-human-food"
    resultData.ZAOHumanDonors = donors
    if profile.containsAfflictedHuman == true then
        resultData.ZAOContainsAfflictedHuman = true
    end
    local sourceData = bodyData(sourceItem)
    if sourceData and sourceData.ZAOHumanOrigin then
        resultData.ZAOHumanSourceTokens = type(resultData.ZAOHumanSourceTokens)
            == "table" and resultData.ZAOHumanSourceTokens or {}
        local token = tostring(sourceData.ZAOHumanOrigin)
        local present = false
        for _, existing in ipairs(resultData.ZAOHumanSourceTokens) do
            if tostring(existing) == token then present = true end
        end
        if not present then
            resultData.ZAOHumanSourceTokens[
                #resultData.ZAOHumanSourceTokens + 1] = token
        end
    end
    local primary = donorFromItem(resultItem)
    if primary then
        resultData.ZAODonorPersonId = primary.personId
        resultData.ZAODonorTerminalState = primary.terminalState
        resultData.ZAODonorForm = primary.form
        resultData.ZAODonorHealth = primary.health
        resultData.ZAODonorInfectionsSurvived = primary.infectionsSurvived
        resultData.ZAODonorImmuneProgress = primary.immuneProgress
    end
    return true
end

local function carriedMatching(body, predicate)
    local item = nil
    pcall(function()
        item = body:getInventory():getFirstEvalRecurse(function(candidate)
            local profile = Diet.foodProfile(candidate)
            return profile ~= nil and predicate(profile, candidate) == true
        end)
    end)
    return item, item and Diet.foodProfile(item) or nil
end

local function carriedHumanFood(body, terminal)
    return carriedMatching(body, function(profile)
        local admitted = Diet.profileAllowed(terminal, profile)
        return profile.human == true and admitted == true
    end)
end

local function afflictedHumanWillingness(state, mind, hungerNeed)
    local disposition = mind and mind.disposition or {}
    local row = state and state.maintenance and state.maintenance.nutrition or {}
    local precedent = math.min(0.30,
        (tonumber(row and row.humanMeals) or 0) * 0.08)
    return (tonumber(hungerNeed) or 0) * 0.65
        + (tonumber(disposition.selfPreservation) or 0) * 0.25
        + (tonumber(disposition.aggression) or 0) * 0.20
        + precedent
        - (tonumber(disposition.compassion) or 0) * 0.65 >= 0.62
end

local function distance(a, b)
    local value = nil
    pcall(function()
        local dx, dy = a:getX() - b:getX(), a:getY() - b:getY()
        value = math.sqrt(dx * dx + dy * dy)
    end)
    return value
end

function Diet.nearestHumanCorpse(body, allowAfflicted)
    if not body or not body:getCell() then return nil end
    local bx, by, bz = math.floor(body:getX()), math.floor(body:getY()),
        math.floor(body:getZ())
    local best, bestDistance, bestProfile, bestCost = nil, nil, nil, nil
    local reachTiles = math.ceil(CORPSE_REACH)
    for x = bx - reachTiles, bx + reachTiles do
        for y = by - reachTiles, by + reachTiles do
            local square = body:getCell():getGridSquare(x, y, bz)
            local corpses = square and square:getDeadBodys() or nil
            if corpses then
                for index = 0, corpses:size() - 1 do
                    local corpse = corpses:get(index)
                    local eligible, _, profile = Diet.corpseEligible(corpse)
                    local apart = eligible and distance(body, corpse) or nil
                    local afflictedSource = profile
                        and profile.terminalState == "afflicted"
                    local cost = apart and apart
                        + (afflictedSource and 0.75 or 0) or nil
                    if apart and apart <= CORPSE_REACH
                        and (allowAfflicted == true or not afflictedSource)
                        and (not bestCost or cost < bestCost) then
                        best, bestDistance, bestProfile, bestCost = corpse,
                            apart, profile, cost
                    end
                end
            end
        end
    end
    return best, bestDistance, bestProfile
end

local function nextToken(root, prefix, personId)
    root.dietSequence = (tonumber(root.dietSequence) or 0) + 1
    return prefix .. ":" .. tostring(personId) .. ":"
        .. tostring(root.dietSequence)
end

local function archive(root, collection, results, action, outcome, reason, hours)
    if not root or not action then return false end
    if not root[results][action.token] then
        action.outcome = outcome
        action.reason = reason
        action.resolvedAtHours = tonumber(hours) or action.startedAtHours or 0
        root[results][action.token] = action
    end
    root[collection][action.personId] = nil
    Diet.runtimeActions[action.token] = nil
    return true
end

function Diet.beginButcher(personId, body, corpse, hours)
    local root = rootStore()
    local eligible, token, donor = Diet.corpseEligibleFor(personId, body, corpse)
    local weapon = cuttingWeapon(body)
    if not (root and zaoLiving(personId, body) and eligible and weapon) then
        return false
    end
    personId = tostring(personId)
    local existing = root.butcherActions[personId]
    if existing then return true end
    local action = {
        version = 1,
        token = nextToken(root, "butcher", personId),
        personId = personId,
        terminalState = terminalOf(personId, body),
        corpseToken = token,
        donor = donor,
        weaponId = weapon:getID(),
        phase = "queued",
        startedAtHours = tonumber(hours) or 0,
    }
    root.butcherActions[personId] = action
    local timed = ZAOButcherHumanAction:new(body, corpse, weapon, action.token)
    Diet.runtimeActions[action.token] = timed
    local queued = SAO and SAO.Needs and SAO.Needs.queueVerified
        and SAO.Needs.queueVerified(timed) or false
    if not queued then
        archive(root, "butcherActions", "butcherResults", action,
            "failed", "timed-action-refused", hours)
        return false
    end
    local data = bodyData(body)
    if data then data.ZAOButcherAction = action.token end
    return true
end

function Diet.completeButcher(actionToken, body, corpse, weapon)
    local root = rootStore()
    local personId = bodyData(body) and bodyData(body).SAOPersonId or nil
    local action = personId and root and root.butcherActions[tostring(personId)]
        or nil
    local eligible, token, donor = Diet.corpseEligibleFor(personId, body, corpse)
    if not action or action.token ~= actionToken or action.phase ~= "queued"
        or not zaoLiving(personId, body) or not eligible
        or token ~= action.corpseToken or weapon:getID() ~= action.weaponId
        or cuttingWeapon(body) ~= weapon then
        return false
    end
    action.phase = "resolving"
    local created = {}
    for _ = 1, FLESH_PIECES do
        local item = body:getInventory():AddItem(FOOD_TYPE)
        if item then
            local data = item:getModData()
            data.ZAOHumanOrigin = action.corpseToken
            data.ZAOButcheredBy = tostring(personId)
            local source = action.donor or donor or {}
            data.ZAODonorPersonId = source.personId
            data.ZAODonorTerminalState = source.terminalState or "ordinary"
            data.ZAODonorForm = source.form or "none"
            data.ZAODonorHealth = source.health
            data.ZAODonorInfectionsSurvived = source.infectionsSurvived or 0
            data.ZAODonorImmuneProgress = source.immuneProgress or 0
            data.ZAOHumanDonors = { copyDonor(source) }
            if tostring(source.terminalState or "") == "afflicted" then
                data.ZAOContainsAfflictedHuman = true
            end
            created[#created + 1] = item:getID()
        end
    end
    if #created == 0 then
        action.phase = "queued"
        return false
    end
    local cdata = bodyData(corpse)
    cdata.ZAOButchered = true
    cdata.ZAOButcheredBy = tostring(personId)
    cdata.ZAOButcherAction = action.token
    action.createdItemIds = created
    action.pieces = #created
    archive(root, "butcherActions", "butcherResults", action,
        "completed", "human-flesh-created", nil)
    local data = bodyData(body)
    if data and data.ZAOButcherAction == action.token then
        data.ZAOButcherAction = nil
    end
    return true
end

function Diet.interruptButcher(actionToken, body, reason)
    local root = rootStore()
    local data = bodyData(body)
    local personId = data and tostring(data.SAOPersonId or "") or ""
    local action = root and root.butcherActions[personId] or nil
    if not action or action.token ~= actionToken then return false end
    if data and data.ZAOButcherAction == action.token then
        data.ZAOButcherAction = nil
    end
    return archive(root, "butcherActions", "butcherResults", action,
        "interrupted", reason or "timed-action-stopped", nil)
end

local function readHunger(body)
    local value = -1
    if ZAOJavaBridge and ZAOJavaBridge.hunger then
        pcall(function() value = tonumber(ZAOJavaBridge:hunger(body)) or -1 end)
    elseif body and CharacterStat then
        pcall(function()
            value = tonumber(body:getStats():get(CharacterStat.HUNGER)) or -1
        end)
    end
    return value
end

local function prepareEat(personId, body, item, hours, suppliedProfile,
        sourceReservation)
    local root = rootStore()
    local terminal, state = terminalOf(personId, body)
    local profile = Diet.foodProfile(item)
    local admitted = Diet.profileAllowed(terminal, profile)
    if not (root and terminal and admitted) then
        return nil, nil end
    personId = tostring(personId)
    local action = {
        version = 1,
        token = nextToken(root, "eat-" .. tostring(profile.class), personId),
        personId = personId,
        terminalState = terminal,
        itemId = item:getID(),
        itemType = item:getFullType(),
        profile = profile,
        hungerBefore = readHunger(body),
        phase = "queued",
        startedAtHours = tonumber(hours) or 0,
        sourceReservation = sourceReservation and tostring(sourceReservation)
            or nil,
    }
    root.dietActions[personId] = action
    local timed = ZAOEatHumanAction:new(body, item, action.token)
    Diet.runtimeActions[action.token] = timed
    local data = bodyData(body)
    if data then data.ZAOEatHumanAction = action.token end
    return action, timed
end

function Diet.beginEat(personId, body, item, hours, suppliedProfile)
    local root = rootStore()
    personId = tostring(personId)
    if root and root.dietActions[personId] then return true end
    local action, timed = prepareEat(personId, body, item, hours,
        suppliedProfile, nil)
    if not action then return false end
    local queued = SAO and SAO.Needs and SAO.Needs.queueVerified
        and SAO.Needs.queueVerified(timed) or false
    if not queued then
        archive(root, "dietActions", "dietResults", action,
            "failed", "timed-action-refused", hours)
        return false
    end
    return true
end

-- SourceUse has already selected and transferred this exact item.  Diet owns
-- only the state-specific admission and physiological result; the returned
-- action is queued and measured by SourceUse under its original reservation.
function Diet.createSourceUseAction(personId, body, item, reservation)
    local root = rootStore()
    local terminal = terminalOf(personId, body)
    local profile = Diet.foodProfile(item)
    local admitted = Diet.profileAllowed(terminal, profile)
    if not (root and terminal and admitted and reservation
        and tostring(reservation.nativeUseTerminalState or terminal)
            == terminal) then return nil end
    if terminal == "afflicted" and (profile.class == "dairy"
        or profile.human and reservation.nativeUsePermitHuman ~= true) then
        return nil
    end
    personId = tostring(personId)
    local existing = root.dietActions[personId]
    if existing then
        if tostring(existing.sourceReservation or "")
                ~= tostring(reservation.id or "")
            or tonumber(existing.itemId) ~= tonumber(item:getID()) then
            return nil
        end
        local timed = ZAOEatHumanAction:new(body, item, existing.token)
        Diet.runtimeActions[existing.token] = timed
        return timed
    end
    local hours = 0
    pcall(function() hours = SAO.History.countyHours() end)
    local _, timed = prepareEat(personId, body, item, hours, profile,
        reservation.id)
    return timed
end

function Diet.sourceUseQueueRefused(personId, body, item, reservation, action)
    local token = action and action.zaoToken or nil
    return token and Diet.interruptEat(token, body,
        "source-use-queue-refused") or false
end

function Diet.completeEat(actionToken, body, item)
    local root = rootStore()
    local data = bodyData(body)
    local personId = data and tostring(data.SAOPersonId or "") or ""
    local action = root and root.dietActions[personId] or nil
    local terminal, state = terminalOf(personId, body)
    local currentProfile = Diet.foodProfile(item)
    local admitted, refusal = Diet.profileAllowed(terminal, currentProfile)
    if not action or action.token ~= actionToken or action.phase ~= "queued"
        or terminal ~= action.terminalState
        or item:getID() ~= action.itemId then return false end
    if not admitted then
        archive(root, "dietActions", "dietResults", action,
            "failed", refusal or "food-not-admitted", nil)
        if data and data.ZAOEatHumanAction == action.token then
            data.ZAOEatHumanAction = nil
        end
        return false
    end
    action.profile = currentProfile
    action.phase = "resolving"
    local nowHours = tonumber(action.startedAtHours) or 0
    pcall(function() nowHours = SAO.History.countyHours() end)
    local after = readHunger(body)
    if terminal == "afflicted" and action.profile.class == "alternative"
        and action.hungerBefore and action.hungerBefore >= 0 and after >= 0
        and CharacterStat then
        local relief = math.max(0, action.hungerBefore - after)
        local retained = relief * (ZAO.Maintenance
            and ZAO.Maintenance.profile.afflictedAlternativeRelief or 0.60)
        local adjusted = math.max(0, math.min(1,
            action.hungerBefore - retained))
        pcall(function()
            body:getStats():set(CharacterStat.HUNGER, adjusted)
        end)
        action.adjustedHunger = adjusted
    end
    if terminal == "afflicted" and ZAO.Maintenance
        and ZAO.Maintenance.recordAfflictedMeal then
        local receipt = ZAO.Maintenance.recordAfflictedMeal(personId, state,
            action.profile, action.token, nowHours)
        action.maintenanceReceipt = receipt and receipt.token or nil
    elseif terminal == "crossed" and action.profile.human
        and ZAO.Maintenance and ZAO.Maintenance.recordPredatoryOutcome then
        local donor = action.profile.donor or {}
        local receipt = ZAO.Maintenance.recordPredatoryOutcome(personId, state,
            "consumption", 0.12, action.token, nowHours, {
                itemId = action.itemId,
                donorPersonId = donor.personId,
                donorTerminalState = donor.terminalState or "ordinary",
            })
        action.maintenanceReceipt = receipt and receipt.token or nil
    end
    archive(root, "dietActions", "dietResults", action,
        "completed", "native-eat-completed", nil)
    if data and data.ZAOEatHumanAction == action.token then
        data.ZAOEatHumanAction = nil
    end
    return true
end

function Diet.interruptEat(actionToken, body, reason)
    local root = rootStore()
    local data = bodyData(body)
    local personId = data and tostring(data.SAOPersonId or "") or ""
    local action = root and root.dietActions[personId] or nil
    if not action or action.token ~= actionToken then return false end
    if data and data.ZAOEatHumanAction == action.token then
        data.ZAOEatHumanAction = nil
    end
    return archive(root, "dietActions", "dietResults", action,
        "interrupted", reason or "timed-action-stopped", nil)
end

local function hunger(body)
    return readHunger(body)
end

local function ordinaryCarriedFood(body)
    if not (body and SAOJavaBridge and SAOJavaBridge.findCarriedFood) then
        return nil
    end
    local ok, item = pcall(function()
        return SAOJavaBridge:findCarriedFood(body)
    end)
    if not ok or not item or Diet.isHumanFood(item) then return nil end
    return item
end

local function observedFoodPlace(personId, body, need)
    if not (body and SAO and SAO.WorldSources
        and SAO.WorldSources.nearestObserved and SAO.Places) then return nil end
    local horizon = nil
    pcall(function()
        horizon = need >= 0.75 and SAO.Places.commitHorizon()
            or SAO.Places.comfortHorizon()
    end)
    if not horizon then return nil end
    local place = nil
    pcall(function()
        place = SAO.WorldSources.nearestObserved(tostring(personId),
            body:getX(), body:getY(), "food", horizon)
    end)
    return place, need >= 0.75 and "desperate" or "standing"
end

function Diet.options(personId, body, state, mind, hours)
    local terminal, ownedState = terminalOf(personId, body)
    if not terminal then return {} end
    state = state or ownedState
    local root, options = rootStore(), {}
    personId = tostring(personId)
    if root.butcherActions[personId] then
        return { { id = terminal .. ":diet:butchering", kind = "diet-pending",
            activity = "butchering", score = 975, interruptsWork = true,
            detail = "continuing human butchery" } }
    end
    if root.dietActions[personId] then
        return { { id = terminal .. ":diet:feeding", kind = "diet-pending",
            activity = "feeding", score = 975, interruptsWork = true,
            detail = "continuing a meal" } }
    end
    local need = hunger(body)
    if need < HUNGER_THRESHOLD then return options end

    local humanFood = carriedHumanFood(body, terminal)
    local sourcePlace, sourceAdmission = observedFoodPlace(personId, body, need)
    if terminal == "crossed" then
        if humanFood then
            options[#options + 1] = {
                id = "crossed:diet:human:" .. tostring(humanFood:getID()),
                kind = "diet-human", activity = "feeding",
                score = 68 + need * 22,
                interruptsWork = need >= 0.75,
                detail = "preferred carried human-origin food",
            }
        end
        local corpse = Diet.nearestHumanCorpse(body, false)
        if corpse and cuttingWeapon(body) then
            options[#options + 1] = {
                id = "crossed:diet:corpse:" .. tostring(corpseToken(corpse)),
                kind = "butcher-human", activity = "butchering",
                score = 62 + need * 22,
                interruptsWork = need >= 0.75,
                corpse = corpse,
                detail = "reachable ordinary human corpse",
            }
        end
        local ordinary = ordinaryCarriedFood(body)
        if ordinary then
            options[#options + 1] = {
                id = "crossed:diet:ordinary:" .. tostring(ordinary:getID()),
                kind = "diet-ordinary", activity = "feeding",
                score = 34 + need * 22, interruptsWork = need >= 0.85,
                detail = "ordinary carried food",
            }
        end
        if sourcePlace then
            options[#options + 1] = {
                id = "crossed:diet:source:" .. tostring(sourcePlace.id),
                kind = "diet-source", activity = "acquiring-food",
                score = 26 + need * 25, interruptsWork = need >= 0.90,
                sourcePlace = sourcePlace, admission = sourceAdmission,
                permitHuman = true,
                detail = "privately observed exact food source",
            }
        end
    else
        local willingHuman = afflictedHumanWillingness(state, mind, need)
        if willingHuman and humanFood then
            options[#options + 1] = {
                id = "afflicted:diet:human:" .. tostring(humanFood:getID()),
                kind = "diet-human", activity = "feeding",
                score = 42 + need * 32,
                interruptsWork = need >= 0.82,
                detail = "individually accepted human-origin food",
            }
        end
        local corpse = willingHuman and Diet.nearestHumanCorpse(body, true)
            or nil
        if corpse and cuttingWeapon(body) then
            options[#options + 1] = {
                id = "afflicted:diet:corpse:" .. tostring(corpseToken(corpse)),
                kind = "butcher-human", activity = "butchering",
                score = 36 + need * 32,
                interruptsWork = need >= 0.85, corpse = corpse,
                detail = "human butchery accepted under current pressure",
            }
        end
        local protein = carriedMatching(body, function(profile)
            return profile.class == "protein"
        end)
        if protein then
            options[#options + 1] = {
                id = "afflicted:diet:protein:" .. tostring(protein:getID()),
                kind = "diet-protein", activity = "feeding",
                score = 60 + need * 30, interruptsWork = need >= 0.75,
                detail = "preferred carried meat or protein",
            }
        end
        local alternative = carriedMatching(body, function(profile)
            return profile.class == "alternative" and profile.dairy ~= true
        end)
        if alternative then
            options[#options + 1] = {
                id = "afflicted:diet:alternative:"
                    .. tostring(alternative:getID()),
                kind = "diet-alternative", activity = "feeding",
                score = 28 + need * 30, interruptsWork = need >= 0.88,
                detail = "feasible non-dairy food with reduced relief",
            }
        end
        if sourcePlace then
            options[#options + 1] = {
                id = "afflicted:diet:source:" .. tostring(sourcePlace.id),
                kind = "diet-source", activity = "acquiring-food",
                score = 24 + need * 30, interruptsWork = need >= 0.90,
                sourcePlace = sourcePlace, admission = sourceAdmission,
                permitHuman = willingHuman == true,
                detail = "privately observed food to inspect and acquire",
            }
        end
    end
    return options
end

function Diet.step(personId, body, state, mind, hours, selectedKind)
    local terminal, ownedState = terminalOf(personId, body)
    if not terminal then return false, "unavailable" end
    state = state or ownedState
    local root = rootStore()
    personId = tostring(personId)
    if root.butcherActions[personId] then return true, "butchering" end
    if root.dietActions[personId] then return true, "feeding" end
    if hunger(body) < HUNGER_THRESHOLD then return false, "sated" end
    local selected = type(selectedKind) == "table" and selectedKind or nil
    selectedKind = selected and selected.kind or selectedKind
    if not selectedKind then
        selected = ZAO.Driver and ZAO.Driver.chooseOption
            and ZAO.Driver.chooseOption(Diet.options(
                personId, body, state, mind, hours)) or nil
        selectedKind = selected and selected.kind or nil
    end
    if selectedKind == "diet-human" then
        local food, profile = carriedHumanFood(body, terminal)
        return food and Diet.beginEat(personId, body, food, hours, profile)
                or false,
            food and "feeding" or "human-food-unavailable"
    elseif selectedKind == "diet-ordinary" then
        local food = ordinaryCarriedFood(body)
        local profile = food and Diet.foodProfile(food) or nil
        local ate = food and Diet.beginEat(personId, body, food, hours, profile)
            or false
        return ate == true, ate and "feeding" or "ordinary-food-unavailable"
    elseif selectedKind == "diet-protein" then
        local food, profile = carriedMatching(body, function(candidate)
            return candidate.class == "protein"
        end)
        local ate = food and Diet.beginEat(personId, body, food, hours, profile)
            or false
        return ate == true, ate and "feeding" or "protein-food-unavailable"
    elseif selectedKind == "diet-alternative" then
        local food, profile = carriedMatching(body, function(candidate)
            return candidate.class == "alternative" and candidate.dairy ~= true
        end)
        local ate = food and Diet.beginEat(personId, body, food, hours, profile)
            or false
        return ate == true, ate and "feeding" or "alternative-food-unavailable"
    elseif selectedKind == "diet-source" then
        if not selected then
            for _, candidate in ipairs(Diet.options(personId, body, state,
                mind, hours)) do
                if candidate.kind == "diet-source" then
                    selected = candidate
                    break
                end
            end
        end
        if not (selected and selected.sourcePlace and SAO and SAO.SourceUse
            and SAO.SourceUse.begin) then return false, "source-unavailable" end
        if ZAO.Driver and ZAO.Driver.cancelRoute then
            ZAO.Driver.cancelRoute(personId, state,
                "exact-food-source-selected", hours)
        end
        local started = SAO.SourceUse.begin(personId, body,
            selected.sourcePlace, "food", selected.admission or "standing", {
                owner = "ZAO.Diet",
                nativeUseOwner = "ZAO.Diet",
                nativeUseTerminalState = terminal,
                nativeUsePermitHuman = selected.permitHuman == true,
                needValue = hunger(body),
            })
        return started == true, started and "acquiring-food"
            or "source-unavailable"
    elseif selectedKind == "butcher-human" then
        local corpse = selected and selected.corpse
            or Diet.nearestHumanCorpse(body, terminal ~= "crossed")
        return corpse and Diet.beginButcher(personId, body, corpse, hours) or false,
            corpse and "butchering" or "human-corpse-unavailable"
    elseif selectedKind == "diet-pending" then
        return false, "pending-action-missing"
    end
    return false, "no-selected-sustenance"
end

-- Interrupted timed actions mint no food and consume no meal. The terminal
-- journal remains durable so a save/reload cannot turn an abandoned action
-- into an unobserved success.
function Diet.resumePending()
    local root = rootStore()
    if not root then return false end
    for _, collection in ipairs({
        { "butcherActions", "butcherResults" },
        { "dietActions", "dietResults" },
    }) do
        local pending = {}
        for _, action in pairs(root[collection[1]]) do pending[#pending + 1] = action end
        for _, action in ipairs(pending) do
            if action.phase == "queued" and not Diet.runtimeActions[action.token] then
                archive(root, collection[1], collection[2], action,
                    "interrupted", "runtime-reconstructed", nil)
            end
        end
    end
    return true
end

ZAOButcherHumanAction = ISBaseTimedAction:derive("ZAOButcherHumanAction")

function ZAOButcherHumanAction:isValid()
    local data = bodyData(self.character)
    local apart = self.corpse and distance(self.character, self.corpse) or nil
    return data ~= nil and self.corpse ~= nil and self.weapon ~= nil
        and cuttingWeapon(self.character) == self.weapon
        and zaoLiving(data.SAOPersonId, self.character)
        and apart ~= nil and apart <= CORPSE_REACH
        and Diet.corpseEligibleFor(data.SAOPersonId, self.character,
            self.corpse) == true
end

function ZAOButcherHumanAction:waitToStart()
    self.character:faceThisObject(self.corpse)
    return self.character:shouldBeTurning()
end

function ZAOButcherHumanAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
end

function ZAOButcherHumanAction:stop()
    Diet.interruptButcher(self.zaoToken, self.character,
        "timed-action-stopped")
    ISBaseTimedAction.stop(self)
end

function ZAOButcherHumanAction:perform()
    ISBaseTimedAction.perform(self)
end

function ZAOButcherHumanAction:complete()
    return Diet.completeButcher(self.zaoToken, self.character,
        self.corpse, self.weapon)
end

function ZAOButcherHumanAction:new(character, corpse, weapon, token)
    local o = ISBaseTimedAction.new(self, character)
    o.corpse, o.weapon, o.zaoToken = corpse, weapon, token
    o.stopOnWalk, o.stopOnRun, o.stopOnAim = true, true, true
    o.maxTime = character:isTimedActionInstant() and 1 or 600
    return o
end

ZAOEatHumanAction = ISEatFoodAction:derive("ZAOEatHumanAction")

function ZAOEatHumanAction:isValid()
    local parentValid = true
    if type(ISEatFoodAction.isValid) == "function" then
        local ok, valid = pcall(ISEatFoodAction.isValid, self)
        parentValid = ok and valid == true
    end
    local data = bodyData(self.character)
    local terminal = data and terminalOf(data.SAOPersonId, self.character) or nil
    local admitted = Diet.profileAllowed(terminal, Diet.foodProfile(self.item))
    return parentValid and admitted == true
end

function ZAOEatHumanAction:stop()
    Diet.interruptEat(self.zaoToken, self.character, "timed-action-stopped")
    ISEatFoodAction.stop(self)
end

function ZAOEatHumanAction:complete()
    if not self:isValid() then
        Diet.interruptEat(self.zaoToken, self.character,
            "consumption-no-longer-admitted")
        return false
    end
    local completed = ISEatFoodAction.complete(self)
    if completed then
        Diet.completeEat(self.zaoToken, self.character, self.item)
    end
    return completed
end

function ZAOEatHumanAction:new(character, item, token)
    local o = ISEatFoodAction.new(self, character, item, 1)
    o.zaoToken = token
    return o
end

local function installEvolvedProvenance()
    if type(ISAddItemInRecipe) ~= "table"
        or type(ISAddItemInRecipe.complete) ~= "function" then return false end
    if ISAddItemInRecipe.ZAOHumanProvenanceWrapped == true then return true end
    local nativeComplete = ISAddItemInRecipe.complete
    ISAddItemInRecipe.complete = function(action)
        local source = action and action.usedItem or nil
        local profile = source and Diet.foodProfile(source) or nil
        local completed = nativeComplete(action)
        if completed and profile and profile.human == true then
            Diet.propagateHumanProvenance(action.baseItem, source, profile)
        end
        return completed
    end
    ISAddItemInRecipe.ZAOHumanProvenanceWrapped = true
    return true
end

local function registerSourceUseOwner()
    if SAO and SAO.SourceUse and SAO.SourceUse.registerNativeUseOwner then
        SAO.SourceUse.registerNativeUseOwner("ZAO.Diet", {
            createAction = Diet.createSourceUseAction,
            queueRefused = Diet.sourceUseQueueRefused,
        })
    end
end

registerSourceUseOwner()
installEvolvedProvenance()

if Diet.onGameStart then Events.OnGameStart.Remove(Diet.onGameStart) end
Diet.onGameStart = function()
    Diet.runtimeActions = {}
    registerSourceUseOwner()
    installEvolvedProvenance()
    Diet.resumePending()
end
Events.OnGameStart.Add(Diet.onGameStart)

return Diet
