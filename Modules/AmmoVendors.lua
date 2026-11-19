-- Ammo vendors: world map pins and a waypoint to the nearest vendor.
local ADDON, HHT = ...
local L = HHT.L

HHT:AddGerman({
    ["Ammo vendors"] = "Munitionshändler",
    ["Shows ammo vendors on the world map and sets a waypoint to the nearest one."] = "Zeigt Munitionshändler auf der Weltkarte und setzt einen Wegpunkt zum nächsten.",
    ["Ammo vendors on map"] = "Munitionshändler auf Karte",
    ["Waypoint to nearest vendor"] = "Wegpunkt zum nächsten Händler",
    ["Sells"] = "Verkauft",
    ["Arrows"] = "Pfeile",
    ["Bullets"] = "Kugeln",
    ["Arrows and bullets"] = "Pfeile und Kugeln",
    ["Show vendors for"] = "Händler zeigen für",
    ["Ammo your weapon uses"] = "Munition deiner Waffe",
    ["Pins appear on the world map. Click a pin to set a waypoint."] = "Die Punkte erscheinen auf der Weltkarte. Klick auf einen Punkt setzt einen Wegpunkt. Ein- und ausschalten geht auch über den Knopf oben links an der Karte.",
    ["Show on the world map"] = "Auf der Weltkarte zeigen",
    ["Also show on the minimap"] = "Auch auf der Minimap zeigen",
    ["No ammo vendors known here."] = "Hier sind keine Munitionshändler bekannt.",
    ["Nearest ammo vendor: %s"] = "Nächster Munitionshändler: %s",
    ["Restock ammo"] = "Munition auffüllen",
    ["Show restock button"] = "Auffüll-Knopf zeigen",
    ["Move vendor buttons to make room"] = "Händlerknöpfe nach links schieben",
    ["Restock button: horizontal"] = "Auffüll-Knopf: horizontal",
    ["Restock button: vertical"] = "Auffüll-Knopf: vertikal",
    ["Reset restock button position"] = "Auffüll-Knopf zurücksetzen",
    ["Fills your quiver or ammo pouch with the ammo your weapon uses."] = "Füllt Köcher oder Munitionsbeutel mit der Munition, die deine Waffe nutzt.",
    ["This vendor does not sell your equipped ammo."] = "Dieser Händler verkauft deine angelegte Munition nicht.",
    ["No room in your quiver or ammo pouch."] = "Kein Platz im Köcher oder Munitionsbeutel.",
    ["Not enough gold."] = "Nicht genug Gold.",
    ["Buy %d x %s for %s?"] = "%d x %s für %s kaufen?",
    ["Bought %d x %s."] = "%d x %s gekauft.",
})

local M = HHT:NewModule("ammovendors", {
    name = "Ammo vendors",
    desc = "Shows ammo vendors on the world map and sets a waypoint to the nearest one.",
    noFrame = true,
    defaults = { kind = "auto", onMap = false, onMinimap = true, restockButton = true, shiftButtons = true, restockX = 0, restockY = 0 },
})

local AV = {}
HHT.AmmoVendors = AV

local ICON = {
    a = "Interface\\Icons\\INV_Ammo_Arrow_02",
    b = "Interface\\Icons\\INV_Ammo_Bullet_02",
    ab = "Interface\\Icons\\INV_Ammo_Arrow_02",
}
local COLOR = { A = { 0.3, 0.55, 1 }, H = { 0.9, 0.25, 0.25 }, N = { 0.9, 0.8, 0.3 } }

local function Sells(t)
    if t == "a" then return L("Arrows") end
    if t == "b" then return L("Bullets") end
    return L("Arrows and bullets")
end

-- Same shape as a pet database beast, so PetMap can draw it.
local function Entry(v)
    local e = v.entry
    if not e then
        local pts = {}
        for _, p in ipairs(v.p) do pts[#pts + 1] = string.format("%d,%d", p[1], p[2]) end
        e = {
            n = v.n, sp = { [v.m] = table.concat(pts, ";") },
            icon = ICON[v.t], color = COLOR[v.fa],
            lines = { L("Sells") .. ": " .. Sells(v.t), v.z },
            vendor = v,
        }
        v.entry = e
    end
    return e
end

function AV.List()
    local data = HHT.AmmoVendorData or {}
    local db = M.db
    local want = db.kind
    if want == "auto" then
        local am = HHT.modules.ammo
        want = (am and am.needs == "bullet" and "b") or (am and am.needs == "arrow" and "a") or "all"
    end
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local out = {}
    for _, v in ipairs(data) do
        local factionOk = v.fa == "N" or (v.fa == "A" and faction == "Alliance") or (v.fa == "H" and faction == "Horde")
        local typeOk = want == "all" or v.t == "ab" or v.t == want
        if factionOk and typeOk then out[#out + 1] = Entry(v) end
    end
    return out
end

function AV.Show()
    if not M.enabled then return end
    local list = AV.List()
    if #list == 0 then HHT.Print(L("No ammo vendors known here.")); return end
    M.db.onMap = true
    if HHT.PetMap then HHT.PetMap:OpenFor(list) end
end

-- While the low-ammo warning is active the vendors show on the map by themselves; hiding them there keeps them off until it is over.
function AV.AutoShown()
    local am = HHT.modules.ammo
    local low = am and am.enabled and am.lowNow and true or false
    if not low then AV.dismissed = nil end
    return low and not AV.dismissed
end

if HHT.PetMap then
    HHT.PetMap.AddLayer("ammo", "Ammo vendors",
        function() if M.enabled and M.db and (M.db.onMap or AV.AutoShown()) then return AV.List() end end,
        function() return M.db and (M.db.onMap or AV.AutoShown()) and true or false end,
        function(v)
            if not M.db then return end
            M.db.onMap = v and true or false
            AV.dismissed = (not v) and AV.AutoShown() or nil
        end,
        function() return M.db and M.db.onMinimap ~= false end)
end

function AV.Nearest()
    if not (M.enabled and HHT.PetMap) then return end
    local best = HHT.PetMap:Nearest(AV.List())
    if not best then HHT.Print(L("No ammo vendors known here.")); return end
    HHT.PetMap:SetWaypointAt(best[1], best[2], best[3], best[4])
end

-- ---------------------------------------------------------------------------
-- Restock button at merchants: fills the bags with the ammo the weapon uses.
-- ---------------------------------------------------------------------------
local function Merchant(i)
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local ok, t = pcall(C_MerchantFrame.GetItemInfo, i)
        if ok and type(t) == "table" then
            return t.name, t.texture, t.price, t.stackCount, t.numAvailable, t.isUsable, t.hasExtendedCost
        end
    end
    return GetMerchantItemInfo(i)
end

local function BagFree(bag)
    local fn = (C_Container and C_Container.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
    local free, kind = fn(bag)
    return free or 0, kind or 0
end

-- How many pieces of an item still fit in quivers and ammo pouches: room in unfinished stacks plus free slots.
local function Capacity(id, stackSize)
    local famFn = (C_Item and C_Item.GetItemFamily) or GetItemFamily
    local fam = famFn and famFn(id) or 0
    local numSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    local slotInfo = C_Container and C_Container.GetContainerItemInfo
    local cap = 0
    for bag = 1, (NUM_BAG_SLOTS or 4) do
        local free, kind = BagFree(bag)
        if kind ~= 0 and bit.band(kind, fam) ~= 0 then
            cap = cap + free * stackSize
            if slotInfo then
                for slot = 1, numSlots(bag) or 0 do
                    local info = slotInfo(bag, slot)
                    if info and info.itemID == id and info.stackCount < stackSize then cap = cap + stackSize - info.stackCount end
                end
            end
        end
    end
    return cap
end

-- What the button would buy at the open merchant: { index, id, name, bundle, bundles, items, price, cost }, or nil plus a reason.
function AV.Plan()
    local am = HHT.modules.ammo
    if not (am and am.enabled and HHT.AmmoKind) then return nil end
    am:Scan()
    local need = am.needs
    if not need then return nil end
    local okE, eq = pcall(GetInventoryItemID, "player", 0)
    eq = okE and eq or nil
    if eq and HHT.AmmoKind(eq) ~= need then eq = nil end
    local sold, best, equipped = false, nil, nil
    for i = 1, GetMerchantNumItems() do
        local link = GetMerchantItemLink(i)
        local id = link and tonumber(link:match("item:(%d+)"))
        if id and HHT.AmmoKind(id) == need then
            local name, tex, price, qty, avail, usable, ext = Merchant(i)
            if name and not ext then
                sold = true
                local e = { index = i, id = id, name = name, tex = tex, price = price or 0, bundle = math.max(1, qty or 1), avail = avail or -1 }
                local unit = e.price / e.bundle
                if id == eq then equipped = e end
                if usable ~= false and (not best or unit > best.price / best.bundle) then best = e end
            end
        end
    end
    if not sold then return nil end
    local pick = eq and equipped or (not eq and best) or nil
    if not pick then return nil, L("This vendor does not sell your equipped ammo.") end
    local stack = GetMerchantItemMaxStack and GetMerchantItemMaxStack(pick.index) or 200
    if not stack or stack < 1 then stack = 200 end
    local bundles = math.floor(Capacity(pick.id, stack) / pick.bundle)
    if bundles < 1 then return nil, L("No room in your quiver or ammo pouch.") end
    local afford = pick.price > 0 and math.floor(GetMoney() / pick.price) or bundles
    if afford < 1 then return nil, L("Not enough gold.") end
    bundles = math.min(bundles, afford)
    if pick.avail >= 0 then bundles = math.min(bundles, pick.avail) end
    if bundles < 1 then return nil, L("Not enough gold.") end
    pick.bundles, pick.items, pick.cost, pick.stack = bundles, bundles * pick.bundle, bundles * pick.price, stack
    return pick
end

local function Count(id)
    local fn = (C_Item and C_Item.GetItemCount) or GetItemCount
    if not fn then return 0 end
    local ok, n = pcall(fn, id)
    return ok and tonumber(n) or 0
end

local function Buy(plan)
    local before = Count(plan.id)
    -- the client counts single items here, also for ammo sold in bundles, so buy in chunks of one full stack
    local left = plan.items
    while left > 0 do
        local q = math.min(plan.stack, left)
        BuyMerchantItem(plan.index, q)
        left = left - q
    end
    C_Timer.After(1.5, function()
        local got = Count(plan.id) - before
        if got > 0 then HHT.Print(string.format(L("Bought %d x %s."), got, plan.name)) end
    end)
end

local function Money(c)
    c = math.floor(c or 0)
    local g, s, k = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
    local function Icon(name) return "|TInterface\\MoneyFrame\\UI-" .. name .. "Icon:14:14:2:0|t" end
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. Icon("Gold") end
    if s > 0 then parts[#parts + 1] = s .. Icon("Silver") end
    if k > 0 or #parts == 0 then parts[#parts + 1] = k .. Icon("Copper") end
    return table.concat(parts, " ")
end

local function Confirm(plan)
    if not StaticPopupDialogs["HHT_AMMO_RESTOCK"] then
        StaticPopupDialogs["HHT_AMMO_RESTOCK"] = {
            text = "%s", button1 = YES, button2 = NO, timeout = 0, whileDead = false, hideOnEscape = true,
            OnAccept = function()
                local ok, p = pcall(AV.Plan)
                if ok and p then Buy(p) end
            end,
        }
    end
    local coins = Money(plan.cost)
    StaticPopup_Show("HHT_AMMO_RESTOCK", string.format(L("Buy %d x %s for %s?"), plan.items, plan.name, coins))
end

local NATIVE = { "MerchantRepairItemButton", "MerchantRepairAllButton", "MerchantGuildBankRepairButton", "MerchantSellAllJunkButton" }

local function NativeButtons()
    local list = {}
    for _, n in ipairs(NATIVE) do
        local f = _G[n]
        if f and f:IsShown() then list[#list + 1] = f end
    end
    return list
end

local function Points(f)
    local pts = {}
    for i = 1, f:GetNumPoints() do pts[i] = { f:GetPoint(i) } end
    return pts
end

local function SetPoints(f, pts, dx)
    f:ClearAllPoints()
    for i, p in ipairs(pts) do f:SetPoint(p[1], p[2], p[3], (p[4] or 0) + (i == 1 and dx or 0), p[5] or 0) end
end

AV.moved = {}

-- Gap the vendor's own buttons leave between each other, so ours lines up with them (never tighter than 8 so the icons do not touch).
function AV.Gap()
    local list = NativeButtons()
    table.sort(list, function(a, b) return (a:GetLeft() or 0) < (b:GetLeft() or 0) end)
    for i = 2, #list do
        local r, l = list[i - 1]:GetRight(), list[i]:GetLeft()
        if r and l and l - r >= 0 and l - r < 40 then AV.gap = l - r; break end
    end
    return math.max(AV.gap or 6, 8)
end

-- Space between the vendor's own button row and the buyback slot as Blizzard lays it out (without our shift).
function AV.Room()
    local bb = _G.MerchantBuyBackItem
    if not (bb and bb:IsShown() and bb:GetLeft()) then return nil end
    local right, applied = nil, 0
    for _, f in ipairs(NativeButtons()) do
        local r = f:GetRight()
        if r and (not right or r > right) then right = r end
        local m, pts = AV.moved[f], Points(f)
        if m and pts[1] and pts[1][2] == m.rel and math.abs((pts[1][4] or 0) - m.x) < 0.05 then applied = m.dx or 0 end
    end
    if not right then return nil end
    return bb:GetLeft() - right + applied
end

-- Slides the vendor's own bottom-row buttons left so the restock button sits in the row as a fourth one.
function AV.ShiftNative(on, extra)
    local list = NativeButtons()
    local inList = {}
    for _, f in ipairs(list) do inList[f] = true end
    local dx = on and -((AV.button and AV.button:GetWidth() or 36) + AV.Gap()) / 2 - (extra or 0) or 0
    for _, f in ipairs(list) do
        local pts = Points(f)
        -- buttons chained to another button follow it
        if pts[1] and not inList[pts[1][2]] then
            local m = AV.moved[f]
            local function Near(a, b) return math.abs((a or 0) - (b or 0)) < 0.05 end
            local intact = m and pts[1][2] == m.rel and Near(pts[1][4], m.x) and Near(pts[1][5], m.y)
            if on and intact and not Near(m.dx, dx) then
                SetPoints(f, m.orig, dx)
                m.x, m.dx = (m.orig[1][4] or 0) + dx, dx
            elseif on and not intact then
                AV.moved[f] = { orig = pts, x = (pts[1][4] or 0) + dx, y = pts[1][5] or 0, rel = pts[1][2], dx = dx }
                SetPoints(f, pts, dx)
            elseif not on and intact then
                SetPoints(f, m.orig, 0)
                AV.moved[f] = nil
            elseif not on then
                AV.moved[f] = nil
            end
        end
    end
end

-- Copies the textures of a vendor button so the new one matches whatever interface is in use. Returns false when nothing could be copied.
local function CloneLook(src, dst, icon)
    local srcIcon = src.Icon or src.icon or _G[(src:GetName() or "") .. "Icon"]
    if not srcIcon then
        for _, r in ipairs({ src:GetRegions() }) do
            local tex = r:IsObjectType("Texture") and r:GetTexture()
            if type(tex) == "string" and tex:lower():find("icons") then srcIcon = r; break end
        end
    end
    if not srcIcon then return false end
    local copied = 0
    local function Copy(r, t)
        local atlas = r.GetAtlas and r:GetAtlas()
        if atlas then
            t:SetAtlas(atlas)
        else
            local tex = r:GetTexture()
            if tex == nil then return false end
            t:SetTexture(tex)
            t:SetTexCoord(r:GetTexCoord())
        end
        local n = r:GetNumPoints()
        for i = 1, n do
            local p, rel, rp, x, y = r:GetPoint(i)
            t:SetPoint(p, rel == src and dst or rel, rp, x, y)
        end
        if n == 0 then t:SetAllPoints(dst)
        elseif n < 2 then t:SetSize(r:GetSize()) end
        t:SetBlendMode(r:GetBlendMode())
        t:SetVertexColor(r:GetVertexColor())
        return true
    end
    for _, r in ipairs({ src:GetRegions() }) do
        if r:IsObjectType("Texture") then
            if r == srcIcon then
                local n = r:GetNumPoints()
                for i = 1, n do
                    local p, rel, rp, x, y = r:GetPoint(i)
                    icon:SetPoint(p, rel == src and dst or rel, rp, x, y)
                end
                if n < 2 then icon:SetSize(r:GetSize()) end
                icon:SetDrawLayer(r:GetDrawLayer())
            else
                local t = dst:CreateTexture(nil, (r:GetDrawLayer()))
                if Copy(r, t) then
                    t:SetShown(r:IsShown())
                    copied = copied + 1
                end
            end
        end
    end
    for _, k in ipairs({ "Normal", "Pushed", "Highlight" }) do
        local s = src["Get" .. k .. "Texture"](src)
        if s and (s:GetTexture() or (s.GetAtlas and s:GetAtlas())) then
            local atlas = s.GetAtlas and s:GetAtlas()
            if atlas then dst["Set" .. k .. "Atlas"](dst, atlas) else dst["Set" .. k .. "Texture"](dst, s:GetTexture()) end
            local d = dst["Get" .. k .. "Texture"](dst)
            if d and not atlas then d:SetTexCoord(s:GetTexCoord()) end
            if k == "Highlight" then d:SetBlendMode(s:GetBlendMode()) end
            copied = copied + 1
        end
    end
    return copied > 0 and srcIcon ~= nil
end

function AV.PlaceButton()
    local b = AV.button
    if not b then return end
    local db = HHT.modules.ammovendors.db
    b:ClearAllPoints()
    -- sits in the bottom row after the repair and sell-junk buttons
    local anchor = _G.MerchantSellAllJunkButton or _G.MerchantGuildBankRepairButton or _G.MerchantRepairAllButton
    local x, y = db.restockX or 0, db.restockY or 0
    if anchor then
        b:SetPoint("LEFT", anchor, "RIGHT", AV.Gap() + x, y)
    else
        b:SetPoint("BOTTOMLEFT", MerchantFrame, "BOTTOMLEFT", 160 + x, 30 + y)
    end
end

-- BetterBags Next swaps Blizzard's merchant window for its own vendor panel; returns that panel while it is in use.
local function BetterBagsPanel()
    local lib = _G.LibStub and _G.LibStub("AceAddon-3.0", true)
    local ok, panel = pcall(function()
        local bb = lib and lib:GetAddon("BetterBags", true)
        local mod = bb and bb:GetModule("NextVendor", true)
        return mod and mod.panel
    end)
    if ok and panel and not panel.off and panel.frame then return panel end
end

function AV.PlaceBetterBags(panel)
    local b = AV.bbButton
    local db = HHT.modules.ammovendors.db
    b:ClearAllPoints()
    b:SetPoint("BOTTOMLEFT", panel.body or panel.frame, "BOTTOMLEFT", 16 + (db.restockX or 0), 6 + (db.restockY or 0))
    local base = (panel.overlay or panel.frame):GetFrameLevel()
    b:SetFrameLevel(base + 5)
end

function AV.RefreshButton()
    local db = HHT.modules.ammovendors.db
    local panel = BetterBagsPanel()
    local b
    if panel then
        AV.MakeBetterBagsButton(panel)
        b = AV.bbButton
        if AV.button then AV.button:Hide(); pcall(AV.ShiftNative, false) end
    else
        b = AV.button
        if AV.bbButton then AV.bbButton:Hide() end
    end
    if not (b and MerchantFrame and MerchantFrame:IsShown()) then return end
    local ok, plan, why = pcall(AV.Plan)
    local away = panel and (panel.tab or 1) ~= 1 or (not panel and MerchantFrame.selectedTab == 2)
    if not ok or away or not db.restockButton then plan, why = nil, nil end
    b.plan, b.why = plan, why
    local show = plan ~= nil or why ~= nil
    b:SetShown(show)
    b.icon:SetTexture(plan and plan.tex or "Interface\\Icons\\INV_Ammo_Arrow_02")
    b.icon:SetDesaturated(plan == nil)
    b:SetAlpha(plan and 1 or 0.6)
    if panel then
        AV.PlaceBetterBags(panel)
        return
    end
    local shift = show and db.shiftButtons ~= false
    pcall(AV.ShiftNative, shift)
    AV.PlaceButton()
    if shift then
        -- Natives are centred by default, but with few of them the row would end against the buyback slot:
        -- keep the space they had to it (up to 16) and take the rest from the left.
        local total = b:GetWidth() + AV.Gap()
        local ok2, room = pcall(AV.Room)
        if ok2 and room then
            local need = math.max(total / 2, total - math.max(room - 16, 0))
            if need - total / 2 > 0.5 then
                pcall(AV.ShiftNative, true, need - total / 2)
                AV.PlaceButton()
            end
        end
    end
end

local function BuildButton(parent, plain)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(36, 36)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local src
    for _, n in ipairs({ "MerchantSellAllJunkButton", "MerchantRepairAllButton", "MerchantGuildBankRepairButton", "MerchantRepairItemButton" }) do
        if _G[n] then src = _G[n]; break end
    end
    local cloned = false
    if src and not plain then
        b:SetSize(src:GetSize())
        cloned = select(2, pcall(CloneLook, src, b, b.icon)) == true
    end
    if plain then b:SetSize(28, 28) end
    if not cloned then
        local edge = b:CreateTexture(nil, "BACKGROUND")
        edge:SetAllPoints()
        edge:SetColorTexture(0.55, 0.42, 0.2, 1)
        b.icon:ClearAllPoints()
        b.icon:SetPoint("TOPLEFT", 2, -2)
        b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.25)
    end
    local plus = b:CreateFontString(nil, "OVERLAY")
    plus:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    plus:SetPoint("BOTTOMRIGHT", -2, 1)
    plus:SetTextColor(0.67, 0.83, 0.45)
    plus:SetText("+")
    b:SetScript("OnClick", function(self)
        if self.plan then Confirm(self.plan) end
    end)
    b:Hide()
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L("Restock ammo"), 1, 1, 1)
        GameTooltip:AddLine(L("Fills your quiver or ammo pouch with the ammo your weapon uses."), 0.7, 0.7, 0.7, true)
        if self.plan then
            GameTooltip:AddLine(string.format("%d x %s", self.plan.items, self.plan.name), 0.67, 0.83, 0.45)
            GameTooltip:AddLine(Money(self.plan.cost), 1, 1, 1)
        elseif self.why then
            GameTooltip:AddLine(self.why, 1, 0.4, 0.3, true)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

function AV.MakeButton()
    if AV.button or not MerchantFrame then return end
    AV.button = BuildButton(MerchantFrame, false)
    AV.PlaceButton()
end

function AV.MakeBetterBagsButton(panel)
    if AV.bbButton then
        if AV.bbButton:GetParent() ~= panel.frame then AV.bbButton:SetParent(panel.frame) end
        return
    end
    AV.bbButton = BuildButton(panel.frame, true)
    -- tab changes redraw the panel, which is when the button must follow
    if hooksecurefunc and not AV.bbHooked then
        AV.bbHooked = true
        pcall(hooksecurefunc, panel, "Draw", function()
            if M.enabled then AV.RefreshButton() end
        end)
    end
end

function M:OnInit()
    if hooksecurefunc then
        -- Blizzard re-anchors its buttons here, so ours are shifted again afterwards
        if _G.MerchantFrame_UpdateRepairButtons then
            hooksecurefunc("MerchantFrame_UpdateRepairButtons", function()
                if M.enabled and AV.button then AV.RefreshButton() end
            end)
        end
        -- switching between the Merchant and Buyback tabs does not fire a merchant event
        if _G.MerchantFrame_Update then
            hooksecurefunc("MerchantFrame_Update", function()
                if M.enabled and AV.button then AV.RefreshButton() end
            end)
        end
    end
    for _, ev in ipairs({ "MERCHANT_SHOW", "MERCHANT_UPDATE", "BAG_UPDATE_DELAYED", "PLAYER_MONEY" }) do
        HHT:Listen(self, ev, function(m)
            if not m.enabled then return end
            AV.MakeButton()
            AV.RefreshButton()
        end)
    end
end

function M:Refresh()
    if HHT.PetMap then HHT.PetMap:Update() end
end

function M:OnDisable()
    if AV.button then AV.button:Hide(); pcall(AV.ShiftNative, false) end
    if AV.bbButton then AV.bbButton:Hide() end
    if HHT.PetMap then HHT.PetMap:ClearWaypoint(); HHT.PetMap:Update() end
end

function M:BuildOptions(form)
    local db = self.db
    form:Check(L("Show on the world map"), db, "onMap")
    form:Check(L("Also show on the minimap"), db, "onMinimap")
    form:Button(L("Ammo vendors on map"), AV.Show, 240)
    form:Button(L("Waypoint to nearest vendor"), AV.Nearest, 240)
    form:Note(L("Pins appear on the world map. Click a pin to set a waypoint."))
    form:Header(L("Behavior"))
    form:Cycle(L("Show vendors for"), db, "kind", {
        { "auto", L("Ammo your weapon uses") }, { "a", L("Arrows") }, { "b", L("Bullets") }, { "all", L("Arrows and bullets") } })
    form:Check(L("Show restock button"), db, "restockButton", function() AV.RefreshButton() end)
    form:Check(L("Move vendor buttons to make room"), db, "shiftButtons", function() AV.RefreshButton() end)
    form:Stepper(L("Restock button: horizontal"), db, "restockX", -400, 400, 2, AV.PlaceButton)
    form:Stepper(L("Restock button: vertical"), db, "restockY", -400, 400, 2, AV.PlaceButton)
    form:Button(L("Reset restock button position"), function()
        db.restockX, db.restockY = 0, 0
        AV.PlaceButton()
    end, 240)
end
