-- Tranquilizing Shot: rotation window for the group's hunters plus an announcer for your own casts.
-- Every client reports its own cast over addon messages; the raid leader or an assistant sets and broadcasts the order.
local ADDON, HHT = ...
local L, S, UI = HHT.L, HHT.Spells, HHT.UI

HHT:AddGerman({
    ["Tranq announcer"] = "Tranq-Ansager",
    ["Tranq rotation"] = "Tranq-Rotation",
    ["Tranquilizing Shot rotation for the group and an announcer for your own shots."] = "Tranq-Rotation fuer die Gruppe und Ansager fuer deine eigenen Schuesse.",
    ["Announces Tranquilizing Shot in chat."] = "Meldet Beruhigenden Schuss im Chat.",
    ["Rotation"] = "Rotation",
    ["Backup"] = "Backup",
    ["Show rotation window"] = "Rotationsfenster zeigen",
    ["Only hunters who know Tranquilizing Shot"] = "Nur Jaeger die Beruhigenden Schuss kennen",
    ["Hunters without this addon cannot report their spellbook and are always listed."] = "Jaeger ohne dieses Addon koennen ihr Zauberbuch nicht melden und werden immer gelistet.",
    ["Show the 'you are next' alert"] = "\"Du bist dran\"-Hinweis zeigen",
    ["Play a sound when I am next"] = "Ton wenn ich dran bin",
    ["Only the raid leader and assistants can change and broadcast the rotation. Everyone sees who changed it in the raid chat. Right-click a bar to mark a missed shot."] = "Nur Schlachtzugsleiter und Assistenten koennen die Rotation aendern und senden. Wer sie geaendert hat, steht fuer alle im Raid-Chat. Rechtsklick auf einen Balken markiert einen Fehlschuss.",
    ["Test mode"] = "Testmodus",
    ["Test mode (fake hunters)"] = "Testmodus (falsche Jaeger)",
    ["Simulate Tranquilizing Shot"] = "Beruhigenden Schuss simulieren",
    ["Simulate a miss"] = "Fehlschuss simulieren",
    ["Announce my Tranquilizing Shot in chat"] = "Meinen Beruhigenden Schuss im Chat ansagen",
    ["You are next to tranq, listen to your raid lead"] = "Du bist mit Tranq dran, hoer auf deinen Raidleiter",
    ["Tranq alert"] = "Tranq-Hinweis",
    ["No hunters in the group."] = "Keine Jaeger in der Gruppe.",
    ["Offline"] = "Offline",
    ["Dead"] = "Tot",
    ["Miss"] = "Fehl",
    ["Send the rotation to the raid"] = "Rotation an den Raid senden",
    ["Reset the rotation"] = "Rotation zuruecksetzen",
    ["Open the settings"] = "Einstellungen oeffnen",
    ["Hide the window"] = "Fenster ausblenden",
    ["Move up"] = "Nach oben",
    ["Move down"] = "Nach unten",
    ["Move to backup"] = "Ins Backup",
    ["Move to rotation"] = "In die Rotation",
    ["Right-click: mark as missed"] = "Rechtsklick: als Fehlschuss markieren",
    ["%s changed the tranq rotation: %s"] = "%s hat die Tranq-Rotation geaendert: %s",
    ["Backup:"] = "Backup:",
    ["Only the raid leader or an assistant can do that."] = "Das duerfen nur Schlachtzugsleiter oder Assistenten.",
    ["Test mode: "] = "Testmodus: ",
    ["The Tranq module now includes a raid rotation and was switched off. Enable it under Tranq rotation in the settings."] = "Das Tranq-Modul enthaelt jetzt eine Raid-Rotation und wurde ausgeschaltet. Aktiviere es in den Einstellungen unter Tranq-Rotation.",
    ["Tranquilizing Shot on %t!"] = "Beruhigender Schuss auf %t!",
    ["Announce to"] = "Ansagen in",
    ["Automatic (instance/raid/party)"] = "Automatisch (Instanz/Raid/Gruppe)",
    ["Say"] = "Sagen",
    ["Party"] = "Gruppe",
    ["Raid"] = "Raid",
    ["Message"] = "Nachricht",
    ["%t is replaced by the target name. Leave empty for the default text."] = "%t wird durch den Zielnamen ersetzt. Leer lassen fuer den Standardtext.",
    ["Also show the message for myself"] = "Nachricht auch fuer mich anzeigen",
    ["Send test message"] = "Testnachricht senden",
    ["target"] = "Ziel",
})

local M = HHT:NewModule("tranq", {
    name = "Tranq rotation",
    enabledByDefault = false,
    desc = "Tranquilizing Shot rotation for the group and an announcer for your own shots.",
    positions = {
        main = { "CENTER", "CENTER", -420, 60 },
        alert = { "TOP", "TOP", 0, -170 },
    },
    defaults = {
        channel = "auto", msg = "", echo = false, announce = true,
        show = true, onlyKnown = true, alert = true, sound = true, test = false,
    },
})

local DEFAULT_MSG = "Tranquilizing Shot on %t!"

local PREFIX = "HHTTRQ"
local CD = 20 -- Tranquilizing Shot cooldown in seconds
local ROW_W, ROW_H, GAP = 210, 18, 2
local TITLE_H = 24
local MAX_MSG = 240

local function CleanName(n)
    if type(n) ~= "string" or HHT.IsSecret(n) then return nil end
    n = n:gsub("%-.*$", "")
    if n == "" then return nil end
    return n
end

local function IndexOf(list, name)
    for i, n in ipairs(list) do
        if n == name then return i end
    end
end

local function Dist()
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
    return nil
end

local function Send(msg)
    local d = Dist()
    if d and C_ChatInfo and C_ChatInfo.SendAddonMessage then pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, d) end
end

-- Group rank of a player: 2 leader, 1 assistant, 0 otherwise.
local function RankOf(name)
    if IsInRaid and IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local n, rank = GetRaidRosterInfo(i)
            if n and CleanName(n) == name then return rank or 0 end
        end
    elseif IsInGroup and IsInGroup() then
        if CleanName(UnitName("player")) == name then return UnitIsGroupLeader("player") and 2 or 0 end
        for i = 1, GetNumSubgroupMembers() do
            local u = "party" .. i
            if CleanName(UnitName(u)) == name then return UnitIsGroupLeader(u) and 2 or 0 end
        end
    end
    return 0
end

local function NewSet(order, backup)
    return { order = order or {}, backup = backup or {}, cd = {}, miss = {}, knows = {}, last = {} }
end

local function Status(set, name, e)
    local t = set.cd[name]
    local remain = 0
    if t then
        remain = t - GetTime()
        if remain <= 0 then
            set.cd[name] = nil
            set.miss[name] = nil
            remain = 0
        end
    end
    return remain, (remain <= 0 and e.online and not e.dead) and true or false
end

function M:OnInit()
    -- the module grew from a plain announcer: switch it off once on update until the user turns it on again
    local db = self.db
    if not db.rotationSeen then
        db.rotationSeen = true
        if db.enabled then
            db.enabled = false
            HHT.Print(L("The Tranq module now includes a raid rotation and was switched off. Enable it under Tranq rotation in the settings."))
        end
    end
    self.lastTarget = nil
    self.lastSent = 0
    self.me = CleanName(UnitName("player")) or "?"
    self.real = NewSet()
    self.demoSet = NewSet()
    self.demoRoster, self.demoMap = {}, {}
    self.roster, self.rmap = {}, {}
    self.rows, self.flat = {}, {}
    self.sig = ""
    self.demoAt = 0
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX) end
    HHT:Listen(self, "UNIT_SPELLCAST_SENT", "OnSent")
    HHT:Listen(self, "UNIT_SPELLCAST_SUCCEEDED", "OnSucceeded")
    HHT:Listen(self, "CHAT_MSG_ADDON", "OnAddon")
    HHT:Listen(self, "GROUP_ROSTER_UPDATE", "OnRoster")
    HHT:Listen(self, "PLAYER_ENTERING_WORLD", "OnWorld")
    HHT:Listen(self, "SPELLS_CHANGED", "OnSpells")
    HHT:Every(self, 0.1, M.Tick)
end

local function IsTranq(spellId)
    spellId = HHT.SafeNumber(spellId)
    if not spellId then return false end
    for _, id in ipairs(S.Catalog.tranq.ids) do
        if id == spellId then return true end
    end
    return false
end

local function Channel(mode)
    if mode == "say" then return "SAY" end
    if mode == "party" then return IsInGroup and IsInGroup() and "PARTY" or nil end
    if mode == "raid" then return IsInRaid and IsInRaid() and "RAID" or nil end
    if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
    return nil
end

function M:Text(name)
    local t = self.db.msg
    if not t or t:match("^%s*$") then t = L(DEFAULT_MSG) end
    name = name or L("target")
    return (t:gsub("%%t", function() return name end))
end

function M:OnSent(event, unit, target, _, spellId)
    if unit ~= "player" or not IsTranq(spellId) then return end
    if type(target) == "string" and not HHT.IsSecret(target) and target ~= "" then self.lastTarget = target end
end

function M:Announce(name)
    local db = self.db
    local text = self:Text(name)
    local chan = Channel(db.channel)
    if chan then
        local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
        local ok = pcall(send, text, chan)
        if not ok then HHT.Print(text) end
    end
    if db.echo then HHT.Print(text) end
end

function M:OnSucceeded(event, unit, _, spellId)
    if type(unit) ~= "string" then return end
    if unit ~= "player" then
        -- other group members: works for hunters without this addon as long as the client shows their casts
        if (unit:match("^raid%d+$") or unit:match("^party%d+$")) and IsTranq(spellId) then
            local ok, n = pcall(UnitName, unit)
            n = ok and CleanName(n) or nil
            if n then self:Cast(n) end
        end
        return
    end
    if not IsTranq(spellId) then return end
    local now = GetTime()
    if now - self.lastSent < 1 then return end
    self.lastSent = now
    self:LocalCast()
    local name = self.lastTarget
    self.lastTarget = nil
    if not self.db.announce then return end
    if not name then
        local ok, n = pcall(UnitName, "target")
        if ok and type(n) == "string" and not HHT.IsSecret(n) then name = n end
    end
    self:Announce(name)
end

-- ---------------------------------------------------------------------------
-- State: one set holds the rotation order, backups, cooldowns and miss marks
-- ---------------------------------------------------------------------------
function M:Set()
    return self.demo and self.demoSet or self.real
end

-- Own state: cast starts the cooldown and sends the hunter to the end of the rotation.
function M:CastOn(set, name)
    local now = GetTime()
    if set.last[name] and now - set.last[name] < 3 then return false end
    set.last[name] = now
    set.cd[name] = now + CD
    set.miss[name] = nil
    local i = IndexOf(set.order, name)
    if i then
        table.remove(set.order, i)
        set.order[#set.order + 1] = name
    end
    return true
end

function M:Cast(name)
    self:CastOn(self.real, name)
    if self.demo then self:CastOn(self.demoSet, name) end
end

function M:Miss(name)
    local sets = { self.real }
    if self.demo then sets[2] = self.demoSet end
    for _, set in ipairs(sets) do
        self:CastOn(set, name)
        if set.cd[name] then set.miss[name] = true end
    end
end

function M:LocalCast()
    self:Cast(self.me)
    Send("C\tS")
end

function M:LocalMiss()
    self:Miss(self.me)
    Send("C\tM")
end

-- ---------------------------------------------------------------------------
-- Group data and addon messages
-- ---------------------------------------------------------------------------
function M:KnowsTranq()
    local r = S.Resolve("@tranq")
    return r and r.known and true or false
end

function M:OnRoster()
    self.dirty = true
    local n = (IsInGroup and IsInGroup()) and GetNumGroupMembers() or 0
    local old = self.lastN or 0
    self.lastN = n
    if n > 0 and n ~= old then
        self.helloAt = self.helloAt or (GetTime() + 1 + math.random() * 3)
        if old <= 1 then self.ask = true end
    end
end

function M:OnWorld()
    self.helloAt = GetTime() + 4 + math.random() * 4
    self.ask = (IsInGroup and IsInGroup()) and true or nil
    self.dirty = true
end

function M:OnSpells()
    self.helloAt = self.helloAt or (GetTime() + 2 + math.random() * 2)
end

local function Split(s)
    local t = {}
    for n in (s or ""):gmatch("[^,]+") do t[#t + 1] = n end
    return t
end

function M:ApplyRotation(order, backup)
    local set = self.real
    wipe(set.order)
    wipe(set.backup)
    for _, n in ipairs(Split(order)) do set.order[#set.order + 1] = n end
    for _, n in ipairs(Split(backup)) do set.backup[#set.backup + 1] = n end
end

function M:OnAddon(event, prefix, msg, channel, sender)
    if prefix ~= PREFIX or type(msg) ~= "string" or HHT.IsSecret(msg) then return end
    if channel ~= "RAID" and channel ~= "PARTY" and channel ~= "INSTANCE_CHAT" then return end
    sender = CleanName(sender)
    if not sender or sender == self.me then return end
    local kind, a, b = msg:match("^(%a)\t?([^\t]*)\t?([^\t]*)$")
    if not kind then return end
    if kind == "H" then
        self.real.knows[sender] = (a == "1")
    elseif kind == "C" then
        if a == "M" then self:Miss(sender) else self:Cast(sender) end
    elseif kind == "R" then
        if RankOf(sender) >= 1 then self:ApplyRotation(a, b) end
    elseif kind == "X" then
        if RankOf(sender) >= 1 and a ~= "" then self:Miss(a) end
    elseif kind == "Q" then
        self.helloAt = self.helloAt or (GetTime() + 1 + math.random() * 3)
        local set = self.real
        if RankOf(self.me) == 2 and #set.order + #set.backup > 0 and not self.sendAt then
            self.sendAt = GetTime() + 2 + math.random() * 2
        end
    end
end

-- Silent rotation sync (used for new members and by the broadcast button).
function M:SendRotation(set)
    set = set or self:Set()
    local o, bk = {}, {}
    for _, n in ipairs(set.order) do o[#o + 1] = n end
    for _, n in ipairs(set.backup) do bk[#bk + 1] = n end
    local function build() return "R\t" .. table.concat(o, ",") .. "\t" .. table.concat(bk, ",") end
    local msg = build()
    while #msg > MAX_MSG and (#bk > 0 or #o > 0) do
        if #bk > 0 then bk[#bk] = nil else o[#o] = nil end
        msg = build()
    end
    Send(msg)
end

function M:RotationText()
    local set = self:Set()
    local text = table.concat(set.order, " > ")
    if #set.backup > 0 then text = text .. " | " .. L("Backup:") .. " " .. table.concat(set.backup, ", ") end
    return text
end

function M:CanEdit()
    if self.demo or not (IsInGroup and IsInGroup()) then return true end
    return RankOf(self.me) >= 1
end

-- Sends the order to every HHT user and tells the raid who changed it.
function M:Broadcast()
    if not self:CanEdit() then
        HHT.Print(L("Only the raid leader or an assistant can do that."))
        return
    end
    local text = string.format(L("%s changed the tranq rotation: %s"), self.me, self:RotationText())
    if self.demo or not Dist() then
        HHT.Print(L("Test mode: ") .. text)
        return
    end
    self:SendRotation()
    local chan = Channel("auto")
    if chan then
        local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
        pcall(send, text:sub(1, 250), chan)
    end
end

-- ---------------------------------------------------------------------------
-- Roster
-- ---------------------------------------------------------------------------
function M:ScanGroup()
    local list = {}
    local function add(unit)
        if not UnitExists(unit) then return end
        local ok, _, class = pcall(UnitClass, unit)
        if not ok or HHT.IsSecret(class) or class ~= "HUNTER" then return end
        local ok2, name = pcall(UnitName, unit)
        name = ok2 and CleanName(name) or nil
        if not name then return end
        list[#list + 1] = {
            name = name, class = class,
            online = UnitIsConnected(unit) ~= false,
            dead = UnitIsDeadOrGhost(unit) and true or false,
        }
    end
    if IsInRaid and IsInRaid() then
        for i = 1, GetNumGroupMembers() do add("raid" .. i) end
    end
    return list
end

-- Keeps the lists in line with the roster: gone/filtered hunters leave, new ones join the rotation.
function M:Sync(set, roster, map)
    local onlyKnown = self.db.onlyKnown
    local function ok(n)
        if not map[n] then return false end
        if onlyKnown and set.knows[n] == false then return false end
        return true
    end
    local seen = {}
    for _, list in ipairs({ set.order, set.backup }) do
        local i = 1
        while i <= #list do
            local n = list[i]
            if seen[n] or not ok(n) then
                table.remove(list, i)
            else
                seen[n] = true
                i = i + 1
            end
        end
    end
    for _, e in ipairs(roster) do
        if not seen[e.name] and ok(e.name) then
            set.order[#set.order + 1] = e.name
            seen[e.name] = true
        end
    end
end

-- Display lists: available hunters first (in rotation order), then the ones on cooldown/dead/offline.
function M:Entries(set, map)
    local function make(list)
        local ready, busy = {}, {}
        for _, n in ipairs(list) do
            local e = map[n]
            if e then
                local remain, avail = Status(set, n, e)
                local row = { name = n, e = e, remain = remain, avail = avail, miss = (remain > 0 and set.miss[n]) and true or false }
                if avail then ready[#ready + 1] = row else busy[#busy + 1] = row end
            end
        end
        for _, r in ipairs(busy) do ready[#ready + 1] = r end
        return ready
    end
    local rot, bak = make(set.order), make(set.backup)
    local nxt
    if rot[1] and rot[1].avail then nxt = rot[1] elseif bak[1] and bak[1].avail then nxt = bak[1] end
    if nxt then nxt.next = true end
    return rot, bak, nxt
end

function M:SeedDemo()
    local me = self.me
    local function E(n, online, dead) return { name = n, class = "HUNTER", online = online ~= false, dead = dead and true or false } end
    local list = { E("Alpha"), E("Bravo"), E(me), E("Charlie"), E("Delta", false), E("Echo"), E("Foxtrot", true, true) }
    self.demoRoster, self.demoMap = list, {}
    for _, e in ipairs(list) do self.demoMap[e.name] = e end
    local set = NewSet({ "Alpha", "Bravo", me, "Charlie" }, { "Delta", "Echo", "Foxtrot" })
    set.cd.Alpha = GetTime() + 14
    set.miss.Alpha = true
    self.demoSet = set
    self.demoAt = GetTime()
    self.sig = ""
end

function M:Simulate(miss)
    local db = self.db
    if not db.test then db.test = true end
    self:Update()
    local name = self.nextName
    if not name then return end
    local set = self.demoSet
    self:CastOn(set, name)
    if miss then set.miss[name] = true end
    self:Update()
end

-- ---------------------------------------------------------------------------
-- Editing (raid leader / assistants)
-- ---------------------------------------------------------------------------
function M:Move(name, block, dir)
    if not self:CanEdit() then return end
    local rows = block == "order" and self.rotRows or self.bakRows
    local i
    for k, r in ipairs(rows or {}) do
        if r.name == name then i = k end
    end
    local j = i and (i + dir)
    if not j or not rows[j] then return end
    rows[i], rows[j] = rows[j], rows[i]
    local list = self:Set()[block]
    wipe(list)
    for _, r in ipairs(rows) do list[#list + 1] = r.name end
    self:Update()
end

function M:Swap(name, block)
    if not self:CanEdit() then return end
    local set = self:Set()
    local i = IndexOf(set[block], name)
    if i then table.remove(set[block], i) end
    local other = block == "order" and "backup" or "order"
    set[other][#set[other] + 1] = name
    self:Update()
end

function M:ToggleMiss(name)
    local set = self:Set()
    if not set.cd[name] or set.miss[name] then return end
    if name == self.me then
        if self.real == set then self:LocalMiss() else set.miss[name] = true end
        return
    end
    if not self:CanEdit() then return end
    set.miss[name] = true
    if self.real ~= set then return end
    Send("X\t" .. name)
end

function M:ResetRotation()
    if not self:CanEdit() then return end
    if self.demo then
        self:SeedDemo()
    else
        local set = self.real
        wipe(set.order)
        wipe(set.backup)
    end
    self.sig = ""
    self:Update()
end

function M:OpenSettings()
    local C = HHT.Config
    if not C then return end
    C:Create()
    if not C.window:IsShown() then C.window:Show() end
    C:Select("tranq")
end

function M:SetWindow(on)
    self.db.show = on and true or false
    self:Update()
end

-- ---------------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------------
local function Tip(btn, text)
    btn:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L(type(text) == "function" and text() or text))
        GameTooltip:Show()
    end)
    btn:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local function IconButton(parent, icon, text, fn, crop)
    local b = UI.Button(parent, 16, 16, "", fn)
    local t = b:CreateTexture(nil, "ARTWORK")
    t:SetSize(12, 12)
    t:SetPoint("CENTER")
    t:SetTexture(icon)
    if crop then t:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    Tip(b, text)
    return b
end

function M:Build()
    if self.frame then return end
    local f = CreateFrame("Frame", "HamingwaysHunterToolsTranq", UIParent)
    f:SetSize(ROW_W + 12, 80)
    self.frame = f
    UI.Panel(f)
    local a = UI.ACCENT
    f.title = UI.Text(f, L("Tranq rotation"), 12, a[1], a[2], a[3])
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -7)
    f.hRot = UI.Text(f, L("Rotation"), 10, 0.62, 0.62, 0.6)
    f.hBak = UI.Text(f, L("Backup"), 10, 0.62, 0.62, 0.6)
    f.empty = UI.Text(f, L("No hunters in the group."), 11, 0.7, 0.68, 0.6)
    f.empty:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -(TITLE_H + 6))
    f.empty:Hide()

    f.bHide = IconButton(f, "Interface\\Buttons\\UI-GroupLoot-Pass-Up", "Hide the window", function() M:SetWindow(false) end)
    f.bHide:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -5)
    f.bSet = IconButton(f, "Interface\\Icons\\INV_Misc_Gear_01", "Open the settings", function() M:OpenSettings() end, true)
    f.bSet:SetPoint("RIGHT", f.bHide, "LEFT", -3, 0)
    f.bReset = IconButton(f, "Interface\\Buttons\\UI-RefreshButton", "Reset the rotation", function() M:ResetRotation() end)
    f.bReset:SetPoint("RIGHT", f.bSet, "LEFT", -3, 0)
    f.bCast = IconButton(f, "Interface\\Icons\\Ability_Warrior_BattleShout", "Send the rotation to the raid", function() M:Broadcast() end, true)
    f.bCast:SetPoint("RIGHT", f.bReset, "LEFT", -3, 0)

    HHT:MakeMovable(f, self, "main", L("Tranq rotation"))
    f:Hide()

    local al = CreateFrame("Frame", "HamingwaysHunterToolsTranqAlert", UIParent)
    al:SetSize(420, 46)
    self.alertFrame = al
    UI.Panel(al, 0.95, 0.8, 0.2)
    al.text = UI.Text(al, L("You are next to tranq, listen to your raid lead"), 15, 1, 0.85, 0.25)
    al.text:SetPoint("CENTER")
    al:SetWidth(math.max(200, al.text:GetStringWidth() + 40))
    al:SetScript("OnUpdate", function(self)
        if UI.Anim() then
            self.text:SetAlpha(0.65 + 0.35 * math.abs(math.sin(GetTime() * 3)))
        else
            self.text:SetAlpha(1)
        end
    end)
    HHT:MakeMovable(al, self, "alert", L("Tranq alert"))
    al:Hide()
end

function M:Row(i)
    local r = self.rows[i]
    if r then return r end
    local f = self.frame
    r = CreateFrame("Button", nil, f)
    r:SetSize(ROW_W, ROW_H)
    r:RegisterForClicks("RightButtonUp")
    local bg = r:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)
    local bar = CreateFrame("StatusBar", nil, r)
    bar:SetPoint("TOPLEFT", r, "TOPLEFT", 1, -1)
    bar:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -1, 1)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    r.bar = bar
    local txt = CreateFrame("Frame", nil, r)
    txt:SetAllPoints(r)
    txt:SetFrameLevel(bar:GetFrameLevel() + 2)
    r.txt = txt
    r.mark = txt:CreateTexture(nil, "OVERLAY")
    r.mark:SetPoint("TOPLEFT", txt, "TOPLEFT", 0, 0)
    r.mark:SetPoint("BOTTOMLEFT", txt, "BOTTOMLEFT", 0, 0)
    r.mark:SetWidth(3)
    r.mark:SetColorTexture(1, 0.9, 0.3, 1)
    r.mark:Hide()
    r.name = UI.Text(txt, "", 11)
    r.name:SetPoint("LEFT", txt, "LEFT", 7, 0)
    r.name:SetJustifyH("LEFT")
    r.name:SetWidth(92)
    r.name:SetWordWrap(false)
    r.time = UI.Text(txt, "", 11)
    r.time:SetJustifyH("RIGHT")
    r.time:SetWidth(52)

    local function mk(label, tip, fn)
        local b = UI.Button(txt, 14, ROW_H - 4, label, function() fn(r) end)
        b:SetFrameLevel(txt:GetFrameLevel() + 1)
        Tip(b, tip)
        return b
    end
    r.bDown = mk("v", "Move down", function(row) M:Move(row.who, row.block, 1) end)
    r.bDown:SetPoint("RIGHT", txt, "RIGHT", -3, 0)
    r.bUp = mk("^", "Move up", function(row) M:Move(row.who, row.block, -1) end)
    r.bUp:SetPoint("RIGHT", r.bDown, "LEFT", -2, 0)
    r.bSwap = mk("B", function() return r.block == "order" and "Move to backup" or "Move to rotation" end,
        function(row) M:Swap(row.who, row.block) end)
    r.bSwap:SetPoint("RIGHT", r.bUp, "LEFT", -2, 0)

    r:SetScript("OnClick", function(self, btn)
        if btn == "RightButton" then M:ToggleMiss(self.who) end
    end)
    r:SetScript("OnEnter", function(self)
        if not M:CanEdit() then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L("Right-click: mark as missed"))
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.rows[i] = r
    return r
end

function M:Paint(row, item)
    local e = item.e
    local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[e.class]
    local cr, cg, cb = 0.67, 0.83, 0.45
    if cc then cr, cg, cb = cc.r, cc.g, cc.b end
    local bar = row.bar
    local r, g, b, status
    if not e.online then
        r, g, b, status = 0.3, 0.3, 0.3, L("Offline")
        bar:SetValue(1)
    elseif e.dead then
        r, g, b, status = 0.3, 0.3, 0.3, L("Dead")
        bar:SetValue(1)
    elseif item.remain > 0 then
        bar:SetValue(math.max(0, math.min(1, 1 - item.remain / CD)))
        status = tostring(math.ceil(item.remain))
        if item.miss then
            r, g, b = 0.85, 0.2, 0.2
            status = L("Miss") .. " " .. status
        else
            r, g, b = cr * 0.55, cg * 0.55, cb * 0.55
        end
    else
        bar:SetValue(1)
        status = ""
        if item.next then r, g, b = 0.3, 0.85, 0.3 else r, g, b = cr, cg, cb end
    end
    bar:SetStatusBarColor(r, g, b)
    row.name:SetText(item.name)
    row.name:SetTextColor(1, 1, 1)
    row.time:SetText(status)
    row.mark:SetShown(item.next and true or false)
end

function M:Draw(rot, bak, canEdit)
    local f = self.frame
    local sig = canEdit and "e" or "v"
    for _, r in ipairs(rot) do sig = sig .. "," .. r.name end
    sig = sig .. "|"
    for _, r in ipairs(bak) do sig = sig .. "," .. r.name end
    if sig ~= self.sig then
        self.sig = sig
        local y = -(TITLE_H + 4)
        local idx = 0
        local function place(list, block)
            for i, it in ipairs(list) do
                idx = idx + 1
                local row = self:Row(idx)
                row.who, row.block = it.name, block
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", f, "TOPLEFT", 6, y)
                y = y - ROW_H - GAP
                row.bSwap:SetShown(canEdit)
                row.bUp:SetShown(canEdit and i > 1)
                row.bDown:SetShown(canEdit and i < #list)
                row.bSwap.label:SetText(block == "order" and "B" or "R")
                row.time:ClearAllPoints()
                row.time:SetPoint("RIGHT", row.txt, "RIGHT", canEdit and -52 or -6, 0)
                row:Show()
            end
        end
        f.hRot:ClearAllPoints()
        f.hRot:SetPoint("TOPLEFT", f, "TOPLEFT", 8, y)
        y = y - 13
        place(rot, "order")
        y = y - 3
        f.hBak:ClearAllPoints()
        f.hBak:SetPoint("TOPLEFT", f, "TOPLEFT", 8, y)
        y = y - 13
        place(bak, "backup")
        for k = idx + 1, #self.rows do self.rows[k]:Hide() end
        f:SetHeight(-y + 6)
        f.hBak:SetShown(#bak > 0 or canEdit)
        f.hRot:SetShown(true)
        f.empty:SetShown(#rot + #bak == 0)
    end
    local k = 0
    for _, it in ipairs(rot) do k = k + 1; self:Paint(self.rows[k], it) end
    for _, it in ipairs(bak) do k = k + 1; self:Paint(self.rows[k], it) end
end

function M:Tick()
    local now = GetTime()
    if self.helloAt and now >= self.helloAt then
        self.helloAt = nil
        if IsInGroup and IsInGroup() then
            if now - (self.lastHello or 0) > 3 then
                self.lastHello = now
                Send("H\t" .. (self:KnowsTranq() and "1" or "0"))
            end
            if self.ask then
                self.ask = nil
                Send("Q")
            end
        end
    end
    if self.sendAt and now >= self.sendAt then
        self.sendAt = nil
        if now - (self.lastRot or 0) > 10 then
            self.lastRot = now
            self:SendRotation(self.real)
        end
    end
    self:Update()
end

function M:Update()
    local f = self.frame
    if not f or not self.db then return end
    local db = self.db
    local now = GetTime()
    local demo = (db.test or HHT:IsUnlocked(self)) and true or false
    if demo ~= self.demo then
        self.demo = demo
        if demo then self:SeedDemo() end
        self.sig = ""
    end
    local set, roster, map
    if demo then
        if not db.test and now - self.demoAt > 25 then self:SeedDemo() end
        set, roster, map = self.demoSet, self.demoRoster, self.demoMap
    else
        set = self.real
        if self.dirty or now - (self.scanAt or 0) > 1 then
            self.dirty = false
            self.scanAt = now
            self.roster = self:ScanGroup()
            self.rmap = {}
            for _, e in ipairs(self.roster) do self.rmap[e.name] = e end
        end
        set.knows[self.me] = self:KnowsTranq()
        roster, map = self.roster, self.rmap
    end
    self.active = demo or (IsInGroup and IsInGroup()) and true or false
    if #roster > 0 then self:Sync(set, roster, map) end
    local rot, bak, nxt = self:Entries(set, map)
    self.rotRows, self.bakRows = rot, bak
    self.nextName = nxt and nxt.name or nil

    local canEdit = self:CanEdit()
    local unlocked = HHT:IsUnlocked(self)
    local grouped = IsInGroup and IsInGroup()
    local show = db.show ~= false and (demo or (grouped and #rot + #bak > 0)) and true or false
    if show then
        f.bCast:SetShown(canEdit)
        f.bReset:SetShown(canEdit)
        self:Draw(rot, bak, canEdit)
    end
    f:SetShown(show)

    local isNext = nxt ~= nil and nxt.name == self.me
    local alertOn = db.alert and (isNext or unlocked) and true or false
    if alertOn and isNext and not self.wasNext and db.sound and not unlocked then
        pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959)
    end
    self.wasNext = isNext
    if self.alertFrame then self.alertFrame:SetShown(alertOn) end
end

function M:OnEnable()
    local db = self.db
    db.rotationSeen = true
    db.order = db.order or {}
    db.backup = db.backup or {}
    self.real.order, self.real.backup = db.order, db.backup
    self:Build()
    self.demo = nil
    self.wasNext = false
    self.sig = ""
    self.lastN = (IsInGroup and IsInGroup()) and GetNumGroupMembers() or 0
    self.helloAt = GetTime() + 3 + math.random() * 3
    self.ask = (IsInGroup and IsInGroup()) and true or nil
    self.dirty = true
    self:Update()
end

function M:OnDisable()
    if self.frame then self.frame:Hide() end
    if self.alertFrame then self.alertFrame:Hide() end
end

function M:OnLockChanged()
    self:Update()
end

function M:Refresh()
    self.sig = ""
    self.dirty = true
    self:Update()
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Rotation"))
    form:Check(L("Show rotation window"), db, "show")
    form:Check(L("Only hunters who know Tranquilizing Shot"), db, "onlyKnown")
    form:Note(L("Hunters without this addon cannot report their spellbook and are always listed."))
    form:Check(L("Show the 'you are next' alert"), db, "alert")
    form:Check(L("Play a sound when I am next"), db, "sound")
    form:Note(L("Only the raid leader and assistants can change and broadcast the rotation. Everyone sees who changed it in the raid chat. Right-click a bar to mark a missed shot."))
    form:Header(L("Test mode"))
    form:Check(L("Test mode (fake hunters)"), db, "test")
    form:Button(L("Simulate Tranquilizing Shot"), function() self:Simulate(false) end, 220)
    form:Button(L("Simulate a miss"), function() self:Simulate(true) end, 220)
    form:Header(L("Announce to"))
    form:Check(L("Announce my Tranquilizing Shot in chat"), db, "announce")
    form:Cycle(L("Announce to"), db, "channel", {
        { "auto", L("Automatic (instance/raid/party)") }, { "say", L("Say") },
        { "party", L("Party") }, { "raid", L("Raid") } })
    form:Check(L("Also show the message for myself"), db, "echo")
    form:Header(L("Message"))
    form:Note(L("%t is replaced by the target name. Leave empty for the default text."))
    form:Text(L("Message"), db, "msg")
    form:Button(L("Send test message"), function() HHT.Print(self:Text(UnitName("target"))) end, 200)
end
