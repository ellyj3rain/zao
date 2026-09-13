-- ZAO_API.lua - the public query surface.
-- Other mods may ask whether ZAO owns a body and what form it carries.

ZAO = ZAO or {}

function ZAO.owns(zombie)
    if ZAOJavaBridge then
        local ok, owned = pcall(function()
            return ZAOJavaBridge:owns(zombie)
        end)
        if ok then return owned end
    end
    if not zombie then return false end
    local ok, data = pcall(function() return zombie:getModData() end)
    if not ok or not data then return false end
    return data.ZAOOwned == true
end

function ZAO.formOf(zombie)
    if ZAOJavaBridge then
        local ok, form = pcall(function()
            return ZAOJavaBridge:formOf(zombie)
        end)
        if ok and form then return form end
    end
    if not ZAO.owns(zombie) then return nil end
    local ok, form = pcall(function()
        return zombie:getModData().ZAOForm
    end)
    if not ok or not form or form == "" then return nil end
    return form
end

function ZAO.performanceOf(zombie)
    if ZAOJavaBridge then
        local ok, performance = pcall(function()
            return ZAOJavaBridge:performanceOf(zombie)
        end)
        if ok and type(performance) == "number" then return performance end
    end
    if not ZAO.owns(zombie) then return nil end
    local ok, performance = pcall(function()
        return zombie:getModData().ZAOFormPerformance
    end)
    if not ok or type(performance) ~= "number" then return nil end
    return performance
end

return ZAO
