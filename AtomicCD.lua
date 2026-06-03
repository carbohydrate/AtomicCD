local name, AtomicCD = ...

local AC = CreateFrame("Frame")

local LibSpecialization = LibStub("LibSpecialization")
local LibSpecGroupHandle = {}

-- specId=Number, the spec ID of the player
-- role=String, the role of the player (TANK or HEALER or DAMAGER)
-- position=String, the position of the player (MELEE or RANGED)
-- playerName=String, the name of the player
-- talents=String, a representation of the chosen player talents that will be in a different format based on WoW flavor (Retail, MoP, etc)
local UnitContainerStore = {}
local UnitSpecStore = {}

LibSpecialization.RegisterGroup(LibSpecGroupHandle, function(specId, role, position, playerName, talents)
    UnitSpecStore[playerName] = {
        specId = specId,
        -- specName = specName,
        role = role,
        position = position,
        talents = talents,
    }

    AtomicCD.setPlayerTalents(talents, playerName)
end)

function AC:OnEvent(event, ...)
    self[event](self, ...)
end

local buttonSize = 34
local hPad = 4

local function getXOffset(i)
    if (i == 0) then
        return -hPad
    else
        local offset = (buttonSize * i) + (hPad * i) + hPad
        return -offset
    end
end

local function setupFrames()
    for i = 1, 5 do
        local unit = (i == 1 and "player") or ("party" .. i)
        local frame = _G["CompactPartyFrameMember" .. i]

        local playerName = GetUnitName(unit, true)
        local libSpecData = UnitSpecStore[playerName]
        if frame and playerName and libSpecData then
            local specId = UnitSpecStore[playerName].specId

            local spells = {}
            local count = 0
            for spellId, _ in pairs(AtomicCD.spellModifiersTable[specId]) do
                local spellFrame = CreateFrame("Frame", nil, UIParent)
                spellFrame:SetPoint("RIGHT", frame, "LEFT", getXOffset(count), 0)
                spellFrame:SetSize(buttonSize, buttonSize)

                local texture = spellFrame:CreateTexture(nil, "BACKGROUND")
                texture:SetAllPoints(spellFrame)
                texture:SetTexture(C_Spell.GetSpellTexture(spellId))
                texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                spellFrame.texture = texture

                local cooldown = CreateFrame("Cooldown", nil, spellFrame, "CooldownFrameTemplate")
                cooldown:SetAllPoints(spellFrame)

                spellFrame.cooldown = cooldown

                spells[spellId] = spellFrame

                count = count + 1
            end

            UnitContainerStore[unit] = spells
            
        else
            -- print("CompactPartyFrame or playerName or no libSpecData at index: ", i, " does not exist")
        end
    end
end

function AC:PLAYER_ENTERING_WORLD(a, b, c)
    setupFrames()
end

local function startManualCooldown(frame, durationMs)
    local startTime = GetTime()
    local duration = durationMs / 1000
    frame.cooldownEnd = startTime + duration
    frame.texture:SetDesaturated(true)
    frame.cooldown:SetCooldown(startTime, duration)

    frame:SetScript("OnUpdate", function(self, elapsed)
        if GetTime() >= self.cooldownEnd then
            self.texture:SetDesaturated(false)
            self.cooldown:SetCooldown(0, 0)
            self.cooldownEnd = nil
            self:SetScript("OnUpdate", nil)
        end
    end)
end

function AC:UNIT_SPELLCAST_SUCCEEDED(unit, castGuid, spellId)
    if not UnitExists(unit) then
        return
    end

    local playerName = GetUnitName(unit, true)
    local unitSpec = UnitSpecStore[playerName]

    if not unitSpec then
        print("No spec info found for player:", playerName)
        return
    end

    -- print("UNIT_SPELLCAST_SUCCEEDED", unit, playerName, "class:", unitSpec.specId, "role:", unitSpec.role, unitSpec.position)

    local container = UnitContainerStore[unit]
    if not container then
        return
    end

    local frame = container[spellId]
    if not frame then
        return
    end

    local baseCooldownMs = GetSpellBaseCooldown(spellId)
    local spellModifiers = AtomicCD.getSpellModifiers(playerName, unitSpec.specId, spellId, unitSpec.talents)

    if (spellModifiers > 0) then
        startManualCooldown(frame, baseCooldownMs - spellModifiers)
    else
        startManualCooldown(frame, baseCooldownMs)
    end
end

function AC:GROUP_ROSTER_UPDATE()
    print("GROUP_ROSTER_UPDATE")
    setupFrames()
end

function AC:PLAYER_SPECIALIZATION_CHANGED()
    print("PLAYER_SPECIALIZATION_CHANGED")
end

SLASH_AtomicCD1 = "/ac"
SLASH_AtomicCD2 = "/acd"

SlashCmdList.AtomicCD = function(msg)
    if msg == "" then
        print("TODO!")
    end
end

-- AC:RegisterEvent("ADDON_LOADED")
AC:RegisterEvent("PLAYER_ENTERING_WORLD")
AC:RegisterEvent("GROUP_ROSTER_UPDATE")
AC:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

AC:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "party1", "party2", "party3", "party4")

AC:SetScript("OnEvent", AC.OnEvent)
