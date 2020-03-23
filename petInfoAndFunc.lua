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
    -- if old pet ~= new pet
    -- removes bars and info about old pet (if existing)
    -- and adds bars and info about new pet (if existing)
    local GUID = UnitGUID(unitID)
    local oldPetGUID = SIR.masterToPet[GUID]
    local newPetGUID = UnitGUID(unitID.."pet")
    if oldPetGUID == newPetGUID or not GUID then
        return
    end
    SIR.util.myPrint("SIR.petInfoFunc.UNIT_PET not same pet")
    if oldPetGUID then
        for _, spell in ipairs(SIR.data.petSpellsByID[getPetID(oldPetGUID)] or {}) do
            SIR.rotationFunc.removeSpellAllTabs(GUID, spell)
            SIR.rotationFunc.removeSpellAllTabs(oldPetGUID, spell)
        end
        SIR.petToMaster[oldPetGUID] = nil
    end
    if newPetGUID then
        SIR.petToMaster[newPetGUID] = GUID
        SIR.masterToPet[GUID] = newPetGUID
        for _, spell in ipairs(SIR.data.petSpellsByID[getPetID(newPetGUID)] or {}) do
            SIR.util.myPrint(spell)
            SIR.rotationFunc.addSpellAllTabs(GUID, spell, SIR.groupInfo[GUID]["CLASS"]
                or select(2, GetPlayerInfoByGUID(GUID))
                or SIR.util.myPrint("no class found - default WL")
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
    else
        SIR.petInfoFunc.UNITPET("player")
    end
end
SIR.petInfoFunc.removePlayerPet = function(GUID)
    SIR.util.myPrint("SIR.petInfoFunc.removePlayerPet", GUID)
    local petGUID = SIR.masterToPet[GUID]
    if not petGUID then
        return
    end
    for _, spell in ipairs(SIR.data.petSpellsByID[getPetID(petGUID)] or {}) do
        SIR.rotationFunc.removeSpellAllTabs(GUID, spell)
        SIR.rotationFunc.removeSpellAllTabs(petGUID, spell)
    end
end

SLASH_SIRPETINFO1 = "/sirpetinfo"
SlashCmdList["SIRPETINFO"] = function()
	printPetInfo()
end