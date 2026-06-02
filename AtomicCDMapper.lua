local _, AtomicCD = ...

local spellModifiersTable = {
    -- Blood
    [250] = {
    },
    -- Frost
    [251] = {
    },
    -- Unholy
    [252] = {
    },

    -- Havoc
    [577] = {
    },
    -- Vengeance
    [581] = {
    },
    -- Devourer
    [1480] = {
    },

    -- Balance
    [102] = {
    },
    -- Feral
    [103] = {
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
    },
    -- Restoration
    [105] = {
    },

    -- Devastation
    [1467] = {
    },
    -- Preservation
    [1468] = {
    },
    -- Augmentation
    [1473] = {
    },

    -- Beast Mastery
    [253] = {
    },
    -- Marksmanship
    [254] = {
    },
    -- Survival
    [255] = {
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
    if not specModifiers then
        return 0
    end

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

AtomicCD.getSpellModifiers = getSpellModifiers
