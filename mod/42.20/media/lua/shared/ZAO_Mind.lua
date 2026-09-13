-- ZAO_Mind.lua - the four pillars with episodic identity decay.
--
-- The turn already fractured the memory. Where further loss occurs it
-- is episodic, not steady (DR-020): the pathogen's daily advance draws
-- decay episodes that take depth from one or two axes, which axis
-- varies per body, and the surviving fraction of each axis is carried
-- in the pathogen state as identityAxes. This surface reads it - it
-- never decays anything itself, and nothing calls a per-tick decay.

ZAO = ZAO or {}
ZAO.Mind = ZAO.Mind or {}
local Mind = ZAO.Mind

local function axisSurvival(state, axis)
    local axes = state and type(state.identityAxes) == "table"
        and state.identityAxes or nil
    if not axes then return 1.0 end
    local value = tonumber(axes[axis])
    if value == nil then return 1.0 end
    if value < 0.0 then return 0.0 end
    if value > 1.0 then return 1.0 end
    return value
end

function Mind.of(record, hour)
    if type(record) ~= "table" then return nil end
    local state = ZAO.State.of(record, hour)

    local perceptionSurvival = axisSurvival(state, "perception")
    local verbsSurvival = axisSurvival(state, "verbs")

    local perception = {
        beliefs = record.lessonsKnown or {},
        decay = state.decayState,
        provenance = record.lessonMeta or {},
        survival = perceptionSurvival,
    }

    local disposition = {
        aggression = (record.traitEchoes
            and record.traitEchoes.aggression or 0)
            * axisSurvival(state, "aggression"),
        selfPreservation = (record.traitEchoes
            and record.traitEchoes.selfPreservation or 0)
            * axisSurvival(state, "selfPreservation"),
        initiative = (record.traitEchoes
            and record.traitEchoes.initiative or 0)
            * axisSurvival(state, "initiative"),
        discipline = (record.traitEchoes
            and record.traitEchoes.discipline or 0)
            * axisSurvival(state, "discipline"),
        nerve = (record.traitEchoes
            and record.traitEchoes.nerve or 0)
            * axisSurvival(state, "nerve"),
    }

    local standing = {
        group = record.diedInGroup or record.unitId,
        claims = record.claims or {},
        trust = record.trust or {},
    }

    local execution = {
        retainedVerbs = record.verbs or {},
        canMove = state.terminalState ~= "dead"
            and verbsSurvival > 0.0,
        canTarget = state.terminalState ~= "dead"
            and verbsSurvival > 0.0,
        survival = verbsSurvival,
    }

    return {
        perception = perception,
        disposition = disposition,
        standing = standing,
        execution = execution,
        pathogen = state,
    }
end

return Mind