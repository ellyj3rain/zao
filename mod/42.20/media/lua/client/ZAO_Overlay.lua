-- ZAO_Overlay.lua - the form overlay.
-- Draws the current form and performance above every nearby SAO survivor,
-- in the world, where the operator can see it while playing.

ZAO = ZAO or {}

ZAOOverlay = ISUIElement:derive("ZAOOverlay")
ZAOOverlay.instance = nil

local FONT_S = UIFont.Small

local COLORS = {
    Puker    = { r = 0.40, g = 0.90, b = 0.60 },
    Husk     = { r = 0.70, g = 0.65, b = 0.60 },
    Skitter  = { r = 0.85, g = 0.65, b = 0.20 },
    Wrecker  = { r = 0.85, g = 0.35, b = 0.25 },
    Leaper   = { r = 0.45, g = 0.75, b = 0.95 },
    Weeper   = { r = 0.60, g = 0.55, b = 0.95 },
    none     = { r = 0.50, g = 0.50, b = 0.50 },
}

function ZAOOverlay:initialise()
    ISUIElement.initialise(self)
end

function ZAOOverlay:render()
    ISUIElement.render(self)
    local me = (ZAO.Participants and ZAO.Participants.player or getSpecificPlayer)(0)
    if not me then
        return
    end

    local playerIndex = me:getPlayerNum()
    local bodies = {}
    if SAO and SAO.Body and SAO.Body.active then
        for id, body in pairs(SAO.Body.active) do
            bodies[#bodies + 1] = { id = id, body = body }
        end
    end
    if ZAO and ZAO.Controller and ZAO.Controller.controlled then
        for id, body in pairs(ZAO.Controller.controlled) do
            bodies[#bodies + 1] = { id = id, body = body, zombie = true }
        end
    end

    for _, entry in ipairs(bodies) do
        local ok = pcall(function()
            local body = entry.body
            local form, performance
            if entry.zombie then
                form = ZAOJavaBridge and ZAOJavaBridge:formOf(body) or nil
                performance = ZAOJavaBridge
                    and ZAOJavaBridge:performanceOf(body) or 0
            else
                local rec = SAO.Identity.get(entry.id)
                if not rec then return end
                local hour = 0
                pcall(function() hour = SAO.History.countyHours() end)
                local state = ZAO.State.of(rec, hour)
                form = state.currentForm
                performance = state.formPerformance
            end
            if not form or form == "none" then return end
            local x = isoToScreenX(playerIndex, body:getX(), body:getY(), body:getZ() + 1.6)
            local y = isoToScreenY(playerIndex, body:getX(), body:getY(), body:getZ() + 1.6)
            if not x or not y then return end
            local color = COLORS[form] or COLORS.none
            local label = tostring(form)
                .. " " .. string.format("%.2f", performance or 0)
            self:drawText(label, x - 34, y - 18,
                color.r, color.g, color.b, 0.85, FONT_S)
        end)
        if not ok then
            -- Keep the overlay alive even if one body is stale.
        end
    end
end

function ZAOOverlay:new()
    local o = ISUIElement:new(0, 0,
        getCore():getScreenWidth(), getCore():getScreenHeight())
    o:initialise()
    return o
end

function ZAOOverlay.ensure()
    local policy = ZAO.Sandbox and ZAO.Sandbox.policy() or nil
    if policy and not policy.overlay then return end
    if ZAOOverlay.instance then return end
    ZAOOverlay.instance = ZAOOverlay:new()
    ZAOOverlay.instance:addToUIManager()
end

Events.OnGameStart.Add(ZAOOverlay.ensure)

return ZAOOverlay
