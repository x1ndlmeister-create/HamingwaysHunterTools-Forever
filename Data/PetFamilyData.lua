-- Pet family stats for WoW Forever: role, stat modifiers (health, armor, damage) and diet.
-- Source: wow-petopia.com/forever (Forever pet system), values as collected by OneForAll (GPL-3.0).
local ADDON, HHT = ...
HHT.PetFamilyData = {
    { n = "Bat", role = "Offense", h = 1.00, a = 1.00, d = 1.07, diet = { "Fruit", "Fungus" } },
    { n = "Bear", role = "Defense", h = 1.08, a = 1.05, d = 0.91, diet = { "Bread", "Cheese", "Fish", "Fruit", "Fungus", "Meat" } },
    { n = "Bird of Prey", role = "Offense", h = 1.00, a = 1.00, d = 1.07, diet = { "Meat" } },
    { n = "Boar", role = "Defense", h = 1.04, a = 1.09, d = 0.90, diet = { "Bread", "Cheese", "Fish", "Fruit", "Fungus", "Meat" } },
    { n = "Carrion Bird", role = "General", h = 1.00, a = 1.05, d = 1.00, diet = { "Fish", "Meat" } },
    { n = "Cat", role = "Offense", h = 0.98, a = 1.00, d = 1.10, diet = { "Fish", "Meat" } },
    { n = "Core Hound", role = "Offense", diet = { "Meat" } },
    { n = "Crab", role = "Defense", h = 0.96, a = 1.13, d = 0.95, diet = { "Bread", "Fish", "Fruit", "Fungus" } },
    { n = "Crocolisk", role = "Defense", h = 0.95, a = 1.10, d = 1.00, diet = { "Fish", "Meat" } },
    { n = "Fox", role = "General", diet = { "Meat" } },
    { n = "Gorilla", role = "Defense", h = 1.04, a = 1.00, d = 1.02, diet = { "Fruit", "Fungus" } },
    { n = "Hyena", role = "General", h = 1.00, a = 1.05, d = 1.00, diet = { "Fruit", "Meat" } },
    { n = "Raptor", role = "Offense", h = 0.95, a = 1.03, d = 1.10, diet = { "Meat" } },
    { n = "Scorpid", role = "Defense", h = 1.00, a = 1.10, d = 0.94, diet = { "Meat" } },
    { n = "Spider", role = "Offense", h = 1.00, a = 1.00, d = 1.07, diet = { "Meat" } },
    { n = "Tallstrider", role = "Defense", h = 1.05, a = 1.00, d = 1.00, diet = { "Cheese", "Fruit", "Fungus" } },
    { n = "Turtle", role = "Defense", h = 1.00, a = 1.13, d = 0.90, diet = { "Fish", "Fruit", "Fungus" } },
    { n = "Wind Serpent", role = "Offense", h = 1.00, a = 1.00, d = 1.07, diet = { "Bread", "Cheese", "Fish" } },
    { n = "Wolf", role = "General", h = 1.00, a = 1.05, d = 1.00, diet = { "Meat" } },
}
