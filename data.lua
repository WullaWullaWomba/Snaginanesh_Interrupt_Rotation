--luacheck: globals
local _, SIR = ...
SIR.data = {
    ["classWideInterrupts"] = {
        ["DEATHKNIGHT"] = 47528;
        --["Death Knight"] = 47528;
        ["DEMONHUNTER"] = 183752;
        --["Demon Hunter"] = 183752;
        ["HUNTER"] = 147362;
        --["Hunter"] = 147362;
        ["MAGE"] = 2139;
        --["Mage"] = 2139;
        ["ROGUE"] = 1766;
        --["Rogue"] = 1766;
        ["SHAMAN"] = 57994;
        --["Shaman"] = 57994;
        ["WARRIOR"] = 6552;
        --["Warrior"] = 6552;
    },
    ["cds"] = {
        [47528]=15,--Mind Freeze DK
        [96231]=15,--Rebuke Paladin
        [6552]=15,--Pummel
        [106839]=15,--Skull Bash
        [119910]=24,--Spell lock sac
        [19647]=24, --spell lock
        [119911]=24, --Optical Blast
        [115781]=24,--Optical blast
        [132409]=24, --sac spell lock
        [171138]=24, --shadow lock
        [171139]=24, -- ^^
        [171140]=24, -- ^^
        [57994]=12, --Wind shear
        [147362]=24, --Counter Shot
        [2139]=24, -- Counterspell
        [1766]=15,--Kick
        [116705]=15, --Spear hand strike
        [97547]=60, --Solar Beam
        [78675]=60,--extra solar
        --[31935]=15, --Avenger's Shield
        [183752]=15, --Consume Magic (DH)
        [15487]=45, -- Silence Priest
        [187707]=15, --Muzzle
    },
    ["specInterrupts"] = {
        -- Monk
        [268] = 116705, -- Brewmaster
        [269] = 116705, -- Windwalker
        [270] = nil, -- Mistweaver

        -- Paladin
        [65] = nil, -- Holy
        [66] = 96231, -- Protection
        [70] = 96231, -- Retribution

        -- Priest
        [256] = nil, -- Discipline
        [257] = nil, -- Holy
        [258] = 15487, -- Shadow

        -- Druid
        [102] = 97547, -- Balance
        [103] = 106839, -- Feral
        [104] = 106839, -- Guardian
        [105] = nil, -- Restoration

        -- Warlock
        [265] = 132409, -- Affliction
        [266] = 132409, -- Demonology
        [267] = 132409, -- Destruction

        -- Death Knight
        [250] = 47528, -- Blood
        [251] = 47528, -- Frost
        [252] = 47528, -- Unholy

        -- Demon Hunter
        [577] = 183752, -- Havoc
        [581] = 183752, -- Vengeance

        -- Hunter
        [253] = 147362, -- Beast Mastery
        [254] = 147362, -- Marksmanship
        [255] = 147362, -- Survival

        -- Mage
        [62] = 2139, -- Arcane
        [63] = 2139, -- Fire
        [64] = 2139, -- Frost

        -- Rogue
        [259] = 1766, -- Assassination
        [260] = 1766, -- Outlaw
        [261] = 1766, -- Subtlety

        -- Shaman
        [262] = 57994, -- Elemental
        [263] = 57994, -- Enhancement
        [264] = 57994, -- Restoration

        --Warrior
        [71] = 6552, -- Arms
        [72] = 6552, -- Fury
        [73] = 6552, -- Protection
    },
    ["classColorsHex"] = {
        ["DEATHKNIGHT"] = "C41F3B",
        ["DEMONHUNTER"] = "A330C9",
        ["DRUID"] = "FF7D0A",
        ["HUNTER"] = "ABD473",
        ["MAGE"] = "40C7EB",
        ["MONK"] = "00FF96",
        ["PALADIN"] = "F58CBA",
        ["PRIEST"] = "FFFFFF",
        ["ROGUE"] = "FFF569",
        ["SHAMAN"] = "0070DE",
        ["WARLOCK"] = "8787ED",
        ["WARRIOR"] = "C79C6E",
    },
    ["classColorsRGB"] = {
        ["DEATHKNIGHT"] = 	{.77, .12, .23},
        ["DEMONHUNTER"] = {.64, .19, .79},
        ["DRUID"] = {1., .49, .04},
        ["HUNTER"] = {.67,.83,.45},
        ["MAGE"] = {.25, .78, .92},
        ["MONK"] = {0, 1, .59},
        ["PALADIN"] = {.96, .55, .73},
        ["PRIEST"] = {1, 1, 1},
        ["ROGUE"] = {1, .96,.41},
        ["SHAMAN"] = {0, .44, .87},
        ["WARLOCK"] = {.53, .53, .93},
        ["WARRIOR"] = {.78, .61, .43},
    },
    ["chatTypes"] = {
        "Party",
        "Raid",
        "Guild",
        "Whisper",
    },
    ["specIDs"] = {
        --Warrior
        71, -- Arms
        72, -- Fury
        73, -- Protection

        -- Paladin
        65, -- Holy
        66, -- Protection
        70, -- Retribution

        -- Hunter
        253, -- Beast Mastery
        254, -- Marksmanship
        255, -- Survival

        -- Rogue
        259, -- Assassination
        260, -- Outlaw
        261, -- Subtlety

        -- Priest
        256, -- Discipline
        257, -- Holy
        258, -- Shadow

        -- Death Knight
        250, -- Blood
        251, -- Frost
        252, -- Unholy

        -- Shaman
        262, -- Elemental
        263, -- Enhancement
        264, -- Restoration

        -- Mage
        62, -- Arcane
        63, -- Fire
        64, -- Frost

        -- Warlock
        265, -- Affliction
        266, -- Demonology
        267, -- Destruction

        -- Monk
        268, -- Brewmaster
        269, -- Windwalker
        270, -- Mistweaver

        -- Druid
        102, -- Balance
        103, -- Feral
        104, -- Guardian
        105, -- Restoration

        -- Demon Hunter
        577, -- Havoc
        581, -- Vengeance
    },
    ["classSpecIDs"] = {
        --Warrior
        [1] = {71, 72, 73,}, -- Arms Fury Protection
        -- Paladin
        [2] = {65, 66, 70,}, -- Holy Protection Retribution
        -- Hunter
        [3] = {253, 254, 255,}, -- Beast Mastery Marksmanship Survival
        -- Rogue
        [4] = {259, 260, 261,}, -- Assassination Outlaw Subtlety
        -- Priest
        [5] = {256, 257, 258,}, -- Discipline Holy Shadow
        -- Death Knight
        [6] = {250, 251, 252,}, -- Blood Frost Unholy
        -- Shaman
        [7] = {262, 263, 264,}, -- Elemental Enhancement Restoration
        -- Mage
        [8] = {62, 63, 64,},-- Arcane Fire Frost
        -- Warlock
        [9] = {265, 266, 267,}, -- Affliction Demonology Destruction
        -- Monk
        [10] = {268, 269, 270,},  -- Brewmaster Windwalker Mistweaver
        -- Druid
        [11] = {102, 103, 104, 105,}, -- Balance Feral Guardian Restoration
        -- Demon Hunter
        [12] = {577, 581,}, -- Havoc Vengeance
    },
}