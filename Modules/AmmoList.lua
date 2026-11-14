-- Reference list of all arrows and bullets with level, damage bonus and source.
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI

HHT:AddGerman({
    ["Show all ammunition"] = "Alle Munition anzeigen",
    ["All ammunition"] = "Alle Munition",
    ["Arrows"] = "Pfeile",
    ["Bullets"] = "Kugeln",
    ["Name"] = "Name",
    ["Lvl"] = "Stufe",
    ["DPS"] = "DPS",
    ["Source"] = "Quelle",
    ["Unknown"] = "Unbekannt",
    ["Quests"] = "Quests",
    ["Quest, vendor"] = "Quest, Haendler",
    ["Crafted, vendor"] = "Hergestellt, Haendler",
    ["Engineering"] = "Ingenieurskunst",
    ["Darkshore (zone drop)"] = "Dunkelkueste (Zonenbeute)",
    ["Vendor"] = "Haendler",
    ["Quest: %s"] = "Quest: %s",
    ["Drop: %s"] = "Beute: %s",
    ["Crafted by Engineers (skill %s)"] = "Hergestellt von Ingenieuren (Skill %s)",
    ["Reputation vendor: %s (%s)"] = "Ruf-Haendler: %s (%s)",
    ["Friendly"] = "Freundlich",
    ["Honored"] = "Wohlwollend",
    ["Revered"] = "Respektvoll",
    ["Conjured by the legendary bow"] = "Erzeugt vom legendaeren Bogen",
    ["Vendor in Halaa (if your faction holds the town)"] = "Haendler in Halaa (wenn deine Fraktion die Stadt haelt)",
    ["Alterac Valley quartermaster"] = "Alteractal-Rueckmeister",
    ["Alterac Valley PvP reputation vendor"] = "PvP-Ruf-Haendler im Alteractal",
    ["In your bags: %d"] = "In deinen Taschen: %d",
    ["Mouse wheel: scroll.  Green: you carry it.  Red: level too high."] = "Mausrad: scrollen.  Gruen: im Besitz.  Rot: Stufe zu hoch.",
    ["Required level"] = "Benoetigte Stufe",
    ["Damage bonus per second"] = "Schadensbonus pro Sekunde",
    ["Crafted by Leatherworkers"] = "Hergestellt von Lederern",
    ["Better quiver"] = "Besserer Koecher",
    ["Better ammo pouch"] = "Besserer Munitionsbeutel",
    ["%s  %d slots, +%d%% speed"] = "%s  %d Plaetze, +%d%% Tempo",
    ["Quest: %s (%s)"] = "Quest: %s (%s)",
    ["Drop: %s (%s)"] = "Beute: %s (%s)",
})

local AL = {}
HHT.AmmoList = AL

-- Complete projectile list of WoW Forever. kind, name, required level, dps, source {type, a, b}, optional item id (or candidates)
local DATA = {
    { "arrow", "Rough Arrow", 1, 1.5, { "v" }, 2512 },
    { "arrow", "Depricated Sharp Arrow", 3, 2.0, { "o", "Unknown" } },
    { "arrow", "Sharp Arrow", 10, 3.5, { "v" }, 2515 },
    { "arrow", "Depricated Whipwood Arrow", 15, 4.5, { "o", "Unknown" } },
    { "arrow", "Razor Arrow", 25, 7.5, { "v" }, 3030 },
    { "arrow", "Depricated Razor Arrow", 30, 8.5, { "o", "Unknown" } },
    { "arrow", "Feathered Arrow", 30, 9.5, { "o", "Quests" }, 3464 },
    { "arrow", "Precision Arrow", 35, 11.5, { "d", "Baelog, Uldaman" }, { 9345, 9399 } },
    { "arrow", "Explosive Arrow", 37, 14.5, { "o", "Unknown" }, 10579 },
    { "arrow", "Jagged Arrow", 40, 13.0, { "v" }, 11285 },
    { "arrow", "Ice Threaded Arrow", 51, 16.5, { "v" }, 19316 },
    { "arrow", "Thorium Headed Arrow", 52, 17.5, { "o", "Quest, vendor" }, { 18042, 15997 } },
    { "arrow", "Doomshot", 54, 20.0, { "d", "Shadow Hunter Vosh'gajin, Blackrock Spire" }, { 12654, 18678 } },
    { "arrow", "Swiftfeather Arrow", 60, 24.5, { "o", "Engineering" }, 274387 },
    { "arrow", "Monster - Fire Arrow", 1, 0.5, { "o", "Unknown" } },

    { "bullet", "Light Shot", 1, 1.5, { "v" }, 2516 },
    { "bullet", "Crafted Light Shot", 5, 2.0, { "o", "Engineering" }, 8067 },
    { "bullet", "Flash Pellet", 1, 2.0, { "q", "Sharing the Land (Mulgore)" } },
    { "bullet", "Heavy Shot", 10, 3.5, { "v" }, 2519 },
    { "bullet", "Smooth Pebble", 13, 4.0, { "d", "Darkshore (zone drop)" }, 5568 },
    { "bullet", "Crafted Heavy Shot", 15, 4.5, { "o", "Engineering" }, 8068 },
    { "bullet", "Solid Shot", 25, 7.5, { "v" }, 3033 },
    { "bullet", "Crafted Solid Shot", 30, 8.5, { "o", "Engineering" }, 8069 },
    { "bullet", "Exploding Shot", 30, 9.5, { "o", "Quests" } },
    { "bullet", "Hi-Impact Mithril Slugs", 37, 12.5, { "o", "Engineering" }, { 10512, 10514 } },
    { "bullet", "Accurate Slugs", 40, 13.0, { "v" }, 11284 },
    { "bullet", "Mithril Gyro-Shot", 44, 15.0, { "o", "Engineering" }, 10513 },
    { "bullet", "Rockshard Pellets", 47, 18.0, { "d", "Lord Roccor, Blackrock Depths" }, 17758 },
    { "bullet", "Ice Threaded Bullet", 51, 16.5, { "v" }, { 19317, 19319 } },
    { "bullet", "Thorium Shells", 52, 17.5, { "o", "Crafted, vendor" }, 15997 },
    { "bullet", "Miniature Cannon Balls", 56, nil, { "d", "Cannon Master Willey, Stratholme" }, { 13377, 18679 } },
    { "bullet", "Swiftstrike Shot", 60, 24.5, { "o", "Engineering" }, 274388 },
}
local PROJECTILE_SUB = { arrow = 2, bullet = 3 }

-- Several candidate ids may be given; the first that is a projectile of the right type wins.
local function ResolveId(kind, ids)
    if type(ids) ~= "table" then ids = { ids } end
    local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    for _, id in ipairs(ids) do
        if not fn then return id end
        local ok, _, _, _, _, _, class, sub = pcall(fn, id)
        if ok and class == 6 and sub == PROJECTILE_SUB[kind] then return id end
    end
end

local function GameLevel(e)
    if not e.id then return nil end
    local ok, _, _, _, _, minLevel = pcall(GetItemInfo or function() end, e.id)
    return ok and tonumber(minLevel) or nil
end
local DEFAULT_ICON = {
    arrow = "Interface\\Icons\\INV_Ammo_Arrow_02",
    bullet = "Interface\\Icons\\INV_Ammo_Bullet_02",
}

local function SourceText(src)
    local t = src[1]
    if t == "v" then return L("Vendor")
    elseif t == "q" then return string.format(L("Quest: %s"), src[2])
    elseif t == "d" then return string.format(L("Drop: %s"), src[2])
    elseif t == "e" then return string.format(L("Crafted by Engineers (skill %s)"), src[2])
    elseif t == "l" then return L("Crafted by Leatherworkers")
    elseif t == "qz" then return string.format(L("Quest: %s (%s)"), src[2], src[3])
    elseif t == "dz" then return string.format(L("Drop: %s (%s)"), src[2], src[3])
    elseif t == "r" then return string.format(L("Reputation vendor: %s (%s)"), L(src[2]), L(src[3]))
    end
    return L(src[2])
end

local function ItemIcon(e)
    if e.id and C_Item and C_Item.GetItemIconByID then
        local ok, t = pcall(C_Item.GetItemIconByID, e.id)
        if ok and t then return t end
    end
    return DEFAULT_ICON[e.kind]
end

local function ItemName(e)
    if e.id and C_Item and C_Item.GetItemNameByID then
        local ok, n = pcall(C_Item.GetItemNameByID, e.id)
        if ok and type(n) == "string" then return n end
    end
    return L(e.name)
end

local entries = { arrow = {}, bullet = {} }
for _, d in ipairs(DATA) do
    local e = { kind = d[1], name = d[2], level = d[3], dps = d[4], src = d[5] }
    if d[6] then e.id = ResolveId(e.kind, d[6]) end
    local list = entries[e.kind]
    list[#list + 1] = e
end
for _, list in pairs(entries) do
    table.sort(list, function(a, b)
        local la, lb = a.level or 999, b.level or 999
        if la ~= lb then return la < lb end
        return (a.dps or 0) < (b.dps or 0)
    end)
end

local ROWS, ROW_H = 14, 26
local win

-- Ammo of the same kind that adds more damage than the equipped one and is usable at your level, best first.
function AL.Upgrades(kind, equipped, includeEngineered)
    local plevel = AL.shotLevel or tonumber(UnitLevel and UnitLevel("player")) or 0
    local base
    local ename = equipped and equipped.name and equipped.name:lower()
    for _, e in ipairs(entries[kind] or {}) do
        if equipped and ((e.id and e.id == equipped.id) or (ename and (ItemName(e):lower() == ename or e.name:lower() == ename))) then
            base = e.dps
            break
        end
    end
    local out = {}
    if not base then return out end
    for _, e in ipairs(entries[kind]) do
        local lvl = e.level or GameLevel(e) or 999
        local engineered = e.src and e.src[2] == "Engineering"
        if e.dps and e.dps > base and lvl <= plevel and not e.name:find("^Depricated") and not e.name:find("^Monster")
            and (includeEngineered or not engineered) then
            out[#out + 1] = e
        end
    end
    table.sort(out, function(a, b) return a.dps > b.dps end)
    return out
end
AL.ItemName, AL.ItemIcon, AL.SourceText = ItemName, ItemIcon, SourceText

-- Quivers hold arrows, ammo pouches hold bullets. kind, item id, name, slots, ranged speed %, required level, faction, source
local BAGS = {
    { "arrow", 2101, "Light Quiver", 6, 10, 1, nil, { "v" } },
    { "arrow", 5439, "Small Quiver", 8, 10, 1, nil, { "v" } },
    { "arrow", 7278, "Light Leather Quiver", 8, 10, 1, nil, { "l" } },
    { "arrow", 11362, "Medium Quiver", 10, 10, 10, nil, { "v" } },
    { "arrow", 3573, "Hunting Quiver", 10, 10, 1, nil, { "q", "Vyrin's Revenge" } },
    { "arrow", 286734, "Ban'ethil Quiver", 10, 10, 1, "Alliance", { "qz", "Escaping Ban'ethil", "Teldrassil" } },
    { "arrow", 3605, "Quiver of the Night Watch", 12, 11, 1, nil, { "q", "The Night Watch" } },
    { "arrow", 7371, "Heavy Quiver", 14, 12, 30, nil, { "l" } },
    { "arrow", 274926, "Matriarch Quiver", 14, 13, 35, "Horde", { "qz", "A Hunter's Quiver", "Riverglades" } },
    { "arrow", 8217, "Quickdraw Quiver", 16, 13, 40, nil, { "l" } },
    { "arrow", 2662, "Ribbly's Quiver", 16, 14, 50, nil, { "dz", "Ribbly Screwspigot", "Blackrock Depths" } },
    { "arrow", 19319, "Harpy Hide Quiver", 16, 15, 55, nil, { "o", "Alterac Valley PvP reputation vendor" } },
    { "arrow", 18714, "Ancient Sinew Wrapped Lamina", 18, 15, 60, nil, { "q", "Ancient Sinew Wrapped Lamina" } },
    { "bullet", 2102, "Small Ammo Pouch", 6, 10, 1, nil, { "v" } },
    { "bullet", 5441, "Small Shot Pouch", 8, 10, 1, nil, { "v" } },
    { "bullet", 7279, "Small Leather Ammo Pouch", 8, 10, 1, nil, { "l" } },
    { "bullet", 11363, "Medium Shot Pouch", 10, 10, 10, nil, { "v" } },
    { "bullet", 3574, "Hunting Ammo Sack", 10, 10, 1, nil, { "q", "Vyrin's Revenge" } },
    { "bullet", 3604, "Bandolier of the Night Watch", 12, 11, 1, nil, { "q", "The Night Watch" } },
    { "bullet", 7372, "Heavy Leather Ammo Pouch", 14, 12, 30, nil, { "l" } },
    { "bullet", 8218, "Thick Leather Ammo Pouch", 16, 13, 40, nil, { "l" } },
    { "bullet", 2663, "Ribbly's Bandolier", 16, 14, 50, nil, { "dz", "Ribbly Screwspigot", "Blackrock Depths" } },
    { "bullet", 19320, "Gnoll Skin Bandolier", 16, 15, 55, nil, { "o", "Alterac Valley PvP reputation vendor" } },
}
local bagById = {}
for _, d in ipairs(BAGS) do
    bagById[d[2]] = { kind = d[1], id = d[2], name = d[3], slots = d[4], haste = d[5], level = d[6], faction = d[7], src = d[8] }
end

-- The kind ("arrow" or "bullet") a known quiver or ammo pouch belongs to.
function AL.BagKind(id)
    local b = bagById[id]
    return b and b.kind
end

-- Quivers or pouches of the kind that beat the equipped one (more speed, then more slots), usable by this character, best first.
-- equippedId nil means none is equipped; an equipped bag this list does not know gives no suggestions.
function AL.BagUpgrades(kind, equippedId)
    local cur
    if equippedId then
        cur = bagById[equippedId]
        if not cur then return {} end
    end
    local plevel = AL.shotLevel or tonumber(UnitLevel and UnitLevel("player")) or 0
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local out = {}
    for _, b in pairs(bagById) do
        if b.kind == kind and b.level <= plevel and (not b.faction or b.faction == faction)
            and (not cur or b.haste > cur.haste or (b.haste == cur.haste and b.slots > cur.slots)) then
            out[#out + 1] = b
        end
    end
    table.sort(out, function(a, b)
        if a.haste ~= b.haste then return a.haste > b.haste end
        if a.slots ~= b.slots then return a.slots > b.slots end
        return a.id < b.id
    end)
    while #out > 5 do out[#out] = nil end
    return out
end

local function OwnedMap()
    local byId, byName = {}, {}
    local am = HHT.modules.ammo
    if am and am.stacks then
        for _, list in pairs(am.stacks) do
            for _, s in ipairs(list) do
                byId[s.id] = (byId[s.id] or 0) + s.count
                byName[s.name:lower()] = (byName[s.name:lower()] or 0) + s.count
            end
        end
    end
    return byId, byName
end

function AL:Refresh()
    if not win or not win:IsShown() then return end
    local list = entries[win.kind]
    local maxOff = math.max(0, #list - ROWS)
    win.offset = math.min(maxOff, math.max(0, win.offset))
    local byId, byName = OwnedMap()
    local plevel = AL.shotLevel or tonumber(UnitLevel and UnitLevel("player")) or 0
    for i = 1, ROWS do
        local row = win.rows[i]
        local e = list[win.offset + i]
        row.entry = e
        if not e then
            row:Hide()
        else
            row:Show()
            local name = ItemName(e)
            local owned = (e.id and byId[e.id]) or byName[name:lower()] or byName[e.name:lower()]
            row.owned = owned
            row.icon:SetTexture(ItemIcon(e))
            row.name:SetText(name)
            row.name:SetTextColor(owned and 0.45 or 0.92, owned and 0.9 or 0.94, owned and 0.35 or 0.97)
            local lvl = e.level or GameLevel(e)
            row.lvl:SetText(lvl and tostring(lvl) or "?")
            if lvl and lvl > plevel then row.lvl:SetTextColor(0.95, 0.35, 0.3) else row.lvl:SetTextColor(0.92, 0.94, 0.97) end
            row.dps:SetText(e.dps and string.format("%.1f", e.dps) or "?")
            row.src:SetText(SourceText(e.src))
        end
    end
    win.range:SetText(string.format("%d-%d / %d", math.min(#list, win.offset + 1), math.min(#list, win.offset + ROWS), #list))
    for k, tab in pairs(win.tabs) do
        local on = (k == win.kind)
        tab.label:SetTextColor(on and UI.ACCENT[1] or 0.7, on and UI.ACCENT[2] or 0.7, on and UI.ACCENT[3] or 0.7)
        tab:SetLabel(L(k == "arrow" and "Arrows" or "Bullets") .. " (" .. #entries[k] .. ")")
    end
end

local function ShowTip(row)
    local e = row.entry
    if not e or not GameTooltip then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    local shown = false
    if e.id and GameTooltip.SetItemByID then shown = pcall(GameTooltip.SetItemByID, GameTooltip, e.id) end
    if not shown then
        GameTooltip:ClearLines()
        GameTooltip:AddLine(ItemName(e), 1, 1, 1)
    end
    GameTooltip:AddLine(L("Required level") .. ": " .. tostring(e.level or GameLevel(e) or "?"), 0.8, 0.8, 0.8)
    if e.dps then GameTooltip:AddLine(L("Damage bonus per second") .. ": +" .. string.format("%.1f", e.dps), 0.8, 0.8, 0.8) end
    GameTooltip:AddLine(SourceText(e.src), 0.67, 0.83, 0.45, true)
    if row.owned then GameTooltip:AddLine(string.format(L("In your bags: %d"), row.owned), 0.45, 0.9, 0.35) end
    GameTooltip:Show()
end

local function Build()
    win = UI.Window("HamingwaysHunterToolsAmmoList", 690, 500, L("All ammunition"))
    win:SetFrameStrata("FULLSCREEN_DIALOG")
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    win:Hide()
    win.kind, win.offset, win.rows, win.tabs = "arrow", 0, {}, {}
    tinsert(UISpecialFrames, "HamingwaysHunterToolsAmmoList")

    local prev
    for _, k in ipairs({ "arrow", "bullet" }) do
        local tab = UI.Button(win, 130, 22, "", function()
            win.kind, win.offset = k, 0
            AL:Refresh()
        end)
        if prev then tab:SetPoint("LEFT", prev, "RIGHT", 6, 0) else tab:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -38) end
        win.tabs[k] = tab
        prev = tab
    end

    local COLS = {
        { "Name", 40, 190 }, { "Lvl", 236, 30 }, { "DPS", 270, 40 }, { "Source", 314, 354 },
    }
    for _, c in ipairs(COLS) do
        local h = UI.Header(win, L(c[1]))
        h:SetPoint("TOPLEFT", win, "TOPLEFT", c[2], -70)
    end

    for i = 1, ROWS do
        local row = CreateFrame("Button", nil, win)
        row:SetSize(666, ROW_H)
        row:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -88 - (i - 1) * ROW_H)
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.15)
        if i % 2 == 0 then
            local stripe = row:CreateTexture(nil, "BACKGROUND")
            stripe:SetAllPoints()
            stripe:SetColorTexture(1, 1, 1, 0.03)
        end
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(22, 22)
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        HHT.Icon.Attach(row.icon)
        local function Cell(x, w)
            local fs = UI.Text(row, "", 12)
            fs:SetPoint("LEFT", row, "LEFT", x - 12, 0)
            fs:SetWidth(w)
            fs:SetJustifyH("LEFT")
            return fs
        end
        row.name = Cell(40, 190)
        row.lvl = Cell(236, 30)
        row.dps = Cell(270, 40)
        row.src = Cell(314, 354)
        row.src:SetTextColor(0.8, 0.8, 0.8)
        row:SetScript("OnEnter", ShowTip)
        row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        win.rows[i] = row
    end

    local function Wheel(_, delta)
        win.offset = win.offset - delta * 3
        AL:Refresh()
    end
    win:EnableMouseWheel(true)
    win:SetScript("OnMouseWheel", Wheel)
    for _, row in ipairs(win.rows) do
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", Wheel)
    end

    win.range = UI.Text(win, "", 12, 0.7, 0.7, 0.7)
    win.range:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -12, 10)
    local hint = UI.Text(win, L("Mouse wheel: scroll.  Green: you carry it.  Red: level too high."), 11, 0.7, 0.7, 0.7)
    hint:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 12, 10)
    win:SetScript("OnShow", function() AL:Refresh() end)
end

function AL:Open()
    if not win then Build() end
    if win:IsShown() then win:Hide() else win:Show() end
end
