-- Pure timing / history logic. Shared by the game menu and validation harness.
local M = {}
M.maps = require("maps")
-- Retain this alias for existing Beast integrations and old log tests.
M.splits = M.maps.cp_final.splits

function M.profile(map)
    return M.maps[map or "cp_final"]
end

function M.splitsFor(map)
    local profile = M.profile(map)
    return profile and profile.splits or {}
end

-- Preferences contain text only; never execute a config string as Lua.
M.labelLimit = 28
function M.cleanLabel(value)
    value = tostring(value or ""):gsub("[%z\1-\31\127]", " "):gsub("%^", "")
    value = value:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    -- Count UTF-8 glyph sequences so a limit never cuts a multibyte name in half.
    local out, count = {}, 0
    for glyph in value:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > M.labelLimit then break end
        out[#out + 1] = glyph
    end
    return table.concat(out):gsub("%s+$", "")
end

function M.preferenceKey(map, def)
    return "br_pref_" .. map .. "_" .. def[3]
end

function M.encodePreference(enabled, label)
    label = M.cleanLabel(label)
    local encoded = label:gsub(".", function(byte) return string.format("%02x", byte:byte()) end)
    return "v1:" .. (enabled and "1" or "0") .. ":" .. encoded
end

function M.decodePreference(raw, def)
    local enabled, hex = tostring(raw or ""):match("^v1:([01]):([0-9a-f]*)$")
    if not enabled or #hex % 2 ~= 0 or #hex > M.labelLimit * 8 then
        return {enabled = true, label = def[2], custom = ""}
    end
    local label = M.cleanLabel((hex:gsub("..", function(byte) return string.char(tonumber(byte, 16)) end)))
    return {enabled = enabled == "1", label = label ~= "" and label or def[2], custom = label}
end

function M.fields(s)
    local out = {}
    for v in (s .. "|"):gmatch("(.-)|") do out[#out + 1] = v end
    return out
end

function M.time(ms)
    if not ms or ms < 0 then return "--:--.-" end
    ms = math.floor(ms)
    return string.format("%02d:%02d.%d", math.floor(ms / 60000), math.floor(ms / 1000) % 60, math.floor(ms / 100) % 10)
end

function M.delta(ms)
    if not ms then return "" end
    return (ms <= 0 and "-" or "+") .. M.time(math.abs(ms))
end

function M.snapshot(s)
    local f = M.fields(s or "")
    return {state = f[1] or "armed", elapsed = tonumber(f[2]) or 0,
        round = tonumber(f[3]) or 0, kills = tonumber(f[4]) or 0,
        downs = tonumber(f[5]) or 0, revives = tonumber(f[6]) or 0,
        headshots = tonumber(f[7]) or 0, players = tonumber(f[8]) or 1,
        dc = tonumber(f[9]) or 0, map = f[10] ~= "" and f[10] or "cp_final"}
end

function M.category(run)
    return tostring(run.players or 1) .. "P / " .. ((run.dc or 0) == 1 and "Director's Cut" or "Standard")
end

function M.history(text)
    local runs, current = {}, nil
    for line in (text or ""):gmatch("([^\n]*)\n") do
        if line:find("ShutdownGame:", 1, true) and current and current.status == "running" then
            current.status = "interrupted"
        end
        local payload = line:match("BR2|([^\r]+)")
        local version2 = payload ~= nil
        if not payload then payload = line:match("BR1|([^\r]+)") end
        if payload then
            local f = M.fields(payload)
            local map = "cp_final"
            if version2 then map = table.remove(f, 1) end
            local kind, name, stamp = f[1], f[2], tonumber(f[3])
            if M.profile(map) and #f == 11 and stamp and stamp >= 0 then
                if kind == "START" then
                    if current and current.status == "running" then current.status = "interrupted" end
                    current = {status = "running", elapsed = 0, splits = {}, order = {}, attempt = #runs + 1, map = map}
                    runs[#runs + 1] = current
                end
                if current and current.status == "running" and current.map == map then
                    current.elapsed = math.max(current.elapsed, stamp)
                    current.round = tonumber(f[4]) or 0
                    current.kills = tonumber(f[5]) or 0
                    current.downs = tonumber(f[6]) or 0
                    current.revives = tonumber(f[7]) or 0
                    current.headshots = tonumber(f[8]) or 0
                    current.players = tonumber(f[9]) or 1
                    current.dc = tonumber(f[10]) or 0
                    if kind == "SPLIT" or kind == "FINISH" then
                        if not current.splits[name] then
                            current.splits[name] = stamp
                            current.order[#current.order + 1] = name
                        end
                    end
                    if kind == "FINISH" then
                        current.status = "finished"
                        current.valid = tonumber(f[11]) == 1
                    elseif kind == "ABORT" then
                        current.status = "aborted"
                    end
                end
            end
        end
    end
    return runs
end

function M.summary(runs, category, map)
    map = map or "cp_final"
    local s = {attempts = 0, finishes = 0, kills = 0, downs = 0, revives = 0,
        best = nil, average = nil, bestSplits = {}, segments = {}}
    local total = 0
    for _, run in ipairs(runs) do
        if (run.map or "cp_final") == map and (not category or M.category(run) == category) then
            s.attempts = s.attempts + 1
            s.kills = s.kills + (run.kills or 0)
            s.downs = s.downs + (run.downs or 0)
            s.revives = s.revives + (run.revives or 0)
            if run.status == "finished" and run.valid then
                s.finishes = s.finishes + 1
                total = total + run.elapsed
                if not s.best or run.elapsed < s.best.elapsed then s.best = run end
            end
            -- Only complete valid runs contribute to comparison / golds.
            if run.status == "finished" and run.valid then
                for name, value in pairs(run.splits) do
                    if not s.bestSplits[name] or value < s.bestSplits[name] then s.bestSplits[name] = value end
                end
                -- A segment is compared only against the same preceding event.
                local previous, last = "first_spawn", 0
                for _, name in ipairs(run.order) do
                    local value = run.splits[name]
                    local key = previous .. ">" .. name
                    if value >= last then
                        local segment = value - last
                        if not s.segments[key] or segment < s.segments[key] then s.segments[key] = segment end
                    end
                    previous, last = name, value
                end
            end
        end
    end
    if s.finishes > 0 then s.average = math.floor(total / s.finishes) end
    return s
end
return M
