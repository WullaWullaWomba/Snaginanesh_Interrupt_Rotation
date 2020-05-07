local _, SIR = ...
--luacheck: globals CombatLogGetCurrentEventInfo strsub unpack SLASH_SIRINTERRUPT1 SLASH_SIRINTERRUPT2
--luacheck: globals GetNumGroupMembers SnagiIntRotaSaved GameTooltip GetPlayerInfoByGUID IsInGroup IsInRaid UnitGUID
--luacheck: globals StaticPopup_Hide UIParent StaticPopupDialogs StaticPopup_Show SlashCmdList C_Timer GetClassInfo
--luacheck: globals random _ UISpecialFrames GetSpellInfo min max floor tremove ItemRefTooltip ConsoleAddMessage
--luacheck: globals ChatFrame_AddMessageEventFilter C_ChatInfo gmatch strfind SLASH_SIRINTERRUPTDUMP1 UIParentLoadAddOn
--luacheck: globals SendChatMessage UIDropDownMenu_SetWidth UIDropDownMenu_Initialize UIDropDownMenu_CreateInfo
--luacheck: globals  UIDropDownMenu_AddButton UIDropDownMenu_SetText UIDropDownMenu_GetText gsub CLASS_ICON_TCOORDS
--luacheck: globals GetNumSpecializationsForClassID GetSpecializationInfoByID GetSpecializationInfo GetSpecialization
--luacheck: globals UnitClass time IsInInstance sort UnitInParty UnitInRaid UnitName
--luacheck: globals CanInspect UnitIsConnected NotifyInspect GetTime GetInspectSpecialization GetTalentInfo
--_, _ = ...

local classSpecIDs = SIR.data.classSpecIDs
local util = SIR.util
local frameUtil = SIR.frameUtil
local optionFrames = SIR.optionFrames
local optionFunc = SIR.optionFunc


local contains, remove= util.contains, util.remove
SIR.tabOptions = SIR.tabOptions or {}
------------------------------------------------------------------------------------------------------------------------

-- LOCALS!

------------------------------------------------------------------------------------------------------------------------
local numTabs = 0
local activeTab = "GENERAL"
local defaultOptions = {
	["TITLE"] = "new_tab",
	["ROTATION"] = {},
	["SPACE"] = 0,
	["XOFF"] = 600,
	["YOFF"] = 450,
	["WIDTH"] = 120,
	["HEIGHT"] = 22,
	["CLASSENABLEOPTIONS"] = {
		--Warrior
		[1] = true, -- Arms Fury Protection
		-- Paladin
		[2] = false, -- Holy Protection Retribution
		-- Hunter
		[3] = true, -- Beast Mastery Marksmanship Survival
		-- Rogue
		[4] = true, -- Assassination Outlaw Subtlety
		-- Priest
		[5] = false, -- Discipline Holy Shadow
		-- Death Knight
		[6] = true, -- Blood Frost Unholy
		-- Shaman
		[7] = true, -- Elemental Enhancement Restoration
		-- Mage
		[8] = true,-- Arcane Fire Frost
		-- Warlock
		[9] = true, -- Affliction Demonology Destruction
		-- Monk
		[10] = false,  -- Brewmaster Windwalker Mistweaver
		-- Druid
		[11] = false, -- Balance Feral Guardian Restoration
		-- Demon Hunter
		[12] = true, -- Havoc Vengeance
	},
	["SPECENABLEOPTIONS"] = {
		--Warrior
		[71] = true, -- Arms
		[72] = true, -- Fury
		[73] = true, -- Protection

		-- Paladin
		[65] = false, -- Holy
		[66] = true, -- Protection
		[70] = true, -- Retribution

		-- Hunter
		[253] = true, -- Beast Mastery
		[254] = true, -- Marksmanship
		[255] = true, -- Survival

		-- Rogue
		[259] = true, -- Assassination
		[260] = true, -- Outlaw
		[261] = true, -- Subtlety

		-- Priest
		[256] = false, -- Discipline
		[257] = false, -- Holy
		[258] = true, -- Shadow

		-- Death Knight
		[250] = true, -- Blood
		[251] = true, -- Frost
		[252] = true, -- Unholy

		-- Shaman
		[262] = true, -- Elemental
		[263] = true, -- Enhancement
		[264] = true, -- Restoration

		-- Mage
		[62] = true, -- Arcane
		[63] = true, -- Fire
		[64] = true, -- Frost

		-- Warlock
		[265] = true, -- Affliction
		[266] = true, -- Demonology
		[267] = true, -- Destruction

		-- Monk
		[268] = true, -- Brewmaster
		[269] = true, -- Windwalker
		[270] = false, -- Mistweaver

		-- Druid
		[102] = true, -- Balance
		[103] = true, -- Feral
		[104] = true, -- Guardian
		[105] = false, -- Restoration

		-- Demon Hunter
		[577] = true, -- Havoc
		[581] = true, -- Vengeance
	},
	["TRACKROTATIONCHECKED"] = false,
	["TRACKALLCHECKED"] = true,
	["TRACKROTATIONFROM"] = 0,
	["TRACKROTATIONTO"] = 40,
	["TRACKALLFROM"] = 2,
	["TRACKALLTO"] = 5,
	["SORTMODE"] = "CD",
	["PLAYSOUND"] = false,
	["REPEATSOUND"] = false,
	["SOUNDPATH"] = "Interface\\AddOns\\Snaginanesh_Interrupt_Rotation\\Sounds\\next.ogg",
}

local toggleOptions = function()
	if optionFrames.container:IsShown() then
		optionFrames.container:Hide()
	else
		optionFrames.container:Show()
	end
end
--SLASH COMMAND
SLASH_SIRINTERRUPT1, SLASH_SIRINTERRUPT2 = "/sir", "/sirinterrupt"
SlashCmdList["SIRINTERRUPT"] = function(msg)
	toggleOptions(msg)
end
------------------------------------------------------------------------------------------------------------------------

-- DATA

------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------

-- Transmission

------------------------------------------------------------------------------------------------------------------------
C_ChatInfo.RegisterAddonMessagePrefix("SnagiIntRotaSend")
C_ChatInfo.RegisterAddonMessagePrefix("SnagiIntRotaReq")

local OriginalSetHyperlink = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(link, ...)
	if(link and link:sub(1, 14) == "SnagiIntRota: ") then
		local text = link:sub(15)

		local i, j = text:find("%S*")
		local source = text:sub(i, j)

		text = text:sub(j+2)
		i, j = text:find("%S*")
		local title = text:sub(i, j)
		text = text:sub(j+1)

		local rotation = {}
		for GUID in gmatch(text, "%w*-%w*-%w*") do
			rotation[#rotation+1] = GUID
		end
		optionFrames.transmissionOkayButton.rotation = rotation
		local rotationText = ""
		for k=1, #rotation do
			rotationText = rotationText..k..". "..util.getColouredNameByGUID(rotation[k])
		end
		optionFrames.transmissionRotationEditBox:SetText(rotationText)

		UIDropDownMenu_SetText(optionFrames.transmissionDropdownMenu, "new tab")
		for _, options in ipairs(SIR.tabOptions) do
			if options["TITLE"] == title then
				UIDropDownMenu_SetText(optionFrames.transmissionDropdownMenu, title)
				break
			end
		end

		optionFrames.transmissionRotationLabelEditBox:SetText(title.."\n"..util.getColouredNameByGUID(source))
		optionFrames.transmissionFrame:Show()
		return
	end
	return OriginalSetHyperlink(self, link, ...);
end

local filterFunc = function(_, _, msg, ...)
	-- example msg [SnagiIntRota:] TITLE
	if msg:sub(1, 16) == "[SnagiIntRota:] " then
		local sourceGUID = select(11, ...)
		local i, j = strfind((msg:sub(17)), "%S*")
		local title = strsub(msg, i+16, j+16)
		local newMsg = "\124HSnagiIntRota: "..sourceGUID.." "..strsub(msg, 17).."\124h[SIR - \124cFFFAD201"
			..title.."\124r]\124h"
		return false, newMsg, ...
	end
	return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", filterFunc)

optionFrames.transmissionOkayButton:SetScript("OnClick", function(self)
	local text = UIDropDownMenu_GetText(optionFrames.transmissionDropdownMenu)
	if not text then
		return
	elseif text == "new tab" then
		optionFrames.createNewTabButton:Click()
		SIR.tabOptions[numTabs]["ROTATION"] = self.rotation
		SIR.tabOptions[numTabs]["TITLE"] = "new_tab"
		optionFrames.rotationTabButtons[numTabs]:SetText(SIR.tabOptions[numTabs]["TITLE"])
		optionFrames.container:Show()
		optionFrames.rotationTabButtons[numTabs]:Click()
	else
		for i, tabOptions in ipairs(SIR.tabOptions) do
			if tabOptions["TITLE"] == text then
				tabOptions["ROTATION"] = self.rotation
				optionFrames.container:Show()
				optionFrames.rotationTabButtons[i]:Click()
				break
			end
		end
	end
	optionFrames.transmissionFrame:Hide()
end)
UIDropDownMenu_Initialize(optionFrames.transmissionDropdownMenu, function()--self, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	for _, tabOptions in ipairs(SIR.tabOptions) do
		info.text = tabOptions["TITLE"]
		info.checked = UIDropDownMenu_GetText(optionFrames.transmissionDropdownMenu) == info.text
		info.optionFunc = function()
				UIDropDownMenu_SetText(optionFrames.transmissionDropdownMenu, tabOptions["TITLE"])
			end
		UIDropDownMenu_AddButton(info)
	end
	info.text = "new tab"
	info.checked = UIDropDownMenu_GetText(optionFrames.transmissionDropdownMenu) == info.text
	info.optionFunc = function()
		UIDropDownMenu_SetText(optionFrames.transmissionDropdownMenu, "new tab")
	end
	UIDropDownMenu_AddButton(info)
end)

------------------------------------------------------------------------------------------------------------------------

-- ADDON FUNCTIONS

------------------------------------------------------------------------------------------------------------------------
local loadTab = function(title)
	numTabs = numTabs+1
	optionFrames.rotationTabButtons[numTabs] = frameUtil.aquireTabButton(optionFrames.container)
	optionFrames.rotationTabButtons[numTabs].key = numTabs
	optionFrames.rotationTabButtons[numTabs]:SetPoint("LEFT", optionFrames.rotationTabButtons[numTabs-1]
		or optionFrames.generalTabButton, "RIGHT", -15, 0)
	optionFrames.rotationTabButtons[numTabs]:SetScript("OnClick", function(self)
		optionFunc.rotationTabButtonOnClick(self)
	end)
	optionFrames.rotationTabButtons[numTabs]:SetText(title)
	SIR.rotationFunc.newRotationTab(numTabs)
end

local updateRotationButtons = function()
	SIR.util.myPrint("updateRotationButtons")
	local rotation = SIR.tabOptions[activeTab]["ROTATION"]
	for i=#rotation+1, #optionFrames.rotationButtons do
		optionFrames.rotationButtons[i]:Hide()
	end
	for i=1, #rotation do
		optionFrames.rotationButtons[i]:SetGUID(rotation[i])
		optionFrames.rotationButtons[i]:SetText(util.getColouredNameByGUID(rotation[i]))
		optionFrames.rotationButtons[i]:Show()
	end
end



local updateGroupMemberButtons = function()
	--done?!!
	SIR.util.myPrint("updateGroupMemberButtons")
	if IsInGroup() then
		local numGroup = GetNumGroupMembers()
		for i=numGroup+1, 40 do
			optionFrames.groupMemberButtons[i]:Hide()
		end

		local groupType = "raid"
		if not IsInRaid() then
			-- only party1-4 exist (not one for the player himself)
			groupType = "party"
			optionFrames.groupMemberButtons[numGroup]:SetGUID(SIR.playerInfo["GUID"])
            optionFrames.groupMemberButtons[numGroup].inRotation = contains(SIR.tabOptions[activeTab]["ROTATION"],
                SIR.playerInfo["GUID"])
			optionFrames.groupMemberButtons[numGroup]:UpdateTexture()
			optionFrames.groupMemberButtons[numGroup]:SetText(SIR.playerInfo["COLOUREDNAME"])
			optionFrames.groupMemberButtons[numGroup]:Show()
			numGroup = numGroup-1
		end
		for i=1, numGroup do
			local GUID = UnitGUID(groupType..i)
			optionFrames.groupMemberButtons[i]:SetGUID(GUID)
			optionFrames.groupMemberButtons[i].inRotation = contains(SIR.tabOptions[activeTab]["ROTATION"], GUID)
			optionFrames.groupMemberButtons[i]:UpdateTexture()
			optionFrames.groupMemberButtons[i]:SetText(SIR.util.getColouredNameByGUID(GUID))
			optionFrames.groupMemberButtons[i]:Show()
		end
	else
		for i=2, 40 do
			optionFrames.groupMemberButtons[i]:Hide()
		end
		optionFrames.groupMemberButtons[1]:SetGUID(SIR.playerInfo["GUID"])
		optionFrames.groupMemberButtons[1].inRotation
		=contains(SIR.tabOptions[activeTab]["ROTATION"],
		SIR.playerInfo["GUID"])
		optionFrames.groupMemberButtons[1]:UpdateTexture()
		optionFrames.groupMemberButtons[1]:SetText(SIR.playerInfo["COLOUREDNAME"])
		optionFrames.groupMemberButtons[1]:Show()
    end
end

local removeRotationMember = function(GUID)
	-- update groupMemberButton if available
	for i=1, 40 do
		if optionFrames.groupMemberButtons[i].GUID == GUID then
			optionFrames.groupMemberButtons[i].inRotation = false
			optionFrames.groupMemberButtons[i]:UpdateTexture()
			break
		end
	end

	local rotationNum = #SIR.tabOptions[activeTab]["ROTATION"]
	for i=1, rotationNum-1 do
		if optionFrames.rotationButtons[i].GUID == GUID then
			for j=i, rotationNum-1 do
				optionFrames.rotationButtons[j].GUID = optionFrames.rotationButtons[j+1].GUID
				optionFrames.rotationButtons[j]:SetText(optionFrames.rotationButtons[j+1]:GetText())
			end
			break
		end
	end
	optionFrames.rotationButtons[rotationNum].GUID = ""
	optionFrames.rotationButtons[rotationNum]:SetText("")
	optionFrames.rotationButtons[rotationNum]:Hide()
	for i=1, #SIR.tabOptions[activeTab]["ROTATION"] do
		if SIR.tabOptions[activeTab]["ROTATION"][i] == GUID then
			remove(SIR.tabOptions[activeTab]["ROTATION"], i)
			break
		end
	end
	SIR.rotationFunc.removeRotationMember(activeTab, GUID)
end
local makeTransmissionText = function()
	local text = "[SnagiIntRota:] "..optionFrames.titleEditBox:GetText().." "
	for _, member in ipairs(SIR.tabOptions[activeTab]["ROTATION"]) do
		text = text..member.." "
	end
	return text
end
local updateGreyOutCheckBoxes = function()
	optionFrames.greyOutDeadCheckBox:SetChecked(generalOptions["GREYOUTDEAD"])
	optionFrames.greyOutDiscCheckBox:SetChecked(generalOptions["GREYOUTDISC"])
	optionFrames.greyOutDiffAreaCheckBox:SetChecked(generalOptions["GREYOUTDIFFAREA"])
end
local updateEnableMenu = function()
	optionFrames.trackAllOption.checkBox:SetChecked(SIR.tabOptions[activeTab]["TRACKALLCHECKED"])
	optionFrames.trackAllOption.fromSlider:SetValue(SIR.tabOptions[activeTab]["TRACKALLFROM"])
	optionFrames.trackAllOption.toSlider:SetValue(SIR.tabOptions[activeTab]["TRACKALLTO"])
	optionFrames.trackAllOption.fromEditBox:SetText(SIR.tabOptions[activeTab]["TRACKALLFROM"])
	optionFrames.trackAllOption.toEditBox:SetText(SIR.tabOptions[activeTab]["TRACKALLTO"])

	optionFrames.trackAllOption.fromSlider:SetEnabled(SIR.tabOptions[activeTab]["TRACKALLCHECKED"])
	optionFrames.trackAllOption.toSlider:SetEnabled(SIR.tabOptions[activeTab]["TRACKALLCHECKED"])
	optionFrames.trackAllOption.fromEditBox:SetEnabled(SIR.tabOptions[activeTab]["TRACKALLCHECKED"])
	optionFrames.trackAllOption.toEditBox:SetEnabled(SIR.tabOptions[activeTab]["TRACKALLCHECKED"])

	if SIR.tabOptions[activeTab]["TRACKALLCHECKED"] then
		optionFrames.trackAllOption.fromFontString:SetTextColor(0.98, 0.82, 0)
		optionFrames.trackAllOption.toFontString:SetTextColor(0.98, 0.82, 0)
	else
		optionFrames.trackAllOption.fromFontString:SetTextColor(0.3, 0.3, 0.3)
		optionFrames.trackAllOption.toFontString:SetTextColor(0.3, 0.3, 0.3)
	end

	optionFrames.trackRotationOption.checkBox:SetChecked(SIR.tabOptions[activeTab]["TRACKROTATIONCHECKED"])
	optionFrames.trackRotationOption.fromSlider:SetValue(SIR.tabOptions[activeTab]["TRACKROTATIONFROM"])
	optionFrames.trackRotationOption.toSlider:SetValue(SIR.tabOptions[activeTab]["TRACKROTATIONTO"])
	optionFrames.trackRotationOption.fromEditBox:SetText(SIR.tabOptions[activeTab]["TRACKROTATIONFROM"])
	optionFrames.trackRotationOption.toEditBox:SetText(SIR.tabOptions[activeTab]["TRACKROTATIONTO"])

	optionFrames.trackRotationOption.fromSlider:SetEnabled(SIR.tabOptions[activeTab]["TRACKROTATIONCHECKED"])
	optionFrames.trackRotationOption.toSlider:SetEnabled(SIR.tabOptions[activeTab]["TRACKROTATIONCHECKED"])
	optionFrames.trackRotationOption.fromEditBox:SetEnabled(SIR.tabOptions[activeTab]["TRACKROTATIONCHECKED"])
	optionFrames.trackRotationOption.toEditBox:SetEnabled(SIR.tabOptions[activeTab]["TRACKROTATIONCHECKED"])

	if SIR.tabOptions[activeTab]["TRACKROTATIONCHECKED"] then
		optionFrames.trackRotationOption.fromFontString:SetTextColor(0.98, 0.82, 0)
		optionFrames.trackRotationOption.toFontString:SetTextColor(0.98, 0.82, 0)
	else
		optionFrames.trackRotationOption.fromFontString:SetTextColor(0.3, 0.3, 0.3)
		optionFrames.trackRotationOption.toFontString:SetTextColor(0.3, 0.3, 0.3)
	end
	for c=1, #optionFrames.enableCheckBoxes do
		optionFrames.enableCheckBoxes[c][1]:SetChecked(SIR.tabOptions[activeTab]["CLASSENABLEOPTIONS"][c])
		for s=1, #classSpecIDs[c] do
			optionFrames.enableCheckBoxes[c][s+1]:SetChecked(
				SIR.tabOptions[activeTab]["SPECENABLEOPTIONS"][classSpecIDs[c][s]])
		end
	end
end
local updateSendMenu = function()
	optionFrames.titleEditBox:SetText(SIR.tabOptions[activeTab]["TITLE"])
end
local updateDisplayMenu = function()
	optionFrames.widthEditBox:SetText(SIR.tabOptions[activeTab]["WIDTH"])
	optionFrames.heightEditBox:SetText(SIR.tabOptions[activeTab]["HEIGHT"])
	optionFrames.spaceEditBox:SetText(SIR.tabOptions[activeTab]["SPACE"])
	optionFrames.xOffEditBox:SetText(SIR.tabOptions[activeTab]["XOFF"])
	optionFrames.yOffEditBox:SetText(SIR.tabOptions[activeTab]["YOFF"])
end
local updateSortMenu = function()
	for k, cb in pairs(optionFrames.sortModeCheckBoxes) do
		cb:SetChecked(k == SIR.tabOptions[activeTab]["SORTMODE"])
	end
end
local updateSoundMenu = function()
	optionFrames.playSoundCheckBox:SetChecked(SIR.tabOptions[activeTab]["PLAYSOUND"])
	optionFrames.repeatSoundCheckBox:SetChecked(SIR.tabOptions[activeTab]["REPEATSOUND"])
	optionFrames.soundPathEditBox:SetText(SIR.tabOptions[activeTab]["SOUNDPATH"])
end

optionFunc.PLAYER_LOGIN = function()
    SIR.tabOptions = SnagiIntRotaSaved.tabOptions or {}
	for i=1, #SIR.tabOptions do
		for k, default in pairs(defaultOptions) do
			if SIR.tabOptions[i][k] == nil then
				SIR.tabOptions[i][k] = default
			end
		end
        loadTab(SIR.tabOptions[i]["TITLE"])
    end
end
optionFunc.GROUP_ROSTER_UPDATE = function()
	if optionFrames.rotationTab:IsShown() then
		updateGroupMemberButtons()
	end
end
optionFunc.save = function()
    SnagiIntRotaSaved.tabOptions = SIR.tabOptions
end
optionFunc.rotationTabOnShow = function()
	updateGroupMemberButtons()
end
optionFunc.generalTabButtonOnClick = function(self)
	optionFrames.rotationTab:Hide()
	optionFrames.generalTab:Show()
	for _, rt in ipairs(optionFrames.rotationTabButtons) do
		rt.inactiveTexture:Show()
		rt.activeTexture:Hide()
	end
	self.inactiveTexture:Hide()
	self.activeTexture:Show()
	optionFrames.leftSideMenu:Hide()
	updateGreyOutCheckBoxes()
end
optionFunc.rotationTabButtonOnClick = function(self)
	activeTab = self.key
	optionFrames.rotationTab:Show()
	optionFrames.generalTab:Hide()
	for _, rt in ipairs(optionFrames.rotationTabButtons) do
		rt.inactiveTexture:Show()
		rt.activeTexture:Hide()
	end
	optionFrames.generalTabButton.activeTexture:Hide()
	optionFrames.generalTabButton.inactiveTexture:Show()
	self.inactiveTexture:Hide()
	self.activeTexture:Show()
	updateRotationButtons()
	updateGroupMemberButtons()
	updateSendMenu()
	updateEnableMenu()
	updateDisplayMenu()
	updateSortMenu()
	updateSoundMenu()
	optionFrames.leftSideMenu:Show()
end
optionFunc.createNewTab = function()
	numTabs = numTabs+1
	optionFrames.rotationTabButtons[numTabs] = frameUtil.aquireTabButton(optionFrames.container)
	optionFrames.rotationTabButtons[numTabs].key = numTabs
	optionFrames.rotationTabButtons[numTabs]:SetPoint("LEFT", optionFrames.rotationTabButtons[numTabs-1]
		or optionFrames.generalTabButton, "RIGHT", -15, 0)
	optionFrames.rotationTabButtons[numTabs]:SetScript("OnClick", function(self)
		optionFunc.rotationTabButtonOnClick(self)
	end)
	optionFrames.rotationTabButtons[numTabs]:SetText("new_tab")
	SIR.tabOptions[numTabs] = util.makeCopy(defaultOptions)
    SIR.rotationFunc.newRotationTab(numTabs)
end
optionFunc.groupMemberOnClick = function(self)
	local rotation = SIR.tabOptions[activeTab]["ROTATION"]
	local GUID = self:GetGUID()
	if not contains(rotation, GUID) then
		-- Add player to activeRotation if not yet in activeRotation
		if #rotation > (#optionFrames.rotationButtons-1) then
			-- If activeRotation full return
			util.myPrint("Rotation full!")
			return
		end
		rotation[#rotation+1] = GUID
		local rotationButton = optionFrames.rotationButtons[#rotation]
		rotationButton:SetText(self:GetText())
		rotationButton.GUID = GUID
		rotationButton:Show()
		self.inRotation = true
		self:UpdateTexture()
		SIR.rotationFunc.addRotationMember(activeTab, GUID)
	else
		removeRotationMember(GUID)
	end
end
optionFunc.enableGroupInstanceButtonOnClick = function(self)
	for _, c in ipairs({optionFrames.enableClassSpecButton:GetChildren()}) do
		c:Hide()
	end
	for _, c in ipairs({self:GetChildren()}) do
		c:Show()
	end
	optionFrames.enableClassSpecButton:UnlockHighlight()
	self:LockHighlight()
end
optionFunc.enableClassSpecButtonOnClick = function(self)
	for _, c in ipairs({optionFrames.enableGroupInstanceButton:GetChildren()}) do
		c:Hide()
	end
	for _, c in ipairs({self:GetChildren()}) do
		c:Show()
	end
	optionFrames.enableGroupInstanceButton:UnlockHighlight()
	self:LockHighlight()
end
optionFunc.groupEnableOptionCheckBoxOnClick = function(self, option)
    local toggle = self:GetChecked()
    SIR.tabOptions[activeTab]["TRACK"..self.model.."CHECKED"] = toggle
	option.fromSlider:SetEnabled(toggle)
	option.fromEditBox:SetEnabled(toggle)
	option.toSlider:SetEnabled(toggle)
	option.toEditBox:SetEnabled(toggle)
	if toggle then
		option.fromFontString:SetTextColor(0.98, 0.82, 0)
		option.toFontString:SetTextColor(0.98, 0.82, 0)
	else
		option.fromFontString:SetTextColor(0.3, 0.3, 0.3)
		option.toFontString:SetTextColor(0.3, 0.3, 0.3)
	end
	SIR.rotationFunc.updateTrackMode(activeTab)
end
optionFunc.groupEnableOptionFromSliderOnMouseWheel = function(self, delta, option)
	-- self.model == "ALL" then
	-- self.model == "ROTATION" then
	local minVal, maxVal = self:GetMinMaxValues()
	local newVal
	if delta == 1 then
		if self:GetValue() == maxVal then
			return
		end
		newVal = self:GetValue()+1
		if newVal > option.toSlider:GetValue() then
			option.toSlider:SetValue(newVal)
			option.toEditBox:SetText(newVal)
			SIR.tabOptions[activeTab]["TRACK"..self.model.."TO"] = newVal
		end
		self:SetValue(newVal)
		SIR.tabOptions[activeTab]["TRACK"..self.model.."FROM"] = newVal
	else
		if self:GetValue() == minVal then
			return
		end
		newVal = self:GetValue()-1
		self:SetValue(newVal)
		SIR.tabOptions[activeTab]["TRACK"..self.model.."FROM"] = newVal
	end
	option.fromEditBox:SetText(newVal)
	SIR.rotationFunc.updateTrackMode(activeTab)
end
optionFunc.groupEnableOptionFromSliderOnMouseUp = function(self, option)
	local newVal = self:GetValue()
	if newVal == SIR.tabOptions[activeTab]["TRACK"..self.model.."FROM"] then
		return
	end
	if newVal > SIR.tabOptions[activeTab]["TRACK"..self.model.."TO"] then
		option.toSlider:SetValue(newVal)
		option.toEditBox:SetText(newVal)
		SIR.tabOptions[activeTab]["TRACK"..self.model.."TO"] = newVal
	end
	option.fromEditBox:SetText(newVal)
	SIR.tabOptions[activeTab]["TRACK"..self.model.."FROM"] = newVal
	SIR.rotationFunc.updateTrackMode(activeTab)
end
optionFunc.groupEnableOptionToSliderOnMouseWheel = function(self, delta, option)
	local minVal, maxVal = self:GetMinMaxValues()
	local newVal

	if delta == 1 then
		if self:GetValue() == maxVal then
			return
		end
		newVal = self:GetValue()+1
		self:SetValue(newVal)

	else
		if self:GetValue() == minVal then
			return
		end
		newVal = self:GetValue()-1
		self:SetValue(newVal)
		if newVal < SIR.tabOptions[activeTab]["TRACK"..self.model.."FROM"] then
			option.fromSlider:SetValue(newVal)
			option.fromEditBox:SetText(newVal)
		end
	end
	option.toEditBox:SetText(newVal)
	SIR.rotationFunc.updateTrackMode(activeTab)
end
optionFunc.groupEnableOptionToSliderOnMouseUp = function(self, option)
	local newVal = self:GetValue()
	if newVal == SIR.tabOptions[activeTab]["TRACK"..self.model.."TO"] then
		return
	end
	if newVal < SIR.tabOptions[activeTab]["TRACK"..self.model.."FROM"] then
		option.fromSlider:SetValue(newVal)
		option.fromEditBox:SetText(newVal)
		SIR.tabOptions[activeTab]["TRACK"..self.model.."FROM"] = newVal
	end
	option.toEditBox:SetText(newVal)
	SIR.tabOptions[activeTab]["TRACK"..self.model.."TO"] = newVal
	SIR.rotationFunc.updateTrackMode(activeTab)
end
optionFunc.groupEnableOptionFromEditBoxOnEnterPressed = function(self, option)
	local newVal = tonumber(self:GetText())
	if newVal > 40 then
		self:SetText(40)
		if SIR.tabOptions[activeTab]["TRACK"..self.model.."FROM"] == 40 then
			return
		end
		newVal = 40
	end
	SIR.tabOptions[activeTab]["TRACK"..self.model.."FROM"] = newVal
	option.fromSlider:SetValue(newVal)
	if newVal > SIR.tabOptions[activeTab]["TRACK"..self.model.."TO"] then
		option.toSlider:SetValue(newVal)
		option.toEditBox:SetText(newVal)
		SIR.tabOptions[activeTab]["TRACK"..self.model.."TO"] = newVal
	end
	self:ClearFocus()
	SIR.rotationFunc.updateTrackMode(activeTab)
end
optionFunc.groupEnableOptionToEditBoxOnEnterPressed = function(self, option)
	local newVal = tonumber(self:GetText())
	if newVal > 40 then
		self:SetText(40)
		if SIR.tabOptions[activeTab]["TRACK"..self.model.."TO"] == 40 then
			return
		end
		newVal = 40
	end
	SIR.tabOptions[activeTab]["TRACK"..self.model.."TO"] = newVal
	option.toSlider:SetValue(newVal)
	if newVal < SIR.tabOptions[activeTab]["TRACK"..self.model.."FROM"] then
		option.fromSlider:SetValue(newVal)
		option.fromEditBox:SetText(newVal)
		SIR.tabOptions[activeTab]["TRACK"..self.model.."FROM"] = newVal
	end
	self:ClearFocus()
	SIR.rotationFunc.updateTrackMode(activeTab)
end
optionFunc.enableClassOnClick = function(self, c)
	local newBool = self:GetChecked()
	SIR.tabOptions[activeTab]["CLASSENABLEOPTIONS"][c] = newBool
	for i=1, #classSpecIDs[c] do
		SIR.tabOptions[activeTab]["SPECENABLEOPTIONS"][classSpecIDs[c][i]] = newBool
		optionFrames.enableCheckBoxes[c][i+1]:SetChecked(newBool)
	end
	if select(2, GetClassInfo(c)) == SIR.playerInfo["CLASS"] then
		SIR.rotationFunc.updateTrackMode(activeTab)
	end
end
optionFunc.enableSpecOnClick = function(self, c, s)
	local newBool = self:GetChecked()
	local specID = classSpecIDs[c][s]
	SIR.tabOptions[activeTab]["SPECENABLEOPTIONS"][specID] = newBool
	for _, spec in ipairs(classSpecIDs[c]) do
		newBool = newBool and SIR.tabOptions[activeTab]["SPECENABLEOPTIONS"][spec]
	end
	SIR.tabOptions[activeTab]["CLASSENABLEOPTIONS"][c] = newBool
	optionFrames.enableCheckBoxes[c][1]:SetChecked(newBool)
	if specID == SIR.playerInfo["SPEC"] then
		SIR.rotationFunc.updateTrackMode(activeTab)
	end
end
optionFunc.rotationButtonOnClick = function(self, button)
	local rotation = SIR.tabOptions[activeTab]["ROTATION"]
	if button == "LeftButton" then
		-- On leftclick
		-- swap up / set last
		local swapButton = optionFrames.rotationButtons[self.value-1]
		if swapButton then
			-- If not first (shown) button then swap
			-- Button
			local tempGUID = swapButton:GetGUID()
			local tempText = swapButton:GetText()

			swapButton:SetGUID(self:GetGUID())
			swapButton:SetText(self:GetText())
			self:SetGUID(tempGUID)
			self:SetText(tempText)
			-- Rotation
			rotation[self.value], rotation[self.value-1] = rotation[self.value-1], rotation[self.value]
		else
			-- If first, set last (shown)
			-- Button
			local tempGUID = self:GetGUID()
			local tempText = self:GetText()
			for j=2, #rotation do
				optionFrames.rotationButtons[j-1]:SetGUID(optionFrames.rotationButtons[j]:GetGUID())
				optionFrames.rotationButtons[j-1]:SetText(optionFrames.rotationButtons[j]:GetText())
			end
			optionFrames.rotationButtons[#rotation]:SetGUID(tempGUID)
			optionFrames.rotationButtons[#rotation]:SetText(tempText)

			-- Rotation
			rotation[#rotation+1] = rotation[1]
			for j=1, #rotation do
				rotation[j] = rotation[j+1]
			end
		end
	else
		-- On rightclick
		-- move down / swap to first
		local swapButton = optionFrames.rotationButtons[self.value+1]
		if swapButton and swapButton:IsShown() then
			-- If not last (shown) button then swap
			-- Button
			local tempGUID = swapButton:GetGUID()
			local tempText = swapButton:GetText()

			swapButton:SetGUID(self:GetGUID())
			swapButton:SetText(self:GetText())

			self:SetGUID(tempGUID)
			self:SetText(tempText)
			-- rotation
			rotation[self.value], rotation[self.value+1] = rotation[self.value+1], rotation[self.value]
		else
			-- If last (shown), set first
			-- Button
			local tempGUID = self:GetGUID()
			local tempText = self:GetText()
			for j=#rotation-1, 1, -1 do
				optionFrames.rotationButtons[j+1]:SetGUID(optionFrames.rotationButtons[j]:GetGUID())
				optionFrames.rotationButtons[j+1]:SetText(optionFrames.rotationButtons[j]:GetText())
			end
			optionFrames.rotationButtons[1]:SetGUID(tempGUID)
			optionFrames.rotationButtons[1]:SetText(tempText)
			-- rotation
			local temp = rotation[#rotation]
			for j=#rotation, 2 do
				rotation[j] = rotation[j-1]
			end
			rotation[1] = temp
		end
	end
	if SIR.tabOptions[activeTab]["SORTMODE"] == "ROTATION" then
		SIR.rotationFunc.sortTab(activeTab)
	end
end
optionFunc.removeMemberOnClick = function(self)
	removeRotationMember(self:GetParent().GUID)
end
optionFunc.testButtonOnClick = function()
	SIR.test = not SIR.test
	print("SIR.test set to:", SIR.test)
	print("currently just enables/disables printing(debug) - will show test bars at some point")
	--[[
	if #testStatusBars == 0 then
		local testClasses = {
			"DEATHKNIGHT",
			"DEMONHUNTER",
			"HUNTER",
			"MAGE",
			"ROGUE",
			"SHAMAN",
			"WARRIOR",
		}
		for i=1, numTabs do
			if rotationFrames[i]:IsShown() then
				for j=1, 6 do
					local currentIndex = #testStatusBars+1
					local current = aquireStatusBar()
					testStatusBars[currentIndex] = current
					current:SetSize(widths[i]-heights[i], heights[i])
					if j==1 then
						current:SetPoint("TOPRIGHT", rotationFrames[i], "BOTTOMRIGHT")
					else
						current:SetPoint("TOPRIGHT", testStatusBars[currentIndex-1], "BOTTOMRIGHT",0 , -spaces[i])
					end
					current.expirationTime = time()+15
					current.currentTime = time()+random(15)
					current:Show()
					current:SetMinMaxValues(0, 15)
					--current:SetValue(time()+random(15))
					setStatusBarOnUpdate(current)
					local class = testClasses[random(7)]
					current.icon:SetTexture(select(3, GetSpellInfo(classWideInterrupts[class])))
					current.icon:SetSize(heights[i], heights[i])
					current.leftText:SetText(class)
					current:SetStatusBarColor(unpack(classColorsRGB[class]))
					C_Timer.After(5, function()
						current:Hide()
						SIR.releaseStatusBar(current)
					end)
				end
			end
		end
	end
	]]--
end
optionFunc.menuButtonOnClick = function(self)
	for _, button in pairs(optionFrames.menuButtons) do
		for _, c in ipairs({button:GetChildren()}) do
			c:Hide()
		end
		button:UnlockHighlight()
	end
	for _, c in ipairs({self:GetChildren()}) do
		c:SetShown(not c:IsShown())
	end
	self:LockHighlight()
end
optionFunc.sortCheckBoxOnClick = function(self)
	for _, scb in pairs(optionFrames.sortModeCheckBoxes) do
		if scb ~= self then
			scb:SetChecked(false)
		end
	end
	SIR.tabOptions[activeTab]["SORTMODE"] = (self:GetChecked() and self.value) or "NONE"
	SIR.rotationFunc.sortTab(activeTab)
end
optionFunc.removeTabOnClick = function()
	for i=activeTab, #SIR.tabOptions do
		SIR.tabOptions[i] = util.makeCopy(SIR.tabOptions[i+1])
	end
	for i=activeTab, #optionFrames.rotationTabButtons-1 do
		optionFrames.rotationTabButtons[i]:SetText(optionFrames.rotationTabButtons[i+1]:GetText())
	end
	frameUtil.releaseTabButton(optionFrames.rotationTabButtons[#optionFrames.rotationTabButtons])
	tremove(optionFrames.rotationTabButtons, #optionFrames.rotationTabButtons)
	SIR.rotationFunc.removeRotationTab(activeTab)
	if optionFrames.rotationTabButtons[activeTab] then
		optionFrames.rotationTabButtons[activeTab]:Click()
	elseif optionFrames.rotationTabButtons[activeTab-1] then
		optionFrames.rotationTabButtons[activeTab-1]:Click()
	else
		optionFrames.generalTabButton:Click()
	end
	numTabs = numTabs-1
end
optionFunc.displayEditBoxOnEnter = function(self, value)
	if tonumber(self:GetText()) then
		SIR.tabOptions[activeTab][value] = tonumber(self:GetText())
		SIR.rotationFunc.updateDisplay(activeTab, value)
	else
		self:SetText(SIR.tabOptions[activeTab][value])
	end
	self:ClearFocus()
end
optionFunc.titleEditBoxOnEnterPressed = function(self)
	local text = self:GetText()
	if text ~= "" then
		SIR.tabOptions[activeTab]["TITLE"] = text
		optionFrames.rotationTabButtons[activeTab]:SetText(text)
	else
		text:SetText(SIR.tabOptions[activeTab]["TITLE"])
	end
	self:ClearFocus()
end
optionFunc.sendRotationOnClick = function(self)
	SendChatMessage(makeTransmissionText(), self.value, _,
		optionFrames.whisperToEditBox:GetText())
end
optionFunc.playSoundCheckBoxOnClick = function(self)
	SIR.tabOptions[activeTab]["PLAYSOUND"] = self:GetChecked()
end
optionFunc.repeatSoundCheckBoxOnClick = function(self)
	SIR.tabOptions[activeTab]["REPEATSOUND"] = self:GetChecked()
end
optionFunc.soundPathEditBoxOnEnterPressed = function(self)
	SIR.tabOptions[activeTab]["SOUNDPATH"] = self:GetText() or ""
end

optionFunc.greyOutDeadCheckBoxOnClick = function(self)
	SIR.generalOptions["GREYOUTDEAD"] = self.getChecked()
	SIR.rotationFunc.updateGreyOut()
end
optionFunc.greyOutDiscCheckBoxOnClick = function(self)
	SIR.generalOptions["GREYOUTDISC"] = self.getChecked()
	SIR.rotationFunc.updateGreyOut()
end
optionFunc.greyOutDiffAreaCheckBoxOnClick = function(self)
	SIR.generalOptions["GREYOUTDIFFAREA"] = self.getChecked()
	SIR.rotationFunc.updateGreyOut()
end

