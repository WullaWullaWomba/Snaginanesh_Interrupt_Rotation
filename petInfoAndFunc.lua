--luacheck: globals UnitGUID GetNumGroupMembers IsInGroup IsInRaid
local _, SIR = ...
SIR.petInfo = {}
local masterToPet = {}
SIR.petInfoFunc = SIR.petInfoFunc or {}
SIR.petInfoFunc.UNIT_PET = function(unitID)
    SIR.util.myPrint("SIR.petUpdate")
    local GUID = UnitGUID(unitID)
    local oldPetGUID = masterToPet[GUID]
    local newPetGUID = UnitGUID(unitID.."pet")
    if oldPetGUID == newPetGUID then
        return
    end
    if oldPetGUID then
        SIR.petInfo[oldPetGUID] = nil
        if SIR.groupInfo[GUID] and SIR.groupInfo[GUID]["CLASS"] == "WARLOCK"
            and string.match(string.sub(oldPetGUID, 20), "%d*") == "6" then
            SIR.rotationFunc.removeByGUID(GUID)
        end
    end
    if newPetGUID then
        local petType = string.match(string.sub(newPetGUID, 20), "%d*")
        -- variable pet behaviour here
        local spellID
        if petType == "6" then
            spellID = 119910 -- todo real value for fellhunter interrupt
        else
            return
        end
        SIR.petInfo[newPetGUID] = GUID
        masterToPet[GUID] = newPetGUID
        --SIR.rotationFunc.addPetBar(GUID, newPetGUID, spellID)
    else
        masterToPet[GUID] = nil
    end
end
SIR.petInfoFunc.PLAYER_LOGIN = function()
    if IsInGroup() then
        local groupType = "raid"
        local numGroup = GetNumGroupMembers()
        if not IsInRaid() then
            groupType = "party"
            numGroup = numGroup -1
            local playerPetGUID = UnitGUID("playerpet")
            if playerPetGUID then
                masterToPet[SIR.playerInfo["GUID"]] = UnitGUID("playerpet")
                SIR.petToMaster[playerPetGUID] = SIR.playerInfo["GUID"]
            end
        end
        for i=1, numGroup do
            local petGUID = UnitGUID(groupType..i.."pet")
            if petGUID then
                local GUID = UnitGUID(groupType..i)
                masterToPet[GUID] = petGUID
                SIR.petToMaster[petGUID] = GUID
            end
        end
    end
end
SIR.petInfoFunc.removePlayerPet = function(GUID)
    local petGUID = masterToPet[GUID]
    if petGUID then
        SIR.petInfo[petGUID] = nil
        masterToPet[GUID] = nil
        SIR.rotationFunc.removeByGUID(petGUID)
    end
end

