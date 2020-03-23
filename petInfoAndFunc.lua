--luacheck: globals UnitGUID GetNumGroupMembers IsInGroup IsInRaid SlashCmdList SLASH_SIRPETINFO1 GetPlayerInfoByGUID
local _, SIR = ...
SIR.petToMaster = SIR.petToMaster or {}
SIR.masterToPet = SIR.masterToPet or {}
SIR.petInfoFunc = SIR.petInfoFunc or {}

local getPetID = function(GUID)
    return tonumber(string.match(string.sub(GUID, select(2, string.find(GUID, "%d+-%d+-%d+-%d+-%d"))), "%d+"))
end
local printPetInfo = function()
    print("----------------------------------------")
    print("SIR.petToMaster :")
    for pet, master in pairs(SIR.petToMaster) do
        print(pet, "=>", master)
    end
    print(" ")
    print("SIR.masterToPet :")
    for master, pet in pairs(SIR.masterToPet) do
        print(master, "=>", pet)
    end
end
SIR.petInfoFunc.UNIT_PET = function(unitID)
    local GUID = UnitGUID(unitID)
    local oldPetGUID = SIR.masterToPet[GUID]
    local newPetGUID = UnitGUID(unitID.."pet")
    if oldPetGUID == newPetGUID or not GUID then
        return
    end
    SIR.util.myPrint("SIR.petUpdate not same pet")
    if oldPetGUID then
        for _, spell in ipairs(SIR.data.petSpellsByID[getPetID(oldPetGUID)] or {}) do
            SIR.util.myPrint(spell)
            SIR.rotationFunc.removeSpellAllTabs(GUID, spell)
            SIR.rotationFunc.removeSpellAllTabs(oldPetGUID, spell)
        end
        SIR.petToMaster[oldPetGUID] = nil
    end
    if newPetGUID then
        -- variable pet behaviour here
        SIR.petToMaster[newPetGUID] = GUID
        SIR.masterToPet[GUID] = newPetGUID
        SIR.util.myPrint("there is a new pet with unitID", getPetID(newPetGUID))
        for _, spell in ipairs(SIR.data.petSpellsByID[getPetID(newPetGUID)] or {}) do
            SIR.util.myPrint(spell)
            SIR.rotationFunc.addSpellAllTabs(GUID, spell, SIR.groupInfo[GUID]["CLASS"]
                or select(2, GetPlayerInfoByGUID(GUID))
                or "WARLOCK")
        end
    else
        SIR.masterToPet[GUID] = nil
    end
end
SIR.petInfoFunc.PLAYER_LOGIN = function()
    if IsInGroup() then
        local groupType = "raid"
        local numGroup = GetNumGroupMembers()
        if not IsInRaid() then
            groupType = "party"
            numGroup = numGroup -1
            SIR.petInfoFunc.UNITPET("player")
        end
        for i=1, numGroup do
            SIR.petInfoFunc.UNITPET(groupType..i)
        end
    end
end
SIR.petInfoFunc.newGroupMember = function(GUID, unitID)
    local petGUID = UnitGUID(unitID.."pet")
    if petGUID then
        SIR.masterToPet[GUID] = petGUID
        SIR.petToMaster[petGUID] = GUID
        for _, spell in ipairs(SIR.data.petSpellsByID[getPetID(petGUID)]) do
            SIR.rotationFunc.addSpellAllTabs(spell)
        end
    end
end
SIR.petInfoFunc.removePlayerPet = function(GUID)
    local petGUID = SIR.masterToPet[GUID]
    if petGUID then
        SIR.petToMaster[petGUID] = nil
        SIR.masterToPet[GUID] = nil
        SIR.rotationFunc.removeByGUID(petGUID)
    end
end

SLASH_SIRPETINFO1 = "/sirpetinfo"
SlashCmdList["SIRPETINFO"] = function()
	printPetInfo()
end