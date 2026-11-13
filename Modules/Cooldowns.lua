-- Cooldown bar: user-pickable spells as icons, works in combat (duration objects).
local ADDON, HHT = ...
local L, UI, S, Icon = HHT.L, HHT.UI, HHT.Spells, HHT.Icon

HHT:AddGerman({
    ["Cooldowns"] = "Abklingzeiten",
    ["Cooldown icons for your hunter spells."] = "Abklingzeit-Symbole fuer deine Jaeger-Zauber.",
    ["Show cooldown numbers"] = "Abklingzeit-Zahlen zeigen",
    ["Grey out icons on cooldown"] = "Symbole bei Abklingzeit ausgrauen",
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
})

local M = HHT:NewModule("cooldowns", {
    name = "Cooldowns",
    desc = "Cooldown icons for your hunter spells.",
    positions = { main = { "CENTER", "CENTER", 0, -230 } },
    defaults = {
        size = 40, shape = "round", borderSize = 2, borderAlpha = 1, spacing = 6, perRow = 8,
        grow = "right", visibility = "always", numbers = true, desaturate = true, names = false,
        display = "all",
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
    self.signature = false
    HHT:Every(self, 0.1, M.Tick)
end

function M:OnReset()
    self.db.spells = DefaultSpells()
    self.db.spellsInit = true
    self.signature = false
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

function M:Tick()
    local f = self.frame
    if not f then return end
    local db = self.db
    local show = HHT:ShouldShow(db.visibility, self)
    if f:IsShown() ~= show then f:SetShown(show) end
    if not show then return end

    local used = 0
    local sig = {}
    local list = {}
    for _, e in ipairs(db.spells) do
        if e.on then
            local rs = S.Resolve(e.spec)
            if rs.known and rs.id then
                local onCd, dur = S.CooldownState(rs.id)
                local visible = true
                if db.display == "cd" then visible = (onCd == true)
                elseif db.display == "ready" then visible = (onCd ~= true) end
                if visible then
                    list[#list + 1] = { rs = rs, onCd = onCd, dur = dur }
                    sig[#sig + 1] = rs.id
                end
            end
        end
    end
    if HHT:IsUnlocked(self) and #list == 0 then
        for _, e in ipairs(db.spells) do
            if e.on and #list < 5 then
                local rs = S.Resolve(e.spec)
                list[#list + 1] = {
                    rs = { icon = rs and rs.icon or "Interface\\Icons\\INV_Misc_QuestionMark", name = rs and rs.name or "" },
                    onCd = (#list % 2 == 0), demo = true,
                }
                sig[#sig + 1] = "d" .. #list
            end
        end
    end
    local signature = table.concat(sig, ",")
    local relayout = (signature ~= self.signature)
    self.signature = signature

    for i, item in ipairs(list) do
        local ic = GetIcon(self, i)
        if relayout then
            ic:Style(db.size, db.shape, db.borderSize, db.borderAlpha, db.numbers)
            self:Place(ic, i - 1)
            ic.label:SetShown(db.names)
        end
        ic:SetIcon(item.rs.icon)
        HHT.Keys.Apply(ic, db, item.rs.name)
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
        ic:Show()
        used = i
    end
    for i = used + 1, #self.icons do self.icons[i]:Hide() end
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
                    row.text:SetWidth(190)
                    row.text:SetJustifyH("LEFT")
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
    form:Check(L("Show spell names"), db, "names")
    form:Header(L("Behavior"))
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
    form:Button(L("Restore default list"), function()
        db.spells = DefaultSpells()
        if form.spellList then form.spellList:Refresh() end
        HHT:RefreshModule(M)
    end, 200)
    form.spellList = BuildSpellList(self, form)
end
