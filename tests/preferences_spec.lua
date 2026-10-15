local Core = require("core")
local def = Core.splitsFor("cp_final")[1]
assert(Core.decodePreference("", def).label == def[2])
assert(Core.decodePreference("v1:0:", def).enabled == false)
for _, raw in ipairs({"v1:0:a", "v1:2:00", "v1:0:xx", "v2:0:00", "v1:0:" .. string.rep("ff", 200)}) do
    local option = Core.decodePreference(raw, def)
    assert(option.enabled and option.label == def[2])
end
local label = 'My "head"; set quit 1'
local encoded = Core.encodePreference(false, label)
assert(encoded:match("^v1:0:[0-9a-f]+$"))
local option = Core.decodePreference(encoded, def)
assert(not option.enabled and option.label == label)
assert(Core.cleanLabel("  Alpha\nBeta^  ") == "Alpha Beta")
assert(Core.cleanLabel(string.rep("a", 40)) == string.rep("a", 28))
local unicode = string.rep("\195\169", 30)
assert(Core.cleanLabel(unicode) == string.rep("\195\169", 28))
assert(Core.decodePreference(Core.encodePreference(true, " \n "), def).label == def[2])
assert(Core.preferenceKey("cp_final", def) ~= Core.preferenceKey("cp_zmb", def))
print("PASS: default names, malformed preference recovery, UTF-8 limits and command-safe encoding")
