local Core = require("core")
local function line(map, kind, name, ms, valid, dc, players)
    return "0:00 BR2|" .. map .. "|" .. kind .. "|" .. name .. "|" .. ms .. "|5|10|0|0|3|" .. (players or 1) .. "|" .. (dc or 0) .. "|" .. (valid or 0) .. "\n"
end
local text = "0:00 BR1|START|first_spawn|0|1|0|0|0|0|1|0|0\n"
    .. "0:01 BR1|FINISH|boss_defeated|90000|1|0|0|0|0|1|0|1\n"
local expected = {}
for index, map in ipairs(Core.maps.order) do
    local time = index * 1000
    expected[map] = time
    text = text .. line(map, "START", "first_spawn", 0)
        .. line(map, "SPLIT", Core.splitsFor(map)[1][1], 50)
        .. line(map, "FINISH", "boss_defeated", time, 1)
        .. line(map, "START", "first_spawn", 0, 0, 1)
        .. line(map, "FINISH", "boss_defeated", 100, 1, 1)
        .. line(map, "START", "first_spawn", 0)
        .. line(map, "FINISH", "boss_defeated", 10, 0)
end
local runs = Core.history(text)
assert(#runs == 16 and runs[1].map == "cp_final")
for _, map in ipairs(Core.maps.order) do
    local s = Core.summary(runs, "1P / Standard", map)
    assert(s.best.map == map and s.best.elapsed == expected[map])
    assert(s.finishes == (map == "cp_final" and 2 or 1))
    assert(Core.summary(runs, "1P / Director's Cut", map).best.elapsed == 100)
    assert(Core.snapshot("running|50|1|2|0|0|1|1|0|" .. map).map == map)
    assert(#Core.splitsFor(map) <= 15)
end
local crossed = Core.history(line("cp_zmb", "START", "first_spawn", 0)
    .. line("cp_rave", "FINISH", "boss_defeated", 10, 1)
    .. line("cp_zmb", "STAT", "team", 500))
assert(crossed[1].status == "running" and crossed[1].elapsed == 500)
assert(Core.profile("cp_frontend") == nil)
assert(#Core.splitsFor("cp_frontend") == 0)
assert(Core.snapshot("running|0|0|0|0|0|0|1|0").map == "cp_final")
local unknown = Core.history(line("cp_frontend", "START", "first_spawn", 0))
assert(#unknown == 0)
print("PASS: five-map PB isolation, legacy BR1 migration, mixed-version history, DC separation, invalid finishes, cross-map record rejection")
