--luacheck: globals CreateFrame UnitGUID GetSpecializationInfo GetSpecialization UnitClass IsInGroup
--luacheck: globals CombatLogGetCurrentEventInfo SnagiIntRotaSaved GetRealmName GetPlayerInfoByGUID
local _, SIR = ...
SIR.data = SIR.data or {}
SIR.util = SIR.util or {}
SIR.frameUtil = SIR.frameUtil or {}
SIR.rotationFrames = SIR.rotationFrames or {}
SIR.optionFunc = SIR.optionFunc or {}
SIR.optionFrames = SIR.optionFrames or {}
SIR.rotationFunc = SIR.rotationFunc or {}
SIR.playerInfo = SIR.playerInfo or {}
SIR.tabOptions = SIR.tabOptions or {}
SIR.pets = {}

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(_, event, ...) f[event](...) end)

f:RegisterEvent("PLAYER_LOGOUT")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LEAVING_WORLD")
f:RegisterEvent("INSPECT_READY")
f:RegisterEvent("UNIT_PET")

f.GROUP_ROSTER_UPDATE = function()
	SIR.groupInfoFunc.GROUP_ROSTER_UPDATE()
end
f.UNIT_PET = function(...)
	SIR.util.myPrint("UNIT_PET", ...)
	SIR.petInfoFunc.UNIT_PET(...)
end

f.COMBAT_LOG_EVENT_UNFILTERED = function()
	SIR.rotationFunc.onCombatLogEvent()
	local _, subEvent  = CombatLogGetCurrentEventInfo()
	if subEvent == "UNIT_DIED" then
		SIR.util.myPrint(CombatLogGetCurrentEventInfo())
	end
end
f.PLAYER_SPECIALIZATION_CHANGED = function()
	SIR.playerInfo["SPEC"] = GetSpecializationInfo(GetSpecialization())
	SIR.groupInfo[SIR.playerInfo["GUID"]]["SPEC"] = SIR.playerInfo["SPEC"]
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
		["REALMN"] = GetRealmName(),
		["COLOUREDNAME"] = SIR.util.getColouredNameByGUID(GUID),
	}
	SnagiIntRotaSaved = SnagiIntRotaSaved or {}
	SIR.optionFunc.load()
	SIR.groupInfoFunc.PLAYER_LOGIN()
	SIR.optionFrames.generalTabButton:Click()
end
f.PLAYER_ENTERING_WORLD = function()

end
f.PLAYER_LOGOUT = function()
end
f.PLAYER_LEAVING_WORLD = function()
	SIR.optionFunc.save()
	SIR.groupInfoFunc.PLAYER_LEAVING_WORLD()
end