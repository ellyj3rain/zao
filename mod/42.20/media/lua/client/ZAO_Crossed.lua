-- ZAO_Crossed - Crossed-specific options under the shared ZAO person driver.
--
-- Crossed retain the person's human shell, physiology, cognition, history and
-- learned capability within the pathogen's established constraints. Their
-- altered motives do not make strategy exceptional: every choice still starts
-- from that actor's private perception, current activity, relationships,
-- pressures and feasible means. Human predation can join sustenance, cruelty,
-- domination, terror and contagion, but it is not a biological-only hunger.
--
-- The options below are a bounded enacted slice. Predation, intentional
-- exposure, blooded weapons, driving, holding ground and food are providers,
-- not a species loop or an exhaustive vocabulary. New human actions can enter
-- the same arbitration without redefining what a Crossed person is.

ZAO = ZAO or {}
ZAO.Crossed = ZAO.Crossed or {}
local Crossed = ZAO.Crossed

local ORGANISE_RADIUS = 15.0   -- kin within this cohere; beyond it they drift
local HOLD_DISTANCE = 3.0      -- arrival, not nearby travel, evidences holding

local DRIVE_ORDER_RANGE = 40.0  -- closer than this they walk
local DRIVE_COOLDOWN_HOURS = 24.0
local CLAIM_RADIUS = 15         -- the sister's own re-find circle
local ACTION_RANGE = 30.0

local function log(msg)
    if ZAO.Log and ZAO.Log.line then ZAO.Log.line("XED", msg) end
end

local function dataOf(body)
    local ok, data = pcall(function() return body:getModData() end)
    if ok and type(data) == "table" then return data end
    return nil
end

local function targetPerson(target)
    local id, state = nil, nil
    pcall(function()
        local data = target:getModData()
        id = data and data.SAOPersonId and tostring(data.SAOPersonId) or nil
    end)
    if id and ZAO.Pathogen then state = ZAO.Pathogen.stateOf(id) end
    return id, state
end

local function targetName(target)
    local name = nil
    pcall(function() name = target:getUsername() end)
    return name and tostring(name) ~= "" and tostring(name) or nil
end

local function routeTo(body, personId, state, kind, targetId,
        x, y, z, running, hours)
    if not (ZAO.Driver and ZAO.Driver.routeTo) then return false end
    local active = ZAO.Driver.routeTo(personId, body, state, kind, targetId,
        math.floor(x), math.floor(y), math.floor(z), running, hours)
    return active == true
end

local function tickCombat(body, data, hours)
    if not data.ZAOCrossedCombat then return false, nil end
    local ok, verdict = pcall(function() return SAOJavaBridge:tickCombat(body) end)
    verdict = ok and tostring(verdict or "") or "COMBAT_TICK_FAILED"
    data.ZAOCrossedCombatVerdict = verdict
    if verdict:find("COMBAT_SUCCEEDED", 1, true) then
        data.ZAOCrossedCombat = nil
        data.ZAOCrossedCombatAt = hours
        return false, "combat-completed"
    end
    if verdict:find("COMBAT_FAILED", 1, true)
        or verdict == "COMBAT_IDLE" or verdict == "NOT_A_SHELL" then
        data.ZAOCrossedCombat = nil
        data.ZAOCrossedCombatAt = hours
        pcall(function() SAOJavaBridge:resetCombat(body) end)
        return false, "combat-failed"
    end
    return true, "combat"
end

local function beginCombat(body, personId, target, data, hours)
    if not (SAOJavaBridge and SAOJavaBridge.beginCombatWithName
        and target) then return false end
    local name = targetName(target)
    if not name then return false end
    local held = body:getPrimaryHandItem()
    local armed = false
    pcall(function() armed = held and instanceof(held, "HandWeapon") end)
    if not armed then
        pcall(function() SAOJavaBridge:equipBestRanged(body) end)
        held = body:getPrimaryHandItem()
        pcall(function() armed = held and instanceof(held, "HandWeapon") end)
    end
    if not armed then
        pcall(function() SAOJavaBridge:equipBestMelee(body) end)
    end
    local ok, verdict = pcall(function()
        return SAOJavaBridge:beginCombatWithName(body, name, ACTION_RANGE)
    end)
    verdict = ok and tostring(verdict or "") or "COMBAT_FAILED"
    data.ZAOCrossedCombatVerdict = verdict
    if verdict:find("COMBAT_STARTED", 1, true) then
        data.ZAOCrossedCombat = true
        data.ZAOCrossedCombatTarget = targetPerson(target) or name
        data.ZAOCrossedCombatStartedAt = hours
        if ZAO.Driver and ZAO.Driver.cancelRoute then
            ZAO.Driver.cancelRoute(personId,
                ZAO.Pathogen.stateOf(personId), "native-combat-started", hours)
        end
        return true
    end
    return false
end

local function distance(zx, zy, tx, ty)
    local dx, dy = zx - tx, zy - ty
    return math.sqrt(dx * dx + dy * dy)
end

-- Any privately observed Crossed person is a possible associate. Prior group
-- and relationship affect the option; neither is required, and sight does not
-- disclose the other person's private route or target.
local function associatesOf(personId, group, visiblePeople)
    local associates = {}
    for _, person in ipairs(visiblePeople or {}) do
        if person.id ~= personId and person.state == "crossed" then
            local otherGroup = nil
            pcall(function()
                otherGroup = SAO.Standing and SAO.Standing.groupOf
                    and SAO.Standing.groupOf(person.id) or nil
                if not otherGroup then
                    local rec = SAO.Identity and SAO.Identity.get(person.id)
                    otherGroup = rec and (rec.diedInGroup or rec.unitId) or nil
                end
            end)
            associates[#associates + 1] = {
                id = person.id, body = person.body,
                dist = person.distance, belief = person.belief,
                relationship = tonumber(person.relationship) or 0,
                priorGroup = group ~= nil and otherGroup == group,
            }
        end
    end
    table.sort(associates, function(a, b) return a.dist < b.dist end)
    return associates
end

-- While a drive the crossed ordered is live, the pass ticks it the
-- same way the sister's driver is ticked: one verdict per call, the
-- terminal verdicts end the trip. The Java side owns the loop ([C82]);
-- Lua orders and reads.
local function driveTick(zombie, data, hours)
    if not SAOJavaBridge then
        data.ZAOCrossedDriving = nil
        return false
    end
    local ok, verdict = pcall(function()
        return SAOJavaBridge:tickDrive(zombie)
    end)
    if not ok or verdict == nil then
        data.ZAOCrossedDriving = nil
        return false
    end
    verdict = tostring(verdict)
    if verdict == "Succeeded" then
        data.ZAOCrossedDriving = nil
        data.ZAOCrossedDriveAt = hours
        log("parked at "
            .. string.format("%.1f,%.1f", zombie:getX(), zombie:getY()))
        return false
    end
    if verdict == "IDLE" or verdict:find("DRIVE_", 1, true) then
        data.ZAOCrossedDriving = nil
        data.ZAOCrossedDriveAt = hours
        return false
    end
    return true
end

-- The person's vocabulary, read from the mind's own retained verbs
-- ([A13]: the crossed are the named consumer of the sister's driving
-- map). The map is the sister's half and this is ours: the call is
-- made, and the verdict is honored. A map that will not take a
-- crossed body yet answers NOT_A_SHELL and the body walks - the
-- honest fallback, the same law the sister's own goers follow.
local function tryDrive(zombie, data, mind, gx, gy, hours)
    local verbs = mind.execution.retainedVerbs or {}
    local canDrive = false
    for _, verb in pairs(verbs) do
        if verb == "drive" then canDrive = true end
    end
    if not canDrive then return false end

    local group = mind.standing.group
    local car = nil
    pcall(function()
        car = SAO.Standing.roadworthy(tostring(group or ""), nil)
    end)
    if not car then return false end

    -- [C115]'s dial crosses here for the same reason it crosses in
    -- the sister's order: Java cannot read SandboxVars.
    local sv = SandboxVars and SandboxVars.SurvivorAwareness or nil
    local cap = (sv and tonumber(sv.DriveSpeedCap)) or 30.0

    local ok, verdict = pcall(function()
        return SAOJavaBridge:driveBegin(
            zombie, CLAIM_RADIUS,
            tostring(car.name or "car"),
            math.floor(gx), math.floor(gy), cap)
    end)
    verdict = ok and tostring(verdict) or "no-bridge"
    if verdict:find("DRIVE_STARTED", 1, true) then
        data.ZAOCrossedDriving = true
        log("ordered the " .. tostring(car.name or "car"):gsub("^Base%.", "")
            .. " for " .. tostring(group))
        return true
    end
    if verdict:find("NOT_A_SHELL", 1, true) then
        -- The sister's widening is her half of the seam ([A13]);
        -- named in both records. Until it lands, the crossed walk,
        -- and the decline is logged once per body, never per scan.
        if not data.ZAOCrossedShellDeclined then
            data.ZAOCrossedShellDeclined = true
            log("the map would not take the body - walking")
        end
        data.ZAOCrossedDriveAt = hours
    end
    return false
end

local function add(options, option)
    if type(option) == "table" and option.id then
        options[#options + 1] = option
    end
end

local function relationFixation(value)
    value = tonumber(value) or 0
    return math.min(1, math.abs(value))
end

function Crossed.options(body, personId, state, mind, now, hours)
    if not (body and mind and mind.execution and mind.execution.canMove) then
        return {}
    end
    personId = tostring(personId)
    local options, data = {}, dataOf(body)
    if not data then return options end
    local disposition = mind.disposition or {}
    local hunger = mind.physical and tonumber(mind.physical.hunger) or 0
    local predatoryPressure = ZAO.Maintenance
        and ZAO.Maintenance.predatoryPressure
        and ZAO.Maintenance.predatoryPressure(state, hours) or 0

    if data.ZAOCrossedDriving then
        add(options, { id = "crossed:driving", kind = "driving",
            activity = "driving", score = 1000, interruptsWork = true,
            detail = "continuing retained vehicle use" })
    end
    if data.ZAOCrossedCombat then
        add(options, { id = "crossed:combat", kind = "combat",
            activity = "combat", score = 990, interruptsWork = true,
            detail = "continuing native combat" })
    end
    if ZAO.Exposure and ZAO.Exposure.activeFor
        and ZAO.Exposure.activeFor(personId) then
        add(options, { id = "crossed:exposure:active", kind = "exposure-active",
            activity = "exposure", score = 980, interruptsWork = true,
            detail = "continuing intentional blood exposure" })
    end
    local activePredation = ZAO.Predation and ZAO.Predation.activeFor
        and ZAO.Predation.activeFor(personId) or nil
    if activePredation then
        add(options, { id = "crossed:predation:active",
            kind = "predation-active", activity = activePredation.phase,
            score = 985, interruptsWork = true,
            targetId = activePredation.targetId,
            detail = "continuing an evidenced predatory encounter" })
    end

    if ZAO.Diet and ZAO.Diet.options then
        local ok, foodOptions = pcall(ZAO.Diet.options, personId, body, state,
            mind, hours)
        if ok and type(foodOptions) == "table" then
            for _, option in ipairs(foodOptions) do add(options, option) end
        end
    end

    if ZAO.Driver and ZAO.Driver.humanPhysiologyOptions then
        local ok, bodyOptions = pcall(ZAO.Driver.humanPhysiologyOptions,
            personId, body, state, mind, hours)
        if ok and type(bodyOptions) == "table" then
            for _, option in ipairs(bodyOptions) do add(options, option) end
        end
    end

    local people = ZAO.Mind and ZAO.Mind.visiblePeople
        and ZAO.Mind.visiblePeople(mind, body, now, ACTION_RANGE) or {}
    local associates = associatesOf(personId,
        mind.standing and mind.standing.group, people)
    local associateIds = {}
    for _, entry in ipairs(associates) do associateIds[entry.id] = true end
    local predationDistance, predationFear = nil, 0

    for _, person in ipairs(people) do
        if person.state == "afflicted" then
            local observedFear = tonumber(person.visibleDistress) or 0
            add(options, {
                id = "crossed:exposure:" .. person.id,
                kind = "exposure", activity = "exposure",
                score = 42 + (tonumber(disposition.aggression) or 0) * 16
                    + (tonumber(disposition.initiative) or 0) * 12
                    + relationFixation(person.relationship) * 8
                    + observedFear * 14,
                interruptsWork = true, targetId = person.id,
                target = person.body,
                detail = "observed Afflicted exposure opportunity",
            })
            -- Afflicted are generally dispreferred as prey and remain useful
            -- to Crossed in many other ways.  They are nevertheless not made
            -- categorically inedible or immune to violence: extreme pressure,
            -- personal fixation and disposition can make this one option.
            if predatoryPressure >= 0.70 then
                add(options, {
                    id = "crossed:predation:afflicted:" .. person.id,
                    kind = "predation", activity = "hunt",
                    score = 12 + predatoryPressure * 30
                        + (tonumber(disposition.aggression) or 0) * 12
                        + relationFixation(person.relationship) * 10
                        + observedFear * 8 - person.distance * 0.25,
                    interruptsWork = predatoryPressure >= 0.90,
                    targetId = person.id, target = person.body,
                    distance = person.distance,
                    detail = "dispreferred Afflicted predation opportunity",
                })
            end
        elseif person.state ~= "crossed" and not associateIds[person.id] then
            local observedFear = tonumber(person.visibleDistress) or 0
            local distanceCost = math.min(ACTION_RANGE, person.distance) * 0.25
            predationDistance = not predationDistance
                and person.distance or math.min(predationDistance, person.distance)
            predationFear = math.max(predationFear, observedFear)
            add(options, {
                id = "crossed:predation:" .. person.id,
                kind = "predation", activity = "hunt",
                score = 38 + predatoryPressure * 36 + hunger * 8
                    + (tonumber(disposition.aggression) or 0) * 15
                    + (tonumber(disposition.initiative) or 0) * 10
                    + relationFixation(person.relationship) * 8
                    + observedFear * 12 - distanceCost,
                interruptsWork = true, targetId = person.id,
                target = person.body, distance = person.distance,
                detail = "observed human predation opportunity",
            })
        end
    end

    local weapon, mode = nil, nil
    if predationDistance and ZAO.Contamination
        and ZAO.Contamination.preparationCandidate then
        weapon, mode = ZAO.Contamination.preparationCandidate(body, personId)
    end
    if weapon then
        add(options, {
            id = "crossed:prepare-weapon:" .. tostring(weapon:getID()),
            kind = "prepare-weapon", activity = "weapon-preparation",
            score = 34 + (tonumber(disposition.initiative) or 0) * 24
                + (tonumber(disposition.discipline) or 0) * 18
                + math.min(ACTION_RANGE, predationDistance) * 0.45
                + predationFear * 8,
            interruptsWork = false, weapon = weapon, mode = mode,
            detail = "available deliberate blood-contamination tactic",
        })
    end

    for _, entry in ipairs(associates) do
        if entry.dist <= ORGANISE_RADIUS then
            add(options, { id = "crossed:kin:" .. entry.id,
                kind = entry.dist <= HOLD_DISTANCE and "hold-kin" or "kin",
                activity = entry.dist <= HOLD_DISTANCE
                    and "holding-with-kin" or "organising",
                score = 20 + (tonumber(disposition.discipline) or 0) * 10
                    + relationFixation(entry.relationship) * 6
                    + (entry.priorGroup and 5 or 0),
                interruptsWork = false, kin = entry,
                detail = "observed Crossed kin" })
        end
    end

    local record = SAO and SAO.Identity and SAO.Identity.get(personId) or nil
    if record and record.homeX and record.homeY
        and (tonumber(disposition.discipline) or 0) >= 0.5 then
        local d = distance(body:getX(), body:getY(), record.homeX, record.homeY)
        add(options, { id = "crossed:home", kind = d <= HOLD_DISTANCE
                and "hold-home" or "home",
            activity = d <= HOLD_DISTANCE and "holding-home" or "returning-home",
            score = 18 + (tonumber(disposition.discipline) or 0) * 10,
            interruptsWork = false, x = record.homeX, y = record.homeY,
            z = record.homeZ or body:getZ(), distance = d,
            detail = "retained home attachment" })
    end

    local route = state.driver and state.driver.route or nil
    if route then
        add(options, { id = "crossed:route:" .. tostring(route.token),
            kind = "route", activity = tostring(route.kind or "moving"),
            score = 28, interruptsWork = route.kind == "hunt"
                or route.kind == "exposure", route = route,
            detail = "continuing a chosen route" })
    end
    return options
end

function Crossed.execute(option, body, personId, state, mind, now, hours)
    if not (type(option) == "table" and body and mind) then
        return false, "idle"
    end
    personId = tostring(personId)
    local data = dataOf(body)
    if not data then return false, "unavailable" end

    if option.kind == "driving" then
        return driveTick(body, data, hours), "driving"
    elseif option.kind == "combat" then
        return tickCombat(body, data, hours)
    elseif option.kind == "exposure-active" then
        local active = ZAO.Exposure and ZAO.Exposure.activeFor
            and ZAO.Exposure.activeFor(personId) or nil
        local target = active and ZAO.Controller and ZAO.Controller.controlled
            and ZAO.Controller.controlled[tostring(active.targetId)] or nil
        if target then
            return ZAO.Exposure.step(body, personId, state, target,
                tostring(active.targetId), now, hours) == true, "exposure"
        end
        return false, "exposure"
    elseif string.sub(tostring(option.kind), 1, 5) == "diet-"
        or option.kind == "butcher-human" then
        if ZAO.Diet and ZAO.Diet.step then
            local ok, committed, activity = pcall(ZAO.Diet.step,
                personId, body, state, mind, hours, option)
            return ok and committed == true, ok and activity or "idle"
        end
        return false, "idle"
    elseif option.owner == "ZAO.Driver.humanPhysiology" then
        if ZAO.Driver and ZAO.Driver.executeHumanPhysiology then
            return ZAO.Driver.executeHumanPhysiology(option, personId, body,
                state, mind, hours)
        end
        return false, "unavailable"
    elseif option.kind == "prepare-weapon" then
        local prepared = ZAO.Contamination
            and ZAO.Contamination.beginPreparation
            and ZAO.Contamination.beginPreparation(personId, body,
                option.weapon, hours) or false
        return prepared == true, prepared and "weapon-preparation" or "idle"
    elseif option.kind == "exposure" then
        local committed = false
        if option.target and ZAO.Exposure then
            pcall(function()
                committed = ZAO.Exposure.step(body, personId, state,
                    option.target, option.targetId, now, hours) == true
            end)
        end
        return committed, "exposure"
    elseif option.kind == "predation-active" then
        local action = ZAO.Predation and ZAO.Predation.activeFor
            and ZAO.Predation.activeFor(personId) or nil
        local targetId = action and action.targetId or option.targetId
        local target = targetId and SAO and SAO.Communication
            and SAO.Communication.bodyFor(targetId) or nil
        if action and ZAO.Predation and ZAO.Predation.step then
            return ZAO.Predation.step(personId, body, targetId, target, hours)
        end
        return false, "idle"
    elseif option.kind == "predation" then
        local target = option.target
        if not target then return false, "idle" end
        if option.distance and option.distance >= DRIVE_ORDER_RANGE
            and (hours - (tonumber(data.ZAOCrossedDriveAt)
                or -999.0)) >= DRIVE_COOLDOWN_HOURS
            and tryDrive(body, data, mind, target:getX(), target:getY(), hours) then
            return true, "driving"
        end
        if ZAO.Predation and ZAO.Predation.step then
            return ZAO.Predation.step(personId, body, option.targetId,
                target, hours)
        end
        return false, "idle"
    elseif option.kind == "kin" then
        local entry = option.kin
        local active = routeTo(body, personId, state, "kin", entry.id,
            entry.body:getX(), entry.body:getY(), entry.body:getZ(),
            false, hours)
        return active, active and "organising" or "idle"
    elseif option.kind == "hold-kin" then
        return false, "holding-with-kin"
    elseif option.kind == "home" then
        if option.distance >= DRIVE_ORDER_RANGE
            and (hours - (tonumber(data.ZAOCrossedDriveAt)
                or -999.0)) >= DRIVE_COOLDOWN_HOURS
            and tryDrive(body, data, mind, option.x, option.y, hours) then
            return true, "driving"
        end
        local active = routeTo(body, personId, state, "home", nil,
            option.x, option.y, option.z, false, hours)
        return active, active and "returning-home" or "idle"
    elseif option.kind == "hold-home" then
        return false, "holding-home"
    elseif option.kind == "route" and option.route then
        local route = option.route
        local active = routeTo(body, personId, state, route.kind,
            route.targetId, route.x, route.y, route.z, route.running, hours)
        return active, active and tostring(route.kind or "moving") or "idle"
    end
    return false, "idle"
end

-- Compatibility for older harnesses. A supplied controller target is ignored;
-- the option set is rebuilt from the actor's own Perception.
function Crossed.decide(body, personId, state, mind, target, now, hours)
    local option = ZAO.Driver and ZAO.Driver.chooseOption
        and ZAO.Driver.chooseOption(Crossed.options(
            body, personId, state, mind, now, hours)) or nil
    return Crossed.execute(option, body, personId, state, mind, now, hours)
end

return Crossed
