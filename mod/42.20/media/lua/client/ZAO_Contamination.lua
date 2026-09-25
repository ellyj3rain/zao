-- ZAO_Contamination - deliberate Crossed blood on weapons and ammunition.
--
-- Preparation is an interruptible timed action on one exact equipped weapon.
-- Ranged preparation covers the rounds loaded at completion; melee preparation
-- covers one connecting strike. Uses are consumed by native attack events, and
-- a later tick applies blood only through the injury the engine actually made.

require "TimedActions/ISBaseTimedAction"

ZAO = ZAO or {}
ZAO.Contamination = ZAO.Contamination or {}
local Contamination = ZAO.Contamination
local priorOnSwing = Contamination.onSwing
local priorOnHit = Contamination.onHit
local priorOnAttackFinished = Contamination.onAttackFinished
local priorTickPending = Contamination.tickPending

Contamination.runtimeActions = Contamination.runtimeActions or {}
Contamination.pendingByActor = Contamination.pendingByActor or {}
Contamination.pendingTargets = Contamination.pendingTargets or {}

local function rootStore()
    local root = ZAO.StateStore and ZAO.StateStore.store() or nil
    if not root then return nil end
    root.contaminationPrep = root.contaminationPrep or {}
    root.contaminationPrepResults = root.contaminationPrepResults or {}
    root.contaminationHits = root.contaminationHits or {}
    root.contaminationResults = root.contaminationResults or {}
    return root
end

local function dataOf(object)
    local data = nil
    if object then pcall(function() data = object:getModData() end) end
    return type(data) == "table" and data or nil
end

local function actorId(body)
    local data = dataOf(body)
    return data and data.SAOPersonId and tostring(data.SAOPersonId) or nil
end

local function crossedOwner(body, suppliedId)
    local personId = tostring(suppliedId or actorId(body) or "")
    local state = personId ~= "" and ZAO.Pathogen
        and ZAO.Pathogen.stateOf(personId) or nil
    local controlled = ZAO.Controller and ZAO.Controller.controlled or nil
    if not (state and state.terminalState == "crossed"
        and controlled and controlled[personId] == body) then
        return nil, nil
    end
    return personId, state
end

local function weaponMode(weapon)
    local ok, eligible, ranged = pcall(function()
        if not weapon or not instanceof(weapon, "HandWeapon") then
            return false, false
        end
        return true, weapon:isRanged() == true
    end)
    if not ok or not eligible then return nil end
    return ranged and "projectile" or "melee"
end

local function archive(root, source, results, key, action, outcome, reason)
    if not (root and action) then return false end
    if not root[results][action.token] then
        action.outcome = outcome
        action.reason = reason
        root[results][action.token] = action
    end
    if source and key ~= nil then root[source][key] = nil end
    Contamination.runtimeActions[action.token] = nil
    return true
end

local function nextToken(root, prefix, personId)
    root.contaminationSequence = (tonumber(root.contaminationSequence) or 0) + 1
    return prefix .. ":" .. tostring(personId) .. ":"
        .. tostring(root.contaminationSequence)
end

local function contaminationOf(weapon)
    local data = dataOf(weapon)
    if not data or not data.ZAOCrossedBloodToken
        or (tonumber(data.ZAOCrossedBloodUses) or 0) <= 0 then return nil end
    return {
        token = tostring(data.ZAOCrossedBloodToken),
        carrierId = tostring(data.ZAOCrossedBloodCarrier or ""),
        uses = tonumber(data.ZAOCrossedBloodUses) or 0,
        mode = tostring(data.ZAOCrossedBloodMode or ""),
    }
end

function Contamination.isPrepared(weapon, personId)
    local row = contaminationOf(weapon)
    return row ~= nil and row.carrierId == tostring(personId or "")
end

-- Pure option discovery. Deliberate blood preparation is one available tactic,
-- never an automatic prelude to every attack. Selection belongs to the
-- Crossed policy; this function only reports the exact equipped means.
function Contamination.preparationCandidate(body, personId)
    local owner = crossedOwner(body, personId)
    local root = owner and rootStore() or nil
    if not (owner and root) then return nil, nil, "not-crossed-owner" end
    if root.contaminationPrep[owner] then return nil, nil, "already-preparing" end
    local weapon = body:getPrimaryHandItem()
    local mode = weaponMode(weapon)
    if not mode then return nil, nil, "no-equipped-weapon" end
    if mode == "projectile" then
        local ammo = 0
        pcall(function() ammo = weapon:getCurrentAmmoCount() end)
        if ammo <= 0 then return nil, nil, "no-loaded-ammunition" end
    end
    if Contamination.isPrepared(weapon, owner) then
        return nil, nil, "already-prepared"
    end
    return weapon, mode, nil
end

function Contamination.beginPreparation(personId, body, weapon, hours)
    local root = rootStore()
    local owner = crossedOwner(body, personId)
    local mode = weaponMode(weapon)
    if not (root and owner and mode and body:getPrimaryHandItem() == weapon) then
        return false
    end
    if Contamination.isPrepared(weapon, owner) then return false end
    if root.contaminationPrep[owner] then return true end
    local action = {
        version = 1,
        token = nextToken(root, "blood-weapon", owner),
        personId = owner,
        weaponId = weapon:getID(),
        weaponType = weapon:getFullType(),
        mode = mode,
        phase = "queued",
        startedAtHours = tonumber(hours) or 0,
    }
    root.contaminationPrep[owner] = action
    local timed = ZAOContaminateWeaponAction:new(body, weapon, action.token)
    Contamination.runtimeActions[action.token] = timed
    local queued = SAO and SAO.Needs and SAO.Needs.queueVerified
        and SAO.Needs.queueVerified(timed) or false
    if not queued then
        archive(root, "contaminationPrep", "contaminationPrepResults",
            owner, action, "failed", "timed-action-refused")
        return false
    end
    local data = dataOf(body)
    if data then data.ZAOContaminationAction = action.token end
    return true
end

function Contamination.completePreparation(actionToken, body, weapon)
    local root = rootStore()
    local owner = crossedOwner(body)
    local action = owner and root and root.contaminationPrep[owner] or nil
    if not action or action.token ~= actionToken or action.phase ~= "queued"
        or body:getPrimaryHandItem() ~= weapon
        or weapon:getID() ~= action.weaponId then return false end
    local mode = weaponMode(weapon)
    if mode ~= action.mode then return false end
    local uses = 1
    if mode == "projectile" then
        pcall(function() uses = math.max(1, weapon:getCurrentAmmoCount()) end)
    end
    local data = dataOf(weapon)
    data.ZAOCrossedBloodToken = action.token
    data.ZAOCrossedBloodCarrier = owner
    data.ZAOCrossedBloodMode = mode
    data.ZAOCrossedBloodUses = uses
    action.phase = "completed"
    action.uses = uses
    archive(root, "contaminationPrep", "contaminationPrepResults",
        owner, action, "completed", "weapon-stamped")
    local bdata = dataOf(body)
    if bdata and bdata.ZAOContaminationAction == action.token then
        bdata.ZAOContaminationAction = nil
    end
    return true
end

function Contamination.interruptPreparation(actionToken, body, reason)
    local root = rootStore()
    local owner = actorId(body)
    local action = owner and root and root.contaminationPrep[owner] or nil
    if not action or action.token ~= actionToken then return false end
    local data = dataOf(body)
    if data and data.ZAOContaminationAction == action.token then
        data.ZAOContaminationAction = nil
    end
    return archive(root, "contaminationPrep", "contaminationPrepResults",
        owner, action, "interrupted", reason or "timed-action-stopped")
end

local function consumeUse(attacker, weapon, kind)
    local root = rootStore()
    local owner, carrierState = crossedOwner(attacker)
    local row = contaminationOf(weapon)
    if not (root and owner and carrierState and row
        and row.carrierId == owner and row.mode == kind) then return nil end
    local token = nextToken(root, "blood-hit", owner)
    local hit = {
        version = 1,
        token = token,
        preparationToken = row.token,
        kind = kind == "projectile" and "crossed-blood-projectile"
            or "crossed-blood-melee",
        carrierId = owner,
        weaponId = weapon:getID(),
        weaponType = weapon:getFullType(),
        phase = "pending",
        ageTicks = 0,
    }
    root.contaminationHits[token] = hit
    local data = dataOf(weapon)
    data.ZAOCrossedBloodUses = row.uses - 1
    if data.ZAOCrossedBloodUses <= 0 then
        data.ZAOCrossedBloodToken = nil
        data.ZAOCrossedBloodCarrier = nil
        data.ZAOCrossedBloodMode = nil
        data.ZAOCrossedBloodUses = nil
    end
    Contamination.pendingByActor[owner] = token
    return hit
end

local function targetIdentity(target)
    local data = dataOf(target)
    if data and data.SAOPersonId then return tostring(data.SAOPersonId) end
    local username = nil
    pcall(function() username = target:getUsername() end)
    if username and tostring(username) ~= "" then
        return "player:" .. tostring(username)
    end
    return nil
end

local function terminalTarget(targetId)
    local state = targetId and ZAO.Pathogen
        and ZAO.Pathogen.stateOf(targetId) or nil
    if not state then return nil, nil end
    if state.terminalState == "afflicted" then return "afflicted", state end
    if state.terminalState == "crossed" then return "crossed", state end
    if state.terminalState == "turned" or state.terminalState == "dead"
        or tostring(state.currentForm or "none") ~= "none" then
        return "mutant-or-dead", state
    end
    return nil, state
end

local function exposeAfflicted(root, hit, target, targetId, carrierState, hours)
    hit.phase = "resolving"
    hit.targetId = targetId
    local result = {
        token = hit.token,
        kind = hit.kind,
        completed = true,
        carrierId = hit.carrierId,
        targetId = targetId,
        atHours = hours,
    }
    local receipt = ZAO.Pathogen and ZAO.Pathogen.expose(targetId,
        carrierState, math.floor((tonumber(hours) or 0) / 24.0), result) or nil
    if type(receipt) ~= "table" then
        return nil, "pathogen-refused-result"
    end
    hit.pathogenReceipt = receipt
    if receipt.converted and ZAO.Exposure
        and ZAO.Exposure.ensureCrossedOwnership then
        local moved, reason = ZAO.Exposure.ensureCrossedOwnership(
            targetId, target, hours)
        if not moved then
            hit.transferPending = true
            hit.transferReason = reason
        end
    end
    return receipt.converted and "converted" or "resisted",
        receipt.converted and "crossed-pathogen" or "pathogen-roll"
end

function Contamination.resolve(token, target)
    local root = rootStore()
    local hit = root and root.contaminationHits[tostring(token or "")] or nil
    if not hit then return root and root.contaminationResults[tostring(token or "")] end
    if hit.phase ~= "pending" then return false end
    local targetId = targetIdentity(target)
    hit.targetId = targetId
    local targetKind, targetState = terminalTarget(targetId)
    local carrierState = ZAO.Pathogen and ZAO.Pathogen.stateOf(hit.carrierId)
        or nil
    local hours = 0
    pcall(function() hours = SAO.History.countyHours() end)
    local outcome, reason
    if not carrierState or carrierState.terminalState ~= "crossed" then
        outcome, reason = "interrupted", "carrier-no-longer-crossed"
    elseif targetKind == "afflicted" then
        outcome, reason = exposeAfflicted(root, hit, target, targetId,
            carrierState, hours)
        if not outcome then
            hit.phase = "pending"
            return false
        end
    elseif targetKind == "crossed" or targetKind == "mutant-or-dead" then
        outcome, reason = "refused", "ineligible-zao-target"
    elseif not (ZAOJavaBridge and ZAOJavaBridge.applyCrossedBlood) then
        outcome, reason = "failed", "native-infection-bridge-unavailable"
    else
        local ok, verdict = pcall(function()
            return ZAOJavaBridge:applyCrossedBlood(target)
        end)
        verdict = ok and tostring(verdict or "") or "REFUSED:bridge-fault"
        if string.sub(verdict, 1, 8) == "APPLIED:" then
            outcome, reason = "infected", verdict
        elseif string.sub(verdict, 1, 9) == "RESISTED:" then
            outcome, reason = "resisted", verdict
        else
            outcome, reason = "refused", verdict
        end
        if targetId and SAO and SAO.Identity and SAO.PhysicalFacts then
            local rec = SAO.Identity.get(targetId)
            if rec then pcall(SAO.PhysicalFacts.refreshBodyFacts, rec, target, hours) end
        end
    end
    hit.phase = "resolved"
    hit.outcome, hit.reason, hit.resolvedAtHours = outcome, reason, hours
    root.contaminationResults[hit.token] = hit
    root.contaminationHits[hit.token] = nil
    Contamination.pendingTargets[hit.token] = nil
    if Contamination.pendingByActor[hit.carrierId] == hit.token then
        Contamination.pendingByActor[hit.carrierId] = nil
    end
    return hit
end

function Contamination.onSwing(attacker, weapon)
    local owner = crossedOwner(attacker)
    if not owner or weaponMode(weapon) ~= "projectile" then return end
    local prior = Contamination.pendingByActor[owner]
    if prior then
        local root = rootStore()
        local miss = root and root.contaminationHits[prior] or nil
        if miss and miss.phase == "pending" then
            if Contamination.pendingTargets[prior] then
                Contamination.resolve(prior, Contamination.pendingTargets[prior])
            else
                miss.phase, miss.outcome, miss.reason = "resolved", "missed",
                    "next-shot-started"
                root.contaminationResults[miss.token] = miss
                root.contaminationHits[miss.token] = nil
                Contamination.pendingTargets[miss.token] = nil
            end
        end
    end
    consumeUse(attacker, weapon, "projectile")
end

function Contamination.onHit(attacker, target, weapon)
    local owner = crossedOwner(attacker)
    local mode = weaponMode(weapon)
    if not (owner and mode) then return end
    local token = mode == "projectile"
        and Contamination.pendingByActor[owner] or nil
    local root = rootStore()
    local hit = token and root and root.contaminationHits[token] or nil
    -- OnWeaponSwing is not exposed by every supported build. The character-hit
    -- event is therefore also an admission point for a projectile use. It still
    -- resolves later, after the native attack has applied its wound.
    if not hit then hit = consumeUse(attacker, weapon, mode) end
    if not hit then return end
    Contamination.pendingTargets[hit.token] = target
    hit.targetId = targetIdentity(target)
end

function Contamination.onAttackFinished(attacker)
    local owner = crossedOwner(attacker)
    local token = owner and Contamination.pendingByActor[owner] or nil
    if not token then return end
    local target = Contamination.pendingTargets[token]
    if target then
        Contamination.resolve(token, target)
        return
    end
    local root = rootStore()
    local hit = root and root.contaminationHits[token] or nil
    if hit then
        hit.phase, hit.outcome, hit.reason = "resolved", "missed",
            "native-attack-finished"
        root.contaminationResults[token] = hit
        root.contaminationHits[token] = nil
    end
    Contamination.pendingByActor[owner] = nil
end

function Contamination.tickPending()
    local root = rootStore()
    if not root then return end
    local tokens = {}
    for token in pairs(Contamination.pendingTargets) do tokens[#tokens + 1] = token end
    for _, token in ipairs(tokens) do
        local hit = root.contaminationHits[token]
        if hit then
            hit.ageTicks = (tonumber(hit.ageTicks) or 0) + 1
            if hit.ageTicks >= 1 then
                Contamination.resolve(token, Contamination.pendingTargets[token])
            end
        else
            Contamination.pendingTargets[token] = nil
        end
    end
end

function Contamination.resumePending()
    local root = rootStore()
    if not root then return false end
    local prep = {}
    for _, action in pairs(root.contaminationPrep) do prep[#prep + 1] = action end
    for _, action in ipairs(prep) do
        if not Contamination.runtimeActions[action.token] then
            archive(root, "contaminationPrep", "contaminationPrepResults",
                action.personId, action, "interrupted", "runtime-reconstructed")
        end
    end
    local hits = {}
    for _, hit in pairs(root.contaminationHits) do hits[#hits + 1] = hit end
    for _, hit in ipairs(hits) do
        hit.phase, hit.outcome, hit.reason = "resolved", "interrupted",
            "runtime-reconstructed"
        root.contaminationResults[hit.token] = hit
        root.contaminationHits[hit.token] = nil
    end
    return true
end

ZAOContaminateWeaponAction = ISBaseTimedAction:derive(
    "ZAOContaminateWeaponAction")

function ZAOContaminateWeaponAction:isValid()
    return self.weapon ~= nil
        and self.character:getPrimaryHandItem() == self.weapon
        and crossedOwner(self.character) ~= nil
end

function ZAOContaminateWeaponAction:start()
    self:setActionAnim("Craft")
    self:setOverrideHandModels(self.weapon, nil)
end

function ZAOContaminateWeaponAction:stop()
    Contamination.interruptPreparation(self.zaoToken, self.character,
        "timed-action-stopped")
    ISBaseTimedAction.stop(self)
end

function ZAOContaminateWeaponAction:perform()
    ISBaseTimedAction.perform(self)
end

function ZAOContaminateWeaponAction:complete()
    return Contamination.completePreparation(self.zaoToken,
        self.character, self.weapon)
end

function ZAOContaminateWeaponAction:new(character, weapon, token)
    local o = ISBaseTimedAction.new(self, character)
    o.weapon, o.zaoToken = weapon, token
    o.stopOnWalk, o.stopOnRun, o.stopOnAim = true, true, true
    o.maxTime = character:isTimedActionInstant() and 1 or 80
    return o
end

if Contamination.onGameStart then
    Events.OnGameStart.Remove(Contamination.onGameStart)
end
Contamination.onGameStart = function()
    Contamination.runtimeActions = {}
    Contamination.pendingByActor = {}
    Contamination.pendingTargets = {}
    Contamination.resumePending()
end
Events.OnGameStart.Add(Contamination.onGameStart)

if Events.OnWeaponSwing and priorOnSwing then
    Events.OnWeaponSwing.Remove(priorOnSwing)
end
if Events.OnWeaponSwing then
    Events.OnWeaponSwing.Add(Contamination.onSwing)
end
if priorOnHit then Events.OnWeaponHitCharacter.Remove(priorOnHit) end
Events.OnWeaponHitCharacter.Add(Contamination.onHit)
if Events.OnPlayerAttackFinished and priorOnAttackFinished then
    Events.OnPlayerAttackFinished.Remove(priorOnAttackFinished)
end
if Events.OnPlayerAttackFinished then
    Events.OnPlayerAttackFinished.Add(Contamination.onAttackFinished)
end
if priorTickPending then Events.OnTick.Remove(priorTickPending) end
Events.OnTick.Add(Contamination.tickPending)

return Contamination
