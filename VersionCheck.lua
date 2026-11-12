-- New version notice. A client cannot reach CurseForge, so guild and group members
-- tell each other their version: ~20 s after login the addon asks ("Q" + own version),
-- players with a newer version answer once ("V" + their version).
local ADDON, HHT = ...

local PREFIX = "HHTVER"
local LOGIN_WINDOW = 180 -- seconds after login in which the note may appear

local function parse(v)
    if type(v) ~= "string" then return nil end
    local t = {}
    for n in v:gmatch("%d+") do t[#t + 1] = tonumber(n) end
    return #t > 0 and t or nil
end

local function newer(a, b)
    for i = 1, math.max(#a, #b) do
        local x, y = a[i] or 0, b[i] or 0
        if x ~= y then return x > y end
    end
    return false
end

local mine
local told, lastAnswer, answeredBy = {}, {}, {}
local loginTime

local function now() return GetTime() end
local function general() return HHT.db and HHT.db.general end
local function enabled() local g = general(); return g and g.versionNotice ~= false end

local function announce(v)
    if told[v] then return end
    told[v] = true
    HHT.Print("|cffffd100" .. string.format(HHT.L("A newer version (%s) is available on CurseForge. You are using %s."), v, HHT.version) .. "|r")
end

local function confirmed(v)
    if not enabled() then return end
    if loginTime and now() - loginTime <= LOGIN_WINDOW then
        announce(v)
    else
        -- too late in the session: show it at the next login
        local g = general()
        local old, t = parse(g.pendingNewVersion), parse(v)
        if not old or newer(t, old) then g.pendingNewVersion = v end
    end
end

local function onVersion(v)
    local t = parse(v)
    if t and mine and newer(t, mine) and not told[v] then confirmed(v) end
end

local function send(msg, dist)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, dist) end
end

local function ask()
    local q = "Q\t" .. HHT.version
    if IsInGuild() then send(q, "GUILD") end
    if IsInRaid() then send(q, "RAID") elseif IsInGroup() then send(q, "PARTY") end
end

-- Answer an older version once; skipped when someone else already answered meanwhile.
local function answer(dist)
    if lastAnswer[dist] and now() - lastAnswer[dist] < 60 then return end
    lastAnswer[dist] = now()
    local v = HHT.version
    C_Timer.After(1 + math.random() * 5, function()
        if answeredBy[v] and now() - answeredBy[v] < 30 then return end
        send("V\t" .. v, dist)
    end)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("CHAT_MSG_ADDON")
ev:SetScript("OnEvent", function(_, event, prefix, msg, channel)
    if event == "PLAYER_LOGIN" then
        if not HHT.db then return end
        mine = parse(HHT.version)
        loginTime = now()
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX) end
        C_Timer.After(8, function()
            local g = general()
            local p = g and g.pendingNewVersion
            if not p then return end
            g.pendingNewVersion = nil
            local t = parse(p)
            if t and mine and newer(t, mine) and enabled() then announce(p) end
        end)
        C_Timer.After(20, ask)
    elseif event == "CHAT_MSG_ADDON" and prefix == PREFIX and mine and type(msg) == "string" then
        if channel ~= "GUILD" and channel ~= "PARTY" and channel ~= "RAID" then return end
        local kind, v = msg:match("^(%a)\t(.+)$")
        if not kind then return end
        if kind == "V" then
            answeredBy[v] = now()
            onVersion(v)
        elseif kind == "Q" then
            onVersion(v) -- the asker may run a newer version too
            local t = parse(v)
            if t and newer(mine, t) then answer(channel) end
        end
    end
end)
