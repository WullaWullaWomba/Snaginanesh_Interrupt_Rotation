--luacheck: globals CreateFrame GetTalentInfo GetPlayerInfoByGUID GetInspectSpecialization NotifyInspect
--luacheck: globals GetSpecializationInfo GetSpecialization CanInspect UnitIsConnected InspectFrame
--luacheck: globals GetNumGroupMembers IsInGroup IsInRaid UnitIsDeadOrGhost
--luacheck: globals GetTime C_Timer max UnitGUID UnitInParty unpack CombatLogGetCurrentEventInfo
--luacheck: globals SLASH_SIRGROUPINFO1 SlashCmdList SnagiIntRotaSaved
local _, SIR = ...
local reverseTable, remove = SIR.util.reverseTable, SIR.util.remove
local toBeInitialized = {}
local toBeInspectedActive = {}
local toBeInspectedInactive = {}
local recentInspectTimes = {}
local numGroupMembers = 0
local inspectNextStarted = false
local printGroupInfo = function()
    print("----------------------------------------")
    print("SIR.groupInfo :")
    local count = 0
    for guid, info in pairs(SIR.groupInfo) do
        local talents = ""
        if info["TALENTS"] then
            for i=1, 7 do
                talents = talents..info["TALENTS"][i] or ""
            end
        end
        print(guid, " ", info["NAME"], " ", info["SERVER"], " ", info["CLASS"], " ",
        info["SPEC"], " ", talents, info["ALIVE"], info["ENABLED"])
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
    print("toBeInitialized #"..#toBeInitialized..":")
    for _, guid in ipairs(toBeInitialized) do
        print(select(6, GetPlayerInfoByGUID(guid)))
    end
    print("----------------------------------------")
end
local loadGroupInfo = function(GUID)
    if SnagiIntRotaSaved.groupInfo[GUID] then
        SIR.groupInfo[GUID] = SnagiIntRotaSaved.groupInfo[GUID]
        return true
    end
    return false
end
local setInitialInfo = function(GUID)
    SIR.util.myPrint("setInitialInfo", GUID)
    if SIR.groupInfo[GUID] then
        for i=#toBeInitialized, 1, -1 do
            if toBeInitialized[i] == GUID then
                remove(toBeInitialized, i)
                break
            end
        end
        return false
    end
    local _, class, _, _, _, name, server = GetPlayerInfoByGUID(GUID)
    local alive
    if server then
        if server == "" then
            server = SIR.playerInfo["REALM"];
            alive = not UnitIsDeadOrGhost(name)
        else
            alive = not UnitIsDeadOrGhost(name.."-"..server)
        end
    else
        SIR.util.myPrint("setInitialInfo no server")
        return false
    end

    SIR.groupInfo[GUID] = {
        ["NAME"] = name,
        ["SERVER"] = server,
        ["CLASS"] = class,
        ["TALENTS"] = {0, 0, 0, 0, 0, 0, 0 },
        ["ALIVE"] = alive,
        ["ENABLED"] = true, -- todo if possible actually check (additionally to connected - testing with true for debug)
    }
    SIR.util.myPrint("SIR.groupInfo[GUID] =", SIR.groupInfo[GUID])
    SIR.rotationFunc.playerInitAllTabs(GUID)
    return true
end
local inspectNext
inspectNext = function()
    if not SIR.enabled then
        C_Timer.After(5, function() inspectNext() end)
        return
    end
	for i = #recentInspectTimes, 1, -1 do
		if (recentInspectTimes[i] < (GetTime()-11)) then
			recentInspectTimes[i] = nil
		else
			break
        end
    end
    for i=#toBeInitialized, 1, -1 do
        if setInitialInfo(toBeInitialized[i]) then
            toBeInspectedActive[#toBeInspectedActive+1] = toBeInitialized[i]
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
        if SIR.groupInfo[GUID] then
            local name = SIR.groupInfo[GUID]["NAME"]
            if UnitInParty(name) then
                toBeInspectedInactive[#toBeInspectedInactive+1] = GUID
                if CanInspect(name) and UnitIsConnected(name) then
                    --SIR.util.myPrint("NotifyInspect", name)
                    NotifyInspect(name)
                    break
                end
            end
        end
    end
    C_Timer.After(2.1, function() inspectNext() end)
end
SIR.groupInfoFunc.initialize = function()
    SnagiIntRotaSaved.groupInfo = SnagiIntRotaSaved.groupInfo or {}
    SnagiIntRotaSaved.groupInfo[SIR.playerInfo["GUID"]] = {
            ["NAME"] = SIR.playerInfo["NAME"],
            ["SERVER"] = SIR.playerInfo["REALM"],
            ["CLASS"] = SIR.playerInfo["CLASS"],
            ["SPEC"] =  SIR.playerInfo["SPEC"],
            ["TALENTS"] = {0, 0, 0, 0, 0, 0, 0 },
            ["ALIVE"] = not UnitIsDeadOrGhost("player"),
            ["ENABLED"] = true,
    }
    for i=1, 7 do
        for j=1, 3 do
            if select(4, GetTalentInfo(i, j, 1, false)) then
                SnagiIntRotaSaved.groupInfo[SIR.playerInfo["GUID"]]["TALENTS"][i] = j
                break
            end
        end
    end

    SIR.util.iterateGroup(function(unitID)
        numGroupMembers = numGroupMembers+1
        local GUID = UnitGUID(unitID)
        if loadGroupInfo(GUID) then
            SIR.groupInfo[GUID]["ALIVE"] = not UnitIsDeadOrGhost(unitID)
            SIR.groupInfo[GUID]["ENABLED"] = true
            if GUID ~= SIR.playerInfo["GUID"] then
                toBeInspectedActive[#toBeInspectedActive+1] = GUID
            end
        else
            toBeInitialized[#toBeInitialized+1] = GUID
        end
    end)
    SIR.rotationFunc.updateNumGroup(numGroupMembers)
    if not inspectNextStarted then
        inspectNextStarted = true
        inspectNext()
    end
end
SIR.groupInfoFunc.disable = function()
    toBeInitialized = {}
    toBeInspectedActive = {}
    toBeInspectedInactive = {}
    SIR.groupInfo = {}
end
SIR.groupInfoFunc.PLAYER_LEAVING_WORLD = function()
    SnagiIntRotaSaved.groupInfo = SIR.groupInfo
end
SIR.groupInfoFunc.INSPECT_READY = function(...)
    recentInspectTimes[#recentInspectTimes+1] = GetTime()
    local GUID = ...
    if not GUID or not SIR.groupInfo[GUID] then
        return
    end
    local oldSpec = SIR.groupInfo[GUID]["SPEC"]
    SIR.groupInfo[GUID]["SPEC"] = GetInspectSpecialization(SIR.groupInfo[GUID]["NAME"])
    SIR.groupInfo[GUID]["TALENTS"] = {
        0, 0, 0, 0, 0, 0, 0
    }
    for i=1, 7 do
        for j=1, 3 do
            if select(4, GetTalentInfo(i, j, 1, true, SIR.groupInfo[GUID]["NAME"])) then
                SIR.groupInfo[GUID]["TALENTS"][i] = j
                break
            end
        end
    end
    if oldSpec ~= SIR.groupInfo[GUID]["SPEC"] then
        SIR.rotationFunc.specUpdateAllTabs(GUID, SIR.groupInfo[GUID]["SPEC"])
    end
    -- todo if talents changed
    --SIR.util.myPrint(SIR.groupInfo[GUID]["NAME"], "inspected")
end
SIR.groupInfoFunc.GROUP_ROSTER_UPDATE = function()
    SIR.util.myPrint("SIR.groupInfoOnGroupRosterUpdate ", numGroupMembers)
    local newNumGroupMembers = max(GetNumGroupMembers(), 1)
    if newNumGroupMembers == numGroupMembers then
        return
    end
    SIR.util.myPrint("newNumGroupMembers", newNumGroupMembers)
    if newNumGroupMembers > numGroupMembers then
        -- add new players
        local groupType = "party"
        if IsInRaid() then
            groupType = "raid"
        end
        for i=1, newNumGroupMembers do
            local GUID = UnitGUID(groupType..i)
            if GUID and (not SIR.groupInfo[GUID]) then
                SIR.petInfoFunc.UNIT_PET(groupType..i)
                toBeInitialized[#toBeInitialized+1] = GUID
            end
        end
        -- remove players that left (or all others if not in party)
    elseif IsInGroup() then
        for GUID, info in pairs(SIR.groupInfo) do
            if not UnitInParty(info["NAME"]) then
                SIR.groupInfo[GUID] = nil
                SIR.petInfoFunc.removePlayerPet(GUID)
                SIR.rotationFunc.removeByGUID(GUID)
            end
        end
    else
        for GUID, _ in pairs(SIR.groupInfo) do
            if GUID ~= SIR.playerInfo["GUID"] then
                SIR.groupInfo[GUID] = nil
                SIR.petInfoFunc.removePlayerPet(GUID)
                SIR.rotationFunc.removeByGUID(GUID)
            end
        end
    end
    numGroupMembers = newNumGroupMembers
    SIR.util.myPrint("set numGroupMembers = newNumGroupMembers")
    SIR.rotationFunc.updateNumGroup(newNumGroupMembers)
end
SIR.groupInfoFunc.PARTY_MEMBER_ENABLE = function(...)
    local GUID = UnitGUID(...)
    if GUID and SIR.groupInfo[GUID] then
        SIR.groupInfo[GUID]["ENABLED"] = true
        --SIR.groupInfo[GUID]["CONNECTED"] = true
        SIR.groupInfo[GUID]["ALIVE"] = not UnitIsDeadOrGhost(...)
        SIR.rotationFunc.updateGreyOutForGUID(GUID)
    end
end
SIR.groupInfoFunc.PARTY_MEMBER_DISABLE = function(...)
    local GUID = UnitGUID(...)
    --local unit = ...
    if GUID and SIR.groupInfo[GUID] then
        --SIR.groupInfo[GUID]["CONNECTED"] = UnitIsConnected(...)
        SIR.groupInfo[GUID]["ENABLED"] = false
        SIR.rotationFunc.updateGreyOutForGUID(GUID)
    end
end
SIR.groupInfoFunc.UNIT_HEALTH = function(...)
    local GUID = UnitGUID(...)
    if GUID and SIR.groupInfo[GUID] then
        if SIR.groupInfo[GUID]["ALIVE"] == false then
            SIR.groupInfo[GUID]["ALIVE"] = true
            SIR.rotationFunc.updateGreyOutForGUID(GUID)
        end
    end
end
SIR.groupInfoFunc.UNIT_DIED = function(GUID)
    if SIR.groupInfo[GUID] then
        SIR.groupInfo[GUID]["ALIVE"] = false
        SIR.rotationFunc.updateGreyOutForGUID(GUID)
    end
end
SLASH_SIRGROUPINFO1 = "/sirgroupinfo"
SlashCmdList["SIRGROUPINFO"] = function()
	printGroupInfo()
end