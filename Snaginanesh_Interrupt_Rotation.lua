--luacheck: globals CreateFrame UnitGUID GetSpecializationInfo GetSpecialization UnitClass IsInGroup
--luacheck: globals CombatLogGetCurrentEventInfo SnagiIntRotaSaved GetRealmName GetPlayerInfoByGUID
local _, SIR = ...
SIR.data, SIR.util, SIR.frameUtil = {}, {}, {}
SIR.optionFrames, SIR.optionFunc, SIR.tabOptions, SIR.generalOptions = {}, {}, {}, {}
SIR.rotationFrames, SIR.rotationFunc = {}, {}
SIR.playerInfo = {}
SIR.groupInfo, SIR.groupInfoFunc = {}, {}
SIR.petToMaster, SIR.masterToPet, SIR.petInfoFunc = {}, {}, {}
SIR.test = false

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(_, event, ...) f[event](...) end)
f:RegisterEvent("PLAYER_LOGIN")

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
	-- if source not in party return
	if sourceFlags%16 > 4 then
		return
	end
	SIR.rotationFunc.onCombatLogEvent(timestamp, subEvent, sourceGUID, spellID)
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
f.PLAYER_LOGIN = function()
	local GUID = UnitGUID("player")
	local _, class, _, _, _, name = GetPlayerInfoByGUID(GUID)
	SIR.playerInfo = {
		["GUID"] = GUID,
		["CLASS"] = class,
		["SPEC"] = GetSpecializationInfo(GetSpecialization()),
		["NAME"] = name,
		["REALM"] = GetRealmName(),
		["COLOUREDNAME"] = SIR.util.getColouredNameByGUID(GUID),
	}
	SnagiIntRotaSaved = SnagiIntRotaSaved or {}
	SIR.tabOptions = SnagiIntRotaSaved.tabOptions or {}
	SIR.generalOptions = SnagiIntRotaSaved.generalOptions or {}
	SIR.optionFunc.PLAYER_LOGIN()
	SIR.groupInfoFunc.PLAYER_LOGIN()
	SIR.petInfoFunc.PLAYER_LOGIN()
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
f.PLAYER_ENTERING_WORLD = function()

end
f.PLAYER_LOGOUT = function()
	SnagiIntRotaSaved.tabOptions = SIR.tabOptions
	SnagiIntRotaSaved.generalOptions = SIR.generalOptions
end
f.PLAYER_LEAVING_WORLD = function()
	SIR.groupInfoFunc.PLAYER_LEAVING_WORLD()
end