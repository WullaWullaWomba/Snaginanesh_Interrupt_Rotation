--luacheck: globals UnitGUID
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
    end
    if newPetGUID then
        local petType = string.match(string.sub(newPetGUID, 20), "%d*")
        -- variable pet behaviour here
        local spellID
        if petType == "6" then
            spellID = 1337 -- todo real value for fellhunter interrupt
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
SIR.petInfoFunc.removePlayerPet = function(GUID)
    local petGUID = masterToPet[GUID]
    if petGUID then
        SIR.petInfo[petGUID] = nil
        masterToPet[GUID] = nil
        SIR.rotationFunc.removeByGUID(petGUID)
    end
end

