--luacheck: globals GetSpellInfo strsub UIParent unpack setBarOnUpdate GetPlayerInfoByGUID
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
local numGroup = 1

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
local insertBar = function(tab, bar)
    local currStatusBars = statusBars[tab]
    local insertAt = 1
    if SIR.tabOptions[tab]["SORTMODE"] == "CD" then
        for i=#currStatusBars, 1, -1 do
            if currStatusBars[i].expirationTime < bar.expirationTime then
                insertAt = i+1
                break
            end
        end
        for j=#currStatusBars, insertAt do
            currStatusBars[j+1] = currStatusBars[j]
        end
    elseif SIR.tabOptions[tab]["SORTMODE"] == "ROTATION" then
        local rotationPos
        local prePos = {}
        for i, rotaMemberGUID in ipairs(SIR.tabOptions[tab]["ROTATION"]) do
            if bar.GUID == rotaMemberGUID then
                rotationPos = i
                break
            end
        end
        for i=1, rotationPos-1 do
            prePos[i] = SIR.tabOptions[tab]["ROTATION"][i]
        end
        insertAt = #currStatusBars+1
        for i=1, #currStatusBars do
            if not contains(prePos, currStatusBars[i].GUID) then
                insertAt = i
                break
            end
        end
    else --SIR.tabOptions[tab]["SORTMODE"] == "NONE"
        insertAt = #currStatusBars+1
    end
    currStatusBars[insertAt] = bar
    if currStatusBars[insertAt+1] then
        for i=1, currStatusBars[insertAt+1]:GetNumPoints() do
        local point, anchorFrame, anchorPoint, _, space= currStatusBars[insertAt+1]:GetPoint(i)
            currStatusBars[insertAt]:SetPoint(point, anchorFrame, anchorPoint, 0, space)
            currStatusBars[insertAt+1]:SetPoint(point, currStatusBars[insertAt], anchorPoint,
                0, SIR.tabOptions[tab]["SPACE"])
        end
    else
        currStatusBars[insertAt]:SetPoint("TOPRIGHT", currStatusBars[insertAt-1] or rotationFrames[tab], "BOTTOMRIGHT",
            0, currStatusBars[insertAt-1] and SIR.tabOptions[tab]["SPACE"] or 0)
    end
end
local addStatusBar = function(tab, GUID, spellID, class, timestamp)
    SIR.util.myPrint("addStatusBar")
    local currStatusBars = statusBars[tab]
    local oldNum = #currStatusBars
    local statusBar = SIR.frameUtil.aquireStatusBar()
    statusBar.icon:SetTexture(select(3, GetSpellInfo(spellID)))
    statusBar.GUID = GUID
    statusBar.spellID = spellID
    statusBar:SetStatusBarColor(unpack(classColorsRGB[class]))
    --todo sorting
    --statusBar:SetPoint("TOPRIGHT", currStatusBars[oldNum] or rotationFrames[tab],
    --    "BOTTOMRIGHT", 0, currStatusBars[oldNum] and -SIR.tabOptions[tab]["SPACE"])
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
    insertBar(tab, statusBar)
    statusBar:Show()
    statusBars[tab][oldNum+1] = statusBar
    -- todo sort
end
local updateOrAddStatusBar = function(tab, GUID, spellID, class, timestamp)
    SIR.util.myPrint("updateOrAddStatusBar")
    -- update if a bar for the player exists
    for _, bar in ipairs(statusBars[tab]) do
        if bar.GUID == GUID then
            bar.spellID = spellID
            if timestamp then
                bar.currentTime = timestamp
                bar.expirationTime = timestamp+cds[spellID]
                setBarOnUpdate(bar)
            else
                bar.currentTime = 0
                bar.expirationTime = 0
            end
            if SIR.tabOptions[tab]["SORTMODE"] == "CD" then
                --todo move bar depending on CD
            end
            return
        end
    end
    -- else add a new bar
    addStatusBar(tab, GUID, spellID, class, timestamp)
end
rotationFunc.sortTab = function(tab)
    local temp = {}
    for _, bar in ipairs(statusBars[tab]) do
        insertBar(tab, temp, bar)
    end
    statusBars[tab] = temp
end
local removeStatusBar = function(tab, index)
    SIR.util.myPrint("removeStatusBar")
    if statusBars[tab][index+1] then
        statusBars[tab][index+1]:ClearAllPoints()
        for j=1, statusBars[tab][index]:GetNumPoints() do
            local point, _, anchorPoint, xOff, yOff = statusBars[tab][index]:GetPoint(j)
            statusBars[tab][index+1]:SetPoint(point, statusBars[index-1] or rotationFrames[tab],
                anchorPoint, xOff, yOff)
        end
    end
    SIR.frameUtil.releaseStatusBar(statusBars[tab][index])
    for i=index, #statusBars-1 do
        statusBars[tab][i] = statusBars[tab][i+1]
    end
end
local removeAllStatusBars = function(tab)
    SIR.util.myPrint("removeAllStatusBars")
    for i=1, #statusBars[tab] do
        SIR.frameUtil.releaseStatusBar(statusBars[tab][i])
    end
    statusBars[tab] = {}
end
rotationFunc.onInterrupt = function (GUID, spellID, timestamp)
    SIR.util.myPrint("rotationFunc.onInterrupt")
    for tab=1, #statusBars do
        if SIR.groupInfo[GUID] then
            updateOrAddStatusBar(tab, GUID, spellID, SIR.groupInfo[GUID]["CLASS"], timestamp)
        else
            -- should (basically) never happen?!
            updateOrAddStatusBar(tab, GUID, spellID, select(2, GetPlayerInfoByGUID(GUID)), timestamp)
        end
    end
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
            if not contains(SIR.tabOptions[tab]["ROTATION"], statusBars[tab][i]:GetGUID()) then
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
rotationFunc.newRotationTab = function(tab)
    local rotationFrame = SIR.frameUtil.aquireRotationFrame(SIR.optionFrames.container, tab)
    rotationFrame:SetPoint("CENTER", UIParent, "CENTER", SIR.tabOptions[tab]["XOFF"], SIR.tabOptions[tab]["YOFF"])
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
