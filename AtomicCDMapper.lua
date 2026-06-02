local _, AtomicCD = ...

local spellModifiersTable = {
    -- bear
    [104] = {
        -- Barkskin
        [22812] = {
            base = 15000,
            talents = {
                [103210] = 5400, -- Survival of the Fittest (5400ms per rank, reduduction applied AFTER base reduduction)
            }
        }
    }
}

-- returns amount of miliseconds to remove from the base cooldown of the spell
local function getSpellModifiers(playerName, specId, spellId)
    local playerTalents = AtomicCD.getPlayerTalents(playerName)

    local specModifiers = spellModifiersTable[specId][spellId]

    if not specModifiers then
        return 0
    end

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
