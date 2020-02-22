--luacheck: globals CreateFrame GameTooltip UISpecialFrames tremove
local _, SIR = ...
SIR.func = SIR.func or {}
local func = SIR.func
local tabButtonPool = {}
local rotationFramePool = {}
local statusBarPool = {}
SIR.frameUtil = {
	["aquireTabButton"] = function(parent)
		local tabButton = tabButtonPool[#tabButtonPool]
		if tabButton then
			tremove(tabButtonPool, #tabButtonPool)
		else
			tabButton = CreateFrame("Button", _, parent)

			tabButton:SetSize(100,35)
			tabButton:SetHitRectInsets(6, 6, 0, 0) --left, right, top, bottom
			local fontString = tabButton:CreateFontString(_, "ARTWORK", "GameFontNormal")
			fontString:SetTextColor(1,1,1)
			fontString:SetText("new_tab")
			tabButton:SetFontString(fontString)

			local inactiveTexture = tabButton:CreateTexture(_, "BACKGROUND")
			inactiveTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab")
			inactiveTexture:SetAllPoints()
			tabButton.inactiveTexture = inactiveTexture

			local activeTexture = tabButton:CreateTexture(_, "BACKGROUND")
			activeTexture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
			activeTexture:SetPoint("TOPLEFT")
			activeTexture:SetSize(tabButton:GetWidth(), tabButton:GetHeight()*2)
			tabButton.activeTexture = activeTexture

		end
		tabButton:GetFontString():SetTextColor(1,1,1)
		tabButton.activeTexture:Hide()
		tabButton.inactiveTexture:Show()
		tabButton:Show()
		return tabButton
	end,
	["releaseTabButton"] = function(tabButton)
		tabButton:Hide()
		tabButtonPool[#tabButtonPool+1] = tabButton
	end,
	["aquireRotationFrame"] = function(key)
		local rotationFrame = rotationFramePool[#rotationFramePool]
		if rotationFrame then
			tremove(rotationFramePool, #rotationFramePool)
			rotationFrame:ClearAllPoints()
		else
			rotationFrame = CreateFrame("Frame")
			rotationFrame:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				tileSize = 32,
				edgeSize = 32,
				tile = true,
				insets = {left="0", right="0", top="0", bottom="0"},
			})
			rotationFrame.fontString = rotationFrame:CreateFontString(_, "ARTWORK", "GameFontNormalLarge")
			rotationFrame:SetMovable(true)
			rotationFrame:RegisterForDrag("LeftButton")
			rotationFrame:SetScript("OnDragStart", function(self)
					self:StartMoving()
				end
			)
			rotationFrame:SetScript("OnDragStop", function(self)
				SIR.func.rotationFrameOnDragStop(self)
			end)
		end
		rotationFrame.key = key
		rotationFrame.fontString:SetText("new_tab")
		rotationFrame.fontString:SetAllPoints()
		rotationFrame:Show()
		rotationFrame:EnableMouse(false)
		rotationFrame:SetAlpha(0)
		return rotationFrame
	end,
	["releaseRotationFrame"] = function(rotationFrame)
		rotationFrame:Hide()
		rotationFramePool[#rotationFramePool+1] = rotationFrame
	end,
	["aquireStatusBar"] = function()
		local sb = statusBarPool[#statusBarPool]
		if sb then
			tremove(statusBarPool, #statusBarPool)
		else
			sb = CreateFrame("StatusBar")
			sb.icon = sb:CreateTexture()
			sb.icon:SetPoint("TOPRIGHT", sb, "TOPLEFT")
			sb.icon:SetPoint("BOTTOMRIGHT", sb, "BOTTOMLEFT")
			sb.rightText = sb:CreateFontString("$parentRightText", "ARTWORK", "GameFontNormal")
			sb.leftText = sb:CreateFontString("$parentRightText", "ARTWORK", "GameFontNormalSmall")
			sb.rightText:SetTextColor(1,1,1)
			sb.rightText:SetPoint("RIGHT")
			sb.leftText:SetTextColor(1,1,1)
			sb.leftText:SetPoint("LEFT")
			sb:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
			sb:SetBackdropColor(0, 0, 0, 0.6)
			sb:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
			sb:SetMinMaxValues(0,0)
		end
		return sb
	end,
	["releaseStatusBar"] = function(statusBar)
		statusBar:Hide()
		statusBarPool[#statusBarPool+1] = statusBar
	end,
	["createFontStringEditBox"] = function(parent)
		--creates an editable text box
	local editBox = CreateFrame("EditBox", _, parent, "InputBoxTemplate")
	local fontString = editBox:CreateFontString(_, "ARTWORK", "GameFontNormalLarge")
	fontString:SetPoint("RIGHT", editBox, "LEFT", -10, 0)
	editBox:SetSize(35, 25)
	editBox:SetScale(1.2)
	editBox:SetMaxLetters(4)
	editBox:SetAutoFocus(false)
	editBox:SetTextInsets(0, 0, 1, 0) --l r t b
	editBox:SetJustifyH("CENTER")
	editBox:SetScript("OnEditFocusGained", function(self) self.oldText = self:GetText() or "" end)
	editBox:SetScript("OnEscapePressed", function(self) self:SetText(self.oldText) self:ClearFocus() end)
	return unpack{fontString, editBox}
	end,
	["createIconCheckbox"] = function(width, height, parent)
		--creates a checkbox with an icon a texture ot it's left - icon needs to be set
		local cb = CreateFrame("CheckButton", _, parent, "ChatConfigBaseCheckButtonTemplate")
		cb:SetSize(width, height)
		local icon = cb:CreateTexture()
		icon:SetPoint("RIGHT", cb, "LEFT")
		icon:SetSize(cb:GetSize())
		cb.icon = icon
		cb:SetHitRectInsets(-width, 0, 0, 0) --l r t b
		return cb
	end,
	["createFontStringCheckbox"] = function(text, parent)
		-- creates a checkbox with a given text to it's left
		local cb = CreateFrame("CheckButton", _, parent, "ChatConfigBaseCheckButtonTemplate")
		cb.fontString = cb:CreateFontString(_, "ARTWORK", "GameFontNormalLarge")
		cb:SetSize(30, 30)
		cb.fontString:SetText(text)
		cb.fontString:SetPoint("RIGHT", cb, "LEFT")
		cb:SetHitRectInsets(-cb.fontString:GetWidth(), 0, 0, 0) --l r t b
		cb:SetScript("OnEnter", function(self)
			if self.tooltipText then
				GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
				GameTooltip:SetText(self.tooltipText, 1, 1, 1)
				GameTooltip:Show()
			end
		end)
		return cb
	end,
	["createGroupMemberButton"] = function (parent)
		local gmb = CreateFrame("Button", _, parent, "UIPanelButtonTemplate")
		gmb:SetSize(100,30)
		gmb.UpdateTexture = function(self)
			if self.inRotation then
				self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
				self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
				self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
			else
				self.Left:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
				self.Middle:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
				self.Right:SetTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
			end
		end
		gmb:SetScript("OnMouseUp", function(self)
			self:UpdateTexture()
		end)
		gmb.SetGUID = function(self, GUID)
			self.GUID = GUID
		end
		gmb.GetGUID = function(self)
			return self.GUID
		end
		gmb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		gmb:SetScript("OnEnable", nil)
		gmb:SetScript("OnDisable", nil)
		gmb:SetScript("OnShow", nil)
		return gmb
	end,
	["createRotationButton"] = function(parent)
		local rb = CreateFrame("Button", _, parent, "UIPanelButtonTemplate")
		rb:SetSize(100, 30)
		rb.SetGUID = function(self, GUID)
			self.GUID = GUID
		end
		rb.GetGUID = function(self)
			return self.GUID
		end
		rb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		return rb
	end,
	["createRemoveMemberButton"] = function(parent)
		local rmb = CreateFrame("Button", "$parentRemove", parent, "UIPanelCloseButton")
		rmb:SetPoint("RIGHT", parent, "LEFT", 5, 0)
		rmb:SetSize(40, 40)
		rmb:Show()
		return rmb
	end,
	["createSortCheckbox"] = function(text, parent)
		local scb = CreateFrame("CheckButton", _, parent, "ChatConfigBaseCheckButtonTemplate")
		scb:Hide()
		scb:SetSize(30, 30)
		scb:SetHitRectInsets(-30, 0, 0, 0)
		scb:SetScript("OnClick", function(self) func.sortCheckboxOnClick(self) end)
		local label = scb:CreateFontString(_, "ARTWORK", "GameFontNormal")
		label:SetPoint("RIGHT", scb, "LEFT", -5, 0)
		label:SetText(text)
		return scb
	end,
	["createMenuButton"] = function(text, parent)
		local ab = CreateFrame("Button", _, parent, "UIPanelButtonTemplate")
		ab:SetSize(100, 40)
		ab:SetText(text)
		ab:SetScript("OnClick", function(self) func.menuButtonOnClick(self) end)
		local arrow = ab:CreateTexture()
		arrow:SetTexture("Interface\\MONEYFRAME\\Arrow-Left-Up")
		arrow:SetSize(20, 40)
		arrow:SetPoint("RIGHT", ab, "LEFT", 9, -4)
		return ab
	end,
	["createSlider"] = function(parent, min, max)
		local slider = CreateFrame("Slider", _, parent, "OptionsSliderTemplate")
		slider:SetSize(200, 15)
		slider:SetMinMaxValues(min, max)
		slider:SetValueStep(1)
		slider:SetObeyStepOnDrag(true)
		slider.minValue, slider.maxValue = slider:GetMinMaxValues()
		return slider
	end,
	["createTwoDigitEditBox"] = function(parent)
		local eb = CreateFrame("EditBox", _, parent, "InputBoxTemplate")
		eb:SetAutoFocus(false)
		eb:SetNumeric(true)
		eb:SetMaxLetters(2)
		eb:SetJustifyH("CENTER")
		eb:SetSize(20, 15)
		eb:SetTextInsets(-2.3, 2.3, 2, 0) --l r t b
		return eb
	end,
	["createFromToOption"] = function(text, model, min, max, parent)
		local option = {
			["checkbox"] = SIR.frameUtil.createFontStringCheckbox(text, parent),
			["fromSlider"] = SIR.frameUtil.createSlider(parent, min, max),
			["fromEditbox"] = SIR.frameUtil.createTwoDigitEditBox(parent),
			["toSlider"] = SIR.frameUtil.createSlider(parent, min, max),
			["toEditbox"] = SIR.frameUtil.createTwoDigitEditBox(parent),
		}
		local fromFontString = option.checkbox:CreateFontString(_, "ARTWORK", "GameFontNormal")
		local toFontString = option.checkbox:CreateFontString(_, "ARTWORK", "GameFontNormal")
		for _, frame in pairs(option) do
			frame.model = model
		end
		for _, f in pairs({option.fromSlider, option.toSlider}) do
			f.High:SetText(f.maxValue)
			f.Low:SetText(f.minValue)
		end
		option.fromSlider:SetPoint("TOPLEFT", option.checkbox, "BOTTOMLEFT", -64, 0)
		option.toSlider:SetPoint("TOP", option.fromSlider, "BOTTOM", 0, -7)


		toFontString:SetPoint("LEFT", option.fromEditbox, "RIGHT", 6, 0)
		option.toEditbox:SetPoint("LEFT", toFontString, "RIGHT", 8, 0)

		fromFontString:SetPoint("LEFT", option.checkbox, "RIGHT", 3, 0)
		option.fromEditbox:SetPoint("LEFT", fromFontString, "RIGHT", 8, 0)

		fromFontString:SetFontObject("GameFontNormal")
		toFontString:SetFontObject("GameFontNormal")
		fromFontString:SetText("from:")
		toFontString:SetText("to:")

		option.checkbox:SetScript("OnClick", function(self) func.groupEnableOptionCheckboxOnClick(self, option)
		end)
		option.fromSlider:SetScript("OnMouseWheel", function(self, delta)
			func.groupEnableOptionFromSliderOnMouseWheel(self, delta, option)
		end)
		option.fromSlider:SetScript("OnMouseUp", function(self)
			func.groupEnableOptionFromSliderOnMouseUp(self, option)
		end)
		option.toSlider:SetScript("OnMouseWheel", function(self, delta)
			func.groupEnableOptionToSliderOnMouseWheel(self, delta, option)
		end)
		option.toSlider:SetScript("OnMouseUp", function(self)
			func.groupEnableOptionToSliderOnMouseUp(self, option)
		end)
		option.fromEditbox:SetScript("OnEnterPressed", function(self)
			func.groupEnableOptionFromEditboxOnEnterPressed(self, option)
		end)
		option.toEditbox:SetScript("OnEnterPressed", function(self)
			func.groupEnableOptionToEditboxOnEnterPressed(self, option)
		end)
			return option
	end
}