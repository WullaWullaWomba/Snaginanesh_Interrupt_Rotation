--luacheck: globals CreateFrame UIParent UISpecialFrames UIDropDownMenu_SetWidth GetClassInfo CLASS_ICON_TCOORDS
--luacheck: globals GetNumSpecializationsForClassID GetSpecializationInfoByID gsub unpack GameTooltip
local _, SIR = ...

local frameUtil = SIR.frameUtil
local data = SIR.data
local optionFunc = SIR.optionFunc

local container = CreateFrame("Frame", "SnagiIntRotaContainer", UIParent, "BackdropTemplate")
    UISpecialFrames[#UISpecialFrames+1] = container:GetName() -- hide on escape - and maybe more <.<
    container:SetFrameStrata("DIALOG")
    container:Hide()
    container:EnableMouse(true)
    container:SetPoint("CENTER")
    container:SetSize(400,475)
    container:RegisterForDrag("LeftButton")
    container:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tileSize = 32,
        edgeSize = 32,
        tile = true,
        insets = {left="11", right="12", top="12", bottom="11"},
    })
    container:SetMovable(true)
    container:SetScript("OnDragStart", function() container:StartMoving() end)
    container:SetScript("OnDragStop", function() container:StopMovingOrSizing() end)
local containerHeader = container:CreateTexture("$parentHeader", "ARTWORK")
    containerHeader:SetSize(440, 64)
    containerHeader:SetPoint("TOP", container, "TOP", 0, 25)
    containerHeader:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")

local containerHeaderText = container:CreateFontString("$parentHeaderText", "ARTWORK", "GameFontNormal")
    containerHeaderText:SetPoint("TOP", containerHeader, "TOP", 0, -14)
    containerHeaderText:SetText("Snaginanesh Interrupt Rotation")

local closeButton = CreateFrame("Button", "$parentRemove", container, "UIPanelCloseButton")
    closeButton:SetScript("OnClick", function() container:Hide() end)
    closeButton:SetPoint("BOTTOMRIGHT", container, "TOPRIGHT", 0, -15)
    closeButton:SetSize(40, 40)
    closeButton:Show()

local generalTab = CreateFrame("Frame", _, container)
    generalTab:SetAllPoints()
    generalTab:Show()

local generalTabButton = frameUtil.aquireTabButton(container)
    generalTabButton:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, 8)
    generalTabButton:SetText("General")
    generalTabButton:SetScript("OnClick", function(self) optionFunc.generalTabButtonOnClick(self) end)

local greyOutLabel = generalTab:CreateFontString(_, "ARTWORK", "GameFontNormalLarge")
    greyOutLabel:SetText("Grey out: ")
    greyOutLabel:SetTextColor(255,255,255)
    greyOutLabel:SetPoint("TOPLEFT", generalTab, "TOPLEFT", 25, -100)

local greyOutDeadCheckBox = frameUtil.createFontStringCheckBox("dead", generalTab)
    greyOutDeadCheckBox.tooltipText = "Greys out dead players."
    greyOutDeadCheckBox:SetPoint("LEFT", greyOutLabel, "RIGHT", 25, 0)
    greyOutDeadCheckBox:SetScript("OnClick", function(self) optionFunc.greyOutDeadCheckBoxOnClick(self) end)
    greyOutDeadCheckBox:SetHitRectInsets(
        -greyOutDeadCheckBox.fontString:GetWidth()/2+greyOutDeadCheckBox:GetWidth()/2
        , -greyOutDeadCheckBox.fontString:GetWidth()/2+greyOutDeadCheckBox:GetWidth()/2
        , -greyOutDeadCheckBox.fontString:GetHeight()
        , 0) --l r t b

    greyOutDeadCheckBox.fontString:ClearAllPoints()
    greyOutDeadCheckBox.fontString:SetPoint("BOTTOM", greyOutDeadCheckBox, "TOP", 0, 0)

local greyOutDisabledCheckBox = frameUtil.createFontStringCheckBox("disabled", generalTab)
    greyOutDisabledCheckBox.tooltipText = "Greys out disconnected AND players leaving your area."
    greyOutDisabledCheckBox:SetPoint("LEFT", greyOutDeadCheckBox, "RIGHT", 50, 0)
    greyOutDisabledCheckBox:SetScript("OnClick", function(self) optionFunc.greyOutDisabledCheckBoxOnClick(self) end)
    greyOutDisabledCheckBox:SetHitRectInsets(
        -greyOutDisabledCheckBox.fontString:GetWidth()/2+greyOutDisabledCheckBox:GetWidth()/2
        , -greyOutDisabledCheckBox.fontString:GetWidth()/2+greyOutDisabledCheckBox:GetWidth()/2
        , -greyOutDisabledCheckBox.fontString:GetHeight()
        , 0) --l r t b

    greyOutDisabledCheckBox.fontString:ClearAllPoints()
    greyOutDisabledCheckBox.fontString:SetPoint("BOTTOM", greyOutDisabledCheckBox, "TOP", 0, 0)

local rotationTab = CreateFrame("Frame", _, container)
    rotationTab:SetAllPoints()
    rotationTab:Hide()
    rotationTab:SetScript("OnShow", function() SIR.optionFunc.rotationTabOnShow() end)
local rotationTabButtons = {}

local createNewTabButton = CreateFrame("Button", _, generalTab, "UIPanelButtonTemplate")
    createNewTabButton.tooltipText = "Creates a new rotation tab, with it's own options (can have multiple tabs)."
    createNewTabButton:SetSize(100, 40)
    createNewTabButton:SetPoint("BOTTOMRIGHT", generalTab, "BOTTOMRIGHT", -15, 15)
    createNewTabButton:SetText("New tab")
    createNewTabButton:SetScript("OnClick", function()
        optionFunc.createNewTab()
    end)
local removeTabButton = CreateFrame("Button", "$parentRemoveTabButton", rotationTab, "UIPanelButtonTemplate")
    removeTabButton:SetSize(100, 40)
    removeTabButton:SetPoint("BOTTOMRIGHT", rotationTab, "BOTTOMRIGHT", -15, 15)
    removeTabButton:SetText("Remove tab")
    removeTabButton:SetScript("OnClick", function() optionFunc.removeTabOnClick() end)

local leftSideMenu = CreateFrame("Frame", _ , container, "BackdropTemplate")
    leftSideMenu:SetPoint("TOPRIGHT", container, "TOPLEFT", 12, 0)
    leftSideMenu:SetPoint("BOTTOMRIGHT", container, "BOTTOMLEFT", 12, 0)
    leftSideMenu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tileSize = 32,
        edgeSize = 32,
        tile = true,
        insets = {left="11", right="12", top="12", bottom="11"},
    })
    leftSideMenu:SetWidth(250)
    leftSideMenu:Hide()

local testButton = CreateFrame("Button", _, container, "UIPanelButtonTemplate")
    testButton.tooltipText = "Generates some example statusbars for each rotation tab."
    testButton:SetSize(100, 40)
    testButton:SetPoint("TOPLEFT", container, "TOPLEFT", 15, -15)
    testButton:SetText("Test")
    testButton:SetScript("OnClick", function() optionFunc.testButtonOnClick() end)

local menuButtons = {
    ["ENABLE"] = frameUtil.createMenuButton("Enable", rotationTab),
    ["SEND"] = frameUtil.createMenuButton("Send", rotationTab),
    ["DISPLAY"] = frameUtil.createMenuButton("Display", rotationTab),
    ["SORTING"] = frameUtil.createMenuButton("Sorting", rotationTab),
    ["SOUND"] = frameUtil.createMenuButton("Sound", rotationTab),
}
menuButtons["ENABLE"].tooltipText = "Select what to track depending on the current group size."
menuButtons["ENABLE"]:SetPoint("TOPLEFT", testButton, "BOTTOMLEFT", 0, -5)
menuButtons["SEND"].tooltipText = "Send your currently selected tab's rotation."
menuButtons["SEND"]:SetPoint("TOPLEFT", menuButtons["ENABLE"], "BOTTOMLEFT", 0, -5)
menuButtons["DISPLAY"]:SetPoint("TOPLEFT", menuButtons["SEND"], "BOTTOMLEFT", 0, -5)
menuButtons["DISPLAY"].tooltipText = "Change display settings for the current tab."
    .."\n\nAlternatively drag the tab's frame to change x and y values."
menuButtons["SORTING"]:SetPoint("TOPLEFT", menuButtons["DISPLAY"], "BOTTOMLEFT", 0, -5)
menuButtons["SOUND"]:SetPoint("TOPLEFT", menuButtons["SORTING"], "BOTTOMLEFT", 0, -5)

local widthFontString, widthEditBox = frameUtil.createFontStringEditBox(menuButtons["DISPLAY"])
    widthFontString:SetText("width:")
    widthEditBox:SetPoint("TOPLEFT", leftSideMenu, "TOPLEFT", 115, -35)
    widthEditBox:SetScript("OnEnterPressed", function(self) optionFunc.displayEditBoxOnEnter(self, "WIDTH") end)
    widthEditBox:Hide()

local heightFontString, heightEditBox = frameUtil.createFontStringEditBox(menuButtons["DISPLAY"])
    heightFontString:SetText("height:")
    heightEditBox:SetPoint("TOP", widthEditBox, "BOTTOM", 0, -6)
    heightEditBox:SetScript("OnEnterPressed", function(self) optionFunc.displayEditBoxOnEnter(self, "HEIGHT") end)
    heightEditBox:Hide()

local spaceFontString, spaceEditBox = SIR.frameUtil.createFontStringEditBox(menuButtons["DISPLAY"])
    spaceFontString:SetText("space:")
    spaceEditBox:SetPoint("TOP", heightEditBox, "BOTTOM", 0, -6)
    spaceEditBox:SetScript("OnEnterPressed", function(self) optionFunc.displayEditBoxOnEnter(self, "SPACE") end)
    spaceEditBox:Hide()

local xOffFontString, xOffEditBox = SIR.frameUtil.createFontStringEditBox(menuButtons["DISPLAY"])
    xOffFontString:SetText("x offset:")
    xOffEditBox:SetPoint("TOP", spaceEditBox, "BOTTOM", 0, -6)
    xOffEditBox:SetScript("OnEnterPressed", function(self) optionFunc.displayEditBoxOnEnter(self, "XOFF") end)
    xOffEditBox:Hide()

local yOffFontString, yOffEditBox = SIR.frameUtil.createFontStringEditBox(menuButtons["DISPLAY"])
    yOffFontString:SetText("y offset:")
    yOffEditBox:SetPoint("TOP", xOffEditBox, "BOTTOM", 0, -6)
    yOffEditBox:SetScript("OnEnterPressed", function(self) optionFunc.displayEditBoxOnEnter(self, "YOFF") end)
    yOffEditBox:Hide()

local titleFontString, titleEditBox = SIR.frameUtil.createFontStringEditBox(menuButtons["SEND"])
    titleEditBox:Hide()
    titleFontString:SetText("Title: ")
    titleFontString:ClearAllPoints()
    titleFontString:SetPoint("BOTTOM", titleEditBox, "TOP", 0, 5)
    titleEditBox:SetWidth(100)
    titleEditBox:SetMaxLetters(11)
    titleEditBox:SetPoint("TOP", leftSideMenu, "TOP", 0, -50)
    titleEditBox:SetScript("OnSpacePressed", function(self)
        self:SetText(gsub(self:GetText(), "%s","_"))
    end)
    titleEditBox:SetScript("OnEnterPressed", function(self) optionFunc.titleEditBoxOnEnterPressed(self) end)


local enableGroupInstanceButton = CreateFrame("Button", _, menuButtons["ENABLE"], "UIPanelButtonTemplate")
    enableGroupInstanceButton.tooltipText = "Select when to track all/none/rotation only interrupts."
    enableGroupInstanceButton:Hide()
    enableGroupInstanceButton:SetSize(110, 40)
    enableGroupInstanceButton:SetText("group/instance")
    enableGroupInstanceButton:SetPoint("TOPLEFT", leftSideMenu, 23, -15)
    enableGroupInstanceButton:LockHighlight()
    enableGroupInstanceButton:SetScript("OnClick", function(self) optionFunc.enableGroupInstanceButtonOnClick(self) end)

local enableClassSpecButton = CreateFrame("Button", _, menuButtons["ENABLE"], "UIPanelButtonTemplate")
    enableClassSpecButton.tooltipText = "Select classes/specs on which to enable tracking."
    enableClassSpecButton:Hide()
    enableClassSpecButton:SetSize(93, 40)
    enableClassSpecButton:SetText("class/spec")
    enableClassSpecButton:SetPoint("LEFT", enableGroupInstanceButton, "RIGHT", 5, 0)
    enableClassSpecButton:SetScript("OnClick", function(self) optionFunc.enableClassSpecButtonOnClick(self) end)

local enableCheckBoxes = {}
--Enable class/spec checkBoxes
for c=1, 12 do
	--for each class
	--make class checkBox & icon
	enableCheckBoxes[c] = {}
	enableCheckBoxes[c][1] = SIR.frameUtil.createIconCheckBox(32, 32, enableClassSpecButton)

	if enableCheckBoxes[c-1] then
		enableCheckBoxes[c][1]:SetPoint("LEFT", enableCheckBoxes[c-1][1], "LEFT")
		enableCheckBoxes[c][1]:SetPoint("TOP", enableCheckBoxes[c-1][#enableCheckBoxes[c-1]], "BOTTOM", 0, -5)
	else
		enableCheckBoxes[c][1]:SetPoint("TOPLEFT", enableGroupInstanceButton, "BOTTOMLEFT", 0+32, -5)
	end
	enableCheckBoxes[c][1].icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
	local class = select(2, GetClassInfo(c))
	local coords = CLASS_ICON_TCOORDS[class]
	enableCheckBoxes[c][1].icon:SetTexCoord(unpack(coords))
    enableCheckBoxes[c][1]:SetScript("OnClick", function(self) optionFunc.enableClassOnClick(self, c) end)

	for s=1, GetNumSpecializationsForClassID(c) do
		local specID = data.classSpecIDs[c][s]
		--make spec checkBox & icon
		local extraOffset = 0
		if s == 1 then
			extraOffset = 10
		end
		enableCheckBoxes[c][s+1] = SIR.frameUtil.createIconCheckBox(22, 22, enableClassSpecButton)
		enableCheckBoxes[c][s+1]:SetPoint("LEFT", enableCheckBoxes[c][s], "RIGHT", 22+extraOffset, 0)
		enableCheckBoxes[c][s+1].spec = specID
		enableCheckBoxes[c][s+1].class = c
		local icon = select(4, GetSpecializationInfoByID(enableCheckBoxes[c][s+1].spec))
		enableCheckBoxes[c][s+1].icon:SetTexture(icon)

		enableCheckBoxes[c][s+1]:SetScript("OnClick", function(self)
            optionFunc.enableSpecOnClick(self, c, s)
		end)
	end
end
-- move guardian (and thereby restoration and DH)
enableCheckBoxes[11][4]:ClearAllPoints()
enableCheckBoxes[11][4]:SetPoint("TOP", enableCheckBoxes[11][2], "BOTTOM")

for i=1, #enableCheckBoxes do
	for j=1, #enableCheckBoxes[i] do
		enableCheckBoxes[i][j]:Hide()
	end
end

local trackAllOption = frameUtil.createFromToOption("Track all", "ALL", 0, 40, enableGroupInstanceButton)

    trackAllOption.checkBox:SetPoint("TOP", enableGroupInstanceButton, "BOTTOMRIGHT", -31, -20)
    trackAllOption.checkBox.tooltipText = "Tracks all interrupts from players in the party\n"..
                                    "when enabled and within the given groupsize."
local trackRotationOption = frameUtil.createFromToOption("Rotation", "ROTATION", 0, 40, enableGroupInstanceButton)
    trackRotationOption.checkBox:SetPoint("TOP", trackAllOption.checkBox, "BOTTOMRIGHT", -14, -80)
    trackRotationOption.checkBox.tooltipText = "Tracks the given players in the rotation"..
                                    "\nwhen enabled and within the given groupsize."..
                                    "\n\nNOTE - If track all is active, tihs will be overruled. "
--Enable trackall / track rotation frames

local sendRotationButtons = {}
for i=1, 4 do
    sendRotationButtons[i] = CreateFrame("Button", _, menuButtons["SEND"], "UIPanelButtonTemplate")
	sendRotationButtons[i]:Hide()
	sendRotationButtons[i]:SetSize(60, 40)
    sendRotationButtons[i]:SetText(data.chatTypes[i])
    sendRotationButtons[i].value = data.chatTypes[i]
    sendRotationButtons[i]:SetScript("OnClick", function(self) optionFunc.sendRotationOnClick(self) end)
end

local sendRotationFontString, whisperToEditBox = SIR.frameUtil.createFontStringEditBox(menuButtons["SEND"])
    sendRotationFontString:SetText("Link in:")
    sendRotationFontString:SetSize(76, 30)
    sendRotationFontString:ClearAllPoints()
    sendRotationFontString:SetPoint("TOP", titleEditBox, "BOTTOM", 0, -15)
    whisperToEditBox:SetWidth(140)
    whisperToEditBox:SetMaxLetters(30)
    whisperToEditBox:SetText("\124cFF606060whisper-target\124r")
    whisperToEditBox:Hide()
    whisperToEditBox:SetScript("OnEnterPressed", function() whisperToEditBox:ClearFocus() end)
sendRotationButtons[1]:SetPoint("RIGHT", sendRotationButtons[2], "LEFT", -5, 0)
sendRotationButtons[2]:SetPoint("TOP", sendRotationFontString, "BOTTOM")
sendRotationButtons[3]:SetPoint("LEFT", sendRotationButtons[2], "RIGHT", 5, 0)
whisperToEditBox:SetPoint("TOP", sendRotationButtons[2], "BOTTOM", 0, -40)
sendRotationButtons[4]:SetPoint("TOP", whisperToEditBox, "BOTTOM", 0, -5)
sendRotationButtons[4]:SetWidth(80)


local groupMemberButtons = {}
for i=1, 40 do
    groupMemberButtons[i] = frameUtil.createGroupMemberButton(rotationTab)
    groupMemberButtons[i]:SetPoint("TOPLEFT", groupMemberButtons[i-1] or rotationTab, "BOTTOMLEFT")
    groupMemberButtons[i]:SetScript("OnClick", function(self) optionFunc.groupMemberOnClick(self) end)
end
-- 3. Position groupMemberButtons
for i=6, 36, 5 do
	if i%10 == 6 then
		groupMemberButtons[i]:SetPoint("TOPLEFT", groupMemberButtons[i-5], "TOPRIGHT")
	else
		groupMemberButtons[i]:SetPoint("TOPLEFT", groupMemberButtons[i-6], "BOTTOMLEFT", 0, -5)
	end

end
groupMemberButtons[1]:SetPoint("TOPLEFT", rotationTab, "TOPRIGHT")

local rotationButtons = {}
local removeMemberButtons = {}
for i=1, 10 do
    rotationButtons[i] = frameUtil.createRotationButton(rotationTab)
    rotationButtons[i].value = i
    rotationButtons[i]:SetPoint("TOPLEFT", rotationButtons[i-1] or rotationTab, "BOTTOMLEFT")
    rotationButtons[i]:SetScript("OnClick", function(self, button) optionFunc.rotationButtonOnClick(self, button) end)
    removeMemberButtons[i] = frameUtil.createRemoveMemberButton(rotationButtons[i])
    removeMemberButtons[i]:SetScript("OnClick", function(self) optionFunc.removeMemberOnClick(self) end)
end
rotationButtons[1]:ClearAllPoints()
rotationButtons[1]:SetPoint("TOPRIGHT", -25, -25)

local sortModeCheckBoxes = {
    ["CD"] = frameUtil.createSortCheckBox("by CD", menuButtons["SORTING"]),
    ["ROTATION"] = frameUtil.createSortCheckBox("by rotation", menuButtons["SORTING"]),
}
sortModeCheckBoxes["CD"].value = "CD"
sortModeCheckBoxes["CD"]:SetPoint("TOPLEFT", leftSideMenu, "TOP", 0, -50)

sortModeCheckBoxes["ROTATION"].value = "ROTATION"
sortModeCheckBoxes["ROTATION"]:SetPoint("TOP", sortModeCheckBoxes["CD"], "BOTTOM", 0, -5)

local playSoundCheckBox = frameUtil.createFontStringCheckBox("play sound", menuButtons["SOUND"])
    playSoundCheckBox.tooltipText = "Play a sound when it's your turn next."
    playSoundCheckBox:SetScript("OnClick", function(self) optionFunc.playSoundCheckBoxOnClick(self) end)
    playSoundCheckBox:SetHitRectInsets(0 , -playSoundCheckBox.fontString:GetWidth(), 0, 0) --l r t b
    playSoundCheckBox:SetPoint("RIGHT", leftSideMenu, "CENTER", -30, 0)
    playSoundCheckBox:SetPoint("TOP", leftSideMenu, "TOP", 0, -50)
    playSoundCheckBox.fontString:ClearAllPoints()
    playSoundCheckBox.fontString:SetPoint("LEFT", playSoundCheckBox, "RIGHT", 10, 0)
    playSoundCheckBox:Hide()

local repeatSoundCheckBox = frameUtil.createFontStringCheckBox("repeat sound", menuButtons["SOUND"])
    repeatSoundCheckBox.tooltipText = "Enabled: plays EVERY time from the tab uses a spell and you're next up."
    .."\n\nDisabled: plays only once until you use your spell."
    repeatSoundCheckBox:SetScript("OnClick", function(self) optionFunc.repeatSoundCheckBoxOnClick(self) end)
    repeatSoundCheckBox:SetHitRectInsets(0 , -repeatSoundCheckBox.fontString:GetWidth(), 0, 0) --l r t b
    repeatSoundCheckBox:SetPoint("TOP", playSoundCheckBox, "BOTTOM", 0, -15)
    repeatSoundCheckBox.fontString:ClearAllPoints()
    repeatSoundCheckBox.fontString:SetPoint("LEFT", repeatSoundCheckBox, "RIGHT", 10, 0)
    repeatSoundCheckBox:Hide()

local soundPathFontString, soundPathEditBox = frameUtil.createFontStringEditBox(menuButtons["SOUND"])
    soundPathFontString:SetText("Sound path:")
    soundPathFontString:SetSize(120, 30)
    soundPathFontString:ClearAllPoints()
    soundPathFontString:SetPoint("TOP", repeatSoundCheckBox, "BOTTOM", 0, -15)
    soundPathFontString:SetPoint("LEFT", leftSideMenu, "CENTER", -soundPathFontString:GetWidth()/2, 0)
    soundPathEditBox:SetPoint("TOP", soundPathFontString, "BOTTOM", 0, 0)
    soundPathEditBox:SetSize(170, 30)
    soundPathEditBox:SetMaxLetters(100)
    soundPathEditBox:SetScript("OnEnterPressed", function(self) optionFunc.soundPathEditBoxOnEnterPressed(self) end)
    soundPathEditBox:Hide()

SIR.optionFrames = {
    --single frames
    ["container"] = container,
    ["generalTab"] = generalTab,
    ["greyOutDeadCheckBox"] = greyOutDeadCheckBox,
    ["greyOutDisabledCheckBox"] = greyOutDisabledCheckBox,
    ["createNewTabButton"] = createNewTabButton,
    ["removeTabButton"] = removeTabButton,
    ["generalTabButton"] = generalTabButton,
    ["rotationTab"] = rotationTab,
    ["leftSideMenu"] = leftSideMenu,
    ["widthEditBox"] = widthEditBox,
    ["heightEditBox"] = heightEditBox,
    ["spaceEditBox"] = spaceEditBox,
    ["xOffEditBox"] = xOffEditBox,
    ["yOffEditBox"] = yOffEditBox,
    ["titleEditBox"] = titleEditBox,
    ["testButton"] = testButton,
    ["enableGroupInstanceButton"] = enableGroupInstanceButton,
    ["enableClassSpecButton"] = enableClassSpecButton,
    ["whisperToEditBox"] = whisperToEditBox,
    ["playSoundCheckBox"] = playSoundCheckBox,
    ["repeatSoundCheckBox"] = repeatSoundCheckBox,
    ["soundPathEditBox"] = soundPathEditBox,
    -- table with different frames
    ["trackAllOption"] = trackAllOption,
    ["trackRotationOption"] = trackRotationOption,
    -- table of equivalent frames
    ["menuButtons"] = menuButtons,
    ["rotationTabButtons"] = rotationTabButtons,
    ["groupMemberButtons"] = groupMemberButtons,
    ["rotationButtons"] = rotationButtons,
    ["removeMemberButtons"] = removeMemberButtons,
    ["sendRotationButtons"] = sendRotationButtons,
    ["sortModeCheckBoxes"] = sortModeCheckBoxes,
    ["enableCheckBoxes"] = enableCheckBoxes,
}