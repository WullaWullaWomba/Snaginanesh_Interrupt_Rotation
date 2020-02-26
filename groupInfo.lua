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
            NotifyInspect(name)
            C_Timer.After(2.1, function() inspectNext() end)
            return
        end
    end
    C_Timer.After(2.1, function() inspectNext() end)
end
SIR.groupInfoLoad = function()
    if not IsInGroup() then
        numGroupMembers = 1
        SIR.groupInfo = {
            [SIR.playerInfo["GUID"]] = {
                ["NAME"] = SIR.playerInfo["NAME"],
                ["SERVER"] = SIR.playerInfo["REALMN"],
                ["CLASS"] = SIR.playerInfo["CLASS"],
                ["SPEC"] =  SIR.playerInfo["SPEC"],
                ["TALENTS"] = {},
            },
        }
        SIR.rotationFunc.playerInit(SIR.playerInfo["GUID"], SIR.playerInfo["CLASS"])
        SIR.rotationFunc.specUpdate(SIR.playerInfo["GUID"], SIR.playerInfo["CLASS"], nil, SIR.playerInfo["SPEC"])
        numGroupMembers = 1
    else
        SIR.groupInfo = SnagiIntRotaSaved.groupInfo
        numGroupMembers = 0
        SIR.groupInfo[SIR.playerInfo["GUID"]] = {
            ["NAME"] = SIR.playerInfo["NAME"],
            ["SERVER"] = SIR.playerInfo["REALMN"],
            ["CLASS"] = SIR.playerInfo["CLASS"],
            ["SPEC"] =  SIR.playerInfo["SPEC"],
            ["TALENTS"] = {},
        }
        for GUID, info in pairs(SIR.groupInfo) do
            if not UnitInParty(info["NAME"]) then
                SIR.groupInfo[GUID] = nil
            else
                numGroupMembers = numGroupMembers+1
                SIR.rotationFunc.playerInit(GUID, info["CLASS"])
                if info["SPEC"] then
                    SIR.rotationFunc.specUpdate(GUID, info["CLASS"], nil, info["SPEC"])
                end
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
    SIR.rotationFunc.specUpdate(GUID, SIR.groupInfo[GUID]["CLASS"], SIR.groupInfo[GUID]["SPEC"])
end
SIR.groupInfoOnGroupRosterUpdate = function()
    if max(GetNumGroupMembers(), 1) ~= numGroupMembers then
        local newNumGroupMembers = max(GetNumGroupMembers(), 1)
        SIR.rotationFunc.updateNumGroup(newNumGroupMembers)
        if newNumGroupMembers > numGroupMembers then
            -- add new players
            local groupType = "party"
            if IsInRaid() then
                groupType = "raid"
            end
            for i=1, newNumGroupMembers do
                local GUID = UnitGUID(groupType..i) or UnitGUID("player")
                if not SIR.groupInfo[GUID] then
                    setInitialInfo(GUID)
                    toBeInitialized[#toBeInitialized+1] = GUID
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
                        SIR.util.myPrint("not in grp GUID ~= SIR.playerInfo[\"GUID\"] - removing player")
                        SIR.groupInfo[GUID] = nil
                        SIR.rotationFunc.removePlayer(GUID)
                    end
                end
            end
        end
        numGroupMembers = newNumGroupMembers
    end
    return
end
SLASH_MYINSPECT1 = "/myinspect"
SlashCmdList["MYINSPECT"] = function()
	printInspect()
end