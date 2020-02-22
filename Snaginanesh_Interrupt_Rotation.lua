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

local classWideInterrupts, cds = SIR.data.classWideInterrupts, SIR.data.cds
local classColorsHex, classColorsRGB = SIR.data.classColorsHex, SIR.data.classColorsRGB
local classSpecIDs = SIR.data.classSpecIDs
local util = SIR.util
local frameUtil = SIR.frameUtil
local optionFrames = SIR.optionFrames

SIR.func = SIR.func or {}
local func = SIR.func

local contains, remove= util.contains, util.remove
------------------------------------------------------------------------------------------------------------------------

-- LOCALS!

------------------------------------------------------------------------------------------------------------------------
local numTabs = 0
local activeTab = "GENERAL"
local playerGUID
local colouredPlayerName
local trackModes = {}
local defaultOptions = {
	["TITLE"] = "new_tab",
	["ROTATION"] = {},
	["SPACE"] = 0,
	["XOFF"] = 500,
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
	["SORTMODE"] = "CD"
}
local rotationTabOptions = {}

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
optionFrames.container:RegisterEvent("PLAYER_LOGOUT")
optionFrames.container:RegisterEvent("PLAYER_LOGIN")
optionFrames.container:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
optionFrames.container:RegisterEvent("GROUP_ROSTER_UPDATE")
optionFrames.container:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
optionFrames.container:RegisterEvent("PLAYER_ENTERING_WORLD")
optionFrames.container:RegisterEvent("INSPECT_READY")

optionFrames.container.PLAYER_ENTERING_WORLD = function()
end
optionFrames.container.GROUP_ROSTER_UPDATE = function()
end
optionFrames.container.COMBAT_LOG_EVENT_UNFILTERED = function()
	local _, subEvent, _, sourceGUID, _, sourceFlags, _, _, _, _, _, spellID  = CombatLogGetCurrentEventInfo()
	if subEvent == "SPELL_CAST_SUCCESS" then
		if not cds[spellID] or sourceFlags%16 > 4 then return end
		--todooo
		IsInGroup(sourceGUID)
		--updateOrAddBar(sourceGUID, spellID, true)
	end
end
optionFrames.container.PLAYER_SPECIALIZATION_CHANGED = function()
end
optionFrames.container.INSPECT_READY = function()
end
optionFrames.container.PLAYER_LOGIN = function()
	playerGUID = UnitGUID("player")
	colouredPlayerName = util.getColouredNameByGUID(playerGUID)
end
optionFrames.container.PLAYER_LOGOUT = function()
end
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

		UIDropDownMenu_SetText(optionFrames.transmissionDropdownMenu, "new rotation tab")
		for index, option in ipairs(rotationTabOptions) do
			if option["TITLE"] == title then
				UIDropDownMenu_SetText(optionFrames.transmissionDropdownMenu, "tab"..index.." - "..title)
				break
			end
		end
		UIDropDownMenu_SetText(optionFrames.transmissionDropdownMenu, "new rotation tab")

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
	elseif text == "new rotation tab" then
		optionFrames.createNewTabButton:Click()
		rotationTabOptions[numTabs]["ROTATION"] = self.rotation
		rotationTabOptions[numTabs]["TITLE"] = strsub(text, 7)
		optionFrames.rotationTabButtons[numTabs]:SetText(rotationTabOptions[numTabs]["TITLE"])
		optionFrames.container:Show()
		optionFrames.rotationTabButtons[numTabs]:Click()
	else
		for i=1, #rotationTabOptions do
			if rotationTabOptions[i]["TITLE"] == strsub(text, 7) then
				rotationTabOptions[i]["ROTATION"] = self.rotation
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
	for i=1, numTabs do
		info.text = "tab"..i.." - "..rotationTabOptions[i]["TITLE"]
		info.checked = UIDropDownMenu_GetText(optionFrames.transmissionDropdownMenu) == info.text
		info.func = function()
				UIDropDownMenu_SetText(optionFrames.transmissionDropdownMenu, "tab"..i.." - "..rotationTabOptions[i]["TITLE"])
			end
		UIDropDownMenu_AddButton(info)
	end
	info.text = "new rotation tab"
	info.checked = UIDropDownMenu_GetText(optionFrames.transmissionDropdownMenu) == info.text
	info.func = function()
		UIDropDownMenu_SetText(optionFrames.transmissionDropdownMenu, "new rotation tab")
	end
	UIDropDownMenu_AddButton(info)
end)

------------------------------------------------------------------------------------------------------------------------

-- ADDON FUNCTIONS

------------------------------------------------------------------------------------------------------------------------

func.updateGroupMemberButtons = function()
	--done?!!
	if IsInGroup() then
		local numGroup = GetNumGroupMembers()
		for i=numGroup+1, 40 do
			optionFrames.groupMemberButtons[i]:Hide()
		end

		local groupType = "raid"
		if not IsInRaid() then
			-- only party1-4 exist (not one for the player himself)
			groupType = "party"
			optionFrames.groupMemberButtons[numGroup]:SetGUID(playerGUID)
			optionFrames.groupMemberButtons[numGroup].inRotation = contains(rotationTabOptions[activeTab]["ROTATION"], playerGUID)
			optionFrames.groupMemberButtons[numGroup]:updateTexture()
			optionFrames.groupMemberButtons[numGroup]:SetText(colouredPlayerName)
			optionFrames.groupMemberButtons[numGroup]:Show()
			numGroup = numGroup-1
		end
		for i=1, numGroup do
			local GUID = UnitGUID(groupType..i)
			optionFrames.groupMemberButtons[i]:SetGUID(GUID)
			optionFrames.groupMemberButtons[i].inRotation = contains(rotationTabOptions[activeTab]["ROTATION"], GUID)
			optionFrames.groupMemberButtons[i]:updateTexture()
			optionFrames.groupMemberButtons:SetText(util.getColouredNameByGUID(GUID))
			optionFrames.groupMemberButtons[i]:Show()
		end
	else
		for i=2, 40 do
			optionFrames.groupMemberButtons[i]:Hide()
		end
		optionFrames.groupMemberButtons[1]:SetGUID(playerGUID)
		optionFrames.groupMemberButtons[1].inRotation = contains(rotationTabOptions[activeTab]["ROTATION"], playerGUID)
		optionFrames.groupMemberButtons[1]:UpdateTexture()
		optionFrames.groupMemberButtons[1]:SetText(colouredPlayerName)
		optionFrames.groupMemberButtons[1]:Show()
	end
end

func.updateRotationButtons = function()
	local rotation = rotationTabOptions[activeTab]["ROTATION"]
	for i=#rotation+1, #optionFrames.rotationButtons do
		optionFrames.rotationButtons[i]:Hide()
	end
	for i=1, #rotation do
		optionFrames.rotationButtons[i]:SetGUID(rotation[i])
		optionFrames.rotationButtons[i]:SetText(util.getColouredNameByGUID(rotation[i]))
	end
end
func.removeRotationMember = function(GUID)
	for i=1, 40 do
		if optionFrames.groupMemberButtons[i]:GetGUID() == GUID then
			optionFrames.groupMemberButtons[i].inRotation = false
			optionFrames.groupMemberButtons[i]:UpdateTexture()
			break
		end
	end
	local rotationNum = #rotationTabOptions[activeTab]["ROTATION"]
	for i=1, rotationNum-1 do
		if optionFrames.rotationButtons:GetGUID() == GUID then
			for j=i, #rotationNum-1 do
				optionFrames.rotationButtons[j]:SetGUID(optionFrames.rotationButtons[j+1]:GetGUID())
				optionFrames.rotationButtons[j]:SetText(optionFrames.rotationButtons[j+1]:GetText())
			end
			break
		end
	end
	optionFrames.rotationButtons[rotationNum]:Hide()
	for i=1, #rotationTabOptions[activeTab]["ROTATION"] do
		if rotationTabOptions[activeTab]["ROTATION"][i] == GUID then
			remove(rotationTabOptions[activeTab]["ROTATION"], i)
			break
		end
	end
end
func.updateTrackMode = function (tabb)
	-- todo get other groupnum?
	local tab = tabb or activeTab
	local old = trackModes[tab]
	if rotationTabOptions[tab]["TRACKALLCHECKED"] and rotationTabOptions[tab]["TRACKALLFROM"]<= numGroup
			<= rotationTabOptions[tab]["TRACKALLTO"] then
		trackModes[tab] = "ALL"
	elseif rotationTabOptions[tab]["TRACKROTATIONCHECKED"] and rotationTabOptions[tab]["TRACKROTATIONFROM"]<= numGroup
			<= rotationTabOptions[tab]["TRACKROTATIONTO"] then
		trackModes[tab] = "ROTATION"
	else
		trackModes[tab] = "NONE"
	end
	if old == trackModes[tab] then
		return
	end
	-- todo
	if trackModes[tab] == "NONE" then
		--remove all bars for tab todo
	elseif old == "NONE" then
		if trackModes[tab] == "ROTATION" then
			-- add rotation
		elseif trackModes[tab] == "ALL" then
			-- add all players
		end
	elseif old == "ROTATION" then
			-- trackModes[tab] == "ALL" unless more modes added

			-- add all that havent been added yet
	else
		-- old == "ALL" unless more modes added
		-- trackModes[tab] == "ROTATION" unless more modes added

		-- remove players that arent part of the rotation

	end
end
func.makeTransmissionText = function()
	local text = "[SnagiIntRota:] "..optionFrames.titleEditBox:GetText().." "
	for _, member in ipairs(rotationTabOptions[activeTab]["ROTATION"]) do
		text = text..member.." "
	end
	return text
end
------------------------------------------------------------------------------------------------------------------------

-- FRAME SCRIPTS

------------------------------------------------------------------------------------------------------------------------
-- optionFrames.groupMemberButtons

func.generalTabButtonOnClick = function(self)
	optionFrames.rotationTab:Hide()
	optionFrames.generalTab:Show()
	for _, rt in ipairs(optionFrames.rotationTabButtons) do
		rt.inactiveTexture:Show()
		rt.activeTexture:Hide()
	end
	self.inactiveTexture:Hide()
	self.activeTexture:Show()
	optionFrames.leftSideMenu:Hide()
end
func.rotationTabButtonOnClick = function(self)
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
	func.updateRotationButtons()
	func.updateGroupMemberButtons()
	optionFrames.leftSideMenu:Show()
end
func.createNewTab = function()
	numTabs = numTabs+1
	optionFrames.rotationFrames[numTabs] = frameUtil.aquireRotationFrame(numTabs)
	optionFrames.rotationTabButtons[numTabs] = frameUtil.aquireTabButton(optionFrames.container)
	optionFrames.rotationTabButtons[numTabs].key = numTabs
	optionFrames.rotationTabButtons[numTabs]:SetPoint("LEFT", optionFrames.rotationTabButtons[numTabs-1] or optionFrames.generalTabButton,
		"RIGHT", -15, 0)
	optionFrames.rotationTabButtons[numTabs]:SetScript("OnClick", function(self) func.rotationTabButtonOnClick(self) end)
	rotationTabOptions[numTabs] = util.makeCopy(defaultOptions)
end
func.groupMemberOnClick = function(self)
	local rotation = rotationTabOptions[activeTab]["ROTATION"]
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
		rotationButton:SetGUID(GUID)
		rotationButton:Show()
		self.inRotation = true
		self:UpdateTexture()
	else
		func.removeRotationMember(GUID)
	end

end
func.enableGroupInstanceButtonOnClick = function(self)
	for _, c in ipairs({optionFrames.enableClassSpecButton:GetChildren()}) do
		c:Hide()
	end
	for _, c in ipairs({self:GetChildren()}) do
		c:Show()
	end
	optionFrames.enableClassSpecButton:UnlockHighlight()
	self:LockHighlight()
end
func.enableClassSpecButtonOnClick = function(self)
	for _, c in ipairs({optionFrames.enableGroupInstanceButton:GetChildren()}) do
		c:Hide()
	end
	for _, c in ipairs({self:GetChildren()}) do
		c:Show()
	end
	optionFrames.enableGroupInstanceButton:UnlockHighlight()
	self:LockHighlight()
end
func.groupEnableOptionCheckboxOnClick = function(self, option)
	local toggle = self:GetChecked()
	option.fromSlider:SetEnabled(toggle)
	option.fromEditbox:SetEnabled(toggle)
	option.toSlider:SetEnabled(toggle)
	option.toEditbox:SetEnabled(toggle)
	if toggle then
		option.fromFontString:SetTextColor(0.98, 0.82, 0)
		option.toFontString:SetTextColor(0.98, 0.82, 0)
		option.fromEditbox:SetTextColor(1, 1, 1)
		option.toEditbox:SetTextColor(1, 1, 1)
	else
		option.fromFontString:SetTextColor(0.3, 0.3, 0.3)
		option.toFontString:SetTextColor(0.3, 0.3, 0.3)
		option.fromEditbox:SetTextColor(0.3, 0.3, 0.3)
		option.toEditbox:SetTextColor(0.3, 0.3, 0.3)
		func.updateTrackMode()
	end
end
func.groupEnableOptionFromSliderOnMouseWheel = function(self, delta, option)
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
			option.toEditbox:SetText(newVal)
			rotationTabOptions[activeTab]["TRACK"..self.model.."TO"] = newVal
		end
		self:SetValue(newVal)
		rotationTabOptions[activeTab]["TRACK"..self.model.."FROM"] = newVal
	else
		if self:GetValue() == minVal then
			return
		end
		newVal = self:GetValue()-1
		self:SetValue(newVal)
		rotationTabOptions[activeTab]["TRACK"..self.model.."FROM"] = newVal
	end
	option.fromEditbox:SetText(newVal)
end
func.groupEnableOptionFromSliderOnMouseUp = function(self, option)
	local newVal = self:GetValue()
	if newVal == rotationTabOptions[activeTab]["TRACK"..self.model.."FROM"] then
		return
	end
	if newVal > rotationTabOptions[activeTab]["TRACK"..self.model.."TO"] then
		option.toSlider:SetValue(newVal)
		option.toEditbox:SetText(newVal)
		rotationTabOptions[activeTab]["TRACK"..self.model.."TO"] = newVal
	end
	option.fromEditbox:SetText(newVal)
	rotationTabOptions[activeTab]["TRACK"..self.model.."FROM"] = newVal
end
func.groupEnableOptionToSliderOnMouseWheel = function(self, delta, option)
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
		if newVal < rotationTabOptions[activeTab]["TRACK"..self.model.."FROM"] then
			option.fromSlider:SetValue(newVal)
			option.fromEditbox:SetText(newVal)
		end
	end
	option.toEditbox:SetText(newVal)
end
func.groupEnableOptionToSliderOnMouseUp = function(self, option)
	local newVal = self:GetValue()
	if newVal == rotationTabOptions[activeTab]["TRACK"..self.model.."TO"] then
		return
	end
	if newVal < rotationTabOptions[activeTab]["TRACK"..self.model.."FROM"] then
		option.fromSlider:SetValue(newVal)
		option.fromEditbox:SetText(newVal)
		rotationTabOptions[activeTab]["TRACK"..self.model.."FROM"] = newVal
	end
	option.toEditbox:SetText(newVal)
	rotationTabOptions[activeTab]["TRACK"..self.model.."TO"] = newVal
end
func.groupEnableOptionFromEditboxOnEnterPressed = function(self, option)
	local newVal = tonumber(self:GetText())
	if newVal > 40 then
		self:SetText(40)
		if rotationTabOptions[activeTab]["TRACK"..self.model.."FROM"] == 40 then
			return
		end
		newVal = 40
	end
	rotationTabOptions[activeTab]["TRACK"..self.model.."FROM"] = newVal
	option.fromSlider:SetValue(newVal)
	if newVal > rotationTabOptions[activeTab]["TRACK"..self.model.."TO"] then
		option.toSlider:SetValue(newVal)
		option.toEditbox:SetText(newVal)
		rotationTabOptions[activeTab]["TRACK"..self.model.."TO"] = newVal
	end
	self:ClearFocus()
end
func.groupEnableOptionToEditboxOnEnterPressed = function(self, option)
	local newVal = tonumber(self:GetText())
	if newVal > 40 then
		self:SetText(40)
		if rotationTabOptions[activeTab]["TRACK"..self.model.."TO"] == 40 then
			return
		end
		newVal = 40
	end
	rotationTabOptions[activeTab]["TRACK"..self.model.."TO"] = newVal
	option.toSlider:SetValue(newVal)
	if newVal < rotationTabOptions[activeTab]["TRACK"..self.model.."FROM"] then
		option.fromSlider:SetValue(newVal)
		option.fromEditbox:SetText(newVal)
		rotationTabOptions[activeTab]["TRACK"..self.model.."FROM"] = newVal
	end
	self:ClearFocus()
end
func.enableClassOnClick = function(self, c)
local newBool = self:GetChecked()
	rotationTabOptions[activeTab]["CLASSENABLEOPTIONS"][c] = newBool
	for i=1, #classSpecIDs[c] do
		rotationTabOptions[activeTab]["SPECENABLEOPTIONS"][classSpecIDs[c][i]] = newBool
		optionFrames.enableCheckboxes[c][i]:SetChecked(newBool)
	end
	-- todo if own spec option changed, update
end
func.enableSpecOnClick = function(self, c, s)
	local newBool = self:GetChecked()
	local specID = classSpecIDs[c][s]
	rotationTabOptions[activeTab]["SPECENABLEOPTIONS"][specID] = newBool
	for _, spec in ipairs(classSpecIDs[c]) do
		newBool = newBool and rotationTabOptions[activeTab]["SPECENABLEOPTIONS"][spec]
	end
	rotationTabOptions[activeTab]["CLASSENABLEOPTIONS"][c] = newBool

	-- todo update if own spec changed
end
-- optionFrames.rotationButtons
func.rotationButtonOnClick = function(self, button)
	local rotation = rotationTabOptions[activeTab]["ROTATION"]
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
end
func.removeMemberOnClick = function(self)
	func.removeRotationMember(self:GetParent():GetGUID())
end
func.testButtonOnClick = function()
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
func.menuButtonOnClick = function(self)
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

func.sortCheckboxOnClick = function(self)
	for _, scb in pairs(optionFrames.sortModeCheckboxes) do
		if scb ~= self then
			scb:SetChecked(false)
		end
	end
	rotationTabOptions[activeTab]["SORTMODE"] = (self:GetChecked() and self.value) or "NONE"
end

func.removeTabOnClick = function()
	--todo
end

func.titleEditBoxOnEnterPressed = function(self)
	local text = self:GetText()
	if text ~= "" then
		rotationTabOptions[activeTab]["TITLE"] = text
		optionFrames.rotationTabButtons[activeTab]:SetText(text)
	else
		text:SetText(rotationTabOptions[activeTab]["TITLE"])
	end
	self:ClearFocus()
end

func.sendRotationOnClick = function(self)
	SendChatMessage(func.makeTransmissionText(), self.value, _,
		optionFrames.whisperToEditBox:GetText())
end
