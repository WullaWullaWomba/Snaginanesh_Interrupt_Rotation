--luacheck: globals UnitGUID GetNumGroupMembers IsInGroup IsInRaid SlashCmdList SLASH_SIRPETINFO1 GetPlayerInfoByGUID
--luacheck: globals UnitAura C_Timer
local _, SIR = ...

local getPetID = function(GUID)
    if GUID then
        return tonumber(string.match(string.sub(GUID, select(2, string.find(GUID, "%d+-%d+-%d+-%d+-%d"))), "%d+"))
    end
end
local addPet = function(GUID, petGUID)
    SIR.petToMaster[petGUID] = GUID
    SIR.masterToPet[GUID] = petGUID

    --Todo make sure groupinfo has been set before
    local class
    if SIR.groupInfo[GUID] then
        class = SIR.groupInfo[GUID]["CLASS"]
    else
        _, class = GetPlayerInfoByGUID(GUID)
    end
    for _, spell in ipairs(SIR.data.petSpellsByID[getPetID(petGUID)] or {}) do
        SIR.rotationFunc.addSpellAllTabs(GUID, spell, class)
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
--[[
local hasAura = function(unitID, spellID)
    for i=1, 40 do
        if select(10, UnitAura(unitID, i)) == spellID then
            SIR.util.myPrint("hasAura", UnitAura(unitID, i))
            return true
        end
    end
    return false
end
]]--
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
        if getPetID(SIR.masterToPet[sourceGUID]) == 417 or getPetID(SIR.masterToPet[sourceGUID]) == 58964 then
            -- 417 felhunter, 58964 observer (glyph)
            SIR.rotationFunc.replaceSpell(sourceGUID, 119910, 132409)
            --SIR.rotationFunc.addSpellAllTabs(sourceGUID, 132409, SIR.groupInfo[sourceGUID]["CLASS"])
            -- sacrificed demon interrupt ability
        end
    elseif subEvent == "SPELL_AURA_REMOVED" then
        SIR.rotationFunc.removeSpellAllTabs(sourceGUID, 132409)
    end
end
SIR.petInfoFunc.UNIT_PET = function(unitID)
    -- if old pet ~= new pet
    -- removes bars and info about old pet (if existing)
    -- and adds bars and info about new pet (if existing)

    local GUID = UnitGUID(unitID)
    local oldPetGUID = SIR.masterToPet[GUID]
    local newPetGUID = UnitGUID(unitID.."pet")
    SIR.util.myPrint("SIR.petInfoFunc.UNIT_PET", "unitID", unitID, "oldPetGUID", oldPetGUID
        , "newPetGUID0", newPetGUID)
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
SIR.petInfoFunc.initialize = function()
    C_Timer.After(5, function()
        SIR.util.iterateGroup(
        function(unitID)
            SIR.petInfoFunc.UNIT_PET(unitID)
        end)
    end)
end
SIR.petInfoFunc.disable = function()
    SIR.petToMaster = {}
    SIR.masterToPet = {}
end
SIR.petInfoFunc.removePlayerPet = function(GUID)
    SIR.util.myPrint("SIR.petInfoFunc.removePlayerPet", GUID)
    local petGUID = SIR.masterToPet[GUID]
    if not petGUID then
        return
    end
    removePet(GUID, petGUID)
end

SLASH_SIRPETINFO1 = "/sirpetinfo"
SlashCmdList["SIRPETINFO"] = function()
	printPetInfo()
end