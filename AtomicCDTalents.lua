local _, AtomicCD = ...

local specTalentData = {}

-- playerName -> talentId
local talentStore = {}

local function readLoadoutHeader(importStream)
    local bitWidthHeaderVersion = 8
    local bitWidthSpecID = 16

    local headerBitWidth = bitWidthHeaderVersion + bitWidthSpecID + 128;
    local importStreamTotalBits = importStream:GetNumberOfBits();
    if (importStreamTotalBits < headerBitWidth) then
        return false, 0, 0, 0;
    end
    local serializationVersion = importStream:ExtractValue(bitWidthHeaderVersion);
    local specID = importStream:ExtractValue(bitWidthSpecID);

    -- treeHash is a 128bit hash, passed as an array of 16, 8-bit values
    local treeHash = {};
    for i = 1, 16, 1 do
        treeHash[i] = importStream:ExtractValue(8);
    end
    return true, serializationVersion, specID, treeHash;
end

local function getTalentData(specId)
    if specTalentData[specId] then
        print('returning cached talent data for specId:', specId)
        -- return unpack(specTalentData[specId])
        return specTalentData[specId]
    end

    local configId = Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID
    local specData = {}
    local specDataByNodeId = {}
    local heroData = {}

    -- configInfo is nil if you don't do this?
    C_ClassTalents.InitializeViewLoadout(specId, 90)
    C_ClassTalents.ViewLoadout({})

    local configInfo = C_Traits.GetConfigInfo(configId)
    if configInfo == nil then return end

    local subTreeIDs = C_ClassTalents.GetHeroTalentSpecsForClassSpec(configId, specId)

    for _, treeId in ipairs(configInfo.treeIDs) do
        local nodes = C_Traits.GetTreeNodes(treeId)
        for _, nodeId in ipairs(nodes) do
            local node = C_Traits.GetNodeInfo(configId, nodeId)
            if node and node.ID ~= 0 then
                for idx, talentId in ipairs(node.entryIDs) do
                    local entryInfo = C_Traits.GetEntryInfo(configId, talentId)
                    if entryInfo.definitionID then
                        local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                        if definitionInfo.spellID then
                            -- local spellName = ExecEnv.GetSpellName(definitionInfo.spellID)
                            local spellName = C_Spell.GetSpellName(definitionInfo.spellID)
                            if spellName then
                                local talentData = {
                                    talentId,
                                    definitionInfo.spellID,
                                    { node.posX, node.posY, idx, #node.entryIDs },
                                    {}, -- Target if it exists,
                                    node.maxRanks
                                }
                                -- print('node.ID:', node.ID)
                                specDataByNodeId[node.ID] = specDataByNodeId[node.ID] or {}
                                specDataByNodeId[node.ID][idx] = talentData
                                for _, edge in pairs(node.visibleEdges) do
                                    local targetNodeId = edge.targetNode
                                    local targetNode = C_Traits.GetNodeInfo(configId, targetNodeId)
                                    local targetNodeTalentId1 = targetNode.entryIDs[1]
                                    if targetNodeTalentId1 then
                                        -- add as target 1st talentId
                                        -- because we don't save nodes
                                        tinsert(talentData[4], targetNodeTalentId1)
                                    end
                                end
                                local subTreeIndex = node.subTreeID and tIndexOf(subTreeIDs, node.subTreeID) or nil
                                if subTreeIndex then
                                    local subTreeInfo = C_Traits.GetSubTreeInfo(configId, node.subTreeID)
                                    talentData[3][1] = node.posX - subTreeInfo.posX
                                    talentData[3][2] = node.posY - subTreeInfo.posY
                                    talentData[3][5] = subTreeIndex
                                    tinsert(heroData, talentData)
                                elseif not node.subTreeID then
                                    tinsert(specData, talentData)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    specTalentData[specId] = specDataByNodeId

    return specDataByNodeId
end

local function setPlayerTalents(talentString, playerName)
    print("setting player talents!")
    local importStream = ExportUtil.MakeImportDataStream(talentString);
    local _, serializationVersion, specId = readLoadoutHeader(importStream);
    local treeID = C_ClassTalents.GetTraitTreeForSpec(specId)
    local treeNodes = C_Traits.GetTreeNodes(treeID);

    local talentsData = getTalentData(specId)

    local results = {};
    local bitWidthRanksPurchased = 6

    for _, nodeId in ipairs(treeNodes) do
        local nodeSelectedValue = importStream:ExtractValue(1)
        local isNodeSelected = nodeSelectedValue == 1
        local isPartiallyRanked = false
        local partialRanksPurchased = 0
        local isChoiceNode = false
        local choiceNodeSelection = 1

        if (isNodeSelected) then
            if serializationVersion == 2 then
                local nodePurchasedValue = importStream:ExtractValue(1)
                local isNodePurchased = nodePurchasedValue == 1
                if (isNodePurchased) then
                    local isPartiallyRankedValue = importStream:ExtractValue(1)
                    isPartiallyRanked = isPartiallyRankedValue == 1
                    if (isPartiallyRanked) then
                        partialRanksPurchased = importStream:ExtractValue(bitWidthRanksPurchased)
                    end
                    local isChoiceNodeValue = importStream:ExtractValue(1)
                    isChoiceNode = isChoiceNodeValue == 1
                    if (isChoiceNode) then
                        choiceNodeSelection = importStream:ExtractValue(2) + 1
                    end
                end
            else
                local isPartiallyRankedValue = importStream:ExtractValue(1)
                isPartiallyRanked = isPartiallyRankedValue == 1
                if (isPartiallyRanked) then
                    partialRanksPurchased = importStream:ExtractValue(bitWidthRanksPurchased)
                end
                local isChoiceNodeValue = importStream:ExtractValue(1)
                isChoiceNode = isChoiceNodeValue == 1
                if (isChoiceNode) then
                    choiceNodeSelection = importStream:ExtractValue(2) + 1
                end
            end
        end

        local tData = talentsData and talentsData[nodeId] and talentsData[nodeId][choiceNodeSelection]

        if tData then
            if isPartiallyRanked then
                results[tData[1]] = partialRanksPurchased
            else
                results[tData[1]] = nodeSelectedValue == 1 and tData[5] or 0
            end
        end
        if isChoiceNode then
            local unselectedChoiceNodeIdx = choiceNodeSelection == 1 and 2 or 1
            local unselectedTalentData = talentsData and talentsData[nodeId] and
            talentsData[nodeId][unselectedChoiceNodeIdx]
            if unselectedTalentData then
                results[unselectedTalentData[1]] = 0
            end
        end
    end

    talentStore[playerName] = results
end

local function getPlayerTalents(playerName)
    if (not talentStore[playerName]) then
        print("no talents found for player:", playerName)
        return nil
    end

    return talentStore[playerName]
end

AtomicCD.setPlayerTalents = setPlayerTalents
AtomicCD.getPlayerTalents = getPlayerTalents
