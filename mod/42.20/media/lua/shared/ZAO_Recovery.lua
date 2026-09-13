-- ZAO_Recovery.lua - recovery facts, read from where they actually live.
--
-- The antibodies mod stores its state as a table on the character's
-- modData - Antibodies -> medicalFile -> knoxInfectionsSurvived,
-- knoxAntibodiesLevel, knoxInfectionStage - so a recovery is read by
-- walking the table, never by comparing the container to true. A
-- survivor run by the sister has no recovery-mod body: their
-- recovery facts are the record's own - infections survived, whether
-- the current course was beaten. Survival keeps the state the
-- pathogen already changed; it never resurrects a body.

ZAO = ZAO or {}
ZAO.Recovery = ZAO.Recovery or {}
local Recovery = ZAO.Recovery

local EMPTY = { antibody = false, cure = false, repeatInfections = 0 }

local function medicalFileOf(player)
    if not player then return nil end
    local okData, data = pcall(function()
        return player:getModData()
    end)
    if not okData or type(data) ~= "table" then return nil end
    local okAntibodies, antibodies = pcall(function()
        return data.Antibodies
    end)
    if not okAntibodies or type(antibodies) ~= "table" then
        return nil
    end
    local okFile, file = pcall(function()
        return antibodies.medicalFile
    end)
    if not okFile or type(file) ~= "table" then return nil end
    return file
end

-- The local player's recovery facts, from the antibodies mod's own
-- table. knoxInfectionStage "NONE" is the cleared course; a level
-- above zero is antibody carried; survived count is the repeat count.
function Recovery.fromPlayer(player)
    local file = medicalFileOf(player)
    if not file then return EMPTY end

    local survived = 0
    pcall(function()
        survived = tonumber(file.knoxInfectionsSurvived) or 0
    end)
    local level = 0
    pcall(function()
        level = tonumber(file.knoxAntibodiesLevel) or 0
    end)
    local stage = nil
    pcall(function()
        stage = tostring(file.knoxInfectionStage or ""):upper()
    end)

    local cleared = stage == "NONE" or stage == ""
    return {
        antibody = level > 0,
        cure = survived > 0 and cleared,
        repeatInfections = survived,
    }
end

-- A survivor's recovery facts, from the sister's own record. The
-- course was beaten when the body fought one off: infections survived
-- count is the repeat count, and the current infection is gone.
function Recovery.fromRecord(record)
    if type(record) ~= "table" then return EMPTY end
    local survived = tonumber(record.infectionsSurvived) or 0
    local cleared = record.knoxInfected ~= true
        and record.dead ~= true
        and record.turnedDormant ~= true
    return {
        antibody = survived > 0 and cleared,
        cure = survived > 0 and cleared,
        repeatInfections = survived,
    }
end

function Recovery.of(source)
    if not source then return EMPTY end
    if type(source) == "table" and source.getModData == nil then
        return Recovery.fromRecord(source)
    end
    if type(source.getModData) == "function" then
        return Recovery.fromPlayer(source)
    end
    return EMPTY
end

return Recovery