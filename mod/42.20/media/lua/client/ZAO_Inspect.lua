-- ZAO_Inspect.lua - the state panel.
-- A local development window, not a gameplay surface. It shows the nearest
-- SAO survivor's ZAO state if SAO is present, and says so plainly if it is not.

require "ISUI/ISCollapsableWindow"

ZAO = ZAO or {}

ZAOInspectWindow = ISCollapsableWindow:derive("ZAOInspectWindow")
ZAOInspectWindow.instance = nil

local FONT_S = UIFont.Small
local FONT_M = UIFont.Medium

local function nearestSurvivor()
    if not SAO or not SAO.Body or not SAO.Body.active then return nil end
    local me = (ZAO.Participants and ZAO.Participants.player or getSpecificPlayer)(0)
    if not me then return nil end
    local px, py = me:getX(), me:getY()
    local best, bestD = nil, nil
    for id, body in pairs(SAO.Body.active) do
        local ok, d = pcall(function()
            local dx, dy = body:getX() - px, body:getY() - py
            return dx * dx + dy * dy
        end)
        if ok and d and (not bestD or d < bestD) then
            best, bestD = id, d
        end
    end
    return best
end

function ZAOInspectWindow:new(x, y, w, h)
    local o = ISCollapsableWindow.new(self, x, y, w, h)
    o.title = "ZAO state"
    o.resizable = false
    o.lines = {}
    return o
end

function ZAOInspectWindow:render()
    ISCollapsableWindow.render(self)
    local x = 12
    local y = self:titleBarHeight() + 8
    if #self.lines == 0 then
        self:drawText("SAO is not loaded.",
            x, y, 0.6, 0.6, 0.6, 1, FONT_M)
        return
    end
    for _, line in ipairs(self.lines) do
        self:drawText(line, x, y, 0.82, 0.82, 0.82, 1, FONT_S)
        y = y + 18
    end
end

function ZAOInspectWindow.toggle()
    if ZAOInspectWindow.instance
        and ZAOInspectWindow.instance:isVisible() then
        ZAOInspectWindow.instance:setVisible(false)
        ZAOInspectWindow.instance:removeFromUIManager()
        ZAOInspectWindow.instance = nil
        return
    end

    local lines = {}
    lines[#lines + 1] = "bridge: " .. (ZAOJavaBridge and "on" or "off")
    local id = nearestSurvivor()
    local rec = id and SAO.Identity and SAO.Identity.get(id) or nil
    if not rec then
        lines[1] = "No survivor is nearby."
    else
        local hour = 0
        pcall(function() hour = SAO.History.countyHours() end)
        local state = ZAO.State.of(rec, hour)
        local mind = ZAO.Mind and ZAO.Mind.of(rec, hour) or nil
        lines[#lines + 1] = "person: " .. tostring(id)
        lines[#lines + 1] = "terminal: " .. tostring(state.terminalState)
        lines[#lines + 1] = "decay: " .. tostring(state.decayState)
        lines[#lines + 1] = "form: " .. tostring(state.currentForm)
        lines[#lines + 1] = string.format(
            "performance: %.2f", tonumber(state.formPerformance) or 0)
        local visible = state.visibleForms or {}
        if #visible == 0 then
            lines[#lines + 1] = "visible forms: none"
        else
            for _, form in ipairs(visible) do
                lines[#lines + 1] = string.format(
                    "visible form: %s (%.2f)",
                    tostring(form.form),
                tonumber(form.performance) or 0)
            end
        end
        if mind then
            lines[#lines + 1] = "mind: perception="
                .. tostring(next(mind.perception.beliefs) ~= nil)
                .. " aggression=" .. string.format(
                    "%.2f", mind.disposition.aggression or 0)
            lines[#lines + 1] = "standing: group="
                .. tostring(mind.standing.group)
            lines[#lines + 1] = "execution: move="
                .. tostring(mind.execution.canMove)
                .. " target=" .. tostring(mind.execution.canTarget)
        end
        local attributes = ZAO.Pathogen
            and ZAO.Pathogen.attributeString(state) or ""
        if attributes ~= "" then
            lines[#lines + 1] = "attributes: " .. attributes
        end
        local history = state.history or {}
        if #history > 0 then
            local last = history[#history]
            lines[#lines + 1] = "last event: " .. tostring(last.type)
                .. " day " .. tostring(last.day)
        end
        local recovery = ZAO.Recovery and ZAO.Recovery.of(rec) or nil
        if recovery then
            lines[#lines + 1] = "recovery: antibody="
                .. tostring(recovery.antibody)
                .. " cure=" .. tostring(recovery.cure)
                .. " infections=" .. tostring(recovery.repeatInfections)
        end
        if ZAO.Settlement then
            local group
            for _, candidate in pairs(ZAO.Settlement.groups or {}) do
                if candidate.members[id] then group = candidate end
            end
            lines[#lines + 1] = "settlement: " .. (group
                and (group.id .. ", necessity "
                    .. string.format("%.2f", group.necessity))
                or "none")
        end
    end

    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local ww, wh = 360, 40 + 18 * (#lines + 1)
    local w = ZAOInspectWindow:new(
        math.max(0, sw - ww - 40),
        math.floor((sh - wh) / 3),
        ww, wh)
    w:initialise()
    w:addToUIManager()
    w.lines = lines
    ZAOInspectWindow.instance = w
end

Events.OnKeyPressed.Add(function(key)
    local ok, bound = pcall(function()
        return getCore():getKey("ZAOInspect")
    end)
    if ok and bound and bound ~= 0 and key == bound then
        ZAOInspectWindow.toggle()
    end
end)

return ZAOInspectWindow
