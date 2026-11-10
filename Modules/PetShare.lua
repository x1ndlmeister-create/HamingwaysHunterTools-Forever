-- Export/import of the beast data (attack speeds, seen, tamed, wishlist) as one line of text, parsed by hand (never executed).
local ADDON, HHT = ...
local L, UI = HHT.L, HHT.UI

HHT:AddGerman({
    ["Export / import beast data"] = "Tierdaten exportieren / importieren",
    ["Export copies the measured attack speeds into the box. Press Ctrl+C and send it on. Import adds the data from the text in the box."] = "Exportieren schreibt die gemessenen Angriffstempi ins Feld. Mit Strg+C kopieren und weitergeben. Importieren fuegt die Daten aus dem Feld hinzu.",
    ["Imported data only fills gaps. Values you have yourself are kept."] = "Importierte Daten fuellen nur Luecken. Eigene Werte bleiben erhalten.",
    ["Also seen, tamed and wishlist"] = "Auch gesehen, gezaehmt und Wunschliste",
    ["Nothing to export yet."] = "Noch nichts zum Exportieren.",
    ["Exported %d speeds, %d seen, %d tamed, %d wishlist. Press Ctrl+C to copy."] = "%d Tempi, %d gesehen, %d gezaehmt, %d Wunschliste exportiert. Mit Strg+C kopieren.",
    ["Imported %d speeds, %d seen, %d tamed, %d wishlist (%d ignored)."] = "%d Tempi, %d gesehen, %d gezaehmt, %d Wunschliste importiert (%d ignoriert).",
    ["This text is not a valid beast data export."] = "Dieser Text ist kein gueltiger Tierdaten-Export.",
})

local SS = {}
HHT.PetShare = SS

local PREFIX = "HHTP1:"
local MAX_LEN = 200000

local function Db()
    local pd = HHT.PetDex
    return pd and pd.module and pd.module.db
end

local function IdList(set)
    local ids = {}
    for id, v in pairs(set) do
        if type(id) == "number" and v then ids[#ids + 1] = id end
    end
    table.sort(ids)
    return ids
end

-- Returns text, speeds, seen, tamed, wish; nil when there is nothing to export.
function SS.Export(personal)
    local db = Db()
    if not db then return nil end
    local sp = IdList(db.speed)
    local parts, counts = {}, { #sp, 0, 0, 0 }
    local v = {}
    for i, id in ipairs(sp) do v[i] = id .. ":" .. string.format("%.2f", db.speed[id]) end
    if #v > 0 then parts[#parts + 1] = "v=" .. table.concat(v, ",") end
    if personal then
        for i, key in ipairs({ { "s", db.seen }, { "t", db.tamed }, { "w", db.wish } }) do
            local ids = IdList(key[2])
            counts[i + 1] = #ids
            if #ids > 0 then parts[#parts + 1] = key[1] .. "=" .. table.concat(ids, ",") end
        end
    end
    if #parts == 0 then return nil end
    return PREFIX .. table.concat(parts, ";"), counts[1], counts[2], counts[3], counts[4]
end

-- Returns speeds, seen, tamed, wish, ignored (all added counts); nil when the text is not an export.
function SS.Import(text, personal)
    local db, pd = Db(), HHT.PetDex
    if not db or type(text) ~= "string" then return nil end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if #text > MAX_LEN or text:sub(1, #PREFIX) ~= PREFIX then return nil end
    local sets = { s = db.seen, t = db.tamed, w = db.wish }
    local added = { v = 0, s = 0, t = 0, w = 0 }
    local ignored, any = 0, false
    for part in text:sub(#PREFIX + 1):gmatch("[^;]+") do
        local kind, list = part:match("^(%a)=(.*)$")
        if kind == "v" or ((kind == "s" or kind == "t" or kind == "w") and personal) then
            any = true
            for token in list:gmatch("[^,]+") do
                local id, val
                if kind == "v" then
                    id, val = token:match("^(%d+):(%d+%.?%d*)$")
                    val = tonumber(val)
                else
                    id = token:match("^(%d+)$")
                end
                id = tonumber(id)
                local ok = id and id < 1e9 and pd.byId[id] and (kind ~= "v" or (val and val >= 0.5 and val <= 5))
                if not ok then
                    ignored = ignored + 1
                elseif kind == "v" then
                    if not db.speed[id] then db.speed[id] = math.floor(val * 100 + 0.5) / 100; added.v = added.v + 1 end
                else
                    if not sets[kind][id] then sets[kind][id] = true; added[kind] = added[kind] + 1 end
                    if kind == "t" and not db.seen[id] then db.seen[id] = true; added.s = added.s + 1 end
                end
            end
        elseif not kind then
            ignored = ignored + 1
        end
    end
    if not any and ignored == 0 then return nil end
    pd.Dirty()
    return added.v, added.s, added.t, added.w, ignored
end

local win

local function Build()
    win = UI.Window("HamingwaysHunterToolsPetShare", 620, 190, L("Export / import beast data"))
    win:SetPoint("CENTER")
    win:SetFrameStrata("FULLSCREEN_DIALOG")
    win:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, "HamingwaysHunterToolsPetShare") end
    win.personal = false
    local note = UI.Text(win, L("Export copies the measured attack speeds into the box. Press Ctrl+C and send it on. Import adds the data from the text in the box."), 11, 0.8, 0.8, 0.8)
    note:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -42)
    note:SetWidth(590)
    note:SetJustifyH("LEFT")
    local note2 = UI.Text(win, L("Imported data only fills gaps. Values you have yourself are kept."), 11, 0.6, 0.6, 0.6)
    note2:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -6)
    note2:SetWidth(590)
    note2:SetJustifyH("LEFT")
    win.box = UI.EditBox(win, 590, nil)
    win.box:SetMaxLetters(MAX_LEN)
    win.box:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -108)
    win.status = UI.Text(win, "", 12, 0.67, 0.83, 0.45)
    win.status:SetPoint("TOPLEFT", win.box, "BOTTOMLEFT", 0, -8)
    local function Say(text, ok)
        win.status:SetText(text)
        if ok then win.status:SetTextColor(0.67, 0.83, 0.45) else win.status:SetTextColor(0.95, 0.4, 0.35) end
    end
    local export = UI.Button(win, 110, 22, L("Export"), function()
        local s, v, se, ta, wi = SS.Export(win.personal)
        if not s then Say(L("Nothing to export yet."), false) return end
        win.box:SetText(s)
        win.box:SetFocus()
        win.box:HighlightText()
        Say(string.format(L("Exported %d speeds, %d seen, %d tamed, %d wishlist. Press Ctrl+C to copy."), v, se, ta, wi), true)
    end)
    export:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 14, 12)
    local import = UI.Button(win, 110, 22, L("Import"), function()
        local v, se, ta, wi, ig = SS.Import(win.box:GetText(), win.personal)
        if v then
            Say(string.format(L("Imported %d speeds, %d seen, %d tamed, %d wishlist (%d ignored)."), v, se, ta, wi, ig), true)
        else
            Say(L("This text is not a valid beast data export."), false)
        end
    end)
    import:SetPoint("LEFT", export, "RIGHT", 8, 0)
    local personal = UI.Check(win, L("Also seen, tamed and wishlist"), function() return win.personal end, function(v) win.personal = v and true or false end)
    personal:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 256, 14)
    local close = UI.Button(win, 110, 22, L("Close"), function() win:Hide() end)
    close:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -14, 12)
end

function SS.Open()
    if not win then Build() end
    win.status:SetText("")
    win:Show()
end
