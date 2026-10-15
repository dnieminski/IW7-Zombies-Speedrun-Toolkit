local Core = require("core")
local scale = _1080p or 1
local function text(parent, id, value, x, y, w, size, color)
    local element = LUI.UIText.new()
    element.id = id
    element:SetFont(FONTS.GetFont(FONTS.MainMedium.File))
    element:SetFontSize(size * scale)
    element:SetAlignment(LUI.Alignment.Left)
    element:SetAnchorsAndPosition(0, 1, 0, 1, x * scale, (x + w) * scale, y * scale, (y + size + 5) * scale)
    if color then element:SetRGBFromTable(color, 0) end
    element:setText(value, 0)
    parent:addElement(element)
    return element
end

local function panel(parent, id, x, y, w, h, alpha)
    local element = LUI.UIImage.new()
    element.id = id
    element:setImage(RegisterMaterial("white"))
    element:SetRGBFromTable({r = 0.025, g = 0.035, b = 0.055}, 0)
    element:SetAlpha(alpha, 0)
    element:SetAnchorsAndPosition(0, 1, 0, 1, x * scale, (x + w) * scale, y * scale, (y + h) * scale)
    parent:addElement(element)
end

local function readHistory()
    local path = Engine.GetDvarString("br_log_path")
    if not path or path == "" then path = Engine.GetDvarString("g_log") end
    if not path or path == "" then path = "iw7-mod/logs/games_mp.log" end
    if not io or not io.fileexists(path) then return {}, "No history yet" end
    local ok, contents = pcall(io.readfile, path)
    if not ok then return {}, "History file unavailable" end
    return Core.history(contents), path
end

local function current()
    return Core.snapshot(Engine.GetDvarString("br_snapshot"))
end

local preferences = {}
local settingsMap = "cp_final"
local function preference(map, def)
    local key = Core.preferenceKey(map, def)
    if not preferences[key] then preferences[key] = Core.decodePreference(Engine.GetDvarString(key), def) end
    return preferences[key]
end

local function savePreference(map, def, enabled, label, controllerIndex)
    local key = Core.preferenceKey(map, def)
    local encoded = Core.encodePreference(enabled, label)
    -- Both the key and value are generated: user text is hex, never console syntax.
    local ok = pcall(function() Engine.ExecNow('seta ' .. key .. ' "' .. encoded .. '"', controllerIndex) end)
    if not ok or Engine.GetDvarString(key) ~= encoded then return false end
    preferences[key] = Core.decodePreference(encoded, def)
    return true
end

local function button(parent, id, label, x, y, w, action, controllerIndex)
    -- The stock Zombies MenuButton forces a 322px background on menu_create.
    -- Own every visual here so artwork and the clickable area share the same bounds.
    local element = LUI.UIButton.new()
    element.id = id
    element:SetAnchorsAndPosition(0, 1, 0, 1, x * scale, (x + w) * scale, y * scale, (y + 32) * scale)
    panel(element, "Fill", 0, 0, w, 32, 0.95)
    local edges = {}
    for index, bounds in ipairs({{0, 0, w, 1}, {0, 31, w, 1}, {0, 0, 1, 32}, {w - 1, 0, 1, 32}}) do
        local edge = LUI.UIImage.new()
        edge.id = "Edge" .. index
        edge:setImage(RegisterMaterial("white"))
        edge:SetAnchorsAndPosition(0, 1, 0, 1, bounds[1] * scale, (bounds[1] + bounds[3]) * scale, bounds[2] * scale, (bounds[2] + bounds[4]) * scale)
        element:addElement(edge)
        edges[index] = edge
    end
    element.Text = text(element, "Text", label, 12, 4, w - 24, 18)
    local function highlight(focused)
        local color = focused and {r = 0.25, g = 0.9, b = 0.75} or {r = 0.35, g = 0.38, b = 0.42}
        for _, edge in ipairs(edges) do edge:SetRGBFromTable(color, 0) end
        element.Text:SetRGBFromTable(focused and {r = 0.25, g = 0.9, b = 0.75} or {r = 0.9, g = 0.9, b = 0.9}, 0)
    end
    element:registerEventHandler("button_over", function() highlight(true) end)
    element:registerEventHandler("button_up", function() highlight(false) end)
    element:registerEventHandler("button_action", action)
    highlight(false)
    parent:addElement(element)
    return element
end

local function splitRows(savedSplits, map)
    local rows = {}
    for index, def in ipairs(Core.splitsFor(map)) do
        local option = preference(map, def)
        local value
        if savedSplits then
            value = savedSplits[def[1]]
        else
            value = tonumber(Engine.GetDvarString("br_split_" .. def[3]))
        end
        if option.enabled then
            rows[#rows + 1] = {name = def[1], label = option.label, order = index, value = value and value >= 0 and value or nil}
        end
    end
    return rows
end

MenuBuilder.registerType("BeastRunnerSplitSettings", function(menu, controller)
    local self = LUI.UIElement.new()
    self.id = "BeastRunnerSplitSettings"
    local controllerIndex = controller and controller.controllerIndex or 0
    local map = Core.profile(settingsMap) and settingsMap or "cp_final"
    panel(self, "Backdrop", 70, 70, 1780, 920, 0.98)
    text(self, "Title", "EDIT SPLITS", 100, 95, 1600, 36)
    local subtitle = text(self, "Subtitle", "", 100, 145, 1600, 22)
    text(self, "Explanation", "OFF hides a split from the overlay and comparisons. Timer, event recording and PB eligibility continue.", 100, 190, 1660, 20)
    text(self, "NameHeader", "SHOW / CUSTOM NAME", 100, 235, 600, 20)
    text(self, "DefaultHeader", "DEFAULT NAME", 980, 235, 790, 20)
    local notice = text(self, "Notice", "Rename up to 28 characters. An empty name restores the default. Settings are saved with the game profile.", 100, 815, 1660, 19)
    local rows = {}
    local refresh
    for index = 1, 15 do
        local row = {def = nil}
        local y = 270 + (index - 1) * 35
        row.toggle = button(self, "Track" .. index, "", 100, y, 490, function()
            local def = row.def
            if not def then return end
            local option = preference(map, def)
            if not savePreference(map, def, not option.enabled, option.custom, controllerIndex) then notice:setText("Could not save settings. Check the console for errors.", 0) end
            refresh()
        end, controllerIndex)
        row.rename = button(self, "Rename" .. index, "RENAME", 620, y, 150, function()
            local def, editMap = row.def, map
            if not def then return end
            if not OSK or not OSK.OpenScreenKeyboard then notice:setText("Keyboard unavailable here. Rename from the Zombies main menu.", 0); return end
            local option = preference(editMap, def)
            OSK.OpenScreenKeyboard(controllerIndex, "Split name (empty = default)", option.label, Core.labelLimit, false, false, true, function(_, value)
                if value == nil then return end -- Cancel must not erase a name.
                local latest = preference(editMap, def)
                if not savePreference(editMap, def, latest.enabled, value, controllerIndex) then notice:setText("Could not save settings. Check the console for errors.", 0) end
                refresh()
            end, CoD and CoD.KeyboardInputTypes and CoD.KeyboardInputTypes.Normal)
        end, controllerIndex)
        row.reset = button(self, "Default" .. index, "DEFAULT", 790, y, 150, function()
            local def = row.def
            if not def then return end
            if not savePreference(map, def, preference(map, def).enabled, "", controllerIndex) then notice:setText("Could not save settings. Check the console for errors.", 0) end
            refresh()
        end, controllerIndex)
        row.label = text(self, "DefaultName" .. index, "", 980, y + 3, 790, 20)
        rows[index] = row
    end
    refresh = function()
        subtitle:setText(string.upper(Core.profile(map).name), 0)
        for index, row in ipairs(rows) do
            row.def = Core.splitsFor(map)[index]
            local def = row.def
            for _, element in ipairs({row.toggle, row.rename, row.reset, row.label}) do element:SetAlpha(def and 1 or 0, 0) end
            for _, element in ipairs({row.toggle, row.rename, row.reset}) do
                if element.SetButtonDisabled then element:SetButtonDisabled(def == nil) end
            end
            if def then
                local option = preference(map, def)
                row.toggle.Text:setText((option.enabled and "[X] " or "[ ] ") .. option.label, 0)
                row.label:setText(def[2], 0)
            else
                row.toggle.Text:setText("", 0); row.label:setText("", 0)
            end
        end
    end
    local function changeMap(direction)
        if not Engine.InFrontend() then return end
        local index = 1
        for i, id in ipairs(Core.maps.order) do if id == map then index = i end end
        map = Core.maps.order[(index - 1 + direction) % #Core.maps.order + 1]
        settingsMap = map
        refresh()
    end
    local previous = button(self, "PreviousMap", "PREVIOUS MAP", 100, 870, 310, function() changeMap(-1) end, controllerIndex)
    local nextMap = button(self, "NextMap", "NEXT MAP", 435, 870, 310, function() changeMap(1) end, controllerIndex)
    previous:SetAlpha(Engine.InFrontend() and 1 or 0, 0); nextMap:SetAlpha(Engine.InFrontend() and 1 or 0, 0)
    button(self, "ResetMap", "RESTORE MAP DEFAULTS", 770, 870, 460, function()
        local ok = true
        for _, def in ipairs(Core.splitsFor(map)) do
            if not savePreference(map, def, true, "", controllerIndex) then ok = false end
        end
        if not ok then notice:setText("Some settings could not be saved. Check the console.", 0) end
        refresh()
    end, controllerIndex)
    button(self, "Done", "DONE", 1260, 870, 310, function() LUI.FlowManager.RequestLeaveMenu(self) end, controllerIndex)
    local bind = LUI.UIBindButton.new()
    self:addElement(bind)
    bind:registerEventHandler("button_secondary", function() LUI.FlowManager.RequestLeaveMenu(self) end)
    bind:registerEventHandler("button_shoulderl", function() changeMap(-1) end)
    bind:registerEventHandler("button_shoulderr", function() changeMap(1) end)
    refresh()
    return self
end)

local function makeHUD(hud)
    if hud.BeastRunner then return end
    local element = LUI.UIElement.new()
    element.id = "BeastRunnerHUD"
    element:SetAnchorsAndPosition(0, 1, 0, 1, 30 * scale, 420 * scale, 30 * scale, 305 * scale)
    hud:addElement(element)
    hud.BeastRunner = element
    panel(element, "Backdrop", 0, 0, 390, 275, 0.8)
    local title = text(element, "Title", "SPEEDRUN TOOLKIT", 14, 12, 365, 17, {r = 0.25, g = 0.9, b = 0.75})
    local timer = text(element, "Timer", "00:00.0", 14, 39, 365, 40)
    local status = text(element, "Status", "ARMED / GAME TIME", 14, 85, 365, 16)
    local stats = text(element, "Stats", "", 14, 112, 365, 16)
    local lines = {}
    for index = 1, 4 do lines[index] = text(element, "Split" .. index, "", 14, 144 + (index - 1) * 25, 365, 16) end
    local cachedCategory, cachedBest = nil, nil
    local function update()
        local map = Engine.GetDvarString("mapname")
        local enabled = Engine.GetDvarString("br_enabled") == "1"
            and Engine.GetDvarString("br_hud") ~= "0"
            and Core.profile(map) ~= nil
        element:SetAlpha(enabled and 1 or 0, 0)
        if not enabled then return end
        local run = current()
        -- Prefer the map in the server snapshot over stale UI/lobby values.
        map = run.map or map
        local profile = Core.profile(map)
        if not profile then element:SetAlpha(0, 0); return end
        title:setText(profile.short .. " / SPEEDRUN TOOLKIT", 0)
        timer:setText(Core.time(run.elapsed), 0)
        local category = Core.category(run)
        local comparisonKey = map .. ":" .. category
        if cachedCategory ~= comparisonKey then
            cachedCategory = comparisonKey
            cachedBest = Core.summary(readHistory(), category, map).best
        end
        local shortCategory = tostring(run.players) .. "P / " .. (run.dc == 1 and "DC" or "STANDARD")
        status:setText(string.upper(run.state) .. " / GAME TIME / " .. shortCategory, 0)
        stats:setText(string.format("ROUND %d    KILLS %d    DOWNS %d", run.round, run.kills, run.downs), 0)
        local completed = {}
        for _, row in ipairs(splitRows(nil, map)) do if row.value then completed[#completed + 1] = row end end
        table.sort(completed, function(a, b)
            if a.value == b.value then return a.order < b.order end
            return a.value < b.value
        end)
        for index = 1, 4 do
            local row = completed[math.max(1, #completed - 3) + index - 1]
            local label = ""
            if row then
                local pb = cachedBest and cachedBest.splits[row.name]
                label = row.label .. "  " .. Core.time(row.value)
                if pb then label = label .. "  " .. Core.delta(row.value - pb) end
            end
            lines[index]:setText(label, 0)
        end
    end
    element:registerEventHandler("br_hud_tick", update)
    element:addElement(LUI.UITimer.new(nil, {interval = 50, event = "br_hud_tick"}))
    update()
end

MenuBuilder.registerType("BeastRunnerStats", function(menu, controller)
    local self = LUI.UIElement.new()
    self.id = "BeastRunnerStats"
    local controllerIndex = controller and controller.controllerIndex or 0
    panel(self, "Backdrop", 70, 70, 1780, 920, 0.98)
    text(self, "Title", "IW7 ZOMBIES SPEEDRUN TOOLKIT", 100, 95, 1600, 36)
    local subtitle = text(self, "Subtitle", "", 100, 145, 1600, 20)
    local header = text(self, "Header", "", 100, 190, 1640, 22)
    local info = text(self, "Info", "", 100, 230, 1640, 20)
    local left, right, currentTimes, pbTimes, deltas = {}, {}, {}, {}, {}
    for index = 1, 16 do
        local y = 280 + (index - 1) * 34
        left[index] = text(self, "Left" .. index, "", 100, y, 1020, 20)
        currentTimes[index] = text(self, "Current" .. index, "", 445, y, 155, 20)
        pbTimes[index] = text(self, "PB" .. index, "", 615, y, 195, 20)
        deltas[index] = text(self, "Delta" .. index, "", 825, y, 245, 20)
        right[index] = text(self, "Right" .. index, "", 1160, 280 + (index - 1) * 34, 650, 20)
    end
    text(self, "Help", "Use the buttons above. Shoulder buttons: change map in main menu. Back: close.", 100, 925, 1600, 19)
    local page = "splits"
    local runs, source = readHistory()
    local selectedMap = (Engine.InFrontend() and runs[#runs] and runs[#runs].map) or current().map or "cp_final"
    local function refresh()
        local frontend = Engine.InFrontend()
        local saved
        if frontend then
            for index = #runs, 1, -1 do
                if runs[index].map == selectedMap then saved = runs[index]; break end
            end
        end
        local live = frontend and (saved or Core.snapshot("")) or current()
        local map = frontend and selectedMap or live.map
        local profile = Core.profile(map) or Core.profile("cp_final")
        subtitle:setText(string.upper(profile.name .. " / FIRST SPAWN TO " .. profile.finishLabel), 0)
        local state = frontend and (saved and saved.status or "no recorded runs") or live.state
        local category = Core.category(live)
        local summary = Core.summary(runs, category, map)
        local label = frontend and (saved and "LAST RUN #" .. saved.attempt .. " / " or "") or ""
        header:setText(label .. category .. "  /  " .. string.upper(state) .. "  /  " .. Core.time(live.elapsed), 0)
        info:setText(string.format("%d %s    %d valid %s    PB %s    Average %s", summary.attempts, summary.attempts == 1 and "attempt" or "attempts", summary.finishes, summary.finishes == 1 and "finish" or "finishes", Core.time(summary.best and summary.best.elapsed), Core.time(summary.average)), 0)
        for index = 1, 16 do
            left[index]:setText("", 0); right[index]:setText("", 0)
            currentTimes[index]:setText("", 0); pbTimes[index]:setText("", 0); deltas[index]:setText("", 0)
        end
        if page == "splits" then
            left[1]:setText("SPLIT", 0)
            currentTimes[1]:setText(frontend and "LAST RUN" or "CURRENT", 0)
            pbTimes[1]:setText("PB CUMULATIVE", 0)
            deltas[1]:setText("DELTA", 0)
            local savedSplits = frontend and (saved and saved.splits or {}) or nil
            for index, row in ipairs(splitRows(savedSplits, map)) do
                local best = summary.best and summary.best.splits[row.name]
                local delta = row.value and best and Core.delta(row.value - best) or ""
                left[index + 1]:setText(row.label, 0)
                currentTimes[index + 1]:setText(Core.time(row.value), 0)
                pbTimes[index + 1]:setText(Core.time(best), 0)
                deltas[index + 1]:setText(delta, 0)
            end
            right[1]:setText(frontend and "LAST RECORDED RUN / TEAM" or "CURRENT RUN / TEAM", 0)
            right[2]:setText("Round: " .. live.round, 0)
            right[3]:setText("Kills: " .. live.kills, 0)
            right[4]:setText("Headshots: " .. live.headshots, 0)
            right[5]:setText("Downs: " .. live.downs, 0)
            right[6]:setText("Revives: " .. live.revives, 0)
            right[8]:setText("RECORDED CATEGORY TOTALS", 0)
            right[9]:setText("Kills: " .. summary.kills .. "   Downs: " .. summary.downs, 0)
            right[10]:setText("Revives: " .. summary.revives, 0)
            right[11]:setText("Finish rate: " .. (summary.attempts > 0 and string.format("%.1f%%", summary.finishes * 100 / summary.attempts) or "--"), 0)
            right[13]:setText("Game time / pauses excluded", 0)
            right[14]:setText("Practice build / boss finish unverified", 0)
        else
            left[1]:setText("RECENT ATTEMPTS / THIS MAP / ALL CATEGORIES", 0)
            local line = 2
            for index = #runs, 1, -1 do
                local run = runs[index]
                if run.map == map and line <= 15 then
                    local state = run.status
                    if state == "finished" and not run.valid then state = "finish / incomplete quest" end
                    left[line]:setText("#" .. run.attempt .. "  " .. Core.category(run) .. "  " .. Core.time(run.elapsed) .. "  " .. state .. "  K:" .. run.kills .. " D:" .. run.downs, 0)
                    line = line + 1
                end
            end
            right[1]:setText("BEST CUMULATIVE SPLITS / THIS CATEGORY", 0)
            for index, row in ipairs(splitRows({}, map)) do
                right[index + 1]:setText(row.label .. "  " .. Core.time(summary.bestSplits[row.name]), 0)
            end
        end
    end
    local function changeMap(direction)
        if not Engine.InFrontend() then return end
        local index = 1
        for i, map in ipairs(Core.maps.order) do if map == selectedMap then index = i end end
        selectedMap = Core.maps.order[(index - 1 + direction) % #Core.maps.order + 1]
        refresh()
    end
    local function switchPage() page = page == "splits" and "history" or "splits"; refresh() end
    local function toggleHUD() Engine.SetDvarString("br_hud", Engine.GetDvarString("br_hud") == "0" and "1" or "0") end
    local function reloadHistory() runs, source = readHistory(); refresh() end
    local controls = {
        {"PreviousMap", "PREVIOUS MAP", function() changeMap(-1) end},
        {"NextMap", "NEXT MAP", function() changeMap(1) end},
        {"ViewHistory", "SPLITS / HISTORY", switchPage},
        {"ToggleHUD", "SHOW / HIDE HUD", toggleHUD},
        {"ReloadHistory", "REFRESH HISTORY", reloadHistory},
        {"EditSplits", "EDIT SPLITS", function()
            settingsMap = Engine.InFrontend() and selectedMap or current().map
            ACTIONS.OpenMenu("BeastRunnerSplitSettings", true, controllerIndex)
        end}
    }
    for index, control in ipairs(controls) do
        local x = 100 + (index - 1) * 280
        local controlButton = button(self, control[1], control[2], x, 870, 265, control[3], controllerIndex)
        if index <= 2 then controlButton:SetAlpha(Engine.InFrontend() and 1 or 0, 0) end
    end
    local bind = LUI.UIBindButton.new()
    self:addElement(bind)
    bind:registerEventHandler("button_secondary", function() LUI.FlowManager.RequestLeaveMenu(self) end)
    bind:registerEventHandler("button_alt1", switchPage)
    bind:registerEventHandler("button_alt2", toggleHUD)
    bind:registerEventHandler("button_shoulderl", function() changeMap(-1) end)
    bind:registerEventHandler("button_shoulderr", function() changeMap(1) end)
    self:registerEventHandler("br_menu_tick", refresh)
    self:addElement(LUI.UITimer.new(nil, {interval = 500, event = "br_menu_tick"}))
    refresh()
    return self
end)

local function wrapButtons(build, isPause)
    return function(menu, controller)
        local self = build(menu, controller)
        if not Engine.IsAliensMode() or self.BeastRunnerButton then return self end
        local controllerIndex = controller and controller.controllerIndex or 0
        -- Barracks uses GenericButton (500px), including its native text/focus
        -- colors. MenuButton has a narrower Zombies-specific skin.
        local button = MenuBuilder.BuildRegisteredType(isPause and "MenuButton" or "GenericButton", {controllerIndex = controllerIndex})
        button.id = "BeastRunnerButton"
        button.Text:setText("SPEEDRUN STATS", 0)
        button.buttonDescription = "Review Zombies run history, splits and personal bests for all five maps."
        button:SetAnchorsAndPosition(0, 1, 0, 1, 0, (isPause and 340 or 500) * scale, 120 * scale, 150 * scale)
        button:registerEventHandler("button_action", function(_, event)
            ACTIONS.OpenMenu("BeastRunnerStats", true, event.controller or controllerIndex)
        end)
        if isPause then
            self:SetBottom(157 * scale, 0)
            self:addElement(button)
        elseif self.ButtonDescription then
            button:addElementBefore(self.ButtonDescription)
        else
            self:addElement(button)
        end
        self.BeastRunnerButton = button
        return self
    end
end

local wrappers = {
    CPPauseMenuButtons = function(build) return wrapButtons(build, true) end,
    HeadquartersCustomizationButtons = function(build) return wrapButtons(build, false) end
}
for name, wrap in pairs(wrappers) do
    if MenuBuilder.m_types[name] then MenuBuilder.m_types[name] = wrap(MenuBuilder.m_types[name]) end
end
local registerType = MenuBuilder.registerType
MenuBuilder.registerType = function(name, build)
    if wrappers[name] then build = wrappers[name](build) end
    return registerType(name, build)
end

-- Aurora's MainMenu script assigns m_types directly after this script loads.
-- Wrap construction so that late assignment still receives the shortcut.
local buildRegisteredType = MenuBuilder.BuildRegisteredType
MenuBuilder.BuildRegisteredType = function(name, options, ...)
    local result = buildRegisteredType(name, options, ...)
    if name == "CPMainMenuButtons" and result and Engine.IsAliensMode() and not result.BeastRunnerButton then
        local controllerIndex = options and options.controllerIndex or 0
        local button = buildRegisteredType("MenuButton", {controllerIndex = controllerIndex})
        button.id = "BeastRunnerButton"
        button.Text:setText("SPEEDRUN STATS", 0)
        button.buttonDescription = "Review Zombies run history, splits and personal bests for all five maps."
        button:SetAnchorsAndPosition(0, 1, 0, 1, 0, 340 * scale, 350 * scale, 380 * scale)
        button:registerEventHandler("button_action", function(_, event)
            ACTIONS.OpenMenu("BeastRunnerStats", true, event.controller or controllerIndex)
        end)
        if result.ButtonDescription then
            result.ButtonDescription:SetAnchorsAndPosition(0, 0, 0, 1, 0, 0, 400 * scale, 458 * scale)
            button:addElementBefore(result.ButtonDescription)
        else
            result:addElement(button)
        end
        result:SetBottom(464 * scale, 0)
        result.BeastRunnerButton = button
    end
    return result
end

if not Engine.InFrontend() and Engine.IsAliensMode() then
    local function attachToActiveHUD(manager)
        local map = Engine.GetDvarString("ui_mapname")
        if not map or map == "" then map = Engine.GetDvarString("mapname") end
        if Core.profile(map) and manager and manager.activeHud then
            makeHUD(manager.activeHud)
            print("[BeastRunner] Overlay attached for " .. map .. ".")
        end
    end
    if LUI.HudManager and LUI.HudManager.CreateHud then
        local original = LUI.HudManager.CreateHud
        LUI.HudManager.CreateHud = function(self, ...)
            local result = original(self, ...)
            attachToActiveHUD(self)
            return result
        end
        -- iw7-mod may load custom scripts after the stock HUD was constructed.
        local root = Engine.GetLuiRoot and Engine.GetLuiRoot()
        if root and root.hudManager then attachToActiveHUD(root.hudManager) end
    else
        print("[BeastRunner] HUD manager unavailable; timer events still record.")
    end
end
