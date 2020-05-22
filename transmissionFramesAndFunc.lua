--luacheck: globals CreateFrame UIDropDownMenu_SetWidth UISpecialFrames UIDropDownMenu_Initialize
--luacheck: globals C_ChatInfo ItemRefTooltip ChatFrame_AddMessageEventFilter UIDropDownMenu_SetText
--luacheck: globals gmatch strfind strsub UIDropDownMenu_GetText UIDropDownMenu_CreateInfo UIDropDownMenu_AddButton
--luacheck: globals SendChatMessage
local _, SIR = ...

local getText = function(tab)
	local text = "[SnagiIntRota:] "..SIR.optionFrames.titleEditBox:GetText().." "
	for _, member in ipairs(SIR.tabOptions[tab]["ROTATION"]) do
		text = text..member.." "
	end
	return text
end

SIR.transmissionFunc.send = function(tab, chatType)
    SendChatMessage(getText(tab), chatType, _,
    SIR.optionFrames.whisperToEditBox:GetText())
end

local transmissionFrame = CreateFrame("Frame", "SnagiIntRotaTransmissionFrame")
    transmissionFrame:SetSize(330, 180)
    transmissionFrame:SetPoint("CENTER")
    transmissionFrame:EnableMouse(true)
    transmissionFrame:SetMovable(true)
    transmissionFrame:RegisterForDrag("LeftButton")
    transmissionFrame:SetScript("OnDragStart", transmissionFrame.StartMoving)
    transmissionFrame:SetScript("OnDragStop", transmissionFrame.StopMovingOrSizing)
    transmissionFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tileSize = 32,
        edgeSize = 32,
        tile = true,
        insets = {left="11", right="12", top="12", bottom="11"},
    })
    transmissionFrame:Hide()
UISpecialFrames[#UISpecialFrames+1] = transmissionFrame:GetName()
local transmissionRotationFrame = CreateFrame("Frame", _, transmissionFrame)
    transmissionRotationFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tileSize = 32,
        edgeSize = 32,
        tile = true,
        insets = {left="11", right="12", top="12", bottom="11"},
    })
    transmissionRotationFrame:SetPoint("TOPLEFT", transmissionFrame, "TOPLEFT")
    transmissionRotationFrame:SetPoint("BOTTOMRIGHT", transmissionFrame, "BOTTOM", 0)

local transmissionRotationEditBox = CreateFrame("EditBox", _ , transmissionRotationFrame)
    transmissionRotationEditBox:SetFontObject("GameFontNormal")
    transmissionRotationEditBox:SetAutoFocus(false)
    transmissionRotationEditBox:SetMultiLine(true)
    transmissionRotationEditBox:SetPoint("TOPLEFT", transmissionRotationFrame, "TOPLEFT", 15, -15)
    transmissionRotationEditBox:SetPoint("BOTTOMRIGHT", transmissionRotationFrame, "BOTTOMRIGHT", -5, 10)
    transmissionRotationEditBox:Disable()

local transmissionCancelButton = CreateFrame("Button", _, transmissionFrame, "UIPanelButtonTemplate")
    transmissionCancelButton:SetSize(60, 30)
    transmissionCancelButton:SetPoint("BOTTOMRIGHT", transmissionFrame, "BOTTOMRIGHT", -15, 15)
    transmissionCancelButton:SetText("Cancel")
    transmissionCancelButton:SetScript("OnClick", function() transmissionFrame:Hide() end)

local transmissionOkayButton = CreateFrame("Button", _, transmissionFrame, "UIPanelButtonTemplate")
    transmissionOkayButton.tooltipText = "Save the given rotation in the selected tab."
    transmissionOkayButton:SetSize(60, 30)
    transmissionOkayButton:SetPoint("BOTTOMRIGHT", transmissionCancelButton, "BOTTOMLEFT", -15, 0)
    transmissionOkayButton:SetText("Okay")

local transmissionDropdownMenu = CreateFrame("Frame", _, transmissionFrame, "UIDropDownMenuTemplate")
    transmissionDropdownMenu:SetPoint("BOTTOMRIGHT", transmissionCancelButton, "TOPRIGHT", 14, 3)
UIDropDownMenu_SetWidth(transmissionDropdownMenu, 120)
local transmissionDropdownMenuLabel = transmissionDropdownMenu:CreateFontString(_, "ARTWORK", "GameFontNormal")
    transmissionDropdownMenuLabel:SetPoint("BOTTOMLEFT", transmissionDropdownMenu, "TOPLEFT", 0, 5)
    transmissionDropdownMenuLabel:SetPoint("BOTTOMRIGHT", transmissionDropdownMenu, "TOPRIGHT", 0, 5)
    transmissionDropdownMenuLabel:SetText("Place inside:")

local transmissionRotationLabelEditBox = CreateFrame("EditBox", _ , transmissionRotationFrame)
    transmissionRotationLabelEditBox:SetFontObject("GameFontNormal")
    transmissionRotationLabelEditBox:SetAutoFocus(false)
    transmissionRotationLabelEditBox:SetMultiLine(true)
    transmissionRotationLabelEditBox:SetJustifyH("CENTER")
    transmissionRotationLabelEditBox:SetSpacing(5)
    transmissionRotationLabelEditBox:SetSize(140, 20)
    transmissionRotationLabelEditBox:SetPoint("TOPLEFT", transmissionRotationFrame, "TOPRIGHT", 3, -25)
    transmissionRotationLabelEditBox:Disable()

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
		transmissionOkayButton.rotation = rotation
		local rotationText = ""
		for k=1, #rotation do
			rotationText = rotationText..k..". "..SIR.util.getColouredNameByGUID(rotation[k]).."\n"
		end
		transmissionRotationEditBox:SetText(rotationText)

		UIDropDownMenu_SetText(transmissionDropdownMenu, "new tab")
		for _, options in ipairs(SIR.tabOptions) do
			if options["TITLE"] == title then
				UIDropDownMenu_SetText(transmissionDropdownMenu, title)
				break
			end
		end

		transmissionRotationLabelEditBox:SetText(title.."\n"..SIR.util.getColouredNameByGUID(source))
		transmissionFrame:Show()
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

transmissionOkayButton:SetScript("OnClick", function(self)
	local text = UIDropDownMenu_GetText(transmissionDropdownMenu)
	if not text then
		return
	elseif text == "new tab" then
		SIR.optionFrames.createNewTabButton:Click()
		SIR.tabOptions[#SIR.tabOptions]["ROTATION"] = self.rotation
		SIR.tabOptions[#SIR.tabOptions]["TITLE"] = "new_tab"
		SIR.optionFrames.rotationTabButtons[#SIR.tabOptions]:SetText(SIR.tabOptions[#SIR.tabOptions]["TITLE"])
		SIR.optionFrames.container:Show()
		SIR.optionFrames.rotationTabButtons[#SIR.tabOptions]:Click()
	else
		for i, tabOptions in ipairs(SIR.tabOptions) do
			if tabOptions["TITLE"] == text then
				tabOptions["ROTATION"] = self.rotation
				SIR.optionFrames.container:Show()
				SIR.optionFrames.rotationTabButtons[i]:Click()
				break
			end
		end
	end
	transmissionFrame:Hide()
end)
UIDropDownMenu_Initialize(transmissionDropdownMenu, function()--self, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	for _, tabOptions in ipairs(SIR.tabOptions) do
		info.text = tabOptions["TITLE"]
		info.checked = UIDropDownMenu_GetText(transmissionDropdownMenu) == info.text
		info.func = function()
				UIDropDownMenu_SetText(transmissionDropdownMenu, tabOptions["TITLE"])
			end
		UIDropDownMenu_AddButton(info)
	end
	info.text = "new tab"
	info.checked = UIDropDownMenu_GetText(transmissionDropdownMenu) == info.text
	info.func = function()
		UIDropDownMenu_SetText(transmissionDropdownMenu, "new tab")
	end
	UIDropDownMenu_AddButton(info)
end)