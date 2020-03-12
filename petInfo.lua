--luacheck: globals UnitGUID
local _, SIR = ...
SIR.petInfo = {}

SIR.petFunc.updatePet = function(unitID)
    if unitID then
        local GUID = UnitGUID(unitID)
        local oldPetGUID = SIR.petInfo[GUID]
        local petGUID = UnitGUID(unitID.."pet")
        if oldPetGUID == petGUID then
            return
        end
        if oldPetGUID then
            -- todo remove old pet
        end
        if petGUID then
            -- add pet
        end
    end
end