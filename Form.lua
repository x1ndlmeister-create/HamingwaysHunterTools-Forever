-- Stacked option forms inside a scroll frame. Widgets bind to (table, key). Headers fold their section.
local ADDON, HHT = ...
local UI = HHT.UI

local floor, max, min = math.floor, math.max, math.min

local function Round(v, step)
    local places = (step < 0.1) and 3 or ((step < 1) and 2 or 0)
    local m = 10 ^ places
    v = floor(v / step + 0.5) * step
    return floor(v * m + 0.5) / m
end

local function Folds()
    local g = HHT.db and HHT.db.general
    if not g then return nil end
    g.fold = g.fold or {}
    return g.fold
end

function UI.NewForm(parent, onChange, id)
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

    local form = { sf = sf, content = content, entries = {}, items = {}, onChange = onChange, id = id }

    -- Places every entry again; entries below a folded header are hidden.
    function form:Layout()
        local y, folded, tailShown = 4, false, false
        for _, e in ipairs(self.entries) do
            local w = e.w
            if e.header then
                y = y + 8
                w:ClearAllPoints()
                w:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -y)
                e.hit:ClearAllPoints()
                e.hit:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(y - 3))
                e.hit:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, -(y - 3))
                y = y + 18
                e.line:ClearAllPoints()
                e.line:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -y)
                e.line:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, -y)
                y = y + 8
                folded = e.folded and true or false
                e.mark:SetText(folded and "[+]" or "[-]")
            elseif folded then
                w:Hide()
            else
                w:Show()
                w:ClearAllPoints()
                w:SetPoint("TOPLEFT", content, "TOPLEFT", e.indent, -y)
                if e.tail then tailShown = true else y = y + e.h + e.gap end
            end
        end
        content:SetHeight(y + (tailShown and (self.tailH or 0) or 0) + 8)
        UpdateThumb()
    end

    function form:Place(w, h, indent, gap)
        self.entries[#self.entries + 1] = { w = w, h = h, indent = indent or 4, gap = gap or 6 }
        self.items[#self.items + 1] = w
        self:Layout()
        return w
    end

    -- Places a widget at the current end without advancing (for a growing list at the end of the form).
    function form:PlaceTail(w)
        self.entries[#self.entries + 1] = { w = w, tail = true, indent = 4 }
        self.items[#self.items + 1] = w
        self:Layout()
    end

    function form:SetTail(h)
        self.tailH = h
        self:Layout()
    end

    function form:Changed(extra)
        if extra then extra() end
        if self.onChange then self.onChange() end
    end

    function form:Header(text)
        local fs = UI.Header(content, text)
        local line = content:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        local hc = UI.PAL.hdrLine
        line:SetColorTexture(hc[1], hc[2], hc[3], hc[4])

        local hit = CreateFrame("Button", nil, content)
        hit:SetHeight(20)
        local hl = hit:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.1)
        local mark = UI.Text(hit, "", 11, 0.6, 0.6, 0.6)
        mark:SetPoint("RIGHT", hit, "RIGHT", -2, 0)

        local key = (id or "") .. "/" .. tostring(text)
        local folds = Folds()
        local e = { header = true, w = fs, line = line, hit = hit, mark = mark, folded = folds and folds[key] and true or false }
        hit:SetScript("OnClick", function()
            e.folded = not e.folded
            local fl = Folds()
            if fl then fl[key] = e.folded or nil end
            self:Layout()
        end)
        self.entries[#self.entries + 1] = e
        self:Layout()
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
