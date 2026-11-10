-- Tranquilizing Shot announcer: tells the group when you fire Tranquilizing Shot.
local ADDON, HHT = ...
local L, S = HHT.L, HHT.Spells

HHT:AddGerman({
    ["Tranq announcer"] = "Tranq-Ansager",
    ["Announces Tranquilizing Shot in chat."] = "Meldet Beruhigenden Schuss im Chat.",
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
    name = "Tranq announcer",
    desc = "Announces Tranquilizing Shot in chat.",
    noFrame = true,
    defaults = {
        channel = "auto", msg = "", echo = false,
    },
})

local DEFAULT_MSG = "Tranquilizing Shot on %t!"

function M:OnInit()
    self.lastTarget = nil
    self.lastSent = 0
    HHT:Listen(self, "UNIT_SPELLCAST_SENT", "OnSent")
    HHT:Listen(self, "UNIT_SPELLCAST_SUCCEEDED", "OnSucceeded")
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
    if unit ~= "player" or not IsTranq(spellId) then return end
    local now = GetTime()
    if now - self.lastSent < 1 then return end
    self.lastSent = now
    local name = self.lastTarget
    self.lastTarget = nil
    if not name then
        local ok, n = pcall(UnitName, "target")
        if ok and type(n) == "string" and not HHT.IsSecret(n) then name = n end
    end
    self:Announce(name)
end

function M:BuildOptions(form)
    local db = self.db
    form:Header(L("Announce to"))
    form:Cycle(L("Announce to"), db, "channel", {
        { "auto", L("Automatic (instance/raid/party)") }, { "say", L("Say") },
        { "party", L("Party") }, { "raid", L("Raid") } })
    form:Check(L("Also show the message for myself"), db, "echo")
    form:Header(L("Message"))
    form:Note(L("%t is replaced by the target name. Leave empty for the default text."))
    form:Text(L("Message"), db, "msg")
    form:Button(L("Send test message"), function() HHT.Print(self:Text(UnitName("target"))) end, 200)
end
