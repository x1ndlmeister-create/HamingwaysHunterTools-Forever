-- Bug report: runs the debug commands, collects their output and packs it into one compressed line the user can copy.
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI

HHT:AddGerman({
    ["Bug report"] = "Fehlerbericht",
    ["Create bug report"] = "Fehlerbericht erstellen",
    ["Something not working? Create a report and paste the line into your bug report. It holds settings and debug data, no character name."] = "Etwas funktioniert nicht? Erstelle einen Bericht und füge die Zeile in deine Fehlermeldung ein. Sie enthält Einstellungen und Debugdaten, keinen Charakternamen.",
    ["Press Ctrl+C to copy the line and paste it into your bug report."] = "Mit Strg+C die Zeile kopieren und in die Fehlermeldung einfügen.",
    ["Select all"] = "Alles markieren",
    ["Show as text"] = "Als Text anzeigen",
    ["Close"] = "Schließen",
    ["%d characters"] = "%d Zeichen",
})

local R = {}
HHT.Report = R

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local MAX_CODE = 4096

-- Phrases that the debug output repeats a lot. Encoder and decoder both start with them in the dictionary,
-- so changing this list means a new format tag. Keep every entry plain ASCII.
local PRIME = {
    " known=true", " known=false", " known=", " aura=false", " aura=", " id=nil", " id=", " name=", " key=nil", " key=",
    " bytes=-", " bytes=", " bind=-", " bind=", " mouse=true", " mouse=false", " mouse=", " vis=true", " vis=false", " vis=",
    " macro=/cast ", " macro=", " w=0", " w=40.00", " combat=false", " combat=", " owned=false", " owned=", " container=true",
    " container=", " group=true", " group=", " slots=", " invSlot=", " link=", " kind=nil", " kind=", " yes=", " err=0", " err=",
    "name=Aspect of the ", "Aspect of the ", "aurasSecret=false combat=false", "feeder: ", "warnings: ", "candidate: ",
    "upgrades: ", "pet slots now: ", "remembered (* = active slot): ", "scanned never this session s ago, pet unit exists: ",
    "## debug", "## pet", "## tame", "## cd", "## ammo debug", "## watch", "## debuffs", "## procs", "## totems", "## petmap",
    "## feedprobe", "modules: ", "addons: ", "easytame: stage=", "  Freezing Trap known=true id=14310 barKey=", "  Tame Beast known=true id=1515 barKey=",
    "cooldowns layout=bar locked=true unlocked=false tooltip=true showKeys=true", "@rapidFire", "@bestialWrath", "@intimidation",
    "@scatterShot", "@", "Mechanical Repair Kit", "Craftsman's Writ: ", "bag buttons", "ammo debug: shot=", "ammo slot (0): ",
    "  arrow stack: ", "  arrow upgrades: ", ", bag upgrades: ", "  bullet upgrades: ", "  bag slot ", ": id=nil  kind=nil", "  bag ", ": invSlot=",
    "procs: engine=true combat=false entries=", "proc ", ": ids=", " buttons=", "summons: no active summon in the totem slots (max 4)",
    "petmap: list=", " map=", " mapShown=", " canvas=true size=", " pins=", " shown=", " hooked=true",
    "HHT ", " | wow ", " | enUS | ", " | deDE | ", "Alliance", "Horde", "NightElf", "Human", "Dwarf", "Gnome", "Orc", "Troll", "Tauren", "Scourge", "HUNTER L",
    "accepted by the game: ", "CanItemID(id)", "CanItemID(link)", "CanItem(", "SpellIsTargeting=true", "SpellCanTargetItemID=true",
    "SpellCanTargetItem=true", "tooltip: opt=", " calls=", " added=", " processor=", " unit=", " npc=", " beast=", " abilities=",
    "feeder: pet=", " rawDiet=", " diets=", " foods=", " current=", "feeder: buff food = ", "feeder: unknown food = ", "happiness: C_PetInfo=",
}

R.PRIME = PRIME

local function NewDict()
    local dict, nxt = {}, 256
    for i = 0, 255 do dict[string.char(i)] = i end
    for _, p in ipairs(PRIME) do
        for len = 2, #p do
            local sub = p:sub(1, len)
            if not dict[sub] then
                dict[sub] = nxt
                nxt = nxt + 1
            end
        end
    end
    return dict, nxt
end

-- LZW with codes of 9 to 12 bits, packed little-endian into base64 (no padding). The decoder lags one entry behind
-- the encoder, so it has to widen the codes one entry earlier.
local function Compress(s)
    local dict, nxt = NewDict()
    local width = 9
    while nxt > 2 ^ width do width = width + 1 end
    local out, acc, bits = {}, 0, 0
    local function put(code)
        acc = acc + code * 2 ^ bits
        bits = bits + width
        while bits >= 6 do
            local v = acc % 64
            out[#out + 1] = B64:sub(v + 1, v + 1)
            acc = (acc - v) / 64
            bits = bits - 6
        end
    end
    local w = ""
    for i = 1, #s do
        local c = s:sub(i, i)
        local wc = w .. c
        if dict[wc] then
            w = wc
        else
            put(dict[w])
            if nxt < MAX_CODE then
                dict[wc] = nxt
                nxt = nxt + 1
                if nxt > 2 ^ width and width < 12 then width = width + 1 end
            end
            w = c
        end
    end
    if w ~= "" then put(dict[w]) end
    if bits > 0 then
        local v = acc % 64
        out[#out + 1] = B64:sub(v + 1, v + 1)
    end
    return table.concat(out)
end
R.Compress = Compress

local function Checksum(s)
    local a, b = 1, 0
    for i = 1, #s do
        a = (a + s:byte(i)) % 65521
        b = (b + a) % 65521
    end
    return string.format("%08x", b * 65536 + a)
end

-- Debug output can hold secret values, which cannot be touched; they are replaced instead of failing the report.
local function Strip(t)
    local ok, r = pcall(function()
        if HHT.IsSecret(t) then return "<secret>" end
        local s = tostring(t)
        if HHT.IsSecret(s) then return "<secret>" end
        s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[%w_]+:", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|H.-|h(.-)|h", "%1")
        s = s:gsub("^Hamingway's HunterTools: ", "")
        return (s:gsub("(%d+%.%d%d)%d+", "%1"))
    end)
    return ok and r or "<unreadable>"
end

local COMMANDS = { "debug", "pet", "tame", "cd", "ammo debug", "watch", "debuffs", "procs", "totems", "petmap", "stance" }

local function Capture(cmd, lines)
    local real = HHT.Print
    local buf = {}
    HHT.Print = function(m) buf[#buf + 1] = Strip(m) end
    R.capturing = true
    local ok, err = pcall(SlashCmdList["HAMINGWAYSHUNTERTOOLS"], cmd)
    R.capturing = false
    HHT.Print = real
    if not ok then buf[#buf + 1] = "error: " .. tostring(err) end
    if #buf == 0 then return end
    lines[#lines + 1] = "## " .. cmd
    for _, ln in ipairs(buf) do lines[#lines + 1] = ln end
end

local function AddonList()
    local api = C_AddOns or {}
    local num = (api.GetNumAddOns or GetNumAddOns)
    local info = (api.GetAddOnInfo or GetAddOnInfo)
    local loaded = (api.IsAddOnLoaded or IsAddOnLoaded)
    local names = {}
    if not (num and info and loaded) then return names end
    for i = 1, num() do
        local r = { info(i) }
        local name = type(r[1]) == "table" and r[1].name or r[1]
        if type(name) == "string" and name ~= ADDON and loaded(i) then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

function R.Build()
    local lines = {}
    local gv, gb = GetBuildInfo()
    local _, class = UnitClass("player")
    local _, race = UnitRace("player")
    local mods = {}
    for key, m in pairs(HHT.modules) do
        if m.enabled then mods[#mods + 1] = key end
    end
    table.sort(mods)
    lines[#lines + 1] = string.format("HHT %s | wow %s.%s | %s | %s %s L%s | %s", tostring(HHT.version), tostring(gv), tostring(gb),
        tostring(GetLocale()), tostring(race), tostring(class), tostring(UnitLevel("player")), tostring(UnitFactionGroup("player")))
    lines[#lines + 1] = "modules: " .. table.concat(mods, ",")
    lines[#lines + 1] = "addons: " .. table.concat(AddonList(), ",")
    for _, cmd in ipairs(COMMANDS) do Capture(cmd, lines) end
    local fm = HHT.modules.feeder
    if fm and fm.lastProbe then
        lines[#lines + 1] = "## feedprobe"
        lines[#lines + 1] = fm.lastProbe
    end
    local text = table.concat(lines, "\n")
    local me = UnitName("player")
    if type(me) == "string" and me ~= "" and not HHT.IsSecret(me) then
        text = text:gsub(me:gsub("%p", "%%%0"), "<me>")
    end
    return text
end

function R.Encode(text)
    local E = C_EncodingUtil
    if E and E.CompressString and E.EncodeBase64 and Enum and Enum.CompressionMethod and Enum.CompressionMethod.Deflate then
        local ok, packed = pcall(function()
            return E.EncodeBase64(E.CompressString(text, Enum.CompressionMethod.Deflate))
        end)
        if ok and type(packed) == "string" and packed ~= "" and not packed:find("%s") then
            return string.format("HHT3:%s:%d:%s", Checksum(text), #text, packed)
        end
    end
    return string.format("HHT2:%s:%d:%s", Checksum(text), #text, Compress(text))
end

local win

local function BuildWindow()
    win = UI.Window("HamingwaysHunterToolsReport", 620, 190, L("Bug report"))
    win:SetPoint("CENTER")
    win:SetFrameStrata("FULLSCREEN_DIALOG")
    win:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, "HamingwaysHunterToolsReport") end
    local note = UI.Text(win, L("Press Ctrl+C to copy the line and paste it into your bug report."), 11, 0.8, 0.8, 0.8)
    note:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -42)
    note:SetWidth(590)
    note:SetJustifyH("LEFT")
    win.box = UI.EditBox(win, 590, nil)
    win.box:SetMaxLetters(0)
    win.box:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -78)
    win.box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    win.box:SetScript("OnTextChanged", function(self, user)
        if user and win.code then self:SetText(win.code); self:HighlightText() end
    end)
    win.status = UI.Text(win, "", 12, 0.67, 0.83, 0.45)
    win.status:SetPoint("TOPLEFT", win.box, "BOTTOMLEFT", 0, -8)
    local sel = UI.Button(win, 110, 22, L("Select all"), function()
        win.box:SetFocus()
        win.box:HighlightText()
    end)
    sel:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 14, 12)
    local show = UI.Button(win, 130, 22, L("Show as text"), function()
        for ln in (win.text or ""):gmatch("[^\n]+") do print(ln) end
    end)
    show:SetPoint("LEFT", sel, "RIGHT", 8, 0)
    local close = UI.Button(win, 110, 22, L("Close"), function() win:Hide() end)
    close:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -14, 12)
end

function R.Open()
    if not win then BuildWindow() end
    win.text = R.Build()
    win.code = R.Encode(win.text)
    win.box:SetText(win.code)
    win.box:SetCursorPosition(0)
    win.status:SetText(string.format(L("%d characters"), #win.code))
    win:Show()
    win.box:SetFocus()
    win.box:HighlightText()
end
