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
local numGroupMembers = -99
local numDead = 0

local printGroupInfo = function()
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
    SIR.util.myPrint("setInitialInfo", GUID)
    if SIR.groupInfo[GUID] then
        for i=1, #toBeInitialized do
            if toBeInitialized[i] == GUID then
                remove(toBeInitialized, i)
                break
            end
        end
        return false
    end
    local _, class, _, _, _, name, server = GetPlayerInfoByGUID(GUID)
    local alive, connected
    if server then
        if server == "" then
            server = SIR.playerInfo["REALMN"];
            alive = not UnitIsDeadOrGhost(name)
            connected = UnitIsConnected(name)
        else
            alive = not UnitIsDeadOrGhost(name.."-"..server)
            connected = UnitIsConnected(name.."-"..server)
        end
    else
        SIR.util.myPrint("setInitialInfo no server")
        return false
    end

    SIR.groupInfo[GUID] = {
        ["NAME"] = name,
        ["SERVER"] = server,
        ["CLASS"] = class,
        ["TALENTS"] = {},
        ["ALIVE"] = alive,
        ["ENABLED"] = true, -- todo if possible actually check (additionally to connected - testing with true for debug)
    }
    SIR.util.myPrint("SIR.groupInfo[GUID] =", SIR.groupInfo[GUID])
    SIR.rotationFunc.playerInitAllTabs(GUID)
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
SIR.groupInfoFunc.PLAYER_LOGIN = function()
    SIR.groupInfo = {
        [SIR.playerInfo["GUID"]] = {
            ["NAME"] = SIR.playerInfo["NAME"],
            ["SERVER"] = SIR.playerInfo["REALMN"],
            ["CLASS"] = SIR.playerInfo["CLASS"],
            ["SPEC"] =  SIR.playerInfo["SPEC"],
            ["TALENTS"] = {},
            ["ALIVE"] = not UnitIsDeadOrGhost("player"),
            ["CONNECTED"] = true,
            ["ENABLED"] = true,
        },
    }
    SIR.groupInfo[SIR.playerInfo["GUID"]]["TALENTS"] = {
        0, 0, 0, 0, 0, 0, 0
    }
    for i=1, 7 do
        for j=1, 3 do
            if select(4, GetTalentInfo(i, j, 1, false)) then
                SIR.groupInfo[SIR.playerInfo["GUID"]]["TALENTS"][i] = j
                break
            end
        end
    end
    numGroupMembers = 1
    if IsInGroup() then
        for GUID, info in pairs(SnagiIntRotaSaved.groupInfo) do
            if UnitInParty(info["NAME"]) and GUID ~= SIR.playerInfo["GUID"] then
                SIR.groupInfo[GUID] = info
                numGroupMembers = numGroupMembers+1
                toBeInspectedActive[#toBeInspectedActive+1] = GUID
            end
        end
    end
    SIR.util.iterateGroup(
        function(unitID)
            setInitialInfo(UnitGUID(unitID))
        end
    )
    SIR.rotationFunc.updateNumGroup(numGroupMembers)
    inspectNext()
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
        SIR.groupInfo[GUID]["CONNECTED"] = true
        SIR.groupInfo[GUID]["ALIVE"] = not UnitIsDeadOrGhost(...)
        SIR.rotationFunc.updateGreyOutForGUID(GUID)
    end
end
SIR.groupInfoFunc.PARTY_MEMBER_DISABLE = function(...)
    local GUID = UnitGUID(...)
    --local unit = ...
    if GUID and SIR.groupInfo[GUID] then
        SIR.groupInfo[GUID]["CONNECTED"] = UnitIsConnected(...)
        SIR.util.myPrint("SIR.groupInfoFunc.PARTY_MEMBER_DISABLE", "SIR.groupInfo[GUID][\"CONNECTED\"]",
            SIR.groupInfo[GUID]["CONNECTED"])
            --C_Timer.After(2.1, function() SIR.util.myPrint("SIR.groupInfoFunc.PARTY_MEMBER_DISABLE", "SIR.groupInfo[GUID][\"CONNECTED\"]",
            --    SIR.groupInfo[GUID]["CONNECTED"], UnitIsConnected(unit)) end)
        SIR.groupInfo[GUID]["ENABLED"] = false
        SIR.rotationFunc.updateGreyOutForGUID(GUID)
    end
end
SIR.groupInfoFunc.UNIT_HEALTH = function(...)
    local GUID = UnitGUID(...)
    if GUID and SIR.groupInfo[GUID] then
        if SIR.groupInfo[GUID]["ALIVE"] == false then
            numDead = numDead-1
            SIR.groupInfo[GUID]["ALIVE"] = true
            SIR.rotationFunc.updateGreyOutForGUID(GUID)
        end
    end
    -- todo unregister UNIT_HEALTH if no one is dead
end
SIR.groupInfoFunc.UNIT_DIED = function (GUID)
    if SIR.groupInfo[GUID] then
        SIR.groupInfo[GUID]["ALIVE"] = false
        numDead = numDead+1
        -- todo register UNIT_HEALTH
        SIR.rotationFunc.updateGreyOutForGUID(GUID)
    end
end
SLASH_SIRGROUPINFO1 = "/sirgroupinfo"
SlashCmdList["SIRGROUPINFO"] = function()
	printGroupInfo()
end