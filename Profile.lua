-- Profile export/import: settings as one line of text, parsed by hand (never executed).
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI

HHT:AddGerman({
    ["Export / import settings"] = "Einstellungen exportieren / importieren",
    ["Export"] = "Exportieren",
    ["Import"] = "Importieren",
    ["Close"] = "Schliessen",
    ["Export copies all settings into the box. Press Ctrl+C, then paste it on another character. Import reads the text in the box."] = "Exportieren schreibt alle Einstellungen ins Feld. Mit Strg+C kopieren und auf einem anderen Charakter einfuegen. Importieren liest den Text im Feld.",
    ["Known ranks, seen and tamed beasts, the wishlist and stable pets belong to the character and are not exported."] = "Bekannte Raenge, gesehene und gezaehmte Tiere, Wunschliste und Stall-Begleiter gehoeren zum Charakter und werden nicht exportiert.",
    ["Settings exported. Press Ctrl+C to copy."] = "Einstellungen exportiert. Mit Strg+C kopieren.",
    ["Settings imported (%d values)."] = "Einstellungen importiert (%d Werte).",
    ["This text is not a valid settings export."] = "Dieser Text ist kein gueltiger Einstellungs-Export.",
})

local PR = {}
HHT.Profile = PR

local PREFIX = "HHT1:"
local MAX_LEN, MAX_DEPTH = 400000, 8

-- Data that belongs to one character and is never exported or imported.
local PERSONAL = {
    petdex = { known = true, pets = true, seen = true, tamed = true, wish = true, stable = true, speed = true },
}

local function Encode(s)
    return (s:gsub("[^%w_ %-%.]", function(c) return string.format("%%%02X", c:byte()) end))
end

local function Decode(s)
    return (s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

local function Scalar(v, out)
    local t = type(v)
    if t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return false end
        out[#out + 1] = "n" .. string.format("%.14g", v) .. ";"
    elseif t == "string" then
        out[#out + 1] = "s" .. Encode(v) .. ";"
    elseif t == "boolean" then
        out[#out + 1] = v and "T" or "F"
    else
        return false
    end
    return true
end

local function Write(v, out, skip, depth)
    if type(v) ~= "table" then return Scalar(v, out) end
    if depth > MAX_DEPTH then return false end
    out[#out + 1] = "{"
    for k, val in pairs(v) do
        if not (skip and skip[k]) and (type(k) == "string" or type(k) == "number") then
            local mark = #out
            local keyOut, valOut = {}, {}
            if Scalar(k, keyOut) and Write(val, valOut, nil, depth + 1) then
                out[#out + 1] = table.concat(keyOut)
                out[#out + 1] = table.concat(valOut)
            else
                for i = #out, mark + 1, -1 do out[i] = nil end
            end
        end
    end
    out[#out + 1] = "}"
    return true
end

function PR.Export()
    local db = HHT.db
    local general, mods = {}, { "{" }
    Write(db.general, general, nil, 1)
    for key, m in pairs(db.mods) do
        local p = {}
        if Write(m, p, PERSONAL[key], 1) then
            mods[#mods + 1] = "s" .. Encode(key) .. ";" .. table.concat(p)
        end
    end
    mods[#mods + 1] = "}"
    return PREFIX .. "{sgeneral;" .. table.concat(general) .. "smods;" .. table.concat(mods) .. "}"
end

-- Reads one value starting at pos; returns value, nextPos or nil on a syntax error.
local function Read(s, pos, depth)
    local c = s:sub(pos, pos)
    if c == "T" then return true, pos + 1 end
    if c == "F" then return false, pos + 1 end
    if c == "n" then
        local num, e = s:match("^n([%d%.eE%+%-]+);()", pos)
        num = tonumber(num)
        if not num then return nil end
        return num, e
    end
    if c == "s" then
        local enc, e = s:match("^s([%w_ %-%.%%]*);()", pos)
        if not enc then return nil end
        return Decode(enc), e
    end
    if c == "{" then
        if depth > MAX_DEPTH then return nil end
        local t = {}
        pos = pos + 1
        while s:sub(pos, pos) ~= "}" do
            if pos > #s then return nil end
            local k, p2 = Read(s, pos, depth + 1)
            if k == nil or (type(k) ~= "string" and type(k) ~= "number") then return nil end
            local v, p3 = Read(s, p2, depth + 1)
            if v == nil then return nil end
            t[k] = v
            pos = p3
        end
        return t, pos + 1
    end
    return nil
end

function PR.Parse(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if #text > MAX_LEN or text:sub(1, #PREFIX) ~= PREFIX then return nil end
    local v, pos = Read(text, #PREFIX + 1, 1)
    if type(v) ~= "table" or pos ~= #text + 1 then return nil end
    if type(v.general) ~= "table" or type(v.mods) ~= "table" then return nil end
    return v
end

-- Copies src into dst for keys dst already has with the same type; returns how many values changed.
local function Apply(dst, src, skip)
    local n = 0
    for k, v in pairs(src) do
        if not (skip and skip[k]) then
            local cur = dst[k]
            if type(cur) == "table" and type(v) == "table" and cur[1] == nil and v[1] == nil then
                n = n + Apply(cur, v)
            elseif cur ~= nil and type(cur) == type(v) then
                dst[k] = HHT.DeepCopy(v)
                n = n + 1
            end
        end
    end
    return n
end

function PR.Import(text)
    local data = PR.Parse(text)
    if not data then return nil end
    local db, n = HHT.db, 0
    n = n + Apply(db.general, data.general)
    for key, m in pairs(HHT.modules) do
        local src = data.mods[key]
        if type(src) == "table" then
            n = n + Apply(m.db, src, PERSONAL[key])
            if type(src.pos) == "table" then
                local pos = {}
                for name, p in pairs(src.pos) do
                    if type(name) == "string" and type(p) == "table" and type(p[1]) == "string" and type(p[2]) == "string"
                        and type(p[3]) == "number" and type(p[4]) == "number" then
                        pos[name] = { p[1], p[2], p[3], p[4] }
                        n = n + 1
                    end
                end
                m.db.pos = next(pos) and pos or m.db.pos
            end
        end
    end
    HHT:EachModule(function(m) HHT:SetEnabled(m, m.db.enabled) end)
    HHT:ApplyAllPositions()
    HHT:ApplyLock()
    if HHT.Config and HHT.Config.Relang then HHT.Config:Relang() end
    return n
end

local win

local function Build()
    win = UI.Window("HamingwaysHunterToolsProfile", 620, 190, L("Export / import settings"))
    win:SetPoint("CENTER")
    win:SetFrameStrata("FULLSCREEN_DIALOG")
    win:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, "HamingwaysHunterToolsProfile") end
    local note = UI.Text(win, L("Export copies all settings into the box. Press Ctrl+C, then paste it on another character. Import reads the text in the box."), 11, 0.8, 0.8, 0.8)
    note:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -42)
    note:SetWidth(590)
    note:SetJustifyH("LEFT")
    local note2 = UI.Text(win, L("Known ranks, seen and tamed beasts, the wishlist and stable pets belong to the character and are not exported."), 11, 0.6, 0.6, 0.6)
    note2:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -6)
    note2:SetWidth(590)
    note2:SetJustifyH("LEFT")
    win.box = UI.EditBox(win, 590, nil)
    win.box:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -108)
    win.status = UI.Text(win, "", 12, 0.67, 0.83, 0.45)
    win.status:SetPoint("TOPLEFT", win.box, "BOTTOMLEFT", 0, -8)
    local export = UI.Button(win, 110, 22, L("Export"), function()
        win.box:SetText(PR.Export())
        win.box:SetFocus()
        win.box:HighlightText()
        win.status:SetText(L("Settings exported. Press Ctrl+C to copy."))
        win.status:SetTextColor(0.67, 0.83, 0.45)
    end)
    export:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 14, 12)
    local import = UI.Button(win, 110, 22, L("Import"), function()
        local n = PR.Import(win.box:GetText())
        if n then
            win.status:SetText(string.format(L("Settings imported (%d values)."), n))
            win.status:SetTextColor(0.67, 0.83, 0.45)
        else
            win.status:SetText(L("This text is not a valid settings export."))
            win.status:SetTextColor(0.95, 0.4, 0.35)
        end
    end)
    import:SetPoint("LEFT", export, "RIGHT", 8, 0)
    local close = UI.Button(win, 110, 22, L("Close"), function() win:Hide() end)
    close:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -14, 12)
end

function PR.Open()
    if not win then Build() end
    win.status:SetText("")
    win:Show()
end
