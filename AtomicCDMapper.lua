local _, AtomicCD = ...

local spellModifiersTable = {
    -- Blood
    [250] = {
        -- Dancing Rune Weapon
        [49028] = {},
    },
    -- Frost
    [251] = {
        -- Breath of Sindragosa
        [1249658] = {},
    },
    -- Unholy
    [252] = {
        -- Army of the Dead
        [42650] = {},
    },

    -- Havoc
    [577] = {
        -- Disrupt
        [183752] = {},
        -- Metamorphosis
        [191427] = {},
    },
    -- Vengeance
    [581] = {
        -- Disrupt
        [183752] = {},
        -- Metamorphosis
        [187827] = {},
    },
    -- Devourer
    [1480] = {
        -- Disrupt
        [183752] = {},
        -- Soul Immolation
        [1241937] = {},
    },

    -- Balance
    [102] = {
        -- Incarnation: Chosen of Elune
        [102560] = {},
    },
    -- Feral
    [103] = {
        [106951] = {
            talents = {
                [103161] = 60000
            }
        }
    },
    -- Guardian
    [104] = {
        -- Barkskin
        [22812] = {
            base = 15000,
            talents = {
                [103210] = 5400, -- Survival of the Fittest (5400ms per rank, reduduction applied AFTER base reduduction)
            },
        },
        -- Incarnation: Guardian of Ursoc
        [102558] = {},
    },
    -- Restoration
    [105] = {
        -- Tranquility
        [740] = {},
        -- Incarnation: Tree of Life
        [33891] = {},
        [102342] = {},
    },

    -- Devastation
    [1467] = {
        -- Dragonrage
        [375087] = {},
    },
    -- Preservation
    [1468] = {
        -- Stasis
        [370537] = {},
        -- TimeDilation
        [357170] = {},
    },
    -- Augmentation
    [1473] = {
        -- Breath of Eons
        [403631] = {},
    },

    -- Beast Mastery
    [253] = {
        -- Counter Shot
        [147362] = {},
    },
    -- Marksmanship
    [254] = {
        -- Counter Shot
        [147362] = {},
        -- Trueshot
        [288613] = {
            talents = {
                -- Calling the Shots
                [128379] = 30000,
            }
        },
    },
    -- Survival
    [255] = {
        -- Takedown
        [1250646] = {
            talents = {
                [135511] = 15000,
            }
        },
        -- Muzzle
        [187707] = {},
    },

    -- Arcane
    [62] = {
    },
    -- Fire
    [63] = {
    },
    -- Frost
    [64] = {
    },

    -- Brewmaster
    [268] = {
    },
    -- Windwalker
    [269] = {
    },
    -- Mistweaver
    [270] = {
    },

    -- Holy
    [65] = {
    },
    -- Protection
    [66] = {
    },
    -- Retribution
    [70] = {
    },

    -- Discipline
    [256] = {
    },
    -- Holy
    [257] = {
    },
    -- Shadow
    [258] = {
    },

    -- Assassination
    [259] = {
    },
    -- Outlaw
    [260] = {
    },
    -- Subtlety
    [261] = {
    },

    -- Elemental
    [262] = {
    },
    -- Enhancement
    [263] = {
    },
    -- Restoration
    [264] = {
        -- Spirit Link Totem
        [98008] = {},
        -- Healing Tide Totem
        [108280] = {
            talents = {
                [101913] = 60000, -- First Ascendant
            },
        },
        -- Ascendance
        [114052] = {
            talents = {
                [101913] = 60000, -- First Ascendant
            },
        },
        -- Wind Shear
        [57994] = {},
    },

    -- Affliction
    [265] = {
    },
    -- Demonology
    [266] = {
    },
    -- Destruction
    [267] = {
    },

    -- Arms
    [71] = {
    },
    -- Fury
    [72] = {
    },
    -- Protection
    [73] = {
    },
}

-- returns amount of miliseconds to remove from the base cooldown of the spell
local function getSpellModifiers(playerName, specId, spellId)
    local specModifiers = spellModifiersTable[specId][spellId]
    local playerTalents = AtomicCD.getPlayerTalents(playerName)

    local baseModifier = specModifiers.base or 0
    local talentsToCheck = specModifiers.talents or {}

    local talentModifier = 0
    for index, numberOfTalentNodesSelected in pairs(talentsToCheck) do
        local tVal = playerTalents[index] or 0
        talentModifier = talentModifier + (tVal * numberOfTalentNodesSelected)
    end

    local spellModifiers = baseModifier + talentModifier

    return spellModifiers
end

AtomicCD.spellModifiersTable = spellModifiersTable
AtomicCD.getSpellModifiers = getSpellModifiers
