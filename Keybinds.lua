-- Keybinds: finds the action bar button holding a spell and reads its binding (default bars, Bartender4, ElvUI).
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI

HHT:AddGerman({
    ["Keybinds"] = "Tastenbelegung",
    ["Show keybinds on the icons"] = "Tastenbelegung auf den Symbolen zeigen",
    ["Keybind text size"] = "Schriftgroesse Tastenbelegung",
    ["Keybind position"] = "Position Tastenbelegung",
    ["Keybind color"] = "Farbe Tastenbelegung",
    ["Top left"] = "Oben links",
    ["Top right"] = "Oben rechts",
    ["Center"] = "Mitte",
    ["Bottom left"] = "Unten links",
    ["Bottom right"] = "Unten rechts",
})

local Keys = {}
HHT.Keys = Keys

local BARS = {
    { "ActionButton", 12, "ACTIONBUTTON" },
    { "MultiBarBottomLeftButton", 12, "MULTIACTIONBAR1BUTTON" },
    { "MultiBarBottomRightButton", 12, "MULTIACTIONBAR2BUTTON" },
    { "MultiBarRightButton", 12, "MULTIACTIONBAR3BUTTON" },
    { "MultiBarLeftButton", 12, "MULTIACTIONBAR4BUTTON" },
    { "MultiBar5Button", 12, "MULTIACTIONBAR5BUTTON" },
    { "MultiBar6Button", 12, "MULTIACTIONBAR6BUTTON" },
    { "MultiBar7Button", 12, "MULTIACTIONBAR7BUTTON" },
    { "BT4Button", 180, nil },
}

local function Short(k)
    k = k:upper()
    k = k:gsub("SHIFT%-", "S"):gsub("CTRL%-", "C"):gsub("ALT%-", "A")
    k = k:gsub("MOUSEWHEELUP", "MwU"):gsub("MOUSEWHEELDOWN", "MwD"):gsub("BUTTON(%d+)", "M%1")
    k = k:gsub("NUMPAD", "N"):gsub("SPACE", "Spc")
    return k
end

local function SpellNameById(id)
    if C_Spell and C_Spell.GetSpellName then
        local ok, n = pcall(C_Spell.GetSpellName, id)
        if ok and type(n) == "string" then return n end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, id)
        if ok and type(info) == "table" and type(info.name) == "string" then return info.name end
    end
    if GetSpellInfo then
        local ok, n = pcall(GetSpellInfo, id)
        if ok and type(n) == "string" then return n end
    end
end

local function ScanButton(map, btn, command)
    local slot = btn.action
    if (type(slot) ~= "number" or HHT.IsSecret(slot) or slot <= 0) and btn.GetAttribute then slot = btn:GetAttribute("action") end
    if type(slot) ~= "number" or HHT.IsSecret(slot) or slot <= 0 or not HasAction(slot) then return end
    local kind, id = GetActionInfo(slot)
    if HHT.IsSecret(kind) or HHT.IsSecret(id) then return end
    local spellId
    if kind == "spell" then spellId = id
    elseif kind == "macro" and GetMacroSpell then spellId = GetMacroSpell(id) end
    if type(spellId) ~= "number" then return end
    local name = SpellNameById(spellId)
    if not name or map[name] then return end
    local text
    if command then
        local k1 = GetBindingKey(command)
        if k1 then text = Short(k1) end
    end
    if not text and btn.HotKey and btn.HotKey.GetText then
        local t = btn.HotKey:GetText()
        if type(t) == "string" and not HHT.IsSecret(t) and t ~= "" and t ~= RANGE_INDICATOR and t:byte(1) < 128 then text = t end
    end
    if text then map[name] = text end
end

local map, builtAt, dirty = nil, 0, true

local function Rebuild()
    local m = {}
    for _, bar in ipairs(BARS) do
        for i = 1, bar[2] do
            local btn = _G[bar[1] .. i]
            if btn then pcall(ScanButton, m, btn, bar[3] and (bar[3] .. i) or nil) end
        end
    end
    for b = 1, 10 do
        for i = 1, 12 do
            local btn = _G["ElvUI_Bar" .. b .. "Button" .. i]
            if btn then pcall(ScanButton, m, btn, nil) end
        end
    end
    map, builtAt, dirty = m, GetTime(), false
end

-- Rebuilds out of combat only; in combat the last known map is used.
function Keys.Get(spellName)
    if not spellName or spellName == "" then return nil end
    local stale = not map or dirty or GetTime() - builtAt > 5
    if stale and (not map or not HHT.InCombat()) then Rebuild() end
    return map[spellName]
end

local watcher = CreateFrame("Frame")
for _, ev in ipairs({ "ACTIONBAR_SLOT_CHANGED", "UPDATE_BINDINGS", "ACTIONBAR_PAGE_CHANGED", "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED" }) do
    pcall(watcher.RegisterEvent, watcher, ev)
end
watcher:SetScript("OnEvent", function() dirty = true end)

-- Applies the module's key settings to an icon.
function Keys.Apply(ic, db, spellName)
    local text = db.showKeys and Keys.Get(spellName) or nil
    ic:SetKey(text, db.keySize, db.keyPos, HHT.Col(db, "key"))
end

function Keys.AddOptions(form, db)
    form:Header(L("Keybinds"))
    form:Check(L("Show keybinds on the icons"), db, "showKeys")
    form:Stepper(L("Keybind text size"), db, "keySize", 8, 24, 1)
    form:Cycle(L("Keybind position"), db, "keyPos", {
        { "TOPLEFT", L("Top left") }, { "TOPRIGHT", L("Top right") }, { "CENTER", L("Center") },
        { "BOTTOMLEFT", L("Bottom left") }, { "BOTTOMRIGHT", L("Bottom right") } })
    form:Color(L("Keybind color"), db.colors, "key")
end
