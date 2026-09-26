-- A native study host may reserve an engine slot for detached rendering and
-- loading. The shared integration marker excludes that reference from actors.
ZAO = ZAO or {}
ZAO.Participants = ZAO.Participants or {}

function ZAO.Participants.player(index)
    local body = getSpecificPlayer(index)
    if body and body:getModData().SAO_ObserverAnchor == true then return nil end
    return body
end

function ZAO.Participants.residencyCenter()
    local reference = getSpecificPlayer(0)
    if not reference then return nil end
    return reference:getX(), reference:getY(), reference:getZ()
end
