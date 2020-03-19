--luacheck: globals UnitGUID GetNumGroupMembers IsInGroup IsInRaid
local _, SIR = ...
SIR.petInfo = {}
local masterToPet = {}
SIR.petInfoFunc = SIR.petInfoFunc or {}
SIR.petInfoFunc.UNIT_PET = function(unitID)
    local GUID = UnitGUID(unitID)
    local oldPetGUID = masterToPet[GUID]
    local newPetGUID = UnitGUID(unitID.."pet")
    if oldPetGUID == newPetGUID then
        return
    end
    SIR.util.myPrint("SIR.petUpdate not same pet")
    if oldPetGUID then
        SIR.petInfo[oldPetGUID] = nil
        if SIR.groupInfo[GUID] and SIR.groupInfo[GUID]["CLASS"] == "WARLOCK"
            and string.match(string.sub(oldPetGUID, 20), "%d*") == "6" then
            SIR.rotationFunc.removeSpellAllTabs(GUID, 119910)
        end
    end
    if newPetGUID then
        local _, petIDstart = string.find(newPetGUID, "Pet-".."%d*".."-".."%d*".."-".."%d*".."-".."%d*".."-".."%d*")
        SIR.util.myPrint(petIDstart)
        SIR.util.myPrint(string.sub(newPetGUID, petIDstart))
        local petType = string.match(string.sub(newPetGUID, petIDstart), "%d*")
        SIR.util.myPrint(newPetGUID)
        SIR.util.myPrint(petType)
        -- variable pet behaviour here
        if petType == "417" then
            SIR.rotationFunc.addSpellAllTabs(GUID, 119910)  -- todo real value for fellhunter interrupt
        else
            return
        end
        SIR.petInfo[newPetGUID] = GUID
        masterToPet[GUID] = newPetGUID
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
SIR.petInfoFunc.newGroupMember = function(unitID)
end
SIR.petInfoFunc.removePlayerPet = function(GUID)
    local petGUID = masterToPet[GUID]
    if petGUID then
        SIR.petInfo[petGUID] = nil
        masterToPet[GUID] = nil
        SIR.rotationFunc.removeByGUID(petGUID)
    end
end

