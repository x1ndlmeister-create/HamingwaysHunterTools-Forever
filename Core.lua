-- Hamingway's HunterTools (WoW Forever). Core: namespace, saved variables, module registry, shared helpers.
local ADDON, HHT = ...
_G.HamingwaysHunterTools = HHT

local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
HHT.version = (GetMeta and GetMeta(ADDON, "Version")) or "?"
HHT.modules = {}
HHT.moduleList = {}
HHT.movables = {}

local pcall, type, pairs, ipairs, tostring, tonumber = pcall, type, pairs, ipairs, tostring, tonumber
local GetTime = GetTime

local PREFIX = "|cffabd473Hamingway's HunterTools|r: "
function HHT.Print(msg) print(PREFIX .. tostring(msg)) end

-- ---------------------------------------------------------------------------
-- Secret value safety
-- ---------------------------------------------------------------------------
function HHT.IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v) == true
end
local IsSecret = HHT.IsSecret

-- Calls fn(...) and returns true/false only when the result is a readable boolean.
function HHT.SafeBool(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, r = pcall(fn, ...)
    if not ok or IsSecret(r) or r == nil then return nil end
    if r == true or r == 1 then return true end
    if r == false or r == 0 then return false end
    return nil
end

function HHT.SafeNumber(v)
    if IsSecret(v) or type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return nil end
    return v
end

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = DeepCopy(v) end
    return c
end
HHT.DeepCopy = DeepCopy

-- Fills missing keys. Arrays (tables with [1]) are treated as values and never merged.
local function Fill(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = DeepCopy(v)
        elseif type(v) == "table" and type(dst[k]) == "table" and v[1] == nil then
            Fill(dst[k], v)
        end
    end
end
HHT.Fill = Fill

function HHT.Col(tbl, key)
    local c = tbl.colors and tbl.colors[key]
    if not c then return 1, 1, 1 end
    return c[1], c[2], c[3]
end

-- Border glow: 2 px of reach per strength step, one stacked layer per pixel. The brightness falls off
-- quadratically, so the layers blend into a smooth fade instead of visible steps.
HHT.GLOW_MAX = 16
function HHT.GlowLayers()
    local g = HHT.db and HHT.db.general
    return math.max(2, math.min(HHT.GLOW_MAX, 2 * (g and g.borderGlowSize or 4)))
end

function HHT.GlowAlpha(i, n)
    local function f(k) return k > n and 0 or 0.65 * (1 - (k - 1) / n) ^ 2 end
    return f(i) - f(i + 1)
end

-- Changes when the general glow is switched or resized; icon modules that restyle only on a changed signature include it.
function HHT.GlowSig()
    local g = HHT.db and HHT.db.general
    return g and g.borderGlow and HHT.GlowLayers() or 0
end

-- Glow of a rectangular element: eight pieces of one soft-edged texture (four corners, four edges) that fade
-- out smoothly at any UI scale. The glow starts at `inner` pixels outside the element and reaches `reach` further.
local GLOW_TEX = "Interface\\AddOns\\" .. ADDON .. "\\Media\\GlowBox"
local GLOW_UV = {
    { 0, 0.5, 0, 0.5 }, { 0.5, 1, 0, 0.5 }, { 0, 0.5, 0.5, 1 }, { 0.5, 1, 0.5, 1 },
    { 0.484, 0.516, 0, 0.5 }, { 0.484, 0.516, 0.5, 1 }, { 0, 0.5, 0.484, 0.516 }, { 0.5, 1, 0.484, 0.516 },
}

function HHT.NewGlowBox(frame, layer)
    local box = {}
    for i, uv in ipairs(GLOW_UV) do
        local t = frame:CreateTexture(nil, layer or "BACKGROUND", nil, -8)
        t:SetTexture(GLOW_TEX)
        t:SetTexCoord(uv[1], uv[2], uv[3], uv[4])
        t:Hide()
        box[i] = t
    end
    return box
end

function HHT.PlaceGlowBox(box, f, inner, reach)
    local o, e = inner, inner + reach
    local function Put(i, p1, r1, x1, y1, p2, r2, x2, y2)
        local t = box[i]
        t:ClearAllPoints()
        t:SetPoint(p1, f, r1, x1, y1)
        t:SetPoint(p2, f, r2, x2, y2)
    end
    Put(1, "TOPLEFT", "TOPLEFT", -e, e, "BOTTOMRIGHT", "TOPLEFT", -o, o)
    Put(2, "TOPLEFT", "TOPRIGHT", o, e, "BOTTOMRIGHT", "TOPRIGHT", e, o)
    Put(3, "TOPLEFT", "BOTTOMLEFT", -e, -o, "BOTTOMRIGHT", "BOTTOMLEFT", -o, -e)
    Put(4, "TOPLEFT", "BOTTOMRIGHT", o, -o, "BOTTOMRIGHT", "BOTTOMRIGHT", e, -e)
    Put(5, "TOPLEFT", "TOPLEFT", -o, e, "BOTTOMRIGHT", "TOPRIGHT", o, o)
    Put(6, "TOPLEFT", "BOTTOMLEFT", -o, -o, "BOTTOMRIGHT", "BOTTOMRIGHT", o, -e)
    Put(7, "TOPLEFT", "TOPLEFT", -e, o, "BOTTOMRIGHT", "BOTTOMLEFT", -o, -o)
    Put(8, "TOPLEFT", "TOPRIGHT", o, o, "BOTTOMRIGHT", "BOTTOMRIGHT", e, -o)
end

function HHT.ShowGlowBox(box, on, r, g, b)
    for i = 1, #box do
        box[i]:SetVertexColor(r, g, b, 0.65)
        box[i]:SetShown(on and true or false)
    end
end

-- Glow of a pill shaped element (rounded bar): a half disk at each end plus soft strips on top and bottom.
-- The end pieces come in steps of 5 % of inner to outer radius; the piece is sized so the inner radius stays exact.
local PILL_TEX = "Interface\\AddOns\\" .. ADDON .. "\\Media\\RoundGlow"

function HHT.NewGlowPill(frame, layer)
    local pill = {}
    for i = 1, 4 do
        local t = frame:CreateTexture(nil, layer or "BACKGROUND", nil, -8)
        t:Hide()
        pill[i] = t
    end
    pill[1]:SetTexCoord(0, 0.5, 0, 1)
    pill[2]:SetTexCoord(0.5, 1, 0, 1)
    pill[3]:SetTexture(GLOW_TEX)
    pill[3]:SetTexCoord(0.484, 0.516, 0, 0.5)
    pill[4]:SetTexture(GLOW_TEX)
    pill[4]:SetTexCoord(0.484, 0.516, 0.5, 1)
    return pill
end

-- inner: distance from the pill to the start of the glow (the border), reach: how far it extends, h: pill height
function HHT.PlaceGlowPill(pill, f, inner, reach, h)
    local r = h / 2
    local q = math.max(0.10, math.min(0.95, math.floor((r + inner) / (r + inner + reach) * 20 + 0.5) / 20))
    local e = (r + inner) / q - r
    local file = PILL_TEX .. math.floor(q * 100 + 0.5)
    pill[1]:SetTexture(file)
    pill[2]:SetTexture(file)
    local function Put(i, p1, r1, x1, y1, p2, r2, x2, y2)
        local t = pill[i]
        t:ClearAllPoints()
        t:SetPoint(p1, f, r1, x1, y1)
        t:SetPoint(p2, f, r2, x2, y2)
    end
    Put(1, "TOPLEFT", "TOPLEFT", -e, e, "BOTTOMRIGHT", "BOTTOMLEFT", r, -e)
    Put(2, "TOPLEFT", "TOPRIGHT", -r, e, "BOTTOMRIGHT", "BOTTOMRIGHT", e, -e)
    Put(3, "TOPLEFT", "TOPLEFT", r, e, "BOTTOMRIGHT", "TOPRIGHT", -r, inner)
    Put(4, "TOPLEFT", "BOTTOMLEFT", r, -inner, "BOTTOMRIGHT", "BOTTOMRIGHT", -r, -e)
end

function HHT.ShowGlowPill(pill, on, r, g, b)
    for i = 1, #pill do
        pill[i]:SetVertexColor(r, g, b, 0.65)
        pill[i]:SetShown(on and true or false)
    end
end

-- ---------------------------------------------------------------------------
-- Defaults
-- ---------------------------------------------------------------------------
-- Defaults
-- ---------------------------------------------------------------------------
local GENERAL_DEFAULTS = {
    locked = true,
    outline = true,
    lang = "auto",
    minimap = true,
    minimapAngle = 215,
    versionNotice = true,
    whatsNew = true,
    scale = 1.0,
    alpha = 1.0,
    theme = "classic",
    style = "flat",
    borderGlow = false,
    borderGlowSize = 4,
    snap = true,
    preview = true,
}

-- Module defaults plus the keys every module shares.
local function ModuleDefaults(m)
    local d = DeepCopy(m.defaults or {})
    if d.enabled == nil then d.enabled = (m.enabledByDefault ~= false) end
    if d.scale == nil then d.scale = 1.0 end
    if d.alpha == nil then d.alpha = 1.0 end
    if d.showWhen == nil then d.showWhen = "always" end
    if d.textStyle == nil then d.textStyle = "outline" end
    return d
end

-- Text flags for fonts inside a module frame: the module's text style (outline, thick outline, plain).
function HHT.TextFlags(owner)
    local f, n = owner, 0
    while f and n < 10 do
        local info = f.hht
        if info then
            local s = info.module.db and info.module.db.textStyle
            if s == "thick" then return "THICKOUTLINE" elseif s == "plain" then return "" end
            return "OUTLINE"
        end
        f = f.GetParent and f:GetParent() or nil
        n = n + 1
    end
    return "OUTLINE"
end

function HHT.StyleFont(fs, size, owner)
    local flags = HHT.TextFlags(owner)
    local font = HHT.UI.FONT
    if fs:SetFont(font, size, flags) == false then fs:SetFont(STANDARD_TEXT_FONT, size, flags) end
    if flags == "" then
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.9)
    else
        fs:SetShadowOffset(0, 0)
    end
end

-- ---------------------------------------------------------------------------
-- Modules
-- ---------------------------------------------------------------------------
-- def: name, desc, defaults, positions = { main = {point, relPoint, x, y} },
--      OnInit(m), OnEnable(m), OnDisable(m), Refresh(m), BuildOptions(m, form)
function HHT:NewModule(key, def)
    local m = { key = key, enabled = false }
    for k, v in pairs(def) do m[k] = v end
    self.modules[key] = m
    self.moduleList[#self.moduleList + 1] = key
    return m
end

function HHT:EachModule(fn)
    for _, key in ipairs(self.moduleList) do fn(self.modules[key]) end
end

function HHT:SetEnabled(m, on)
    on = (on and not m.wip) and true or false
    m.db.enabled = on
    if on and not m.enabled then
        m.enabled = true
        if m.OnEnable then m:OnEnable() end
        if m.Refresh then m:Refresh() end
    elseif not on and m.enabled then
        m.enabled = false
        if m.OnDisable then m:OnDisable() end
    end
end

function HHT:RefreshModule(m)
    if m.enabled and m.Refresh then m:Refresh() end
end

function HHT:RefreshAll()
    self:EachModule(function(m) self:RefreshModule(m) end)
end

function HHT:ResetModule(m)
    local wasOn = m.enabled
    if wasOn then self:SetEnabled(m, false) end
    local fresh = ModuleDefaults(m)
    self.db.mods[m.key] = fresh
    m.db = fresh
    if m.OnReset then m:OnReset() end
    if wasOn then self:SetEnabled(m, true) end
    self:ApplyAllPositions()
end

-- ---------------------------------------------------------------------------
-- Events (one shared frame, modules only receive events while enabled)
-- ---------------------------------------------------------------------------
local evFrame = CreateFrame("Frame")
HHT.handlers = {}

function HHT:Listen(m, event, fn)
    local list = self.handlers[event]
    if not list then
        list = {}
        self.handlers[event] = list
        pcall(evFrame.RegisterEvent, evFrame, event)
    end
    list[#list + 1] = { m, fn }
end

evFrame:SetScript("OnEvent", function(_, event, ...)
    local list = HHT.handlers[event]
    if not list then return end
    for i = 1, #list do
        local h = list[i]
        local m, fn = h[1], h[2]
        if m.enabled then
            if type(fn) == "string" then fn = m[fn] end
            if fn then fn(m, event, ...) end
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Movable frames
-- ---------------------------------------------------------------------------
-- Modules the user switched off in the move-set popup stay put while the frames are unlocked.
function HHT:InMoveSet(m)
    local g = self.db and self.db.general
    local skip = g and g.moveSkip
    return not (m and skip and skip[m.key])
end

-- With a module argument it also answers true while that module is previewed or unlocked from its settings page.
function HHT:IsUnlocked(m)
    local g = self.db and self.db.general
    if not g then return g end
    if g.locked == false and self:InMoveSet(m) then return true end
    if m ~= nil and self.showcase and self.showcase[m.key] then return true end
    return m ~= nil and (m == self.previewModule or m.moveUnlock == true)
end

-- Frames may be dragged when everything is unlocked or when this module was unlocked on its own.
function HHT:CanMove(m)
    local g = self.db and self.db.general
    if not g then return false end
    return (g.locked == false and self:InMoveSet(m)) or (m ~= nil and m.moveUnlock == true)
end

-- Shows one module in demo mode (nil ends it). Used while its settings page is open.
function HHT:SetPreview(m)
    local old = self.previewModule
    if old == m then return end
    self.previewModule = m
    for _, x in ipairs({ old or false, m or false }) do
        if x and x.enabled and x.OnLockChanged then x:OnLockChanged(self:IsUnlocked(x)) end
    end
    self:ApplyAllLooks()
end

function HHT:ApplyPosition(frame)
    local info = frame.hht
    if not info or frame.hhtFollow then return end
    local m = info.module
    local pos = m.db.pos and m.db.pos[info.key]
    if not pos then
        local d = m.positions and m.positions[info.key] or { "CENTER", "CENTER", 0, 0 }
        pos = d
    end
    -- Frames holding secure buttons cannot be moved in combat; the position is applied again later.
    if InCombatLockdown() and frame:IsProtected() then
        self.lookPending = true
        return
    end
    frame:ClearAllPoints()
    frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

function HHT:ApplyAllPositions()
    for _, f in ipairs(self.movables) do self:ApplyPosition(f) end
end

function HHT:ApplyLock()
    local outline = self.db.general.outline
    local combat = InCombatLockdown()
    for _, f in ipairs(self.movables) do
        local can = not f.hhtFollow and self:CanMove(f.hht and f.hht.module) and true or false
        if combat and f:IsProtected() then
            self.lockPending = true
        else
            f:EnableMouse(can)
        end
        if f.hhtOutline then f.hhtOutline:SetShown(can and outline and true or false) end
        if f.hhtLabel then f.hhtLabel:SetShown(can and outline and true or false) end
    end
    self:EachModule(function(m)
        if m.enabled and m.OnLockChanged then m:OnLockChanged(self:IsUnlocked(m)) end
    end)
    self:ApplyAllLooks()
end

-- Moving frames and previews end when combat starts, so nothing stays behind on screen.
function HHT:LockForCombat()
    local g = self.db and self.db.general
    if not g then return end
    local was = g.locked == false or self.previewModule ~= nil
    self:EachModule(function(m)
        if m.moveUnlock then was = true; m.moveUnlock = nil end
    end)
    if not was then return end
    g.locked = true
    self.previewModule = nil
    self:ApplyLock()
    self.Print(self.L("Frames locked because combat started."))
end

function HHT:SetLocked(locked)
    self.db.general.locked = locked and true or false
    if locked then
        self:EachModule(function(m) m.moveUnlock = nil end)
    end
    self:ApplyLock()
    self.Print(locked and self.L("Frames locked.") or self.L("Frames are unlocked. Drag them with the left mouse button."))
end

function HHT:ApplyGlobalLook(frame)
    local g = self.db.general
    local info = frame.hht
    local ms = info and info.module.db.scale or 1
    local ma = info and info.module.db.alpha or 1
    local mod = info and info.module
    local hidden = frame.hhtFaded or (mod and mod.db.visibility == nil and not self:ShouldShow(mod.db.showWhen, mod))
    local scale = (g.scale or 1) * ms
    -- Scaling a frame with secure buttons is blocked in combat; it is applied once combat ends.
    if not (InCombatLockdown() and frame:IsProtected()) and frame:GetScale() ~= scale then
        local old = frame.hhtScaled
        frame:SetScale(scale)
        frame.hhtScaled = scale
        if self.Bar then self.Bar.ResnapAll() end
        if old and old ~= scale and info and not frame.hhtFollow then
            -- Offsets are measured in the frame's own scale, so they are converted to keep the frame where it is.
            local m = info.module
            local pos = m.db.pos and m.db.pos[info.key] or (m.positions and m.positions[info.key]) or { "CENTER", "CENTER", 0, 0 }
            m.db.pos = m.db.pos or {}
            m.db.pos[info.key] = { pos[1], pos[2], pos[3] * old / scale, pos[4] * old / scale }
            self:ApplyPosition(frame)
        end
    end
    frame.hhtScaled = frame.hhtScaled or scale
    if mod and mod.ownAlpha and not hidden then
        -- The module sets its own alpha from its tick; a full alpha here would flash it until the next tick.
        if mod.bar then mod:Tick() else frame:SetAlpha(0) end
        return
    end
    frame:SetAlpha(hidden and 0 or (g.alpha or 1) * ma)
end

function HHT:ApplyAllLooks()
    for _, f in ipairs(self.movables) do self:ApplyGlobalLook(f) end
end

-- Snapping while dragging: edges, centres and icon centres of the other frames, in UIParent units.
local SNAP_RANGE = 8

local function AddSnapPoints(f, xs, ys)
    local ui = UIParent:GetEffectiveScale()
    local Num = HHT.SafeNumber
    -- Frame geometry can be a secret value (secure children); such frames are skipped.
    local function One(r, pad)
        local gx, gy = r:GetCenter()
        local cx, cy = Num(gx), Num(gy)
        local k = Num(r:GetEffectiveScale())
        local w, h = Num(r:GetWidth()), Num(r:GetHeight())
        if not (cx and cy and k and w and h) then return false end
        k = k / ui
        cx, cy = cx * k, cy * k
        if pad then
            local hw, hh = w * k / 2, h * k / 2
            xs[#xs + 1] = cx - hw; xs[#xs + 1] = cx + hw
            ys[#ys + 1] = cy - hh; ys[#ys + 1] = cy + hh
        end
        xs[#xs + 1] = cx
        ys[#ys + 1] = cy
        return true
    end
    One(f, true)
    for _, c in ipairs({ f:GetChildren() }) do
        local w = Num(c:GetWidth())
        if w and w >= 10 and w <= 80 and c:IsShown() then One(c, false) end
    end
end

local function SnapGuide()
    local g = HHT.snapGuide
    if g then return g end
    g = CreateFrame("Frame", nil, UIParent)
    g:SetAllPoints(UIParent)
    g:SetFrameStrata("TOOLTIP")
    g:Hide()
    g.v = g:CreateTexture(nil, "OVERLAY")
    g.v:SetColorTexture(0.67, 0.83, 0.45, 0.85)
    g.v:SetWidth(1)
    g.h = g:CreateTexture(nil, "OVERLAY")
    g.h:SetColorTexture(0.67, 0.83, 0.45, 0.85)
    g.h:SetHeight(1)
    HHT.snapGuide = g
    return g
end

local function DragUpdate(driver)
    local frame, d = driver.frame, driver.data
    local s = UIParent:GetEffectiveScale()
    local mx, my = GetCursorPosition()
    local cx, cy = mx / s - d.gx, my / s - d.gy
    local lineX, lineY
    if HHT.db.general.snap ~= false and not IsShiftKeyDown() then
        local bx, by = SNAP_RANGE, SNAP_RANGE
        local dx, dy
        for _, o in ipairs(d.ox) do
            for _, t in ipairs(d.tx) do
                local diff = t - (cx + o)
                if math.abs(diff) < bx then bx, dx, lineX = math.abs(diff), diff, t end
            end
        end
        for _, o in ipairs(d.oy) do
            for _, t in ipairs(d.ty) do
                local diff = t - (cy + o)
                if math.abs(diff) < by then by, dy, lineY = math.abs(diff), diff, t end
            end
        end
        if dx then cx = cx + dx end
        if dy then cy = cy + dy end
    end
    local ux, uy = UIParent:GetCenter()
    local k = frame:GetEffectiveScale() / s
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", (cx - ux) / k, (cy - uy) / k)
    local g = SnapGuide()
    g.v:ClearAllPoints()
    g.h:ClearAllPoints()
    g.v:SetShown(lineX ~= nil)
    g.h:SetShown(lineY ~= nil)
    if lineX then
        g.v:SetPoint("TOPLEFT", UIParent, "TOPLEFT", lineX, 0)
        g.v:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", lineX, 0)
    end
    if lineY then
        g.h:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, lineY)
        g.h:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, lineY)
    end
    g:Show()
end

function HHT:BeginDrag(frame)
    local s = UIParent:GetEffectiveScale()
    local cx, cy = frame:GetCenter()
    local k = HHT.SafeNumber(frame:GetEffectiveScale())
    if not (HHT.SafeNumber(cx) and HHT.SafeNumber(cy) and k) then
        frame:StartMoving()
        return
    end
    k = k / s
    cx, cy = cx * k, cy * k
    local mx, my = GetCursorPosition()
    local d = { gx = mx / s - cx, gy = my / s - cy, ox = {}, oy = {}, tx = {}, ty = {} }
    AddSnapPoints(frame, d.ox, d.oy)
    for i, v in ipairs(d.ox) do d.ox[i] = v - cx end
    for i, v in ipairs(d.oy) do d.oy[i] = v - cy end
    local ux, uy = UIParent:GetCenter()
    d.tx[1], d.ty[1] = ux, uy
    for _, f in ipairs(self.movables) do
        if f ~= frame and f:IsVisible() and (HHT.SafeNumber(f:GetAlpha()) or 0) > 0 then AddSnapPoints(f, d.tx, d.ty) end
    end
    local driver = self.dragDriver
    if not driver then
        driver = CreateFrame("Frame")
        self.dragDriver = driver
    end
    driver.frame, driver.data = frame, d
    driver:SetScript("OnUpdate", DragUpdate)
end

function HHT:EndDrag()
    local driver = self.dragDriver
    if driver then
        driver:SetScript("OnUpdate", nil)
        driver.frame, driver.data = nil, nil
    end
    if self.snapGuide then self.snapGuide:Hide() end
end

-- Registers frame as draggable. label = shown while unlocked.
function HHT:MakeMovable(frame, m, key, label)
    frame.hht = { module = m, key = key or "main", label = label }
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if HHT:CanMove(m) then HHT:BeginDrag(self) end
    end)
    frame:SetScript("OnDragStop", function(self)
        HHT:EndDrag()
        self:StopMovingOrSizing()
        if not self.hht then return end
        local p, _, rp, x, y = self:GetPoint(1)
        if not p then return end
        m.db.pos = m.db.pos or {}
        m.db.pos[self.hht.key] = { p, rp, math.floor(x + 0.5), math.floor(y + 0.5) }
    end)

    local o = CreateFrame("Frame", nil, frame)
    o:SetAllPoints(frame)
    o:SetFrameLevel(frame:GetFrameLevel() + 20)
    self.UI.Border(o, 0.67, 0.83, 0.45, 0.9)
    o:Hide()
    frame.hhtOutline = o
    local fs = self.UI.Text(o, label or m.name or "", 10, 0.67, 0.83, 0.45)
    fs:SetPoint("BOTTOM", o, "TOP", 0, 2)
    frame.hhtLabel = fs
    fs:Hide()

    self.movables[#self.movables + 1] = frame
    self:ApplyPosition(frame)
    self:ApplyGlobalLook(frame)
    local can = not frame.hhtFollow and self:CanMove(m) and true or false
    frame:EnableMouse(can)
    o:SetShown(can and self.db.general.outline and true or false)
    fs:SetShown(can and self.db.general.outline and true or false)
end

-- ---------------------------------------------------------------------------
-- Visibility rules shared by modules
-- ---------------------------------------------------------------------------
function HHT.HasAttackableTarget()
    if not UnitExists("target") then return false end
    if UnitIsDead("target") then return false end
    local ok, r = pcall(UnitCanAttack, "player", "target")
    return ok and r == true
end

-- Keys that are named differently for bindings than the name the key press reports (German layout).
local KEY_ALIASES = { ["Ü"] = "[", ["Ö"] = ";", ["Ä"] = "'", ["ß"] = "-", ["´"] = "=", ["^"] = "`", ["#"] = "\\", ["+"] = "]" }

local KEY_LOWER = { ["Ü"] = "ü", ["Ö"] = "ö", ["Ä"] = "ä" }

-- Binds a key to click a button. The game accepts the reported name of some keys without ever firing it, so the
-- lowercase umlaut the game reports and the US alias are bound as well. Returns true when at least one name is bound.
function HHT.BindClick(owner, key, button, prefix)
    prefix = prefix or ""
    local tries = { key }
    if KEY_LOWER[key] then tries[#tries + 1] = KEY_LOWER[key] end
    if KEY_ALIASES[key] then tries[#tries + 1] = KEY_ALIASES[key] end
    local bound = false
    for _, k in ipairs(tries) do
        pcall(SetOverrideBindingClick, owner, true, prefix .. k, button, "LeftButton")
        local act = GetBindingAction and GetBindingAction(prefix .. k, true)
        if act == nil or act ~= "" then bound = true end
    end
    return bound
end

-- /hht key: shows what the game reports for a pressed key and which binding names it accepts.
function HHT.KeyTest()
    if HHT.InCombat() then return end
    local f = HHT.keyTestFrame
    if not f then
        f = CreateFrame("Frame", nil, UIParent)
        f:SetSize(1, 1)
        f:SetPoint("CENTER")
        f:EnableKeyboard(true)
        f.btn = CreateFrame("Button", "HamingwaysHunterToolsKeyTestBtn", UIParent, "SecureActionButtonTemplate")
        f:SetScript("OnKeyDown", function(self, key)
            if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then return end
            self:Hide()
            local bytes = {}
            for i = 1, #key do bytes[#bytes + 1] = string.byte(key, i) end
            HHT.Print("key=[" .. key .. "] len=" .. #key .. " bytes=" .. table.concat(bytes, ","))
            local seen, list = {}, { key, key:upper(), key:lower() }
            for _, a in pairs(KEY_ALIASES) do list[#list + 1] = a end
            for _, k in ipairs(list) do
                if not seen[k] then
                    seen[k] = true
                    local ok, err = pcall(SetOverrideBindingClick, self.btn, true, k, "HamingwaysHunterToolsKeyTestBtn", "LeftButton")
                    local act = GetBindingAction and GetBindingAction(k, true)
                    HHT.Print("try [" .. k .. "] ok=" .. tostring(ok) .. " action=[" .. tostring(act) .. "]" .. (err and (" err=" .. tostring(err)) or ""))
                end
            end
            ClearOverrideBindings(self.btn)
        end)
        HHT.keyTestFrame = f
    end
    f:Show()
    HHT.Print("Press a key (test)")
end

function HHT.InCombat()
    return UnitAffectingCombat("player") and true or false
end

-- Frames with secure buttons cannot be hidden in combat: fade them and finish with FlushHidden afterwards.
function HHT.HideSecure(f)
    if InCombatLockdown() then f:SetAlpha(0); f.hhtFaded = true else f:Hide() end
end

function HHT.ShowSecure(f)
    f:SetAlpha(1)
    f.hhtFaded = nil
    f:Show()
end

function HHT.FlushHidden(f)
    if f and f.hhtFaded and not InCombatLockdown() then
        f:Hide()
        f:SetAlpha(1)
        f.hhtFaded = nil
    end
end

function HHT:ShouldShow(mode, m)
    if self:IsUnlocked(m) then return true end
    if mode == "always" then return true end
    if mode == "combat" then return self.InCombat() end
    if mode == "target" then return self.HasAttackableTarget() end
    if mode == "combattarget" then return self.InCombat() or self.HasAttackableTarget() end
    return true
end

function HHT.VisibilityChoices()
    local L = HHT.L
    return {
        { "always", L("Always") },
        { "combat", L("In combat") },
        { "target", L("With target") },
        { "combattarget", L("Combat or target") },
    }
end

function HHT.ShapeChoices()
    local L = HHT.L
    return { { "square", L("Square") }, { "round", L("Round") } }
end

-- Look settings that most modules share (icon shape, border, bar texture). Reading gives the value most modules
-- use; writing sets it in every module that has the setting, whatever it was before.
local LOOK_DEFAULT = { shape = "round", borderSize = 2, borderAlpha = 1, barTexture = "blizzard", barShape = "square", bevel = 0.6 }

function HHT:GetLook(key)
    local counts, best, bestN = {}, nil, 0
    for _, k in ipairs(self.moduleList) do
        local v = self.modules[k].db[key]
        if v ~= nil then
            counts[v] = (counts[v] or 0) + 1
            if counts[v] > bestN then best, bestN = v, counts[v] end
        end
    end
    if best == nil then return LOOK_DEFAULT[key] end
    return best
end

-- Border colour: the plain border colour keys ("edge" for bars, "border" for icons) of modules that have a border.
-- Colours that carry a meaning (cooldown ready or not, warning, ammo low ...) are left alone.
local BORDER_KEYS = { "edge", "border" }

local function HasBorder(db)
    return db.colors and (db.border ~= nil or db.borderSize ~= nil)
end

function HHT:GetBorderColor()
    local first
    for _, k in ipairs(self.moduleList) do
        local db = self.modules[k].db
        if HasBorder(db) then
            for _, ck in ipairs(BORDER_KEYS) do
                local c = db.colors[ck]
                if c then
                    if k == "castbar" then return c end
                    first = first or c
                end
            end
        end
    end
    return first or { 0.55, 0.42, 0.2 }
end

function HHT:SetBorderColor(c)
    for _, k in ipairs(self.moduleList) do
        local db = self.modules[k].db
        if HasBorder(db) then
            for _, ck in ipairs(BORDER_KEYS) do
                if db.colors[ck] then db.colors[ck] = { c[1], c[2], c[3] } end
            end
        end
    end
end

function HHT:SetLook(key, value)
    if key == "borderColor" then
        self:SetBorderColor(value)
    else
        for _, k in ipairs(self.moduleList) do
            local db = self.modules[k].db
            if db[key] ~= nil then db[key] = value end
            if key == "borderSize" and db.border ~= nil then db.border = value > 0 end
        end
    end
    self:RefreshAll()
    if self.Icon and self.Icon.RefreshFinish then self.Icon.RefreshFinish() end
    self:ApplyAllLooks()
end

-- A table whose fields read and write the shared look settings, so a form widget can be bound to it.
HHT.Look = setmetatable({}, {
    __index = function(_, key)
        if key == "borderColor" then return HHT:GetBorderColor() end
        return HHT:GetLook(key)
    end,
    __newindex = function(_, key, value) HHT:SetLook(key, value) end,
})

-- Small ticker so modules can poll cheaply without owning a frame.
function HHT:Every(m, interval, fn)
    local f = CreateFrame("Frame")
    local acc = 0
    f:SetScript("OnUpdate", function(_, dt)
        if not m.enabled then return end
        acc = acc + dt
        if acc >= interval then
            local el = acc
            acc = 0
            fn(m, el)
        end
    end)
    return f
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
function HHT:InitDB()
    self.firstRun = (HamingwaysHunterToolsDB == nil)
    HamingwaysHunterToolsDB = HamingwaysHunterToolsDB or {}
    local db = HamingwaysHunterToolsDB
    db.general = db.general or {}
    Fill(db.general, GENERAL_DEFAULTS)
    -- Remembers whether the character already existed before the quick install (decides if its settings are worth sharing).
    if db.general.origin == nil then db.general.origin = self.firstRun and "new" or "old" end
    if self.UI and self.UI.ApplyTheme then self.UI.ApplyTheme(db.general.theme) end
    db.mods = db.mods or {}
    self.db = db
    self:EachModule(function(m)
        local d = db.mods[m.key]
        if not d then d = {}; db.mods[m.key] = d end
        Fill(d, ModuleDefaults(m))
        -- "Show only in combat" became the choice "Show when" (the visibility option, or showWhen for modules without one).
        if d.onlyCombat then
            if d.visibility ~= nil then d.visibility = "combat" else d.showWhen = "combat" end
            d.onlyCombat = false
        end
        if m.wip then d.enabled = false end
        m.db = d
    end)
end

function HHT:Start()
    self:EachModule(function(m)
        if m.OnInit then m:OnInit() end
    end)
    self:EachModule(function(m)
        m.enabled = false
        if m.db.enabled then self:SetEnabled(m, true) end
    end)
    if self.Config and self.Config.Init then self.Config:Init() end
    for _, ev in ipairs({ "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED" }) do
        local f = self.combatFrame or CreateFrame("Frame")
        self.combatFrame = f
        f:RegisterEvent(ev)
        f:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_REGEN_DISABLED" then
                HHT:LockForCombat()
            elseif event == "PLAYER_REGEN_ENABLED" then
                if HHT.lockPending then
                    HHT.lockPending = nil
                    HHT:ApplyLock()
                end
                if HHT.lookPending then
                    HHT.lookPending = nil
                    HHT:ApplyAllPositions()
                end
            end
            HHT:ApplyAllLooks()
        end)
    end
    self:ApplyAllLooks()
    self:WatchBlocked()
end

-- Blocked interface actions caused by this addon are counted silently; /hht blocked lists them.
-- /hht trace follows calls on protected frames in combat back to the line in this addon (until the next reload).
function HHT:TraceProtectedCalls()
    if self.traceOn then return end
    self.traceOn = true
    local ok, index = pcall(function() return getmetatable(CreateFrame("Frame")).__index end)
    if not ok or type(index) ~= "table" then return end
    local seen = {}
    for _, name in ipairs({ "SetShown", "Show", "Hide", "SetPoint", "ClearAllPoints", "SetSize", "SetWidth", "SetHeight", "SetScale", "SetParent" }) do
        if index[name] then
            pcall(hooksecurefunc, index, name, function(f)
                if not InCombatLockdown() then return end
                local ok2, prot = pcall(f.IsProtected, f)
                if not (ok2 and prot) then return end
                local lines = {}
                for line in tostring(debugstack(2, 12, 0)):gmatch("[^\n]+") do
                    if line:find(ADDON, 1, true) then lines[#lines + 1] = line end
                    if #lines >= 3 then break end
                end
                if #lines == 0 then return end
                local key = name .. lines[1]
                if seen[key] then return end
                seen[key] = true
                HHT.Print("Protected call " .. name .. " in combat: " .. table.concat(lines, " <- "))
            end)
        end
    end
end

function HHT:WatchBlocked()
    if self.blockedFrame then return end
    local f = CreateFrame("Frame")
    self.blockedFrame = f
    self.blocked = {}
    f:RegisterEvent("ADDON_ACTION_BLOCKED")
    f:RegisterEvent("ADDON_ACTION_FORBIDDEN")
    f:SetScript("OnEvent", function(_, _, addon, func)
        if addon ~= ADDON then return end
        local key = tostring(func)
        HHT.blocked[key] = (HHT.blocked[key] or 0) + 1
    end)
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= ADDON then return end
        local _, class = UnitClass("player")
        HHT.isHunter = (class == "HUNTER")
        if HHT.isHunter then HHT:InitDB() end
    elseif event == "PLAYER_LOGIN" then
        if not HHT.isHunter then
            HHT.db = nil
            HHT.Print(HHT.L("Hunter only. Addon is inactive on this character."))
            return
        end
        HHT:Start()
        boot:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------
SLASH_HAMINGWAYSHUNTERTOOLS1 = "/hht"
SLASH_HAMINGWAYSHUNTERTOOLS2 = "/hamingway"

-- /hht test <name>: shows a feature without having to go somewhere.
local TESTS = {
    { "rare", "rare beast alert", function() local m = HHT.modules.petwatch; return m and m.enabled and m:Test() end },
    { "arrow", "direction arrow to a rare", function() return HHT.PetWatch and HHT.PetWatch.TestArrow() end },
    { "nearby", "pet ability alert", function() local m = HHT.modules.petnearby; return m and m.enabled and m:Test() end },
    { "zone", "upgrade beast list of the current zone", function() local m = HHT.modules.petnearby; return m and m.enabled and m:TestZone() end },
    { "train", "pet training hint", function() local m = HHT.modules.pettrain; return m and m.enabled and m:Test() end },
    { "guide", "level 10 pet guide hint", function() local m = HHT.modules.petguide; return m and m.enabled and m:Test() end },
    { "minimap", "minimap pins around you", function() return HHT.PetMap and HHT.PetMap:TestMinimap() end },
}

function HHT.RunTest(what)
    for _, t in ipairs(TESTS) do
        if t[1] == what then
            if not t[3]() then HHT.Print("test " .. what .. ": module is off or not ready.") end
            return
        end
    end
    local names = {}
    for _, t in ipairs(TESTS) do names[#names + 1] = t[1] .. " (" .. t[2] .. ")" end
    HHT.Print("/hht test: " .. table.concat(names, ", "))
end

SlashCmdList["HAMINGWAYSHUNTERTOOLS"] = function(msg)
    if not HHT.db then return end
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    local testWhat = msg:match("^test%s*(.*)$")
    local petSearch = msg:match("^pets%s*(.*)$")
    local shotWhat = msg:match("^shot%s*(.*)$")
    if shotWhat then
        if HHT.RunShot then HHT.RunShot(shotWhat) end
    elseif petSearch then
        if HHT.PetDex then HHT.PetDex:Toggle(petSearch ~= "" and petSearch or nil) end
    elseif testWhat then
        HHT.RunTest(testWhat)
    elseif msg == "guide" then
        if HHT.PetDex then HHT.PetDex:Open("guide") end
    elseif msg == "petmap" then
        if HHT.PetMap then HHT.PetMap:Debug() end
    elseif msg == "ammo" then
        if HHT.AmmoVendors then HHT.AmmoVendors.Show() end
    elseif msg == "ammo go" then
        if HHT.AmmoVendors then HHT.AmmoVendors.Nearest() end
    elseif msg == "ammo debug" then
        local am = HHT.modules.ammo
        if am and am.Debug then am:Debug() end
    elseif msg == "stable" then
        if HHT.StableMasters then HHT.StableMasters.Show() end
    elseif msg == "stable go" then
        if HHT.StableMasters then HHT.StableMasters.Nearest() end
    elseif msg == "food" then
        if HHT.FoodVendors then HHT.FoodVendors.Show() end
    elseif msg == "food go" then
        if HHT.FoodVendors then HHT.FoodVendors.Nearest() end
    elseif msg == "trainer" then
        if HHT.Trainers then HHT.Trainers.Show() end
    elseif msg == "trainer go" then
        if HHT.Trainers then HHT.Trainers.Nearest() end
    elseif msg == "watch" then
        if HHT.PetWatch then HHT.PetWatch.Debug() end
    elseif msg == "debuffs" then
        if HHT.Debuffs then HHT.Debuffs:Debug() end
    elseif msg == "nearby" then
        if HHT.modules.petnearby then HHT.modules.petnearby:Why() end
    elseif msg == "train" then
        if HHT.modules.pettrain and HHT.modules.pettrain.enabled then HHT.modules.pettrain:Recheck() end
    elseif msg == "procs" then
        if HHT.Procs then HHT.Procs:Debug() end
    elseif msg == "totems" then
        if HHT.Summons then HHT.Summons:Debug() end
    elseif msg == "auras" then
        if HHT.Procs then HHT.Procs:ListAuras() end
    elseif msg == "auras pet" then
        if HHT.Procs then HHT.Procs:ListAuras(false, "pet") end
    elseif msg == "auras watch" then
        if HHT.Procs then
            HHT.Procs.watch = not HHT.Procs.watch
            HHT.Print("auras watch: " .. (HHT.Procs.watch and "on, short buffs are listed when combat ends" or "off"))
        end
    elseif msg == "proctex" then
        if HHT.Procs then HHT.Procs:TexPreview() end
    elseif msg == "petinfo" then
        if HHT.PetDex and HHT.PetDex.Inspect then HHT.PetDex.Inspect() end
    elseif msg == "tranq" then
        local tm = HHT.modules.tranq
        if tm and tm.enabled then tm:SetWindow(tm.db.show == false) end
    elseif msg == "news" then
        if HHT.WhatsNew then HHT.WhatsNew.Open("all") end
    elseif msg == "setup" then
        if HHT.Setup then HHT.Setup.Open() end
    elseif msg == "lock" then
        HHT:SetLocked(true)
    elseif msg == "unlock" then
        HHT:SetLocked(false)
    elseif msg == "debug" then
        local S = HHT.Spells
        HHT.Print("aurasSecret=" .. tostring(S.AurasSecret()) .. " combat=" .. tostring(HHT.InCombat()))
        local keys = {}
        for _, k in ipairs(S.Aspects) do keys[#keys + 1] = k end
        keys[#keys + 1] = "trueshotAura"; keys[#keys + 1] = "hunterMark"; keys[#keys + 1] = "callPet"
        for _, k in ipairs(keys) do
            local rs = S.Resolve("@" .. k)
            local found = rs.known and S.AuraByName("player", rs.name, "HELPFUL")
            HHT.Print(string.format("%s known=%s id=%s name=%s aura=%s", k, tostring(rs.known), tostring(rs.id), tostring(rs.name), tostring(found)))
        end
        local pm = HHT.modules.pet
        if pm and pm.ReadHappiness then
            local okC, c1 = false, nil
            if C_PetInfo and C_PetInfo.GetPetHappiness then okC, c1 = pcall(C_PetInfo.GetPetHappiness) end
            local g1, g2 = nil, nil
            if GetPetHappiness then g1, g2 = GetPetHappiness() end
            HHT.Print("happiness: C_PetInfo=" .. tostring(c1) .. " global=" .. tostring(g1) .. "/" .. tostring(g2) .. " used=" .. tostring(pm.ReadHappiness()))
        end
        local fm = HHT.modules.feeder
        if pm and pm.DebugExtras then pm:DebugExtras() end
        if fm and fm.Debug then fm:Debug() end
        local w = HHT.modules.warnings
        if w and w.Collect then
            local keys2 = {}
            for _, e in ipairs(w:Collect()) do keys2[#keys2 + 1] = e.key end
            HHT.Print("warnings: quiet=" .. tostring(w.Quiet()) .. " enabled=" .. tostring(w.enabled) .. " list=" .. table.concat(keys2, ","))
            if w.PetDebug then HHT.Print(w:PetDebug()) end
        end
    elseif msg == "cd" then
        local cm = HHT.modules.cooldowns
        if cm and cm.Debug then cm:Debug() end
    elseif msg == "key" then
        HHT.KeyTest()
    elseif msg == "blocked" then
        local n = 0
        for func, count in pairs(HHT.blocked or {}) do
            n = n + 1
            HHT.Print("Blocked action: " .. func .. " x" .. count)
        end
        if n == 0 then HHT.Print("No blocked actions.") end
    elseif msg == "trace" then
        HHT:TraceProtectedCalls()
        HHT.Print("Tracing protected calls in combat until the next reload.")
    elseif msg == "reset" then
        for _, m in pairs(HHT.modules) do m.db.pos = nil end
        HHT:ApplyAllPositions()
        HHT.Print(HHT.L("Positions reset."))
    else
        if HHT.Config then HHT.Config:Toggle() end
    end
end
