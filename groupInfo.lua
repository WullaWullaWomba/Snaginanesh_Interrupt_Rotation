--luacheck: globals CreateFrame GetTalentInfo GetPlayerInfoByGUID GetInspectSpecialization NotifyInspect
--luacheck: globals GetSpecializationInfo GetSpecialization CanInspect UnitIsConnected InspectFrame
--luacheck: globals GetNumGroupMembers IsInGroup IsInRaid UnitIsDeadOrGhost
--luacheck: globals GetTime C_Timer max UnitGUID UnitInParty unpack
--luacheck: globals SLASH_MYINSPECT1 SlashCmdList SnagiIntRotaSaved
local _, SIR = ...
SIR.util = SIR.util or {}
SIR.playerInfo = SIR.playerInfo or {}
SIR.groupInfo = SIR.groupInfo or {}

local reverseTable, remove = SIR.util.reverseTable, SIR.util.remove
local toBeInitialized = {}
local toBeInspectedActive = {}
local toBeInspectedInactive = {}
local recentInspectTimes = {}
local numGroupMembers = -99

local printInspect = function()
    print("----------------------------------------")
    print("SIR.groupInfo :")
    local count = 0
    for guid, info in pairs(SIR.groupInfo) do
        print(guid, " ", info["NAME"], " ", info["SERVER"], " ", info["CLASS"], " ",
        info["SPEC"], " ", unpack(info["TALENTS"]))
        count = count+1
    end
    print("#SIR.groupInfo "..count)
    print(" ")
    print("toBeInspectedActive #"..#toBeInspectedActive..":")
    for _, guid in ipairs(toBeInspectedActive) do
        print(select(6, GetPlayerInfoByGUID(guid)))
    end
    print(" ")
    print("toBeInspectedInactive #"..#toBeInspectedInactive..":")
    for _, guid in ipairs(toBeInspectedInactive) do
        print(select(6, GetPlayerInfoByGUID(guid)))
    end
    print(" ")
    print("toBeInspectedInactive #"..#toBeInitialized..":")
    for _, guid in ipairs(toBeInitialized) do
        print(select(6, GetPlayerInfoByGUID(guid)))
    end
    print("----------------------------------------")
end
local setInitialInfo = function(GUID)
    local _, class, _, _, _, name, server = GetPlayerInfoByGUID(GUID)
    if server then
        if server == "" then
            server = SIR.playerInfo["REALMN"];
        end
    else
        return false
    end
    SIR.groupInfo[GUID] = {
        ["NAME"] = name,
        ["SERVER"] = server,
        ["CLASS"] = class,
        ["TALENTS"] = {},
    }
    SIR.rotationFunc.playerInit(GUID)
    return true
end

local inspectNext
inspectNext = function()
	for i = #recentInspectTimes, 1, -1 do
		if (recentInspectTimes[i] < (GetTime()-11)) then
			recentInspectTimes[i] = nil
		else
			break
        end
    end
    for i=#toBeInitialized, 1, -1 do
        if setInitialInfo(toBeInitialized[i]) then
            remove(toBeInitialized, i)
        end
    end
    if #recentInspectTimes > 4 or (InspectFrame and InspectFrame:IsShown()) or UnitIsDeadOrGhost("player") then
        C_Timer.After(2.1, function() inspectNext() end)
		return
    end
    if #toBeInspectedActive == 0 then
        toBeInspectedActive, toBeInspectedInactive = toBeInspectedInactive, toBeInspectedActive
        reverseTable(toBeInspectedActive)
    end

    for i=#toBeInspectedActive, 1, -1  do
        local GUID = toBeInspectedActive[i]
        toBeInspectedActive[i] = nil
        toBeInspectedInactive[#toBeInspectedInactive+1] = GUID
        local name = SIR.groupInfo[GUID]["NAME"]
        --todo UnitInParty(name)
        if CanInspect(name) and UnitIsConnected(name) and UnitInParty(name) then
            --SIR.util.myPrint("NotifyInspect", name)
            NotifyInspect(name)
            break
        end
    end
    C_Timer.After(2.1, function() inspectNext() end)
end
SIR.groupInfoLoad = function()
    if not IsInGroup() then
        SIR.groupInfo = {
            [SIR.playerInfo["GUID"]] = {
                ["NAME"] = SIR.playerInfo["NAME"],
                ["SERVER"] = SIR.playerInfo["REALMN"],
                ["CLASS"] = SIR.playerInfo["CLASS"],
                ["SPEC"] =  SIR.playerInfo["SPEC"],
                ["TALENTS"] = {},
            },
        }
        numGroupMembers = 1
    else
        SIR.groupInfo = SnagiIntRotaSaved.groupInfo or {}
        SIR.groupInfo[SIR.playerInfo["GUID"]] = {
            ["NAME"] = SIR.playerInfo["NAME"],
            ["SERVER"] = SIR.playerInfo["REALMN"],
            ["CLASS"] = SIR.playerInfo["CLASS"],
            ["SPEC"] =  SIR.playerInfo["SPEC"],
            ["TALENTS"] = {},
        }
        numGroupMembers = 0
        for GUID, info in pairs(SIR.groupInfo) do
            if not UnitInParty(info["NAME"]) then
                SIR.groupInfo[GUID] = nil
            else
                numGroupMembers = numGroupMembers+1
            end
        end
    end
    for i=1, 7 do
        for j=1, 3 do
            if select(4, GetTalentInfo(i, j, 1, false)) then
                SIR.groupInfo[SIR.playerInfo["GUID"]]["TALENTS"][i] = j
                break
            elseif j==3 then
                SIR.groupInfo[SIR.playerInfo["GUID"]]["TALENTS"][i] = 0
            end
        end
    end
    SIR.rotationFunc.updateNumGroup(numGroupMembers)
    --SIR.groupInfoOnGroupRosterUpdate()
    inspectNext()
end
SIR.groupInfoSave = function()
    SnagiIntRotaSaved.groupInfo = SIR.groupInfo
end
SIR.groupInfoOnInspect = function(...)
    recentInspectTimes[#recentInspectTimes+1] = GetTime()
    local GUID = ...
    if not GUID or (not SIR.groupInfo[GUID] and not setInitialInfo(GUID)) then
        return
    end
    local oldSpec = SIR.groupInfo[GUID]["SPEC"]
    SIR.groupInfo[GUID]["SPEC"] = GetInspectSpecialization(SIR.groupInfo[GUID]["NAME"])
    for i=1, 7 do
        for j=1, 3 do
            local _, _, _, selected = GetTalentInfo(i, j, 1, true, SIR.groupInfo[GUID]["NAME"])
            if selected then
                SIR.groupInfo[GUID]["TALENTS"][i] = j
                break
            end
        end
    end
    if oldSpec ~= SIR.groupInfo[GUID]["SPEC"] then
        SIR.rotationFunc.specUpdate(GUID, SIR.groupInfo[GUID]["CLASS"], SIR.groupInfo[GUID]["SPEC"])
    end
    -- todo if talents changed
end
SIR.groupInfoOnGroupRosterUpdate = function()
    --SIR.util.myPrint("SIR.groupInfoOnGroupRosterUpdate ", numGroupMembers)

    if max(GetNumGroupMembers(), 1) ~= numGroupMembers then
        local newNumGroupMembers = max(GetNumGroupMembers(), 1)
        if newNumGroupMembers > numGroupMembers then
            --SIR.util.myPrint("newNumGroupMembers > numGroupMembers ", newNumGroupMembers)
            -- add new players
            local groupType = "party"
            if IsInRaid() then
                groupType = "raid"
            end
            for i=1, newNumGroupMembers do
                local GUID = UnitGUID(groupType..i) or UnitGUID("player")
                if not SIR.groupInfo[GUID] then
                    toBeInitialized[#toBeInitialized+1] = GUID
                end
                if GUID ~= SIR.playerInfo["GUID"] then
                    --SIR.util.myPrint("adding ", SIR.groupInfo[GUID]["NAME"],"to be inspected")
                    toBeInspectedActive[#toBeInitialized+1] = GUID
                end
            end
        else
            -- remove players that left
            if IsInGroup() then
                for GUID, info in pairs(SIR.groupInfo) do
                    if not UnitInParty(info["NAME"]) then
                        SIR.groupInfo[GUID] = nil
                        SIR.rotationFunc.removePlayer(GUID)
                    end
                end
            else
                for GUID, _ in pairs(SIR.groupInfo) do
                    if GUID ~= SIR.playerInfo["GUID"] then
                        --SIR.util.myPrint("not in grp GUID ~= SIR.playerInfo[\"GUID\"] - removing player")
                        SIR.groupInfo[GUID] = nil
                        SIR.rotationFunc.removePlayer(GUID)
                    end
                end
            end
        end
        numGroupMembers = newNumGroupMembers
        SIR.rotationFunc.updateNumGroup(newNumGroupMembers)
    end
end
SLASH_MYINSPECT1 = "/myinspect"
SlashCmdList["MYINSPECT"] = function()
	printInspect()
end