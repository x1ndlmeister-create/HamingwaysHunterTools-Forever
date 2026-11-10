-- Stacked option forms inside a scroll frame. Widgets bind to (table, key).
local ADDON, HHT = ...
local UI = HHT.UI

local floor, max, min = math.floor, math.max, math.min

local function Round(v, step)
    local places = (step < 0.1) and 3 or ((step < 1) and 2 or 0)
    local m = 10 ^ places
    v = floor(v / step + 0.5) * step
    return floor(v * m + 0.5) / m
end

function UI.NewForm(parent, onChange)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    sf:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    sf:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 0)
    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(390, 10)
    sf:SetScrollChild(content)
    sf:EnableMouseWheel(true)

    local thumb = sf:CreateTexture(nil, "OVERLAY")
    thumb:SetWidth(3)
    thumb:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.45)
    thumb:Hide()

    local function UpdateThumb()
        local viewH, contentH = sf:GetHeight(), content:GetHeight()
        if contentH <= viewH + 1 then thumb:Hide(); return end
        local range = contentH - viewH
        local cur = sf:GetVerticalScroll()
        local h = max(20, viewH * viewH / contentH)
        thumb:SetHeight(h)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPRIGHT", sf, "TOPRIGHT", 6, -((viewH - h) * (cur / range)))
        thumb:Show()
    end

    sf:SetScript("OnMouseWheel", function(self, delta)
        local range = max(0, content:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(min(range, max(0, self:GetVerticalScroll() - delta * 40)))
        UpdateThumb()
    end)
    sf:SetScript("OnSizeChanged", UpdateThumb)

    local form = { sf = sf, content = content, y = 4, items = {}, onChange = onChange }

    function form:Place(w, h, indent, gap)
        w:ClearAllPoints()
        w:SetPoint("TOPLEFT", content, "TOPLEFT", indent or 4, -self.y)
        self.y = self.y + h + (gap or 6)
        content:SetHeight(self.y + 8)
        UpdateThumb()
        self.items[#self.items + 1] = w
        return w
    end

    -- Places a widget at the current y without advancing (for a growing list at the end of the form).
    function form:PlaceTail(w)
        w:ClearAllPoints()
        w:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -self.y)
        self.items[#self.items + 1] = w
    end

    function form:SetTail(h)
        content:SetHeight(self.y + h + 8)
        UpdateThumb()
    end

    function form:Changed(extra)
        if extra then extra() end
        if self.onChange then self.onChange() end
    end

    function form:Header(text)
        self.y = self.y + 8
        local fs = UI.Header(content, text)
        self:Place(fs, 14, 4, 4)
        local line = content:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -self.y)
        line:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, -self.y)
        line:SetColorTexture(0.55, 0.42, 0.2, 0.6)
        self.y = self.y + 8
        return fs
    end

    function form:Note(text, r, g, b)
        local fs = UI.Text(content, text, 11, r or 0.68, g or 0.65, b or 0.58)
        fs:SetWidth(375)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(true)
        local h = max(14, fs:GetStringHeight())
        self:Place(fs, h, 4, 6)
        return fs
    end

    function form:Check(label, tbl, key, extra)
        local c = UI.Check(content, label,
            function() return tbl[key] end,
            function(v) tbl[key] = v and true or false; self:Changed(extra) end)
        return self:Place(c, 20, 4, 4)
    end

    function form:Stepper(label, tbl, key, minv, maxv, step, extra)
        local s = UI.Stepper(content, label,
            function() return tbl[key] end,
            function(v) tbl[key] = Round(v, step); self:Changed(extra) end,
            minv, maxv, step)
        return self:Place(s, 20, 4, 5)
    end

    function form:Cycle(label, tbl, key, choices, extra)
        local c = UI.Cycle(content, label, choices,
            function() return tbl[key] end,
            function(v) tbl[key] = v; self:Changed(extra) end)
        return self:Place(c, 22, 4, 5)
    end

    -- tbl[key] = { r, g, b }
    function form:Color(label, tbl, key, extra)
        local c = UI.Color(content, label,
            function() local t = tbl[key]; return t[1], t[2], t[3] end,
            function(r, g, b) tbl[key] = { r, g, b }; self:Changed(extra) end)
        return self:Place(c, 22, 4, 5)
    end

    -- Label above a single-line text field bound to tbl[key].
    function form:Text(label, tbl, key, extra)
        local f = CreateFrame("Frame", nil, content)
        f:SetSize(380, 42)
        local fs = UI.Text(f, label, 12, 0.92, 0.94, 0.97)
        fs:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        local e = UI.EditBox(f, 370, function(t) tbl[key] = t; self:Changed(extra) end)
        e:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -18)
        e:SetMaxLetters(200)
        function f:Refresh() e:SetTextSafe(tbl[key] or "") end
        return self:Place(f, 42, 4, 6)
    end

    function form:Button(label, fn, w)
        local b = UI.Button(content, w or 170, 22, label, function() fn(); self:Refresh() end)
        return self:Place(b, 22, 4, 6)
    end

    function form:Refresh()
        for _, it in ipairs(self.items) do
            if it.Refresh then it:Refresh() end
        end
    end

    return form
end
