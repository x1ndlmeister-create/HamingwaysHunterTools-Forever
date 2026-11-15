-- Cooldown bar: user-pickable spells as icons, works in combat (duration objects).
local ADDON, HHT = ...
local L, UI, S, Icon = HHT.L, HHT.UI, HHT.Spells, HHT.Icon

HHT:AddGerman({
    ["Cooldowns"] = "Abklingzeiten",
    ["Cooldown icons for your hunter spells."] = "Abklingzeit-Symbole fuer deine Jaeger-Zauber.",
    ["Show cooldown numbers"] = "Abklingzeit-Zahlen zeigen",
    ["Grey out icons on cooldown"] = "Symbole bei Abklingzeit ausgrauen",
    ["Show if usable (red = out of range, blue = no resource)"] = "Nutzbarkeit zeigen (rot = ausser Reichweite, blau = keine Ressource)",
    ["Show spell names"] = "Zaubernamen zeigen",
    ["Icons shown"] = "Angezeigte Symbole",
    ["All spells"] = "Alle Zauber",
    ["Only on cooldown"] = "Nur bei Abklingzeit",
    ["Only when ready"] = "Nur wenn bereit",
    ["Ready border"] = "Rahmen bereit",
    ["Cooldown border"] = "Rahmen Abklingzeit",
    ["Tracked spells"] = "Verfolgte Zauber",
    ["Add spell"] = "Zauber hinzufuegen",
    ["Restore default list"] = "Standardliste wiederherstellen",
    ["Unknown spells are hidden automatically."] = "Unbekannte Zauber werden automatisch ausgeblendet.",
    ["Border alpha"] = "Rahmen-Deckkraft",
    ["Layout"] = "Anordnung",
    ["One bar"] = "Eine Leiste",
    ["Individual icons"] = "Einzelne Symbole",
    ["Show spell tooltip on mouseover"] = "Zauber-Tooltip bei Mausueberfahrt zeigen",
    ["One bar: icons line up from the first icon and move together. Individual icons: each icon moves on its own. Both: click (also in combat) or give a key in the spell list below. Icons hidden by the filters cannot be clicked."] = "Eine Leiste: Die Symbole reihen sich ab dem ersten Symbol auf und werden zusammen verschoben. Einzelne Symbole: Jedes Symbol laesst sich einzeln verschieben. In beiden Layouts sind sie anklickbar (auch im Kampf) und koennen in der Zauberliste unten eine Taste bekommen. Durch die Filter ausgeblendete Symbole sind nicht klickbar.",
    ["Reset icon positions"] = "Symbol-Positionen zuruecksetzen",
    ["Key per spell: click the key field, then press a key. Right-click clears it. The key replaces its normal function."] = "Taste pro Zauber: Tastenfeld anklicken, dann Taste druecken. Rechtsklick loescht sie. Die Taste ersetzt ihre normale Funktion.",
})

local M = HHT:NewModule("cooldowns", {
    name = "Cooldowns",
    desc = "Cooldown icons for your hunter spells.",
    positions = { main = { "CENTER", "CENTER", 0, -230 } },
    defaults = {
        size = 40, shape = "round", borderSize = 2, borderAlpha = 1, spacing = 6, perRow = 8,
        grow = "right", visibility = "always", numbers = true, desaturate = true, names = false,
        display = "all", layout = "bar", tooltip = false, nextId = 0, usable = true,
        showKeys = true, keySize = 12, keyPos = "TOPRIGHT",
        spells = {},
        colors = {
            ready = { 0.67, 0.83, 0.45 },
            cd = { 0.55, 0.42, 0.20 },
            key = { 1, 1, 0.4 },
        },
    },
})

local DEFAULT_KEYS = {
    "rapidFire", "bestialWrath", "intimidation", "scatterShot", "concussive", "freezingTrap", "frostTrap",
    "explosiveTrap", "immolationTrap", "feignDeath", "deterrence", "disengage", "tranq", "readiness", "distracting",
}

local function DefaultSpells()
    local t = {}
    for _, k in ipairs(DEFAULT_KEYS) do t[#t + 1] = { spec = "@" .. k, on = true } end
    return t
end

function M:OnInit()
    if self.db.spells == nil or (#self.db.spells == 0 and not self.db.spellsInit) then
        self.db.spells = DefaultSpells()
    end
    self.db.spellsInit = true
    self.icons = {}
    self.singles = {}
    self.owner = CreateFrame("Frame")
    self.signature = false
    HHT:Every(self, 0.1, M.Tick)
end

function M:OnReset()
    self.db.spells = DefaultSpells()
    self.db.spellsInit = true
    self.signature = false
    self.bindSig = nil
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsCooldowns", UIParent)
    f:SetSize(40, 40)
    self.frame = f
    HHT:MakeMovable(f, self, "main", L("Cooldowns"))
end

function M:OnEnable()
    self:Build()
    self.frame:Show()
    self.signature = false
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
    self:HideSingles()
end

function M:OnLockChanged()
    self:Tick()
end

function M:Refresh()
    self.signature = false
    local f = self.frame
    if f then
        f:SetSize(self.db.size, self.db.size)
        HHT:ApplyGlobalLook(f)
    end
end

local function GetIcon(self, i)
    local ic = self.icons[i]
    if not ic then
        ic = Icon.New(self.frame)
        self.icons[i] = ic
    end
    return ic
end

function M:Place(ic, idx)
    local db = self.db
    local s, sp = db.size, db.spacing
    local per = math.max(1, db.perRow)
    local step = s + sp
    local along = idx % per
    local across = math.floor(idx / per)
    local f = self.frame
    ic:ClearAllPoints()
    if db.grow == "right" then
        ic:SetPoint("TOPLEFT", f, "TOPLEFT", along * step, -across * step)
    elseif db.grow == "left" then
        ic:SetPoint("TOPRIGHT", f, "TOPRIGHT", -along * step, -across * step)
    elseif db.grow == "down" then
        ic:SetPoint("TOPLEFT", f, "TOPLEFT", across * step, -along * step)
    else
        ic:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", across * step, along * step)
    end
end

-- Action-bar style hint on ready spells: red = out of range, blue = missing resource, dark = not usable.
local function Tint(ic, item, db)
    local r, g, b = 1, 1, 1
    if db.usable and not item.demo and not item.onCd and item.rs.id then
        local usable, noPower = HHT.Spells.Usable(item.rs.id)
        if usable == false then
            if noPower then r, g, b = 0.45, 0.45, 1 else r, g, b = 0.5, 0.5, 0.5 end
        elseif HHT.Spells.InRange(item.rs.id, "target") == false then
            r, g, b = 1, 0.3, 0.3
        end
    end
    ic:SetTint(r, g, b)
end

local function Paint(ic, item, db)
    Tint(ic, item, db)
    ic:SetIcon(item.rs.icon)
    ic.label:SetText(db.names and item.rs.name or "")
    if item.demo then
        ic.cdId = nil
        if item.onCd then
            ic:SetTimer(GetTime() - 8, 30)
            ic:SetDesaturated(db.desaturate)
            ic:SetBorderColor(HHT.Col(db, "cd"))
        else
            ic:ClearCooldown()
            ic:SetDesaturated(false)
            ic:SetBorderColor(HHT.Col(db, "ready"))
        end
    elseif item.onCd then
        ic:ShowCooldown(item.dur)
        ic:SetDesaturated(db.desaturate)
        ic:SetBorderColor(HHT.Col(db, "cd"))
        ic.cdId = item.rs.id
    else
        ic:ClearCooldown()
        ic:SetDesaturated(false)
        ic:SetBorderColor(HHT.Col(db, "ready"))
        if ic.cdId == item.rs.id then ic:Flash() end
        ic.cdId = nil
    end
end

-- ---------------------------------------------------------------------------
-- Individual icons: one movable frame with a secure button per tracked spell (clickable in combat, optional key)
-- ---------------------------------------------------------------------------
-- Default spot of an icon that was never moved: the same grid the bar would use, around the bar's position.
function M:DefaultPos(idx)
    local db = self.db
    local step = db.size + db.spacing
    local per = math.max(1, db.perRow)
    local along, across = idx % per, math.floor(idx / per)
    local dx, dy
    if db.grow == "right" then dx, dy = along * step, -across * step
    elseif db.grow == "left" then dx, dy = -along * step, -across * step
    elseif db.grow == "down" then dx, dy = across * step, -along * step
    else dx, dy = across * step, along * step end
    local base = db.pos and db.pos.main
    if not (base and base[1] == "CENTER" and base[2] == "CENTER") then base = self.positions.main end
    return { "CENTER", "CENTER", base[3] + dx, base[4] + dy }
end

local function IndexOf(list, e)
    for i, x in ipairs(list) do if x == e then return i end end
    return 1
end

-- Bar layout: the icon follows the bar frame, so it takes no mouse for dragging and shows no move outline.
local function SetFollow(s, follow, canMove)
    s.follow = follow
    local h = s.holder
    h.hhtFollow = follow or nil
    local can = (not follow) and canMove and true or false
    h:EnableMouse(can)
    local outline = can and HHT.db.general.outline and true or false
    if h.hhtOutline then h.hhtOutline:SetShown(outline) end
    if h.hhtLabel then h.hhtLabel:SetShown(outline) end
    if not follow then HHT:ApplyPosition(h) end
end

local function MakeSingle(self, e)
    local db = self.db
    local s = {}
    local holder = CreateFrame("Frame", "HamingwaysHunterToolsCooldown" .. e.id, UIParent)
    holder:SetSize(db.size, db.size)
    holder.hhtFollow = (db.layout ~= "single") or nil
    s.follow = db.layout ~= "single"
    s.holder = holder
    s.ic = Icon.New(holder)
    s.ic:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    local btn = CreateFrame("Button", "HamingwaysHunterToolsCooldownBtn" .. e.id, holder, "SecureActionButtonTemplate")
    btn:SetAllPoints(s.ic)
    btn:SetFrameLevel(s.ic.over:GetFrameLevel() + 5)
    btn:RegisterForClicks("AnyUp")
    btn:SetAttribute("useOnKeyDown", false)
    btn:SetAttribute("type1", "macro")
    btn:SetAttribute("macrotext1", "")
    btn:SetScript("OnEnter", function(b)
        local rs = s.rs
        if not (M.db.tooltip and rs and rs.id and GameTooltip) then return end
        GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
        if not (GameTooltip.SetSpellByID and pcall(GameTooltip.SetSpellByID, GameTooltip, rs.id)) then
            GameTooltip:AddLine(rs.name or "", 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    s.btn = btn
    local rs = S.Resolve(e.spec)
    self.positions["s" .. e.id] = self:DefaultPos(IndexOf(db.spells, e) - 1)
    HHT:MakeMovable(holder, self, "s" .. e.id, rs and rs.name or L("Cooldowns"))
    return s
end

local function HideSingle(s)
    if InCombatLockdown() then s.ic:Hide() else s.holder:Hide() end
end

function M:HideSingles()
    for _, s in pairs(self.singles or {}) do HideSingle(s) end
    if not InCombatLockdown() then
        self.singlesHidden = true
        self.signature = false
        self.bindSig = nil
        self:ApplyBindings({})
    end
end

function M:ApplyBindings(list)
    if InCombatLockdown() or not self.owner or not (ClearOverrideBindings and SetOverrideBindingClick) then return end
    ClearOverrideBindings(self.owner)
    for _, b in ipairs(list) do
        if not HHT.BindClick(self.owner, b[1], b[2]) then
            HHT.Print(string.format(L("Key: %s"), b[1]) .. " - " .. L("could not be bound"))
        end
    end
end

function M:Debug()
    local db = self.db
    HHT.Print(string.format("cooldowns layout=%s locked=%s unlocked=%s tooltip=%s showKeys=%s combat=%s",
        tostring(db.layout), tostring(HHT.db.general.locked), tostring(HHT:IsUnlocked(self)), tostring(db.tooltip),
        tostring(db.showKeys), tostring(InCombatLockdown())))
    for _, e in ipairs(db.spells) do
        local s = self.singles[e]
        if e.on and s then
            local b = s.btn
            HHT.Print(string.format("%s key=%s bytes=%s known=%s vis=%s mouse=%s w=%s macro=%s bind=%s", tostring(e.spec),
                tostring(e.key), e.key and table.concat({ e.key:byte(1, -1) }, ".") or "-", tostring(s.rs and s.rs.known),
                tostring(b:IsVisible()), tostring(b:IsMouseEnabled()),
                tostring(b:GetWidth()), tostring(b:GetAttribute("macrotext1")),
                tostring(e.key and e.key ~= "" and GetBindingAction and GetBindingAction(e.key:upper(), true) or "-")))
        end
    end
end

function M:TickSingle(show)
    local db = self.db
    local combat = InCombatLockdown()
    local unlocked = HHT:IsUnlocked(self)
    local canMove = HHT:CanMove(self)
    self.singlesHidden = false
    local bar = db.layout ~= "single"
    local slot = 0
    -- bar layout: unknown spells only show as placeholders while nothing is known yet, so the bar looks the same unlocked and locked
    local anyKnown, demos = false, 0
    if bar then
        for _, e in ipairs(db.spells) do
            if e.on then
                local r = S.Resolve(e.spec)
                if r.known and r.id then anyKnown = true; break end
            end
        end
    end
    local base = table.concat({ db.size, db.shape, db.borderSize, db.borderAlpha, db.numbers and 1 or 0, db.names and 1 or 0,
        db.grow, db.perRow, db.spacing, bar and "b" or "s" }, ",")
    local seen, binds, bindSig = {}, {}, {}
    for idx, e in ipairs(db.spells) do
        if e.on then
            if not e.id then db.nextId = (db.nextId or 0) + 1; e.id = db.nextId end
            local s = self.singles[e]
            if not s and not combat then s = MakeSingle(self, e); self.singles[e] = s end
            if s then
                seen[e] = true
                local rs = S.Resolve(e.spec)
                s.rs = rs
                local item
                if rs.known and rs.id then
                    local onCd, dur = S.CooldownState(rs.id)
                    item = { rs = rs, onCd = onCd, dur = dur }
                elseif unlocked and not (bar and (anyKnown or demos >= 5)) then
                    demos = demos + 1
                    item = {
                        rs = { icon = rs.icon or "Interface\\Icons\\INV_Misc_QuestionMark", name = rs.name or "" },
                        onCd = (idx % 2 == 0), demo = true,
                    }
                end
                local vis = show and item ~= nil
                if vis and not unlocked then
                    if db.display == "cd" then vis = item.onCd == true
                    elseif db.display == "ready" then vis = item.onCd ~= true end
                end
                if vis then slot = slot + 1 end
                if not combat then
                    local sig = base .. ":" .. (bar and 0 or idx)
                    local restyle = s.styleSig ~= sig
                    if restyle then
                        s.styleSig = sig
                        s.holder:SetSize(db.size, db.size)
                        s.ic:Style(db.size, db.shape, db.borderSize, db.borderAlpha, db.numbers)
                        s.ic.label:SetWidth(db.size + 40)
                        s.ic.label:SetShown(db.names)
                    end
                    if s.follow ~= bar then SetFollow(s, bar, canMove) end
                    if bar then
                        if vis and (restyle or s.slot ~= slot) then
                            self:Place(s.holder, slot - 1)
                            s.slot = slot
                        end
                    elseif restyle then
                        self.positions["s" .. e.id] = self:DefaultPos(idx - 1)
                        HHT:ApplyPosition(s.holder)
                    end
                    if s.holder:IsShown() ~= (item ~= nil) then s.holder:SetShown(item ~= nil) end
                    if rs.known and rs.name and rs.name ~= "" and s.macroName ~= rs.name then
                        s.macroName = rs.name
                        s.btn:SetAttribute("macrotext1", "/cast " .. rs.name)
                    end
                    local want = vis and item ~= nil and not item.demo and not canMove
                    if s.mouse ~= want then s.btn:EnableMouse(want); s.mouse = want end
                end
                if item then
                    local key = e.key and e.key ~= "" and e.key:upper() or nil
                    if key then
                        s.ic:SetKey(db.showKeys and key or nil, db.keySize, db.keyPos, HHT.Col(db, "key"))
                    else
                        HHT.Keys.Apply(s.ic, db, item.rs.name)
                    end
                    Paint(s.ic, item, db)
                    if s.ic:IsShown() ~= vis then s.ic:SetShown(vis) end
                    if key and not item.demo then
                        binds[#binds + 1] = { key, s.btn:GetName() }
                        bindSig[#bindSig + 1] = key .. ">" .. e.id
                    end
                elseif s.ic:IsShown() then
                    s.ic:Hide()
                end
            end
        end
    end
    for e, s in pairs(self.singles) do
        if not seen[e] then HideSingle(s) end
    end
    local sig = table.concat(bindSig, ",")
    if not combat and sig ~= self.bindSig then
        self.bindSig = sig
        self:ApplyBindings(binds)
    end
end

function M:Tick()
    local f = self.frame
    if not f then return end
    local db = self.db
    local show = HHT:ShouldShow(db.visibility, self)
    -- bar layout: the bar frame is the first slot and the drag handle, the icons line up from it
    local wantBar = db.layout ~= "single" and show
    if f:IsShown() ~= wantBar then f:SetShown(wantBar) end
    self:TickSingle(show)
end

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------
local ROW_H = 24
local MAX_ROWS = 40

local function BuildSpellList(m, form)
    local db = m.db
    local list = CreateFrame("Frame", nil, form.content)
    list:SetSize(380, 10)
    list.rows = {}

    local addBtn
    local function Changed()
        HHT:RefreshModule(m)
    end

    local function Rebuild()
        local n = #db.spells
        for i = 1, MAX_ROWS do
            local row = list.rows[i]
            if i <= n then
                if not row then
                    row = CreateFrame("Frame", nil, list)
                    row:SetSize(380, ROW_H)
                    row.on = UI.Check(row, "", function() return row.entry and row.entry.on end,
                        function(v) if row.entry then row.entry.on = v and true or false; Changed() end end)
                    row.on:SetPoint("LEFT", row, "LEFT", 0, 0)
                    row.on:SetWidth(18)
                    row.icon = row:CreateTexture(nil, "ARTWORK")
                    row.icon:SetSize(18, 18)
                    row.icon:SetPoint("LEFT", row, "LEFT", 24, 0)
                    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                    HHT.Icon.Attach(row.icon)
                    row.text = UI.Text(row, "", 12)
                    row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
                    row.text:SetWidth(122)
                    row.text:SetJustifyH("LEFT")
                    row.key = UI.Button(row, 76, 20, "", function() end)
                    row.key:SetPoint("LEFT", row, "LEFT", 176, 0)
                    row.key:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                    row.key:SetScript("OnClick", function(_, button)
                        local e = row.entry
                        if not e then return end
                        if button == "RightButton" then
                            e.key = ""
                            m.bindSig = nil
                            list:Refresh(); Changed()
                        elseif HHT.CaptureKey then
                            HHT.CaptureKey(function(key)
                                e.key = key
                                m.bindSig = nil
                                list:Refresh(); Changed()
                            end)
                        end
                    end)
                    row.up = UI.Button(row, 20, 20, "^", function()
                        local idx = row.index
                        if idx > 1 then db.spells[idx], db.spells[idx - 1] = db.spells[idx - 1], db.spells[idx]; list:Refresh(); Changed() end
                    end)
                    row.up:SetPoint("RIGHT", row, "RIGHT", -48, 0)
                    row.down = UI.Button(row, 20, 20, "v", function()
                        local idx = row.index
                        if idx < #db.spells then db.spells[idx], db.spells[idx + 1] = db.spells[idx + 1], db.spells[idx]; list:Refresh(); Changed() end
                    end)
                    row.down:SetPoint("LEFT", row.up, "RIGHT", 2, 0)
                    row.del = UI.Button(row, 20, 20, "x", function()
                        table.remove(db.spells, row.index); list:Refresh(); Changed()
                    end)
                    row.del:SetPoint("LEFT", row.down, "RIGHT", 2, 0)
                    list.rows[i] = row
                end
                row.index = i
                row.entry = db.spells[i]
                local rs = S.Resolve(row.entry.spec)
                row.icon:SetTexture(rs.icon)
                row.icon:SetDesaturated(not rs.known)
                row.text:SetText(rs.name)
                row.key:SetLabel((row.entry.key and row.entry.key ~= "") and row.entry.key:upper() or "-")
                row.text:SetTextColor(rs.known and 0.92 or 0.5, rs.known and 0.94 or 0.5, rs.known and 0.97 or 0.5)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(i - 1) * ROW_H)
                row.on:Refresh()
                row:Show()
            elseif row then
                row:Hide()
            end
        end
        local h = n * ROW_H + 30
        list:SetHeight(h)
        addBtn:ClearAllPoints()
        addBtn:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(n * ROW_H + 6))
        form:SetTail(h)
    end

    addBtn = UI.Button(list, 140, 22, L("Add spell"), function(self)
        local items = S.ListSpellbook()
        UI.ShowMenu(self, items, function(item)
            if #db.spells >= MAX_ROWS then return end
            db.spells[#db.spells + 1] = { spec = item.value, on = true }
            list:Refresh(); Changed()
        end)
    end)

    list.Refresh = Rebuild
    form:PlaceTail(list)
    Rebuild()
    return list
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Stepper(L("Icon size"), db, "size", 20, 96, 2)
    form:Stepper(L("Border size"), db, "borderSize", 0, 4, 1)
    form:Stepper(L("Border alpha"), db, "borderAlpha", 0, 1, 0.1)
    form:Stepper(L("Spacing"), db, "spacing", 0, 30, 1)
    form:Check(L("Show cooldown numbers"), db, "numbers")
    form:Check(L("Grey out icons on cooldown"), db, "desaturate")
    form:Check(L("Show if usable (red = out of range, blue = no resource)"), db, "usable")
    form:Check(L("Show spell names"), db, "names")
    form:Header(L("Behavior"))
    form:Cycle(L("Layout"), db, "layout", {
        { "bar", L("One bar") }, { "single", L("Individual icons") } })
    form:Check(L("Show spell tooltip on mouseover"), db, "tooltip")
    form:Note(L("One bar: icons line up from the first icon and move together. Individual icons: each icon moves on its own. Both: click (also in combat) or give a key in the spell list below. Icons hidden by the filters cannot be clicked."))
    form:Button(L("Reset icon positions"), function()
        if db.pos then
            for k in pairs(db.pos) do
                if type(k) == "string" and k:find("^s%d") then db.pos[k] = nil end
            end
        end
        self.signature = false
        for _, s in pairs(self.singles or {}) do s.styleSig = nil end
    end, 200)
    form:Cycle(L("Show when"), db, "visibility", HHT.VisibilityChoices())
    form:Cycle(L("Icons shown"), db, "display", {
        { "all", L("All spells") }, { "cd", L("Only on cooldown") }, { "ready", L("Only when ready") } })
    form:Cycle(L("Grow direction"), db, "grow", {
        { "right", L("Right") }, { "left", L("Left") }, { "up", L("Up") }, { "down", L("Down") } })
    form:Stepper(L("Icons per row"), db, "perRow", 1, 20, 1)
    HHT.Keys.AddOptions(form, db)
    form:Header(L("Colors"))
    form:Color(L("Ready border"), db.colors, "ready")
    form:Color(L("Cooldown border"), db.colors, "cd")
    form:Header(L("Tracked spells"))
    form:Note(L("Unknown spells are hidden automatically."))
    form:Note(L("Key per spell: click the key field, then press a key. Right-click clears it. The key replaces its normal function."))
    form:Button(L("Restore default list"), function()
        db.spells = DefaultSpells()
        if form.spellList then form.spellList:Refresh() end
        HHT:RefreshModule(M)
    end, 200)
    form.spellList = BuildSpellList(self, form)
end
