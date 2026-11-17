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
    content:SetSize(480, 10)
    sf:SetScrollChild(content)
    sf:EnableMouseWheel(true)

    local UpdateThumb = UI.ScrollBar(sf, content, 4, 40)
    local form = { sf = sf, content = content, entries = {}, items = {}, onChange = onChange, id = id }

    local function Active(p)
        if not p.vis then return false end
        if not p.get then return true end
        local v = p.get()
        return v and v ~= 0 and v ~= "" and true or false
    end

    -- Places every entry again. Hidden are: entries below a folded header, advanced entries in the simple view,
    -- entries whose parent setting is off and headers without a visible entry.
    function form:Layout()
        local ents = self.entries
        for _, e in ipairs(ents) do
            if not e.header then
                local v = not e.dead and not (e.adv and not (e.sec and e.sec.advOn))
                if v and e.parent then v = Active(e.parent) end
                e.vis = v and true or false
            end
        end
        local any, anyAdv = false, false
        for i = #ents, 1, -1 do
            local e = ents[i]
            if e.header then
                e.vis = any or anyAdv
                e.hasAdv = anyAdv
                any, anyAdv = false, false
            elseif not e.cond then
                if e.vis then any = true end
                if e.adv and not e.dead then anyAdv = true end
            end
        end

        local y, folded, first, rowY = 4, false, true, 4
        for _, e in ipairs(ents) do
            local w = e.w
            if e.header then
                if e.vis then
                    y = y + (first and 2 or 14)
                    first = false
                    w:Show(); e.line:Show(); e.hit:Show()
                    w:ClearAllPoints()
                    w:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -y)
                    e.hit:ClearAllPoints()
                    e.hit:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(y - 3))
                    e.hit:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, -(y - 3))
                    y = y + 19
                    e.line:ClearAllPoints()
                    e.line:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -y)
                    e.line:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, -y)
                    y = y + 11
                    folded = e.folded and true or false
                    e.mark:SetText(folded and "+" or "")
                    e.sw:SetShown(e.hasAdv)
                    e.sw:Refresh()
                else
                    w:Hide(); e.line:Hide(); e.hit:Hide()
                    folded = false
                end
            elseif e.cond then
                -- no widget: only a condition other entries depend on
            elseif folded or not e.vis then
                w:Hide()
                if e.hit2 then e.hit2:Hide() end
            elseif e.inline then
                -- sits right of the entry placed before it, on the same line
                w:Show()
                if e.hit2 then e.hit2:Show() end
                w:ClearAllPoints()
                w:SetPoint("TOPLEFT", content, "TOPLEFT", e.inline, -rowY)
            else
                first = false
                w:Show()
                if e.hit2 then e.hit2:Show() end
                w:ClearAllPoints()
                w:SetPoint("TOPLEFT", content, "TOPLEFT", e.indent, -y)
                rowY = y
                if e.tail then y = y + (self.tailH or 0) + 8 else y = y + e.h + e.gap end
            end
        end
        content:SetHeight(y + 8)
        UpdateThumb()
    end

    function form:Place(w, h, indent, gap)
        local e = { w = w, h = h, indent = indent or 4, gap = gap or 6 }
        self.entries[#self.entries + 1] = e
        self.items[#self.items + 1] = w
        self.last = e
        self:Layout()
        return w
    end

    -- Places a widget at the current end without advancing (for a growing list at the end of the form).
    function form:PlaceTail(w)
        local e = { w = w, tail = true, indent = 4 }
        self.entries[#self.entries + 1] = e
        self.items[#self.items + 1] = w
        self.last = e
        self:Layout()
    end

    -- Names the entry placed last (the label the layout refers to) and gives its value for dependent entries.
    function form:Tag(label, get)
        local e = self.last
        e.label = (label and label ~= "") and label or nil
        e.get = get
    end

    -- The entry placed last sits on the line of the entry before it, at x.
    function form:Inline(x)
        self.last.inline = x
    end

    function form:Name(label)
        self.last.label = HHT.L(label)
    end

    -- Entries with the same group are claimed together by one layout row.
    function form:Group(name)
        self.last.group = name
    end

    -- An entry without a widget: other entries can depend on it (fn returns true while it holds).
    function form:Cond(label, fn)
        local e = { cond = true, label = label, get = fn, indent = -10 }
        self.entries[#self.entries + 1] = e
        self.last = e
        self:Layout()
    end

    local function ShowTip(e, w)
        if not (GameTooltip and e.tip) then return end
        GameTooltip:SetOwner(w, "ANCHOR_NONE")
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("TOPLEFT", w, "BOTTOMLEFT", 0, -2)
        GameTooltip:SetText(HHT.L(e.tip), 1, 1, 1, 1, true)
        GameTooltip:Show()
    end

    local function HideTip()
        if GameTooltip then GameTooltip:Hide() end
    end

    -- Tooltip over the label and over the controls of a row.
    function form:SetTip(e, text)
        e.tip = text
        local w = e.w
        if not text or e.tipDone or not w then return end
        e.tipDone = true
        local function Hook(f)
            if f.IsMouseEnabled and f:IsMouseEnabled() then
                f:HookScript("OnEnter", function() ShowTip(e, w) end)
                f:HookScript("OnLeave", HideTip)
                return true
            end
        end
        if not Hook(w) then
            local isFrame = w.GetChildren ~= nil
            local hit = CreateFrame("Frame", nil, isFrame and w or w:GetParent())
            hit:SetPoint("TOPLEFT", w, "TOPLEFT", 0, 0)
            if isFrame then
                hit:SetSize(246, math.min(e.h or 20, 20))
            else
                hit:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", 0, 0)
            end
            hit:EnableMouse(true)
            hit:SetScript("OnEnter", function() ShowTip(e, w) end)
            hit:SetScript("OnLeave", HideTip)
            e.hit2 = hit
        end
        if w.GetChildren then
            for _, c in ipairs({ w:GetChildren() }) do Hook(c) end
        end
    end

    function form:SetTail(h)
        self.tailH = h
        self:Layout()
    end

    function form:Changed(extra)
        if extra then extra() end
        if self.onChange then self.onChange() end
        self:Layout()
    end

    local function MakeHeader(text, sid)
        local fs = UI.Header(content, text)
        local hc = UI.PAL.head
        local line = UI.FadeLine(content, hc[1], hc[2], hc[3], 0.7)

        local hit = CreateFrame("Button", nil, content)
        hit:SetHeight(20)
        local hl = hit:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        UI.Gradient(hl, false, UI.ACCENT[1], UI.ACCENT[2], UI.ACCENT[3], 0.1, 0)
        local mark = UI.Text(hit, "", 13, 0.7, 0.7, 0.7)
        mark:SetPoint("RIGHT", hit, "RIGHT", -2, 0)

        local key = (sid or id or "") .. "/" .. tostring(text)
        local folds = Folds()
        local e = { header = true, w = fs, line = line, hit = hit, mark = mark, folded = folds and folds[key] and true or false }
        local g = HHT.db and HHT.db.general
        e.advOn = g and g.advSec and g.advSec[key] and true or false

        -- Switch for the advanced rows of this section; only shown when the section has some.
        local sw = UI.Switch(hit, function() return e.advOn end, function(v)
            e.advOn = v and true or false
            local gg = HHT.db and HHT.db.general
            if gg then
                gg.advSec = gg.advSec or {}
                gg.advSec[key] = e.advOn or nil
            end
            form:Layout()
        end)
        sw:SetPoint("RIGHT", hit, "RIGHT", -22, 0)
        sw:SetFrameLevel(hit:GetFrameLevel() + 2)
        sw:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(HHT.L("Advanced"), 1, 1, 1)
            GameTooltip:AddLine(HHT.L("Shows the advanced settings of this section."), 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        sw:HookScript("OnLeave", function() GameTooltip:Hide() end)
        e.sw = sw
        hit:SetScript("OnClick", function()
            e.folded = not e.folded
            local fl = Folds()
            if fl then fl[key] = e.folded or nil end
            form:Layout()
        end)
        return e
    end

    function form:Header(text)
        local e = MakeHeader(text)
        self.entries[#self.entries + 1] = e
        self:Layout()
        return e.w
    end

    function form:Note(text, r, g, b)
        local fs = UI.Text(content, text, 11, r or 0.68, g or 0.65, b or 0.58)
        fs:SetWidth(460)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(true)
        local h = max(14, fs:GetStringHeight())
        self:Place(fs, h, 4, 6)
        return fs
    end

    function form:Check(label, tbl, key, extra, opts)
        local c = UI.Toggle(content, label,
            function() return tbl[key] end,
            function(v) tbl[key] = v and true or false; self:Changed(extra) end, opts)
        self:Place(c, 22, 4, 8)
        self:Tag(label, function() return tbl[key] end)
        return c
    end

    function form:Stepper(label, tbl, key, minv, maxv, step, extra)
        local s = UI.Stepper(content, label,
            function() return tbl[key] end,
            function(v) tbl[key] = Round(v, step); self:Changed(extra) end,
            minv, maxv, step)
        self:Place(s, 20, 4, 8)
        self:Tag(label, function() return tbl[key] end)
        return s
    end

    function form:Cycle(label, tbl, key, choices, extra)
        local c = UI.Cycle(content, label, choices,
            function() return tbl[key] end,
            function(v) tbl[key] = v; self:Changed(extra) end)
        self:Place(c, 22, 4, 8)
        self:Tag(label, function() return tbl[key] end)
        return c
    end

    -- tbl[key] = { r, g, b }
    function form:Color(label, tbl, key, extra)
        local c = UI.Color(content, label,
            function() local t = tbl[key]; return t[1], t[2], t[3] end,
            function(r, g, b) tbl[key] = { r, g, b }; self:Changed(extra) end)
        self:Place(c, 22, 4, 8)
        self:Tag(label)
        return c
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
        self:Place(f, 42, 4, 6)
        self:Tag(label, function() return tbl[key] end)
        return f
    end

    function form:Button(label, fn, w)
        local b = UI.Button(content, w or 170, 22, label, function() fn(); self:Refresh() end)
        self:Place(b, 22, 4, 8)
        self:Tag(label)
        return b
    end

    function form:Refresh()
        for _, it in ipairs(self.items) do
            if it.Refresh then it:Refresh() end
        end
        self:Layout()
    end

    -- Rebuilds the page after the layout (HHT.Layout[page]): sections in order, each row "[+|*]Label[ >> Parent]".
    -- "+" marks an advanced row (shown in the advanced view only), "*" claims every entry of a group, "Parent" makes
    -- the row depend on another row. Entries the layout does not name stay hidden.
    -- opts: from = first entry to arrange (earlier ones stay as they are), secId = id for the section states,
    -- skip = labels that stay hidden, solo = labels that get their own row instead of sitting inline.
    function form:ApplyLayout(spec, tips, opts)
        if not spec then return end
        opts = opts or {}
        local skip, solo = {}, {}
        for n in pairs(opts.skip or {}) do skip[HHT.L(n)] = true end
        for n in pairs(opts.solo or {}) do solo[n] = true end
        local pre, rest = {}, {}
        for i, e in ipairs(self.entries) do
            if i < (opts.from or 1) then pre[#pre + 1] = e else rest[#rest + 1] = e end
        end
        local queues, groups, claimed = {}, {}, {}
        for _, e in ipairs(rest) do
            if e.header then
                e.w:Hide(); e.line:Hide(); e.hit:Hide()
            else
                e.dead = true
                if e.group then
                    groups[e.group] = groups[e.group] or {}
                    table.insert(groups[e.group], e)
                end
                if e.label then
                    queues[e.label] = queues[e.label] or {}
                    table.insert(queues[e.label], e)
                end
            end
        end
        local out, byName = {}, {}
        for _, e in ipairs(rest) do
            if e.cond then
                e.dead = false
                byName[e.label] = e
                claimed[e] = true
                out[#out + 1] = e
            end
        end
        for _, sec in ipairs(spec) do
            local list = {}
            for _, row in ipairs(sec[2]) do
                local adv, claim, name, dep = row:match("^([+]?)([*]?)(.-) >> (.+)$")
                if not name then adv, claim, name = row:match("^([+]?)([*]?)(.+)$") end
                local parent = dep and byName[dep]
                local found
                if claim == "*" then
                    found = groups[name]
                else
                    local q = queues[HHT.L(name)]
                    local e = q and table.remove(q, 1)
                    if e and not claimed[e] then found = { e } end
                end
                if found then
                    for _, e in ipairs(found) do
                        if not claimed[e] then
                            claimed[e] = true
                            if skip[e.label] then
                                out[#out + 1] = e
                            else
                                e.dead, e.adv, e.parent = false, adv == "+", parent
                                if solo[name] then e.inline = nil end
                                e.indent = parent and (parent.indent + 14) or 4
                                if tips and tips[name] then self:SetTip(e, tips[name]) end
                                byName[name] = byName[name] or e
                                list[#list + 1] = e
                            end
                        end
                    end
                elseif HHT.layoutDebug then
                    HHT.Print("layout: no entry for '" .. name .. "' on " .. tostring(id))
                end
            end
            if #list > 0 then
                local hdr = MakeHeader(HHT.L(sec[1]), opts.secId)
                out[#out + 1] = hdr
                for _, e in ipairs(list) do
                    e.sec = hdr
                    out[#out + 1] = e
                end
            end
        end
        for _, e in ipairs(rest) do
            if not e.header and not claimed[e] then
                out[#out + 1] = e
                if HHT.layoutDebug and e.label then HHT.Print("layout: unused '" .. e.label .. "' on " .. tostring(id)) end
            end
        end
        for _, e in ipairs(out) do pre[#pre + 1] = e end
        self.entries = pre
        self:Layout()
    end

    return form
end
