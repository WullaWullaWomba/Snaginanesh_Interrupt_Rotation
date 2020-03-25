--luacheck: globals UnitGUID GetNumGroupMembers IsInGroup IsInRaid SlashCmdList SLASH_SIRPETINFO1 GetPlayerInfoByGUID
--luacheck: globals UnitAura
local _, SIR = ...
SIR.petToMaster = SIR.petToMaster or {}
SIR.masterToPet = SIR.masterToPet or {}
SIR.petInfoFunc = SIR.petInfoFunc or {}

local getPetID = function(GUID)
    return tonumber(string.match(string.sub(GUID, select(2, string.find(GUID, "%d+-%d+-%d+-%d+-%d"))), "%d+"))
end
local addPet = function(GUID, petGUID)
    SIR.petToMaster[petGUID] = GUID
    SIR.masterToPet[GUID] = petGUID
    for _, spell in ipairs(SIR.data.petSpellsByID[getPetID(petGUID)] or {}) do
        -- todo make sure SIR.groupInfo[GUID] is set before
        SIR.util.myPrint("trying to add spell", spell, SIR.groupInfo[GUID] and SIR.groupInfo[GUID]["CLASS"])
        SIR.rotationFunc.addSpellAllTabs(GUID, spell,
            SIR.groupInfo[GUID] and SIR.groupInfo[GUID]["CLASS"]
            or select(2, GetPlayerInfoByGUID(GUID))
            or SIR.util.myPrint("no class found - default WL")
            or "WARLOCK")
    end
end
local removePet = function(GUID, petGUID)
    for _, spell in ipairs(SIR.data.petSpellsByID[getPetID(petGUID)] or {}) do
        SIR.rotationFunc.removeSpellAllTabs(GUID, spell)
        SIR.rotationFunc.removeSpellAllTabs(petGUID, spell)
    end
    SIR.petToMaster[petGUID] = nil
    SIR.masterToPet[GUID] = nil
end
local hasAura = function(unitID, spellID)
    for i=1, 40 do
        if select(10, UnitAura(unitID, i)) == spellID then
            return true
        end
    end
    return false
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
SIR.petInfoFunc.onCombatLogEvent = function(subEvent, sourceGUID)
    if subEvent == "SPELL_AURA_APPLIED" then
        SIR.rotationFunc.addSpellAllTabs(sourceGUID, 132409, SIR.groupInfo[sourceGUID]["CLASS"])
    elseif subEvent == "SPELL_AURA_REMOVED" then
        SIR.rotationFunc.removeSpellAllTabs(sourceGUID, 132409)
    end
end
SIR.petInfoFunc.playerInitByUnitID = function(unitID)

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
    SIR.util.myPrint("SIR.petInfoFunc.UNIT_PET not same pet", unitID)
    if oldPetGUID then
        removePet(GUID, oldPetGUID)
    end
    if newPetGUID then
        addPet(GUID, newPetGUID)
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
            SIR.petInfoFunc.UNIT_PET("player")
            if hasAura("player", 196099) then
                local GUID = UnitGUID("player")
                SIR.rotationFunc.addSpellAllTabs(GUID, 132409, "WARLOCK")
            end
        end
        for i=1, numGroup do
            SIR.petInfoFunc.UNIT_PET(groupType..i)
            if hasAura(groupType..i, 196099) then
                local GUID = UnitGUID(groupType..i)
                SIR.rotationFunc.addSpellAllTabs(GUID, 132409, "WARLOCK")
            end
        end
    else
        SIR.petInfoFunc.UNIT_PET("player")
        if hasAura("player", 196099) then
            local GUID = UnitGUID("player")
            SIR.rotationFunc.addSpellAllTabs(GUID, 132409, "WARLOCK")
        end
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