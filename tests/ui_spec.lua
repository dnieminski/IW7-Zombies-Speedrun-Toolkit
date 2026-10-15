-- API-shaped smoke harness, not a replacement for testing the game's HKS/LUI.
local values = {br_snapshot = "running|145000|1|10|0|0|2|1|0", br_enabled = "1", mapname = "cp_final",
    br_split_2 = "130700", br_split_3 = "145000", br_split_0 = "145000"}
local made = {}
local methods = {}
function methods:addElement(child) self.children[#self.children + 1] = child end
function methods:registerEventHandler(name, fn) self.handlers[name] = fn end
function methods:setText(value) self.value = value end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetAnchorsAndPosition(...) self.bounds = {...} end
for _, name in ipairs({"SetFont", "SetFontSize", "SetAlignment", "SetRGBFromTable", "setImage", "SetBottom", "addElementBefore"}) do
    methods[name] = function() end
end
local function new()
    local e = setmetatable({children = {}, handlers = {}}, {__index = methods})
    made[#made + 1] = e
    return e
end
_1080p = 1
FONTS = {MainMedium = {File = "font"}, GetFont = function(s) return s end}
RegisterMaterial = function(s) return s end
local frontend = false
Engine = {GetDvarString = function(k) return values[k] or "" end,
    SetDvarString = function(k, v) values[k] = v end,
    InFrontend = function() return frontend end, IsAliensMode = function() return true end}
LUI = {UIText = {new = new}, UIImage = {new = new}, UIElement = {new = new}, UIBindButton = {new = new},
    UIButton = {new = function() local e = new(); e.isButton = true; return e end},
    UITimer = {new = new}, Alignment = {Left = 0},
    HudManager = {CreateHud = function(manager) manager.activeHud = new() end},
    FlowManager = {RequestLeaveMenu = function() end}}
MenuBuilder = {m_types = {CPPauseMenuButtons = new, HeadquartersCustomizationButtons = new}}
function MenuBuilder.registerType(name, fn) MenuBuilder.m_types[name] = fn end
function MenuBuilder.BuildRegisteredType(name, args)
    if name == "MenuButton" or name == "GenericButton" then local e = new(); e.Text = new(); e.widgetType = name; return e end
    return MenuBuilder.m_types[name](nil, args)
end
ACTIONS = {OpenMenu = function() end}
io.fileexists = function() return false end
local existingManager = {activeHud = new()}
Engine.GetLuiRoot = function() return {hudManager = existingManager} end
require("__init__")
assert(existingManager.activeHud.BeastRunner)
local manager = {}
LUI.HudManager.CreateHud(manager)
local hud = manager.activeHud
assert(hud.BeastRunner)
hud.BeastRunner.handlers.br_hud_tick()
assert(hud.BeastRunner.alpha == 1)
local hudById = {}
for _, child in ipairs(hud.BeastRunner.children) do if child.id then hudById[child.id] = child end end
assert(hudById.Status.value == "RUNNING / GAME TIME / 1P / STANDARD")
values.br_snapshot = "running|145050|1|10|0|0|2|1|1"
hud.BeastRunner.handlers.br_hud_tick()
assert(hudById.Status.value == "RUNNING / GAME TIME / 1P / DC")
assert(hudById.Timer.value == "02:25.0")
values.br_hud = "0"
hud.BeastRunner.handlers.br_hud_tick()
assert(hud.BeastRunner.alpha == 0 and values.br_snapshot:find("running", 1, true))
values.br_hud = "1"
hud.BeastRunner.handlers.br_hud_tick()
assert(hud.BeastRunner.alpha == 1)
values.mapname = "cp_frontend"
local otherManager = {}
LUI.HudManager.CreateHud(otherManager)
assert(not otherManager.activeHud.BeastRunner)
values.mapname = "cp_final"
local stats = MenuBuilder.m_types.BeastRunnerStats(nil, {controllerIndex = 0})
stats.handlers.br_menu_tick()
local byId = {}
for _, child in ipairs(stats.children) do if child.id then byId[child.id] = child end end
assert(byId.Left2.value == "N31L head collected")
assert(byId.Current2.value == "02:10.7")
assert(byId.Left3.value == "N31L head installed")
assert(byId.Current3.value == "02:25.0")
assert(byId.Left4.value == "Pack-a-Punch bridge")
assert(byId.Current4.value == "--:--.-")
local bind
for _, child in ipairs(stats.children) do if child.handlers.button_alt1 then bind = child end end
assert(bind)
bind.handlers.button_alt1()
assert(byId.Current2.value == "" and byId.PB2.value == "" and byId.Delta2.value == "")
bind.handlers.button_alt2()
assert(values.br_hud == "0")
byId.ReloadHistory.handlers.button_action()
assert(MenuBuilder.m_types.CPPauseMenuButtons(nil, {controllerIndex = 0}).BeastRunnerButton)
local barracksButton = MenuBuilder.m_types.HeadquartersCustomizationButtons(nil, {controllerIndex = 0}).BeastRunnerButton
assert(barracksButton.widgetType == "GenericButton", "Barracks shortcut must inherit native GenericButton text and focus styling")
assert(barracksButton.bounds[6] - barracksButton.bounds[5] == 500, "Barracks shortcut must match the neighboring 500px buttons")
assert(barracksButton.Text.value == "SPEEDRUN STATS")
-- MainMenu assigns its builder after our script; construction must still wrap it.
MenuBuilder.m_types.CPMainMenuButtons = new
assert(MenuBuilder.BuildRegisteredType("CPMainMenuButtons", {controllerIndex = 0}).BeastRunnerButton)
-- A fresh launch must use disk history, not stale in-match dvars.
frontend = true
io.fileexists = function() return true end
io.readfile = function() return "0:00 BR1|START|first_spawn|0|1|0|0|0|0|1|1|0\n"
    .. "0:10 BR1|SPLIT|neil_head_found|10000|2|99|1|0|20|1|1|0\n"
    .. "0:11 ShutdownGame:\n" end
local savedMenu = MenuBuilder.m_types.BeastRunnerStats(nil, {controllerIndex = 0})
local savedById = {}
for _, child in ipairs(savedMenu.children) do if child.id then savedById[child.id] = child end end
assert(savedById.Current2.value == "00:10.0")
assert(savedById.Right3.value == "Kills: 99")
assert(savedById.Header.value:find("INTERRUPTED", 1, true))
-- Map selection in the frontend uses its own history and profile.
savedById.NextMap.handlers.button_action()
assert(savedById.Subtitle.value:find("ZOMBIES IN SPACELAND", 1, true))
assert(savedById.Left2.value == "Pack-a-Punch visited")
assert(savedById.Current2.value == "--:--.-")
savedById.PreviousMap.handlers.button_action()
assert(savedById.Current2.value == "00:10.0")
frontend = false
values.br_hud = "1"
for _, map in ipairs(require("core").maps.order) do
    values.mapname = map
    values.br_snapshot = "running|1000|1|10|0|0|2|1|0|" .. map
    local mapManager = {}
    LUI.HudManager.CreateHud(mapManager)
    assert(mapManager.activeHud.BeastRunner)
    local title
    for _, child in ipairs(mapManager.activeHud.BeastRunner.children) do if child.id == "Title" then title = child.value end end
    assert(title == require("core").profile(map).short .. " / SPEEDRUN TOOLKIT")
    local mapMenu = MenuBuilder.m_types.BeastRunnerStats(nil, {controllerIndex = 0})
    mapMenu.handlers.br_menu_tick()
end
print("PASS: existing/future Beast HUD attachment, other-map exclusion, hide/show without stopping timer, split IDs, fixed columns, menu controls, saved history")

-- User-facing customization edits presentation, never recorded split identity.
local Core = require("core")
local writes = {}
Engine.ExecNow = function(command)
    local key, value = command:match('^seta ([%w_]+) "(v1:[01]:[0-9a-f]*)"$')
    assert(key and value, "Unsafe settings command: " .. command)
    values[key] = value
    writes[#writes + 1] = command
end
local keyboardCallback, keyboardInitial
OSK = {OpenScreenKeyboard = function(controller, title, initial, limit, verify, filter, empty, callback)
    assert(limit == 28 and empty)
    keyboardInitial, keyboardCallback = initial, callback
end}
local function childrenById(element)
    local result = {}
    for _, child in ipairs(element.children) do if child.id then result[child.id] = child end end
    return result
end
values.mapname = "cp_final"
values.br_snapshot = "running|145000|1|10|0|0|2|1|0|cp_final"
local customStats = MenuBuilder.m_types.BeastRunnerStats(nil, {controllerIndex = 0})
local customStatsById = childrenById(customStats)
customStatsById.EditSplits.handlers.button_action()
local settings = MenuBuilder.m_types.BeastRunnerSplitSettings(nil, {controllerIndex = 0})
local settingsById = childrenById(settings)
assert(settingsById.Track1.Text.value == "[X] N31L head collected")
settingsById.Rename1.handlers.button_action()
assert(keyboardInitial == "N31L head collected")
keyboardCallback(0, 'Head "pickup"; quit')
assert(settingsById.Track1.Text.value == '[X] Head "pickup"; quit')
assert(settingsById.DefaultName1.value == "N31L head collected")
customStats.handlers.br_menu_tick()
assert(customStatsById.Left2.value == 'Head "pickup"; quit')
assert(customStatsById.Current2.value == "02:10.7")
local customManager = {}
LUI.HudManager.CreateHud(customManager)
local customHUD = childrenById(customManager.activeHud.BeastRunner)
assert(customHUD.Split1.value:find('Head "pickup"; quit', 1, true))
settingsById.Track1.handlers.button_action()
assert(settingsById.Track1.Text.value == '[ ] Head "pickup"; quit')
customStats.handlers.br_menu_tick()
customManager.activeHud.BeastRunner.handlers.br_hud_tick()
assert(customStatsById.Left2.value == "N31L head installed")
assert(not customHUD.Split1.value:find("pickup", 1, true))
assert(values.br_split_2 == "130700" and values.br_snapshot:find("running", 1, true))
settingsById.Rename1.handlers.button_action()
keyboardCallback(0, nil) -- Cancel keeps name and OFF state.
assert(settingsById.Track1.Text.value == '[ ] Head "pickup"; quit')
settingsById.Default1.handlers.button_action()
assert(settingsById.Track1.Text.value == "[ ] N31L head collected")
settingsById.Track1.handlers.button_action()
assert(settingsById.Track1.Text.value == "[X] N31L head collected")
-- A callback captures its original map even if the settings page changes map.
frontend = true
settingsById.Rename1.handlers.button_action()
settingsById.NextMap.handlers.button_action()
assert(settingsById.Subtitle.value == "ZOMBIES IN SPACELAND")
keyboardCallback(0, "Neil")
assert(settingsById.Track1.Text.value == "[X] Pack-a-Punch visited")
settingsById.PreviousMap.handlers.button_action()
assert(settingsById.Track1.Text.value == "[X] Neil")
-- A new UI load restores preferences from archived values, not old Lua state.
package.loaded.__init__ = nil
require("__init__")
local restored = MenuBuilder.m_types.BeastRunnerSplitSettings(nil, {controllerIndex = 0})
local restoredById = childrenById(restored)
assert(restoredById.Track1.Text.value == "[X] Neil")
restoredById.ResetMap.handlers.button_action()
assert(restoredById.Track1.Text.value == "[X] N31L head collected")
assert(#writes >= 18)
Engine.ExecNow = function() error("save unavailable") end
restoredById.Track1.handlers.button_action()
assert(restoredById.Track1.Text.value == "[X] N31L head collected")
assert(restoredById.Notice.value:find("Could not save", 1, true))
print("PASS: rename, cancel, default/reset, split visibility, unchanged recording, map isolation, UI reload and save failures")

-- Stock Zombies MenuButton artwork ignores requested width. Toolkit controls
-- must own their visuals, with every child contained inside the hit rectangle.
local function checkButtonGeometry(parent)
    local buttons = {}
    for _, element in ipairs(parent.children) do
        if element.isButton then
            local b = element.bounds
            local width, height = b[6] - b[5], b[8] - b[7]
            assert(width > 0 and math.abs(height - 32 * _1080p) < 0.001)
            for _, child in ipairs(element.children) do
                local c = child.bounds
                assert(c and c[5] >= 0 and c[7] >= 0 and c[6] <= width + 0.001 and c[8] <= height + 0.001, element.id .. " artwork overflows")
            end
            element.handlers.button_over(); element.handlers.button_up()
            assert(element.bounds == b, "Focus must not change geometry")
            for _, other in ipairs(buttons) do
                local a = other.bounds
                assert(b[6] <= a[5] or a[6] <= b[5] or b[8] <= a[7] or a[8] <= b[7], element.id .. " overlaps " .. other.id)
            end
            buttons[#buttons + 1] = element
        end
    end
    return #buttons
end
for _, resolutionScale in ipairs({2 / 3, 1, 4 / 3}) do
    _1080p = resolutionScale
    package.loaded.__init__ = nil
    require("__init__")
    local layoutStats = MenuBuilder.m_types.BeastRunnerStats(nil, {controllerIndex = 0})
    local layoutSettings = MenuBuilder.m_types.BeastRunnerSplitSettings(nil, {controllerIndex = 0})
    assert(checkButtonGeometry(layoutStats) == 6)
    assert(checkButtonGeometry(layoutSettings) == 49)
    local ids = childrenById(layoutSettings)
    for index = 1, 15 do
        assert(ids["Default" .. index].bounds[6] < ids["DefaultName" .. index].bounds[5])
        assert(ids["Rename" .. index].bounds[6] < ids["Default" .. index].bounds[5])
    end
end
print("PASS: custom button artwork stays inside hit bounds; no control/label overlap at 720p, 1080p and 1440p scales")
