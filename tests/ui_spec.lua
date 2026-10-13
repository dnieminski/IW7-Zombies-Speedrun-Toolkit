-- API-shaped smoke harness, not a replacement for testing the game's HKS/LUI.
local values = {br_snapshot = "running|145000|1|10|0|0|2|1|0", br_enabled = "1", mapname = "cp_final",
    br_split_2 = "130700", br_split_3 = "145000", br_split_0 = "145000"}
local made = {}
local methods = {}
function methods:addElement(child) self.children[#self.children + 1] = child end
function methods:registerEventHandler(name, fn) self.handlers[name] = fn end
function methods:setText(value) self.value = value end
function methods:SetAlpha(value) self.alpha = value end
for _, name in ipairs({"SetFont", "SetFontSize", "SetAlignment", "SetAnchorsAndPosition", "SetRGBFromTable", "setImage", "SetBottom", "addElementBefore"}) do
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
    UITimer = {new = new}, Alignment = {Left = 0},
    HudManager = {CreateHud = function(manager) manager.activeHud = new() end},
    FlowManager = {RequestLeaveMenu = function() end}}
MenuBuilder = {m_types = {CPPauseMenuButtons = new, HeadquartersCustomizationButtons = new}}
function MenuBuilder.registerType(name, fn) MenuBuilder.m_types[name] = fn end
function MenuBuilder.BuildRegisteredType(name, args)
    if name == "MenuButton" then local e = new(); e.Text = new(); return e end
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
values.mapname = "cp_zmb"
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
bind.handlers.button_alt3()
assert(MenuBuilder.m_types.CPPauseMenuButtons(nil, {controllerIndex = 0}).BeastRunnerButton)
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
print("PASS: existing/future Beast HUD attachment, other-map exclusion, hide/show without stopping timer, split IDs, fixed columns, menu controls, saved history")
