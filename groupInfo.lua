--luacheck: globals CreateFrame GetTalentInfo GetPlayerInfoByGUID GetInspectSpecialization NotifyInspect
--luacheck: globals GetSpecializationInfo GetSpecialization CanInspect UnitIsConnected InspectFrame
--luacheck: globals GetNumGroupMembers IsInGroup IsInRaid UnitIsDeadOrGhost
--luacheck: globals GetTime C_Timer max UnitGUID UnitInParty
--luacheck: globals SLASH_MYINSPECT1 SlashCmdList GetRealmName
local _, SIR = ...
SIR.groupInfo = SIR.groupInfo or {}
local reverseTable, remove = SIR.util.reverseTable, SIR.util.remove
local groupInfo = {}
local toBeInitialized = {}
local toBeInspectedActive = {}
local toBeInspectedInactive = {}
local recentInspectTimes = {}

local numGroupMembers = 1
local playerGUID
local f = CreateFrame("Frame")

local printInspect = function()
    print("----------------------------------------")
    print("groupInfo :")
    local count = 0
    for guid, info in pairs(groupInfo) do
        print(guid, " ", info["NAME"], " ", info["SERVER"], " ", info["CLASS"], " ",
        info["SPEC"], " ", unpack(info["TALENTS"]))
        count = count+1
    end
    print("#groupInfo "..count)
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
            server = GetRealmName();
        end
    else
        return false
    end
    groupInfo[GUID] = {
        ["NAME"] = name,
        ["SERVER"] = server,
        ["CLASS"] = class,
        ["TALENTS"] = {},
    }
    return true
end

SLASH_MYINSPECT1 = "/myinspect"
SlashCmdList["MYINSPECT"] = function()
	printInspect()
end

f:SetScript("OnEvent", function(_, event, ...) f[event](...)
end)
f:RegisterEvent("INSPECT_READY")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("GROUP_ROSTER_UPDATE")

f.PLAYER_LOGIN = function()
    playerGUID = UnitGUID("player")
    local _, class, _, _, _, name = GetPlayerInfoByGUID(playerGUID)
    groupInfo[playerGUID] = {
        ["NAME"] = name,
        ["SERVER"] = GetRealmName(),
        ["CLASS"] = class,
        ["SPEC"] =  GetSpecializationInfo(GetSpecialization()),
        ["TALENTS"] = {},
    }
    for i=1, 7 do
        for j=1, 3 do
            if select(4, GetTalentInfo(i, j, 1, false)) then
                groupInfo[playerGUID]["TALENTS"][i] = j
                break
            elseif j==3 then
                groupInfo[playerGUID]["TALENTS"][i] = 0
            end
        end
    end
    numGroupMembers = 1
    -- TODO setup player bars
end
f.INSPECT_READY = function(...)
    recentInspectTimes[#recentInspectTimes+1] = GetTime()
    local GUID = ...
    if not GUID or (not groupInfo[GUID] and not setInitialInfo(GUID)) then
        return
    end
    groupInfo[GUID]["SPEC"] = GetInspectSpecialization(groupInfo[GUID]["NAME"])
    for i=1, 7 do
        for j=1, 3 do
            local _, _, _, selected = GetTalentInfo(i, j, 1, true, groupInfo[GUID]["NAME"])
            if selected then
                groupInfo[GUID]["TALENTS"][i] = j
                break
            end
        end
    end
    -- TODO setup/update character for/if talents changed
end
f.GROUP_ROSTER_UPDATE = function()
    if GetNumGroupMembers() ~= numGroupMembers then
        local newNumGroupMembers = max(GetNumGroupMembers(), 1)
        if newNumGroupMembers > numGroupMembers then
            -- add new players
            local groupType = "party"
            if IsInRaid() then
                groupType = "raid"
            end
            for i=1, newNumGroupMembers do
                local GUID = UnitGUID(groupType..i) or UnitGUID("player")
                if not groupInfo[GUID] then
                    setInitialInfo(GUID)
                    toBeInitialized[#toBeInitialized+1] = GUID
                end
            end
        else
            -- remove players that left
            if IsInGroup() then
                for GUID, info in pairs(groupInfo) do
                    if not UnitInParty(info["NAME"]) then
                        groupInfo[GUID] = nil
                        -- TODO elsewhere bars
                    end
                end
            else
                for GUID, _ in pairs(groupInfo) do
                    if GUID ~= playerGUID then
                        groupInfo[GUID] = nil
                        -- TODO elsewhere bars
                    end
                end
            end
        end
        numGroupMembers = newNumGroupMembers
    end
    return
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
        local name = groupInfo[GUID]["NAME"]
        --todo UnitInParty(name)
        if CanInspect(name) and UnitIsConnected(name) and UnitInParty(name) then
            NotifyInspect(name)
            C_Timer.After(2.1, function() inspectNext() end)
            return
        end
    end
    C_Timer.After(2.1, function() inspectNext() end)
end
inspectNext()