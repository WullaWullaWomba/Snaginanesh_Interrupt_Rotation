--luacheck: globals CreateFrame UnitGUID GetSpecializationInfo GetSpecialization UnitClass IsInGroup
--luacheck: globals CombatLogGetCurrentEventInfo SnagiIntRotaSaved GetRealmName GetPlayerInfoByGUID
local _, SIR = ...
SIR.data = SIR.data or {}
SIR.util = SIR.util or {}
SIR.frameUtil = SIR.frameUtil or {}
SIR.rotationFrames = SIR.rotationFrames or {}
SIR.func = SIR.func or {}
SIR.optionFrames = SIR.optionFrames or {}
SIR.rotationFunc = SIR.rotationFunc or {}
SIR.playerInfo = SIR.playerInfo or {}
SIR.tabOptions = SIR.tabOptions or {}
local cds = SIR.data.cds
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

f.GROUP_ROSTER_UPDATE = function()
	SIR.groupInfoOnGroupRosterUpdate()
end
f.COMBAT_LOG_EVENT_UNFILTERED = function()
	local timestamp, subEvent, _, sourceGUID, _, sourceFlags, _, _, _, _, _, spellID  = CombatLogGetCurrentEventInfo()
	if subEvent == "SPELL_CAST_SUCCESS" then
		if not cds[spellID] or sourceFlags%16 > 4 then return end
		SIR.rotationFramesAndFunc.onInterrupt(sourceGUID, spellID, timestamp)
	end
end
f.PLAYER_SPECIALIZATION_CHANGED = function()
end
f.INSPECT_READY = function()
	SIR.groupInfoOnInspect()
end
f.PLAYER_LOGIN = function()
end
f.PLAYER_ENTERING_WORLD = function()
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
	--SIR.func.load()
	SIR.groupInfoLoad()
end
f.PLAYER_LOGOUT = function()
end
f.PLAYER_LEAVING_WORLD = function()
	SIR.func.save()
	SIR.groupInfoSave()
end