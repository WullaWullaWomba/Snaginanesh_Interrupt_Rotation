--luacheck: globals CreateFrame UnitGUID GetSpecializationInfo GetSpecialization UnitClass IsInGroup
--luacheck: globals CombatLogGetCurrentEventInfo SnagiIntRotaSaved GetRealmName GetPlayerInfoByGUID
local _, SIR = ...
local addonLoaded, playerLoggedIn = false, false
SIR.data, SIR.util, SIR.frameUtil = {}, {}, {}
SIR.optionFrames, SIR.optionFunc, SIR.tabOptions, SIR.generalOptions = {}, {}, {}, {}
SIR.rotationFrames, SIR.rotationFunc = {}, {}
SIR.playerInfo = {}
SIR.groupInfo, SIR.groupInfoFunc = {}, {}
SIR.petToMaster, SIR.masterToPet, SIR.petInfoFunc = {}, {}, {}
SIR.transmissionFunc = {}
SIR.test = false
SIR.enabled = true

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(_, event, ...) f[event](...) end)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
local initialize = function()
	-- addon has both loaded & player logged in
	SnagiIntRotaSaved = SnagiIntRotaSaved or {}
	local GUID = UnitGUID("player")
	local _, class = UnitClass("player")
	local name = UnitName("player")
	SIR.playerInfo = {
		["GUID"] = GUID,
		["CLASS"] = class,
		["SPEC"] = GetSpecializationInfo(GetSpecialization()),
		["NAME"] = name,
		["REALM"] = GetRealmName(),
		["COLOUREDNAME"] = SIR.util.getColouredNameByGUID(GUID),
	}
	SIR.tabOptions = SnagiIntRotaSaved.tabOptions or {}
	SIR.generalOptions = SnagiIntRotaSaved.generalOptions or {}
	SIR.optionFunc.initialize()
	SIR.groupInfoFunc.initialize()
	SIR.petInfoFunc.initialize()
	SIR.optionFrames.generalTabButton:Click()
	f:RegisterEvent("UNIT_PET")
	f:RegisterEvent("PLAYER_LOGOUT")
	f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	f:RegisterEvent("GROUP_ROSTER_UPDATE")
	f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:RegisterEvent("PLAYER_LEAVING_WORLD")
	f:RegisterEvent("INSPECT_READY")
	f:RegisterEvent("PARTY_MEMBER_ENABLE")
	f:RegisterEvent("PARTY_MEMBER_DISABLE")
	f:RegisterEvent("UNIT_HEALTH")
end
local disable = function()
	SIR.util.myPrint("disabling")
	SIR.enabled = false
	f:UnregisterAllEvents()
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	SIR.groupInfoFunc.disable()
	SIR.petInfoFunc.disable()
	SIR.rotationFunc.disable()
end
f.PARTY_MEMBER_ENABLE = function(...)
	SIR.util.myPrint("PARTY_MEMBER_ENABLE", ...)
	SIR.groupInfoFunc.PARTY_MEMBER_ENABLE(...)
end
f.PARTY_MEMBER_DISABLE = function(...)
	SIR.util.myPrint("PARTY_MEMBER_DISABLE", ...)
	SIR.groupInfoFunc.PARTY_MEMBER_DISABLE(...)
end
f.UNIT_HEALTH = function(...)
	-- SIR.util.myPrint("UNIT_HEALTH", ...)
	SIR.groupInfoFunc.UNIT_HEALTH(...)
end
f.GROUP_ROSTER_UPDATE = function()
	SIR.groupInfoFunc.GROUP_ROSTER_UPDATE()
	SIR.optionFunc.GROUP_ROSTER_UPDATE()
end
f.UNIT_PET = function(...)
	if ... then
		SIR.petInfoFunc.UNIT_PET(...)
	end
end

f.COMBAT_LOG_EVENT_UNFILTERED = function()
	-- 196099 (felhunter sac aura spellID)
	local timestamp, subEvent,_ , sourceGUID, _, _, sourceFlags, destGUID, _, _, _, spellID
		= CombatLogGetCurrentEventInfo()
	-- if source not in raid/party/player return
	if sourceFlags%16 > 4 then
		return
	end
	SIR.rotationFunc.onCombatLogEvent(timestamp, subEvent, sourceGUID, spellID)
	-- sacrifice demon (WL)
	if spellID == 196099 then
		SIR.petInfoFunc.onCombatLogEvent(subEvent, sourceGUID)
	end
	if subEvent == "UNIT_DIED" then
		SIR.groupInfoFunc.UNIT_DIED(destGUID)
	end
end
f.PLAYER_SPECIALIZATION_CHANGED = function()
	SIR.util.myPrint("PLAYER_SPECIALIZATION_CHANGED")
	SIR.playerInfo["SPEC"] = GetSpecializationInfo(GetSpecialization())
	SIR.groupInfo[SIR.playerInfo["GUID"]]["SPEC"] = SIR.playerInfo["SPEC"]
	SIR.rotationFunc.specUpdateAllTabs(SIR.playerInfo["GUID"], SIR.playerInfo["SPEC"])
	-- todo update talents
	for i=1, #SIR.tabOptions do
		SIR.rotationFunc.updateTrackMode(i)
	end
end
f.INSPECT_READY = function(...)
	SIR.groupInfoFunc.INSPECT_READY(...)
end

f.ADDON_LOADED = function (addonName)
	if addonName ~= "Snaginanesh_Interrupt_Rotation" then
		return
	end
	addonLoaded = true
	if playerLoggedIn then
		initialize()
	end
end

f.PLAYER_LOGIN = function ()
	playerLoggedIn = true
	if addonLoaded then
		initialize()
	end
end

f.PLAYER_ENTERING_WORLD = function()
	local _, instanceType = GetInstanceInfo()
	if (instanceType == "pvp") or (instanceType == "arena") then
		if SIR.enabled then
			disable()
		end
	else
		if not SIR.enabled then
			SIR.util.myPrint("enabling")
			initialize()
			SIR.enabled = true
		end
	end

end
f.PLAYER_LOGOUT = function()
	SnagiIntRotaSaved.tabOptions = SIR.tabOptions
	SnagiIntRotaSaved.generalOptions = SIR.generalOptions
end
f.PLAYER_LEAVING_WORLD = function()
	SIR.groupInfoFunc.PLAYER_LEAVING_WORLD()
end