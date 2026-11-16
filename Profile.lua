-- Profile export/import: settings as one line of text, parsed by hand (never executed).
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI

HHT:AddGerman({
    ["Export / import settings"] = "Einstellungen exportieren / importieren",
    ["Export"] = "Exportieren",
    ["Import"] = "Importieren",
    ["Close"] = "Schließen",
    ["Export copies all settings into the box. Press Ctrl+C, then paste it on another character. Import reads the text in the box."] = "Exportieren schreibt alle Einstellungen ins Feld. Mit Strg+C kopieren und auf einem anderen Charakter einfügen. Importieren liest den Text im Feld.",
    ["Known ranks, seen and tamed beasts, the wishlist and stable pets belong to the character and are not exported."] = "Bekannte Ränge, gesehene und gezähmte Tiere, Wunschliste und Stall-Begleiter gehören zum Charakter und werden nicht exportiert.",
    ["Settings exported. Press Ctrl+C to copy."] = "Einstellungen exportiert. Mit Strg+C kopieren.",
    ["Settings imported (%d values)."] = "Einstellungen importiert (%d Werte).",
    ["This text is not a valid settings export."] = "Dieser Text ist kein gültiger Einstellungs-Export.",
    ["Profiles, export and import"] = "Profile, Export und Import",
    ["Profiles"] = "Profile",
    ["Profile"] = "Profil",
    ["Other characters"] = "Andere Charaktere",
    ["No profiles yet. Save the current settings or import some text."] = "Noch keine Profile. Speichere die aktuellen Einstellungen oder importiere einen Text.",
    ["No other character has saved settings yet. Log in on it once with this version."] = "Noch kein anderer Charakter hat Einstellungen gespeichert. Logge dich dort einmal mit dieser Version ein.",
    ["Profiles are shared by all your characters. Load replaces the settings of this character. Export with nothing selected copies the current settings."] = "Profile gelten für alle deine Charaktere. Laden ersetzt die Einstellungen dieses Charakters. Exportieren ohne Auswahl kopiert die aktuellen Einstellungen.",
    ["Name"] = "Name",
    ["Load"] = "Laden",
    ["Overwrite"] = "Überschreiben",
    ["Rename"] = "Umbenennen",
    ["Copy"] = "Kopieren",
    ["Delete"] = "Löschen",
    ["Click again"] = "Nochmal klicken",
    ["Save current settings as new profile"] = "Aktuelle Einstellungen als Profil speichern",
    ["Import as new profile"] = "Als neues Profil importieren",
    ["Text for export and import"] = "Text für Export und Import",
    ["Imported profile"] = "Importiertes Profil",
    ["copy"] = "Kopie",
    ["Level %d"] = "Level %d",
    ["Profile saved: %s"] = "Profil gespeichert: %s",
    ["Profile loaded (%d values)."] = "Profil geladen (%d Werte).",
    ["Profile overwritten with the current settings."] = "Profil mit den aktuellen Einstellungen überschrieben.",
    ["Renamed."] = "Umbenannt.",
    ["Deleted."] = "Gelöscht.",
    ["Enter a name first."] = "Gib zuerst einen Namen ein.",
    ["A profile with this name already exists."] = "Ein Profil mit diesem Namen gibt es schon.",
    ["Imported as %s. Select it and press Load to use it."] = "Importiert als %s. Wähle es aus und drücke Laden.",
    ["Too many profiles. Delete one first."] = "Zu viele Profile. Lösche zuerst eines.",
    ["Paste the text to import into the box first."] = "Füge zuerst den Text zum Importieren ins Feld ein.",
})

local PR = {}
HHT.Profile = PR

local PREFIX = "HHT1:"
local MAX_LEN, MAX_DEPTH, MAX_PROFILES = 400000, 8, 40

-- Data that belongs to one character and is never exported or imported.
local PERSONAL = {
    petdex = { known = true, pets = true, seen = true, tamed = true, wish = true, stable = true, speed = true },
}
local PERSONAL_GENERAL = { setupDone = true, setupAsk = true, seenVersion = true, origin = true, fold = true }

-- ---------------------------------------------------------------------------
-- Account wide store: a copy of every configured character's settings and the named profiles
-- ---------------------------------------------------------------------------
local function Shared()
    HamingwaysHunterToolsShared = HamingwaysHunterToolsShared or {}
    local sh = HamingwaysHunterToolsShared
    sh.chars = sh.chars or {}
    sh.profiles = sh.profiles or {}
    return sh
end

-- WoW Forever characters have a first name and a surname.
local function FullName()
    local first, surname = UnitName("player")
    first = first or "?"
    if type(surname) == "string" and surname ~= "" then return first .. " " .. surname end
    return first
end

local function CharKey()
    return FullName() .. "-" .. (GetRealmName() or "?")
end

local function Trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

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
    Write(db.general, general, PERSONAL_GENERAL, 1)
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

-- Loads settings text into this character; returns the number of values set or nil when the text is invalid.
function PR.Load(text)
    local data = PR.Parse(text)
    if not data then return nil end
    local db, n = HHT.db, 0
    n = n + Apply(db.general, data.general, PERSONAL_GENERAL)
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

-- Settings of the other characters, newest first.
local function Chars()
    local me, list = CharKey(), {}
    for key, c in pairs(Shared().chars) do
        if key ~= me and type(c) == "table" and type(c.text) == "string" then
            local name, realm = key:match("^(.-)%-([^%-]+)$")
            list[#list + 1] = { key = key, name = name or key, realm = realm, text = c.text, time = c.time or 0, level = c.level }
        end
    end
    table.sort(list, function(a, b)
        if a.time ~= b.time then return a.time > b.time end
        return a.key < b.key
    end)
    return list
end

local function CharLabel(c)
    if c.realm and c.realm ~= GetRealmName() then return c.name .. " (" .. c.realm .. ")" end
    return c.name
end

-- Everything that could be taken over, for the quick install: { label =, text = }.
function PR.Sources()
    local out = {}
    for _, c in ipairs(Chars()) do out[#out + 1] = { label = CharLabel(c), text = c.text } end
    for _, p in ipairs(Shared().profiles) do out[#out + 1] = { label = L("Profile") .. ": " .. p.name, text = p.text } end
    return out
end

-- Called at logout: keeps a copy of this character's settings for the others to find.
function PR.Publish()
    local g = HHT.db and HHT.db.general
    if not g or (g.setupDone == nil and g.origin ~= "old") then return end
    Shared().chars[CharKey()] = { text = PR.Export(), time = time(), ver = HHT.version, level = UnitLevel("player") }
end

local function NameTaken(name, except)
    local low = name:lower()
    for i, p in ipairs(Shared().profiles) do
        if i ~= except and p.name:lower() == low then return true end
    end
    return false
end

local function UniqueName(base)
    if not NameTaken(base) then return base end
    local n = 2
    while NameTaken(base .. " " .. n) do n = n + 1 end
    return base .. " " .. n
end

local function NumberedName(base)
    local n = 1
    while NameTaken(base .. " #" .. n) do n = n + 1 end
    return base .. " #" .. n
end

-- Returns the new profile's index, or nil when the list is full.
function PR.Add(name, text)
    local list = Shared().profiles
    if #list >= MAX_PROFILES then return nil end
    list[#list + 1] = { name = UniqueName(name), text = text, time = time() }
    return #list
end

-- ---------------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------------
local win, sel
local rows = {}
local ROW_W = 300

local function Status(msg, bad)
    win.status:SetText(msg or "")
    if bad then win.status:SetTextColor(0.95, 0.4, 0.35) else win.status:SetTextColor(0.67, 0.83, 0.45) end
end

-- Returns "profile" or "char" and the stored entry of the selection.
local function Selected()
    if not sel then return nil end
    local sh = Shared()
    local e = (sel.kind == "profile" and sh.profiles[sel.index]) or (sel.kind == "char" and sh.chars[sel.key]) or nil
    if e then return sel.kind, e end
    sel = nil
end

local function SetOn(b, on)
    if on then b:Enable() else b:Disable() end
    b:SetAlpha(on and 1 or 0.4)
end

local function Disarm(b)
    if b.armed then b.armed = nil; b:SetLabel(b.normal) end
end

local function DisarmAll()
    Disarm(win.load); Disarm(win.over); Disarm(win.delete)
end

local function RefreshButtons()
    local kind = Selected()
    SetOn(win.load, kind ~= nil)
    SetOn(win.over, kind == "profile")
    SetOn(win.rename, kind == "profile")
    SetOn(win.copy, kind ~= nil)
    SetOn(win.delete, kind ~= nil)
end

local function IsSelected(it)
    if not sel or it.kind ~= sel.kind then return false end
    return (it.kind == "profile" and it.index == sel.index) or (it.kind == "char" and it.key == sel.key)
end

local function RefreshList()
    local sh = Shared()
    local items = { { head = L("Profiles") } }
    if #sh.profiles == 0 then items[#items + 1] = { note = L("No profiles yet. Save the current settings or import some text.") } end
    for i, p in ipairs(sh.profiles) do
        items[#items + 1] = { kind = "profile", index = i, name = p.name, info = date("%Y-%m-%d", p.time or 0) }
    end
    items[#items + 1] = { head = L("Other characters") }
    local chars = Chars()
    if #chars == 0 then items[#items + 1] = { note = L("No other character has saved settings yet. Log in on it once with this version.") } end
    for _, c in ipairs(chars) do
        local info = date("%Y-%m-%d", c.time)
        if c.level then info = string.format(L("Level %d"), c.level) .. "  " .. info end
        items[#items + 1] = { kind = "char", key = c.key, name = CharLabel(c), info = info }
    end

    local y = 2
    for i, it in ipairs(items) do
        local b = rows[i]
        if not b then
            b = CreateFrame("Button", nil, win.content)
            UI.Selectable(b)
            b.name = UI.Text(b, "", 12)
            b.name:SetJustifyH("LEFT")
            b.info = UI.Text(b, "", 11, 0.6, 0.62, 0.66)
            b.info:SetPoint("RIGHT", b, "RIGHT", -8, 0)
            b:SetScript("OnClick", function(self)
                local x = self.item
                if not (x and x.kind) then return end
                sel = { kind = x.kind, index = x.index, key = x.key }
                win.nameBox:SetText(x.name)
                DisarmAll()
                RefreshList()
                RefreshButtons()
            end)
            rows[i] = b
        end
        b.item = it
        b:ClearAllPoints()
        b.name:ClearAllPoints()
        local h = 22
        if it.head or it.note then
            b:EnableMouse(false)
            b:SetSelected(false)
            b.info:SetText("")
            b.name:SetPoint("TOPLEFT", b, "TOPLEFT", it.head and 2 or 10, 0)
            b.name:SetWidth(ROW_W - 14)
            b.name:SetWordWrap(true)
            if it.head then
                local a = UI.PAL.head
                b.name:SetTextColor(a[1], a[2], a[3])
                b.name:SetText(it.head)
                y = y + (i > 1 and 8 or 0)
                h = 20
            else
                b.name:SetTextColor(0.6, 0.62, 0.66)
                b.name:SetText(it.note)
                h = math.max(16, b.name:GetStringHeight() + 4)
            end
        else
            b:EnableMouse(true)
            b:SetSelected(IsSelected(it))
            b.name:SetPoint("LEFT", b, "LEFT", 10, 0)
            b.name:SetWidth(ROW_W - 130)
            b.name:SetWordWrap(false)
            b.name:SetTextColor(0.92, 0.94, 0.97)
            b.name:SetText(it.name)
            b.info:SetText(it.info)
        end
        b:SetSize(ROW_W, h)
        b:SetPoint("TOPLEFT", win.content, "TOPLEFT", 0, -y)
        b:Show()
        y = y + h + 2
    end
    for i = #items + 1, #rows do rows[i]:Hide() end
    win.content:SetHeight(y + 4)
    win.updateBar()
end

local function SelectProfile(index)
    local p = Shared().profiles[index]
    sel = { kind = "profile", index = index }
    win.nameBox:SetText(p and p.name or "")
    DisarmAll()
    RefreshList()
    RefreshButtons()
end

-- Buttons that replace data ask for a second click.
local function GuardButton(label, w, fn)
    local b = UI.Button(win, w, 22, label)
    b.normal = label
    b:SetScript("OnClick", function(self)
        if self.armed then
            Disarm(self)
            fn()
            return
        end
        local token = GetTime()
        self.armed = token
        self:SetLabel(L("Click again"))
        C_Timer.After(4, function() if self.armed == token then Disarm(self) end end)
    end)
    return b
end

local function DoLoad()
    local kind, e = Selected()
    if not kind then return end
    local n = PR.Load(e.text)
    if n then Status(string.format(L("Profile loaded (%d values)."), n)) else Status(L("This text is not a valid settings export."), true) end
end

local function DoOverwrite()
    local kind, p = Selected()
    if kind ~= "profile" then return end
    p.text, p.time = PR.Export(), time()
    Status(L("Profile overwritten with the current settings."))
    RefreshList()
end

local function DoDelete()
    local kind = Selected()
    if not kind then return end
    local sh = Shared()
    if kind == "profile" then table.remove(sh.profiles, sel.index) else sh.chars[sel.key] = nil end
    sel = nil
    win.nameBox:SetText("")
    Status(L("Deleted."))
    RefreshList()
    RefreshButtons()
end

local function DoRename()
    local kind, p = Selected()
    if kind ~= "profile" then return end
    local name = Trim(win.nameBox:GetText())
    if name == "" then Status(L("Enter a name first."), true); return end
    if NameTaken(name, sel.index) then Status(L("A profile with this name already exists."), true); return end
    p.name = name
    Status(L("Renamed."))
    RefreshList()
end

local function DoCopy()
    local kind, e = Selected()
    if not kind then return end
    local typed = Trim(win.nameBox:GetText())
    local name
    if kind == "profile" then
        name = (typed ~= "" and typed ~= e.name) and typed or (e.name .. " " .. L("copy"))
    else
        name = typed ~= "" and typed or sel.key:match("^[^%-]+") or sel.key
    end
    local index = PR.Add(name, e.text)
    if not index then Status(L("Too many profiles. Delete one first."), true); return end
    SelectProfile(index)
    Status(string.format(L("Profile saved: %s"), Shared().profiles[index].name))
end

local function DoSave()
    local name = Trim(win.nameBox:GetText())
    if name == "" then name = NumberedName(L("Profile")) end
    local index = PR.Add(name, PR.Export())
    if not index then Status(L("Too many profiles. Delete one first."), true); return end
    SelectProfile(index)
    Status(string.format(L("Profile saved: %s"), Shared().profiles[index].name))
end

local function DoExport()
    local kind, e = Selected()
    win.box:SetText(kind and e.text or PR.Export())
    win.box:SetFocus()
    win.box:HighlightText()
    Status(L("Settings exported. Press Ctrl+C to copy."))
end

local function DoImport()
    local text = Trim(win.box:GetText())
    if text == "" then Status(L("Paste the text to import into the box first."), true); return end
    if not PR.Parse(text) then Status(L("This text is not a valid settings export."), true); return end
    local sh = Shared()
    local n = (sh.imports or 0) + 1
    local base = L("Imported profile")
    while NameTaken(base .. " #" .. n) do n = n + 1 end
    local index = PR.Add(base .. " #" .. n, text)
    if not index then Status(L("Too many profiles. Delete one first."), true); return end
    sh.imports = n
    SelectProfile(index)
    Status(string.format(L("Imported as %s. Select it and press Load to use it."), sh.profiles[index].name))
end

local function Build()
    win = UI.Window("HamingwaysHunterToolsProfile", 660, 430, L("Profiles, export and import"))
    win:SetPoint("CENTER")
    win:SetFrameStrata("FULLSCREEN_DIALOG")
    win:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, "HamingwaysHunterToolsProfile") end

    local note = UI.Text(win, L("Profiles are shared by all your characters. Load replaces the settings of this character. Export with nothing selected copies the current settings."), 11, 0.8, 0.8, 0.8)
    note:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -40)
    note:SetWidth(632)
    note:SetJustifyH("LEFT")
    local note2 = UI.Text(win, L("Known ranks, seen and tamed beasts, the wishlist and stable pets belong to the character and are not exported."), 11, 0.6, 0.6, 0.6)
    note2:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -4)
    note2:SetWidth(632)
    note2:SetJustifyH("LEFT")

    local box = CreateFrame("Frame", nil, win)
    box:SetSize(326, 232)
    box:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -92)
    UI.Round(box, 6, 0, 0, 0, 0.28, "BACKGROUND")
    local sf = CreateFrame("ScrollFrame", nil, box)
    sf:SetPoint("TOPLEFT", box, "TOPLEFT", 6, -6)
    sf:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -14, 6)
    win.content = CreateFrame("Frame", nil, sf)
    win.content:SetSize(ROW_W, 10)
    sf:SetScrollChild(win.content)
    win.updateBar = UI.ScrollBar(sf, win.content, 10, 44)

    local rx = 356
    local nameLabel = UI.Text(win, L("Name"), 12)
    nameLabel:SetPoint("TOPLEFT", win, "TOPLEFT", rx, -92)
    win.nameBox = UI.EditBox(win, 290, nil)
    win.nameBox:SetMaxLetters(40)
    win.nameBox:SetPoint("TOPLEFT", win, "TOPLEFT", rx, -110)

    win.load = GuardButton(L("Load"), 142, DoLoad)
    win.load:SetPoint("TOPLEFT", win, "TOPLEFT", rx, -142)
    win.over = GuardButton(L("Overwrite"), 142, DoOverwrite)
    win.over:SetPoint("TOPLEFT", win, "TOPLEFT", rx + 148, -142)
    win.rename = UI.Button(win, 142, 22, L("Rename"), DoRename)
    win.rename:SetPoint("TOPLEFT", win, "TOPLEFT", rx, -172)
    win.copy = UI.Button(win, 142, 22, L("Copy"), DoCopy)
    win.copy:SetPoint("TOPLEFT", win, "TOPLEFT", rx + 148, -172)
    win.delete = GuardButton(L("Delete"), 142, DoDelete)
    win.delete:SetPoint("TOPLEFT", win, "TOPLEFT", rx, -202)
    win.export = UI.Button(win, 142, 22, L("Export"), DoExport)
    win.export:SetPoint("TOPLEFT", win, "TOPLEFT", rx + 148, -202)
    local save = UI.Button(win, 290, 22, L("Save current settings as new profile"), DoSave)
    save:SetPoint("TOPLEFT", win, "TOPLEFT", rx, -246)
    UI.SetPrimary(save, UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3])

    local boxLabel = UI.Text(win, L("Text for export and import"), 12)
    boxLabel:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -334)
    win.box = UI.EditBox(win, 632, nil)
    win.box:SetMaxLetters(MAX_LEN)
    win.box:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -352)
    win.status = UI.Text(win, "", 12, 0.67, 0.83, 0.45)
    win.status:SetPoint("TOPLEFT", win.box, "BOTTOMLEFT", 0, -8)

    local import = UI.Button(win, 200, 22, L("Import as new profile"), DoImport)
    import:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 14, 12)
    local close = UI.Button(win, 110, 22, L("Close"), function() win:Hide() end)
    close:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -14, 12)
end

function PR.Open()
    if not win then Build() end
    win.status:SetText("")
    DisarmAll()
    RefreshList()
    RefreshButtons()
    win:Show()
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGOUT")
ev:SetScript("OnEvent", function()
    if not HHT.db then return end
    -- The quick install puts the settings aside while it is open; they are put back first.
    local setup = HHT.Setup
    if setup and setup.snap then setup:Restore(true) end
    pcall(PR.Publish)
end)
