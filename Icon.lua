-- Reusable icon widget: square or round, solid border, cooldown swipe, texts, blink.
local ADDON, HHT = ...
local UI = HHT.UI

local Icon = {}
HHT.Icon = Icon

local MASK = "Interface\\AddOns\\" .. ADDON .. "\\Media\\RoundMask"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT = UI.FONT

local floor, max, min, sin = math.floor, math.max, math.min, math.sin

local function SetRound(tex, owner, on)
    if not (owner.CreateMaskTexture and tex.AddMaskTexture) then return end
    if on then
        if not tex.hhtMask then
            local m = owner:CreateMaskTexture()
            m:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            m:SetAllPoints(tex)
            tex.hhtMask = m
        end
        if not tex.hhtOn then tex:AddMaskTexture(tex.hhtMask); tex.hhtOn = true end
    elseif tex.hhtOn then
        tex:RemoveMaskTexture(tex.hhtMask)
        tex.hhtOn = false
    end
end

local function SetSwipeRound(cool, on)
    if on then
        pcall(cool.SetSwipeTexture, cool, MASK)
        cool.hhtRound = true
    elseif cool.hhtRound then
        pcall(cool.SetSwipeTexture, cool, WHITE)
        cool.hhtRound = false
    end
end

local function SetFont(fs, size)
    if fs:SetFont(FONT, size, "OUTLINE") == false then fs:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE") end
end

local methods = {}

-- opts: size, shape ("square"/"round"), borderSize (0 = none), borderAlpha (0..1), numbers (bool)
function methods:Style(size, shape, borderSize, borderAlpha, numbers)
    size = size or 36
    local round = (shape == "round")
    local bs = max(0, min(4, borderSize or 1))
    self:SetSize(size, size)
    self.border:ClearAllPoints()
    self.border:SetPoint("TOPLEFT", self, "TOPLEFT", -bs, bs)
    self.border:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", bs, -bs)
    self.border:SetShown(bs > 0)
    self.border:SetAlpha(borderAlpha or 1)
    SetRound(self.tex, self, round)
    SetRound(self.border, self, round)
    SetSwipeRound(self.cool, round)
    pcall(self.cool.SetHideCountdownNumbers, self.cool, numbers == false)
    SetFont(self.text, max(8, floor(size * 0.42)))
    SetFont(self.count, max(8, floor(size * 0.30)))
    SetFont(self.label, max(8, min(12, floor(size * 0.28))))
    self.round = round
end

function methods:SetBorderColor(r, g, b)
    self.border:SetColorTexture(r, g, b, 1)
end

function methods:SetIcon(tex)
    self.tex:SetTexture(tex)
end

function methods:SetDesaturated(on)
    self.tex:SetDesaturated(on and true or false)
end

function methods:ShowCooldown(durObj)
    if not durObj then self.cool:Clear(); return false end
    if pcall(self.cool.SetCooldownFromDurationObject, self.cool, durObj, true) then return true end
    return false
end

function methods:ClearCooldown()
    self.cool:Clear()
end

-- Static timer: start/duration in plain numbers (not secret)
function methods:SetTimer(start, duration)
    self.cool:SetCooldown(start, duration)
end

local KEY_ANCHOR = {
    TOPLEFT = { 2, -2 }, TOPRIGHT = { -2, -2 }, CENTER = { 0, 0 }, BOTTOMLEFT = { 2, 2 }, BOTTOMRIGHT = { -2, 2 },
}

-- Small bind text on the icon; empty text hides it. Only touches the font string when something changed.
function methods:SetKey(text, size, pos, r, g, b)
    local fs = self.key
    if not text or text == "" then
        if self.keyText ~= "" then fs:SetText(""); self.keyText = "" end
        return
    end
    size = size or 12
    pos = KEY_ANCHOR[pos] and pos or "TOPRIGHT"
    if self.keySize ~= size then SetFont(fs, size); self.keySize = size end
    if self.keyPos ~= pos then
        local a = KEY_ANCHOR[pos]
        fs:ClearAllPoints()
        fs:SetPoint(pos, self, pos, a[1], a[2])
        self.keyPos = pos
    end
    fs:SetTextColor(r or 1, g or 1, b or 0.4)
    if self.keyText ~= text then fs:SetText(text); self.keyText = text end
end

function methods:SetBlink(on, speed)
    if on then
        self.blinkSpeed = speed or 5
        if not self.blinking then
            self.blinking = true
            self.blinkT = 0
            self.over:SetScript("OnUpdate", function(_, dt)
                self.blinkT = self.blinkT + dt * self.blinkSpeed
                self:SetAlpha(0.45 + 0.55 * (0.5 + 0.5 * sin(self.blinkT)))
            end)
        end
    elseif self.blinking then
        self.blinking = false
        self.over:SetScript("OnUpdate", nil)
        self:SetAlpha(1)
    end
end

function Icon.New(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(36, 36)

    f.border = f:CreateTexture(nil, "BACKGROUND")
    f.border:SetTexture(WHITE)
    f.border:SetVertexColor(1, 1, 1, 1)

    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetAllPoints(f)
    f.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    f.cool = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cool:SetAllPoints(f)
    pcall(f.cool.SetDrawEdge, f.cool, false)
    pcall(f.cool.SetDrawBling, f.cool, false)

    f.over = CreateFrame("Frame", nil, f)
    f.over:SetAllPoints(f)
    f.over:SetFrameLevel(f.cool:GetFrameLevel() + 2)

    f.text = f.over:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.count = f.over:CreateFontString(nil, "OVERLAY")
    f.count:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 2)
    f.label = f.over:CreateFontString(nil, "OVERLAY")
    f.label:SetPoint("TOP", f, "BOTTOM", 0, -2)
    SetFont(f.text, 14); SetFont(f.count, 11); SetFont(f.label, 10)
    f.key = f.over:CreateFontString(nil, "OVERLAY")
    SetFont(f.key, 12)
    f.keyText = ""

    for k, v in pairs(methods) do f[k] = v end
    f:SetBorderColor(0.55, 0.42, 0.2)
    return f
end
