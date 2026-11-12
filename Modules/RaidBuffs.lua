-- Missing raid and party buffs. Placeholder, not available yet.
local ADDON, HHT = ...

HHT:AddGerman({
    ["WIP - coming soon"] = "In Arbeit - kommt bald",
    ["This module is not available yet and cannot be enabled."] = "Dieses Modul ist noch nicht verfuegbar und kann nicht aktiviert werden.",
    ["Missing buffs"] = "Fehlende Buffs",
    ["Shows missing raid and party buffs. WIP, coming soon."] = "Zeigt fehlende Raid- und Gruppenbuffs. In Arbeit, kommt bald.",
})

HHT:NewModule("raidbuffs", {
    name = "Missing buffs",
    desc = "Shows missing raid and party buffs. WIP, coming soon.",
    noFrame = true,
    wip = true,
})
