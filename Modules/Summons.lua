-- Summon timers: the active summons (e.g. Summon Hawk) that the game keeps in its totem slots, with their remaining time.
local ADDON, HHT = ...
local L, UI, Icon = HHT.L, HHT.UI, HHT.Icon

HHT:AddGerman({
    ["Summons"] = "Beschwoerungen",
    ["Active summons such as Summon Hawk with their remaining time. The default UI shows them under the player frame; they are not buffs."] =
        "Aktive Beschwoerungen wie Habicht beschwoeren mit ihrer Restzeit. Das Standard-UI zeigt sie unter dem Spielerrahmen, sie sind keine Buffs.",
    ["Show names"] = "Namen zeigen",
    ["Border colour"] = "Rahmenfarbe",
    ["Show remaining time numbers"] = "Restzeit-Zahlen zeigen",
})

local M = HHT:NewModule("summons", {
    name = "Summons",
    desc = "Active summons such as Summon Hawk with their remaining time. The default UI shows them under the player frame; they are not buffs.",
    positions = { main = { "CENTER", "CENTER", -200, -140 } },
    defaults = {
        size = 36, shape = "round", borderSize = 2, borderAlpha = 1, spacing = 4,
        grow = "right", visibility = "always", numbers = true, names = false,
        colors = { border = { 0.67, 0.83, 0.45 } },
    },
})
HHT.Summons = M

local MAXS = MAX_TOTEMS or 4
local SAMPLE = "Interface\\Icons\\INV_Misc_QuestionMark"

local function IsSecret(v)
    return issecretvalue and issecretvalue(v) or false
end

local probes = {}

-- A hidden cooldown frame shows itself while the slot's duration runs; its shown state is readable in combat.
local function SlotActive(slot)
    if not GetTotemDuration then return nil end
    local okd, durObj = pcall(GetTotemDuration, slot)
    if not okd then return nil end
    if not durObj then return false end
    local cd = probes[slot]
    if not cd then
        cd = CreateFrame("Cooldown", nil, UIParent, "CooldownFrameTemplate")
        cd:SetSize(2, 2)
        cd:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -400, 400)
        pcall(cd.SetDrawSwipe, cd, false)
        pcall(cd.SetDrawEdge, cd, false)
        pcall(cd.SetDrawBling, cd, false)
        pcall(cd.SetHideCountdownNumbers, cd, true)
        cd:SetAlpha(0)
        probes[slot] = cd
    end
    cd:Clear()
    if not pcall(cd.SetCooldownFromDurationObject, cd, durObj, true) then return nil end
    return HHT.SafeBool(cd.IsShown, cd)
end

-- Returns kind: "empty", "plain" (readable) or "secret" (combat; only widgets may consume the values).
local function ReadSlot(slot)
    local ok, have, name, start, dur, icon = pcall(GetTotemInfo, slot)
    if not ok then return "empty" end
    if IsSecret(have) or IsSecret(dur) or IsSecret(icon) then
        return "secret", { have = have, icon = icon, slot = slot, active = SlotActive(slot) }
    end
    if not have or type(dur) ~= "number" or dur <= 0 then return "empty" end
    return "plain", { name = name, start = start, dur = dur, icon = icon }
end

function M:OnInit()
    self.icons = {}
    self.styled = false
    self.order = {}
    HHT:Every(self, 0.2, M.Tick)
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsSummons", UIParent)
    f:SetSize(36, 36)
    self.frame = f
    HHT:MakeMovable(f, self, "main", L("Summons"))
end

function M:OnEnable()
    self:Build()
    self.frame:Show()
    self.styled = false
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
end

function M:Refresh()
    self.styled = false
    local f = self.frame
    if f then
        f:SetSize(self.db.size, self.db.size)
        HHT:ApplyGlobalLook(f)
    end
end

function M:OnLockChanged() self.styled = false end

function M:Place(ic, idx)
    local db = self.db
    local step = db.size + db.spacing
    local f = self.frame
    ic:ClearAllPoints()
    if db.grow == "right" then
        ic:SetPoint("TOPLEFT", f, "TOPLEFT", idx * step, 0)
    elseif db.grow == "left" then
        ic:SetPoint("TOPRIGHT", f, "TOPRIGHT", -idx * step, 0)
    elseif db.grow == "down" then
        ic:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -idx * step)
    else
        ic:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, idx * step)
    end
end

function M:Tick()
    local f = self.frame
    if not f then return end
    local db = self.db
    local show = HHT:ShouldShow(db.visibility)
    if f:IsShown() ~= show then f:SetShown(show) end
    if not show then return end

    local list = {}
    local secretMode = false
    local bySlot, plain = {}, {}
    for slot = 1, MAXS do
        local kind, r = ReadSlot(slot)
        if kind == "secret" then
            secretMode = true
            bySlot[slot] = r
        elseif kind == "plain" then
            r.idx = slot
            plain[#plain + 1] = r
        end
    end
    if secretMode then
        -- occupied slots keep their spawn order; a slot with unknown state stays in, the engine hides it while empty
        local seen, order = {}, {}
        for _, s in ipairs(self.order) do
            local r = bySlot[s]
            if r and r.active ~= false and not seen[s] then seen[s] = true; order[#order + 1] = s end
        end
        for s = 1, MAXS do
            local r = bySlot[s]
            if r and r.active ~= false and not seen[s] then order[#order + 1] = s end
        end
        self.order = order
        for _, s in ipairs(order) do list[#list + 1] = bySlot[s] end
    else
        table.sort(plain, function(a, b) return a.start < b.start end)
        list = plain
        self.order = {}
        for _, r in ipairs(plain) do self.order[#self.order + 1] = r.idx end
    end
    if #list == 0 and HHT:IsUnlocked() then
        list[1] = { name = L("Summons"), icon = SAMPLE }
    end

    local restyle = not self.styled
    self.styled = true
    for i, item in ipairs(list) do
        local ic = self.icons[i]
        if not ic then
            ic = Icon.New(f)
            self.icons[i] = ic
            restyle = true
        end
        if restyle then
            ic:Style(db.size, db.shape, db.borderSize, db.borderAlpha, db.numbers)
            ic:SetBorderColor(HHT.Col(db, "border"))
            ic.hhtPos = nil
        end
        local pos = i - 1
        if ic.hhtPos ~= pos then self:Place(ic, pos); ic.hhtPos = pos end
        ic:SetIcon(item.icon)
        if item.slot then
            -- the engine hides empty slots and runs the timer from the duration object
            pcall(ic.SetAlphaFromBoolean, ic, item.have, 1, 0)
            ic.label:SetText("")
            local okd, durObj = pcall(GetTotemDuration, item.slot)
            if okd and durObj then ic:ShowCooldown(durObj) else ic:ClearCooldown() end
        else
            ic:SetAlpha(1)
            ic.label:SetText(db.names and item.name or "")
            if item.start then
                pcall(ic.SetTimer, ic, item.start, item.dur)
            else
                ic:ClearCooldown()
            end
        end
        ic:Show()
    end
    for i = #list + 1, #self.icons do self.icons[i]:Hide() end
end

-- /hht totems
function M:Debug()
    if not GetTotemInfo then HHT.Print("summons: GetTotemInfo does not exist in this client"); return end
    local n = 0
    for slot = 1, MAXS do
        local kind, r = ReadSlot(slot)
        if kind == "secret" then
            n = n + 1
            local okd, d = pcall(GetTotemDuration, slot)
            HHT.Print(string.format("slot %d: values are secret (combat), active=%s, GetTotemDuration ok=%s obj=%s", slot, tostring(r.active), tostring(okd), tostring(d ~= nil)))
        elseif kind == "plain" then
            n = n + 1
            HHT.Print(string.format("slot %d: %s  start=%s dur=%s icon=%s", slot, tostring(r.name), tostring(r.start), tostring(r.dur), tostring(r.icon)))
        end
    end
    if n == 0 then HHT.Print("summons: no active summon in the totem slots (max " .. MAXS .. ")") end
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Appearance"))
    form:Cycle(L("Icon shape"), db, "shape", HHT.ShapeChoices())
    form:Stepper(L("Icon size"), db, "size", 20, 96, 2)
    form:Stepper(L("Border size"), db, "borderSize", 0, 4, 1)
    form:Stepper(L("Spacing"), db, "spacing", 0, 30, 1)
    form:Check(L("Show remaining time numbers"), db, "numbers")
    form:Check(L("Show names"), db, "names")
    form:Color(L("Border colour"), db.colors, "border")
    form:Header(L("Behavior"))
    form:Cycle(L("Show when"), db, "visibility", HHT.VisibilityChoices())
    form:Cycle(L("Grow direction"), db, "grow", {
        { "right", L("Right") }, { "left", L("Left") }, { "up", L("Up") }, { "down", L("Down") } })
end
