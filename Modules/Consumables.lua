-- Missing consumables. Placeholder, not available yet.
local ADDON, HHT = ...

HHT:AddGerman({
    ["Missing consumables"] = "Fehlende Verbrauchsgueter",
    ["Shows missing consumables such as food, flasks and potions. WIP, coming soon."] = "Zeigt fehlende Verbrauchsgueter wie Essen, Flaeschchen und Traenke. In Arbeit, kommt bald.",
})

HHT:NewModule("consumables", {
    name = "Missing consumables",
    desc = "Shows missing consumables such as food, flasks and potions. WIP, coming soon.",
    noFrame = true,
    wip = true,
})
