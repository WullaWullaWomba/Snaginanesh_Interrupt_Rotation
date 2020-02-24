local _, SIR = ...
SIR.util = SIR.util or {}
SIR.frameUtil = SIR.frameUtil or {}
SIR.rotationFunc = SIR.rotationFunc or {}
SIR.func = SIR.func or {}
SIR.optionFrames = SIR.optionFrames or {}
SIR.tabOptions = SIR.tabOptions or {}

local tabOptions = SIR.tabOptions
local specInterrupts = SIR.data.specInterrupts
local classWideInterrupts = SIR.data.classWideInterrupts
local rotationFunc = SIR.rotationFunce
local contains = SIR.util.contains
local rotationFrames = {}
local statusBars = {}
local trackModes = {}
local numGroup = 0
rotationFunc.updateNumGroup = function(num)
    numGroup = num
    for i=1, #trackModes do
        rotationFunc.updateTrackMode(i)
    end
end
rotationFunc.removePlayer = function(GUID)
end

rotationFunc.updateTrackMode = function(tab)
	local old = trackModes[tab]
	if SIR.tabOptions[tab]["TRACKALLCHECKED"] and SIR.tabOptions[tab]["TRACKALLFROM"]<= numGroup
			<= SIR.tabOptions[tab]["TRACKALLTO"] then
		trackModes[tab] = "ALL"
	elseif SIR.tabOptions[tab]["TRACKROTATIONCHECKED"] and SIR.tabOptions[tab]["TRACKROTATIONFROM"]<= numGroup
			<= SIR.tabOptions[tab]["TRACKROTATIONTO"] then
		trackModes[tab] = "ROTATION"
	else
		trackModes[tab] = "NONE"
	end
	if old == trackModes[tab] then
		return
	end
	-- todo
    if trackModes[tab] == "NONE" then
        for i=1, #statusBars[tab] do
            SIR.frameUtil.releaseStatusBar(statusBars[tab][i])
            statusBars[tab] = {}
        end
	elseif old == "NONE" then
        if trackModes[tab] == "ROTATION" then
            --add rotation
            for i=1, #SIR.tabOptions[tab]["ROTATION"] do
                local GUID = SIR.tabOptions[tab]["ROTATION"][i]
                if SIR.groupInfo[GUID] then
                    rotationFunc.playerInit(GUID, SIR.groupInfo[GUID]["CLASS"])
                    if SIR.groupInfo[GUID]["SPEC"] then
                        rotationFunc.specUpdate(GUID, SIR.groupInfo[GUID]["CLASS"], nil, SIR.groupInfo[GUID]["SPEC"])
                    end
                end
            end
		elseif trackModes[tab] == "ALL" then
            for GUID, info in pairs(SIR.groupInfo) do
                rotationFunc.playerInit(GUID, info["CLASS"])
                if info["SPEC"] then
                    rotationFunc.specUpdate(GUID, info["CLASS"], nil, info["SPEC"])
                end
            end
		end
	elseif old == "ROTATION" then
			-- trackModes[tab] == "ALL" unless more modes added
            -- add all that havent been added yet
            for GUID, info in pairs(SIR.groupInfo) do
                if not contains(SIR.tabOptions[tab]["ROTATION"], GUID) then
                    rotationFunc.playerInit(GUID, info["CLASS"])
                    if info["SPEC"] then
                        rotationFunc.specUpdate(GUID, info["CLASS"], nil, info["SPEC"])
                    end
                end
            end
	else
		-- old == "ALL" unless more modes added
		-- trackModes[tab] == "ROTATION" unless more modes added
        -- remove players that arent part of the rotation
        for i=#statusBars(tab), 1, -1 do
            if not contains(SIR.tabOptions[tab]["ROTATION"], statusBars[tab][i]:GetGUID()) then
                rotationFunc.releaseStatusBar(tab, i)
            end
        end
	end
end
rotationFunc.playerInit = function(GUID, class)
    if classWideInterrupts[class] then
        for i=1, #tabOptions do
            if trackModes[i] == "ALL" or trackModes[i] == "ROTATION"
                and contains(tabOptions[i]["ROTATION"], GUID) then
                --add player to rotation
            end
        end
    end
end
rotationFunc.specUpdate = function(GUID, class, oldSpec, newSpec)
    if classWideInterrupts[class] then
        return
    end
    if oldSpec then
        if specInterrupts[oldSpec] == specInterrupts[newSpec] then
            return
        end
        if not specInterrupts[oldSpec] then
            -- setup bars for new spec
        elseif not specInterrupts[newSpec] then
            -- remove oldSpec bars
        else
            -- update existing bars
        end
    end
end
rotationFunc.newStatusBar = function()
    local sb = SIR.frameUtil.aquireStatusBar()
    sb.icon:SetTexture()
    --statusBar.icon:SetTexture(select(3, GetSpellInfo(spellID)))
end
