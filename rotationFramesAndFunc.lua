--luacheck: globals GetSpellInfo strsub UIParent unpack setBarOnUpdate GetPlayerInfoByGUID CombatLogGetCurrentEventInfo
local _, SIR = ...
SIR.util = SIR.util or {}
SIR.frameUtil = SIR.frameUtil or {}
SIR.rotationFunc = SIR.rotationFunc or {}
SIR.func = SIR.func or {}
SIR.optionFrames = SIR.optionFrames or {}
SIR.tabOptions = SIR.tabOptions or {}
SIR.groupInfo = SIR.groupInfo or {}

local specInterrupts, classWideInterrupts = SIR.data.specInterrupts, SIR.data.classWideInterrupts
local classColorsRGB = SIR.data.classColorsRGB
local cds = SIR.data.cds
local rotationFunc = SIR.rotationFunc
local contains = SIR.util.contains
local rotationFrames = {}
local statusBars = {}
local trackModes = {}
local numGroup = -99

local setBarOnUpdate = function(sb)
    sb:SetScript("OnUpdate", function(self, elapsed)
        self.currentTime = self.currentTime+elapsed
        local t = self.expirationTime-self.currentTime
        if t>10 then
            self.rightText:SetText(strsub(t, 1, 4))
        elseif t>0 then
            self.rightText:SetText(strsub(t, 1, 3))
        else
            self:SetScript("OnUpdate", nil)
            self.rightText:SetText("")
        end
        self:SetValue(15-t)
    end)
end
local insertBar = function(tab, bars, bar)
    SIR.util.myPrint("insertBar")
    local insertAt = #bars+1
    if SIR.tabOptions[tab]["SORTMODE"] == "CD" then
        for i=#bars, 1, -1 do
            if bars[i].expirationTime < bar.expirationTime then
                insertAt = i+1
                break
            end
        end
    elseif SIR.tabOptions[tab]["SORTMODE"] == "ROTATION" then
        -- if not part of the rotation all rotation people should be in front
        local rotationPos
        local prePos = {}
        for i, rotaMemberGUID in ipairs(SIR.tabOptions[tab]["ROTATION"]) do
            if bar.GUID == rotaMemberGUID then
                rotationPos = i
                break
            end
        end
        if rotationPos then
            for i=1, rotationPos-1 do
                prePos[i] = SIR.tabOptions[tab]["ROTATION"][i]
            end
            insertAt = #bars+1
            for i=1, #bars do
                if not contains(prePos, bars[i].GUID) then
                    insertAt = i
                    break
                end
            end
        end
    end
    bar:SetPoint("TOPRIGHT", bars[insertAt-1] or rotationFrames[tab], "BOTTOMRIGHT",
    0, bars[insertAt-1] and SIR.tabOptions[tab]["SPACE"] or 0)
    if bars[insertAt] then
        bars[insertAt]:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT",
            0, SIR.tabOptions[tab]["SPACE"])
    end
    for i=#bars, insertAt, -1 do
        bars[i+1] = bars[i]
    end
    bars[insertAt] = bar
end
local addStatusBar = function(tab, GUID, spellID, class, timestamp)
    SIR.util.myPrint("addStatusBar")
    SIR.util.myPrint(tab, GUID, spellID, class, timestamp)
    local statusBar = SIR.frameUtil.aquireStatusBar()
    statusBar.icon:SetTexture(select(3, GetSpellInfo(spellID)))
    statusBar.GUID = GUID
    statusBar.spellID = spellID
    statusBar:SetStatusBarColor(unpack(classColorsRGB[class]))
    statusBar:SetSize(SIR.tabOptions[tab]["WIDTH"]-SIR.tabOptions[tab]["HEIGHT"], SIR.tabOptions[tab]["HEIGHT"])
    statusBar.icon:SetSize(SIR.tabOptions[tab]["HEIGHT"], SIR.tabOptions[tab]["HEIGHT"])
    statusBar.leftText:SetText(SIR.groupInfo[GUID] and SIR.groupInfo[GUID]["NAME"] or "noname")
    if timestamp then
        statusBar.currentTime = timestamp
        statusBar.expirationTime = timestamp+cds[spellID]
        setBarOnUpdate(statusBar)
    else
        statusBar.currentTime = 0
        statusBar.expirationTime = 0
        setBarOnUpdate(statusBar)
    end
    insertBar(tab, statusBars[tab], statusBar)
    statusBar:Show()
end
local updateOrAddStatusBar = function(tab, GUID, spellID, class, timestamp)
    SIR.util.myPrint("updateOrAddStatusBar")
    -- update if a bar for the player exists
    for i, bar in ipairs(statusBars[tab]) do
        if bar.GUID == GUID then
            bar.spellID = spellID
            if timestamp then
                bar.currentTime = timestamp
                if spellID == 15487 and SIR.groupInfo[GUID]["TALENTS"][4] == 1 then
                    bar.expirationTime = timestamp+30
                else
                    bar.expirationTime = timestamp+cds[spellID]
                    setBarOnUpdate(bar)
                end
            else
                bar.currentTime = 0
                bar.expirationTime = 0
            end
            -- resort / move bar to correct index if sortmode is by CD
            if SIR.tabOptions[tab]["SORTMODE"] == "CD" then
                local moveTo = i
                -- find the index to place the bar into
                for j=i+1, #statusBars[tab] do
                    if statusBars[tab][j].expirationTime < bar.expirationTime then
                        moveTo = moveTo+1
                    else
                        break
                    end
                end
                -- if the position changes
                if moveTo ~= i then
                    -- adjust anchors
                    SIR.util.myPrint("moveTo", moveTo, "i", i)
                    statusBars[tab][i+1]:SetPoint(bar:GetPoint(1))
                    bar:SetPoint("TOPRIGHT", statusBars[tab][moveTo], "BOTTOMRIGHT", 0, -SIR.tabOptions[tab]["SPACE"])
                    if statusBars[tab][moveTo+1] then
                        statusBars[tab][moveTo+1]:SetPoint("TOPRIGHT", statusBars[tab][moveTo], "BOTTOMRIGHT",
                        0, -SIR.tabOptions[tab]["SPACE"])
                    end
                    -- adjust table
                    for j=i, moveTo-1 do
                        statusBars[tab][j] = statusBars[tab][j+1]
                    end
                    statusBars[tab][moveTo] = bar
                end
            end
            return
        end
    end
    -- else add a new bar
    addStatusBar(tab, GUID, spellID, class, timestamp)
end
local removeStatusBar = function(tab, index)
    SIR.util.myPrint("removeStatusBar")
    if statusBars[tab][index+1] then
        statusBars[tab][index+1]:SetPoint("TOPRIGHT", statusBars[tab][index-1] or rotationFrames[tab], "BOTTOMRIGHT",
            0, statusBars[tab][index-1] and SIR.tabOptions[tab]["SPACE"] or 0)
    end
    SIR.frameUtil.releaseStatusBar(statusBars[tab][index])
    for i=index, #statusBars do
        statusBars[tab][i] = statusBars[tab][i+1]
    end
end
local removeAllStatusBars = function(tab)
    SIR.util.myPrint("removeAllStatusBars tab", tab, "#", #statusBars[tab])
    for i=#statusBars[tab], 1, -1 do
        SIR.frameUtil.releaseStatusBar(statusBars[tab][i])
    end
    statusBars[tab] = {}
end

rotationFunc.sortTab = function(tab)
    SIR.util.myPrint("sortTab", tab)
    SIR.util.myPrint(statusBars[tab])
    local temp = {}
    for _, bar in ipairs(statusBars[tab]) do
        insertBar(tab, temp, bar)
    end
    statusBars[tab] = temp
end
rotationFunc.onCombatLogEvent = function ()
    local timestamp, subEvent, _, sourceGUID, _, sourceFlags, _, _, _, _, _, spellID  = CombatLogGetCurrentEventInfo()
    if subEvent ~= "SPELL_CAST_SUCCESS" or not cds[spellID] or sourceFlags%16 > 4 then
        return
    end
    for tab=1, #statusBars do
        if SIR.groupInfo[sourceGUID] then
            updateOrAddStatusBar(tab, sourceGUID, spellID, SIR.groupInfo[sourceGUID]["CLASS"], timestamp)
        else
            -- should (basically) never happen?!
            updateOrAddStatusBar(tab, sourceGUID, spellID, select(2, GetPlayerInfoByGUID(sourceGUID)), timestamp)
        end
    end
end
SIR.rotationFunc.addRotationMember = function(tab, GUID)
    if not (trackModes[tab] == "ROTATION") then
        return
    end
    SIR.util.myPrint("rotationFunc.addPlayerToTab")
    local class, spec = SIR.groupInfo[GUID]["CLASS"], SIR.groupInfo[GUID]["SPEC"]
    if not class then
        SIR.util.myPrint("rotationFunc.addPlayerToTab", "no class")
        return
    end
    local spellID = classWideInterrupts[class]
    if not spellID and spec then
        spellID = specInterrupts[spec]
    end
    if spellID then
        addStatusBar(tab, GUID, spellID, class)
    end
end
rotationFunc.removeRotationMember = function(tab, GUID)
    if not (trackModes[tab] == "ROTATION") then
        return
    end
    SIR.util.myPrint("rotationFunc.removePlayerFromTab")
    for i, bar in ipairs(statusBars[tab]) do
        if bar.GUID == GUID then
            removeStatusBar(tab, i)
        end
    end
end
rotationFunc.updateNumGroup = function(num)
    numGroup = num
    for i=1, #trackModes do
        rotationFunc.updateTrackMode(i)
    end
end
rotationFunc.updateTrackMode = function(tab)
    SIR.util.myPrint("updateTrackMode tab "..tab.." current mode: "..trackModes[tab])
    local old = trackModes[tab]
    if not SIR.tabOptions[tab]["SPECENABLEOPTIONS"][SIR.playerInfo["SPEC"]] then
        trackModes[tab] = "NONE"
	elseif SIR.tabOptions[tab]["TRACKALLCHECKED"] and SIR.tabOptions[tab]["TRACKALLFROM"]<= numGroup
        and numGroup <= SIR.tabOptions[tab]["TRACKALLTO"] then
		trackModes[tab] = "ALL"
	elseif SIR.tabOptions[tab]["TRACKROTATIONCHECKED"] and SIR.tabOptions[tab]["TRACKROTATIONFROM"]<= numGroup
        and numGroup <= SIR.tabOptions[tab]["TRACKROTATIONTO"] then
        trackModes[tab] = "ROTATION"
	else
		trackModes[tab] = "NONE"
    end
	if old == trackModes[tab] then
		return
    end

    if trackModes[tab] == "NONE" then
        removeAllStatusBars(tab)
	elseif old == "NONE" then
        if trackModes[tab] == "ROTATION" then
            --add rotation
            for i=1, #SIR.tabOptions[tab]["ROTATION"] do
                local GUID = SIR.tabOptions[tab]["ROTATION"][i]
                if SIR.groupInfo[GUID] then
                    rotationFunc.playerInit(GUID, SIR.groupInfo[GUID]["CLASS"])
                    if SIR.groupInfo[GUID]["SPEC"] then
                        rotationFunc.specUpdate(GUID, SIR.groupInfo[GUID]["CLASS"], SIR.groupInfo[GUID]["SPEC"])
                    end
                end
            end
		elseif trackModes[tab] == "ALL" then
            for GUID, info in pairs(SIR.groupInfo) do
                rotationFunc.playerInit(GUID, info["CLASS"])
                if info["SPEC"] then
                    rotationFunc.specUpdate(GUID, info["CLASS"], info["SPEC"])
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
                    rotationFunc.specUpdate(GUID, info["CLASS"], info["SPEC"])
                end
            end
        end
	else
		-- old == "ALL" unless more modes added
		-- trackModes[tab] == "ROTATION" unless more modes added
        -- remove players that arent part of the rotation
        for i=#statusBars[tab], 1, -1 do
            if not contains(SIR.tabOptions[tab]["ROTATION"], statusBars[tab][i].GUID) then
                removeStatusBar(tab, i)
            end
        end
    end
end
rotationFunc.playerInit = function(GUID, class)
    SIR.util.myPrint("rotationFunc.playerInit")
    if classWideInterrupts[class] then
        for tab=1, #rotationFrames do
            if trackModes[tab] == "ALL" or (trackModes[tab] == "ROTATION"
                and contains(SIR.tabOptions[tab]["ROTATION"], GUID)) then
                addStatusBar(tab, GUID, classWideInterrupts[class], class)
            end
        end
    end
end
rotationFunc.specUpdate = function(GUID, class, newSpec)
    SIR.util.myPrint("rotationFunc.specUpdate")
    if not specInterrupts[newSpec] then
        rotationFunc.removePlayer(GUID)
    else
        for tab=1, #statusBars do
            updateOrAddStatusBar(tab, GUID, specInterrupts[newSpec], class)
        end
    end
    --[[ if classWideInterrupts[class] then
        return
    end
    if oldSpec then
        if specInterrupts[oldSpec] == specInterrupts[newSpec] then
            return
        end
        if not specInterrupts[oldSpec] then
            addStatusBar(tab, GUID, specInterrupts[spec])
        elseif not specInterrupts[newSpec] then
            for tab=1, #statusBars do
                local currStatusBars = statusBars[tab]
                for i, bar in ipairs(currStatusBars) do
                    if bar.GUID == GUID then
                        removeStatusBar(tab, i)
                    end
                end
            end
        else
            for tab=1, #statusBars do
                local currStatusBars = statusBars[tab]
                for _, bar in ipairs(currStatusBars) do
                    if bar.GUID == GUID and bar.spellID ~= specInterrupts[newSpec]then
                        bar.spellID = specInterrupts[newSpec]
                        bar.icon:SetTexture(select(3, GetSpellInfo(specInterrupts[newSpec])))
                        bar.expirationTime = 0
                        bar.currentTime = 0
                    end
                end
            end
        end
    end ]]--
end
rotationFunc.removePlayer = function(GUID)
    SIR.util.myPrint("rotationFunc.removePlayer")
    for tab=1, #statusBars do
        for bar=1, #statusBars[tab] do
            if statusBars[tab][bar].GUID == GUID then
                removeStatusBar(tab, bar)
            end
        end
    end
end
rotationFunc.newRotationTab = function(tab)
    local rotationFrame = SIR.frameUtil.aquireRotationFrame(SIR.optionFrames.container, tab)
    rotationFrame:ClearAllPoints()
    rotationFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
        SIR.tabOptions[tab]["XOFF"], SIR.tabOptions[tab]["YOFF"])
    rotationFrame:SetSize(SIR.tabOptions[tab]["WIDTH"], SIR.tabOptions[tab]["HEIGHT"])
    rotationFrame.fontString:SetText(SIR.tabOptions[tab]["TITLE"])
    rotationFrames[tab] = rotationFrame
    trackModes[tab] = "NONE"
    statusBars[tab] = {}
    rotationFunc.updateTrackMode(tab)
end
rotationFunc.removeRotationTab = function(tab)
    removeAllStatusBars(tab)
    SIR.frameUtil.releaseRotationFrame(rotationFrames[tab])
    for i=tab, #rotationFrames-1 do
        rotationFrames[i] = rotationFrames[i+1]
        trackModes[i] = trackModes[i+1]
        statusBars[i] = statusBars[i+1]
    end
end
rotationFunc.updateDisplay = function(tab, value)
    SIR.util.myPrint("rotationFunc.updateDisplay")
    if value == "WIDTH" then
        rotationFrames[tab]:SetWidth(SIR.tabOptions[tab]["WIDTH"])
        for _, bar in ipairs(statusBars[tab]) do
            bar:SetWidth(SIR.tabOptions[tab]["WIDTH"]-SIR.tabOptions[tab]["HEIGHT"])
        end
    elseif value == "HEIGHT" then
        rotationFrames[tab]:SetHeight(SIR.tabOptions[tab]["HEIGHT"])
        for _, bar in ipairs(statusBars[tab]) do
            bar:SetHeight(SIR.tabOptions[tab]["HEIGHT"])
            bar.icon:SetSize(SIR.tabOptions[tab]["HEIGHT"], SIR.tabOptions[tab]["HEIGHT"])
        end
    elseif value == "SPACE" then
        local currStatusBars = statusBars[tab]
        for i=2, #currStatusBars do
            for j=1, currStatusBars:GetNumPoints() do
                local point, anchorFrame, anchorPoint = currStatusBars[i]:GetPoint(j)
                currStatusBars[i]:SetPoint(point, anchorFrame, anchorPoint, 0, SIR.tabOptions[tab]["SPACE"])
            end
        end
    else -- value == "XOFF" or value == "YOFF"
        rotationFrames[tab]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
            SIR.tabOptions[tab]["XOFF"], SIR.tabOptions[tab]["YOFF"])
    end
end
rotationFunc.rotationFrameOnDragStop = function(self)
    self:StopMovingOrSizing()
    local xOff ,yOff = self:GetRect()
    SIR.tabOptions[self.key]["XOFF"], SIR.tabOptions[self.key]["YOFF"] = xOff, yOff
    SIR.optionFrames.xOffEditBox:SetText(xOff)
    SIR.optionFrames.yOffEditBox:SetText(yOff)
    self:ClearAllPoints()
    self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", xOff, yOff)
    self:SetSize(SIR.tabOptions[self.key]["WIDTH"], SIR.tabOptions[self.key]["HEIGHT"])
    self:Show()
end