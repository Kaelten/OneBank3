local OneBag3 = LibStub('AceAddon-3.0'):GetAddon('OneBag3', true)
local OneBank3 = LibStub('AceAddon-3.0'):NewAddon('OneBank3', 'OneCore-1.0', 'OneFrame-1.0', 'OneConfig-1.0',
	'OnePlugin-1.0', 'AceHook-3.0', 'AceEvent-3.0', 'AceConsole-3.0', 'AceTimer-3.0')
local AceDB3 = LibStub('AceDB-3.0')
local L = LibStub("AceLocale-3.0"):GetLocale("OneBank3")

OneBank3.IsRetail = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE
OneBank3.IsClassic = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC
OneBank3.IsBC = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC

OneBank3:InitializePluginSystem()

--- Handles the do once configuration, including db, frames and configuration
function OneBank3:OnInitialize()
	self.db = AceDB3:New("OneBank3DB")
	self.db:RegisterDefaults(self.defaults)

	self.displayName = "OneBank3"
	self.isBank = true

	self.bankBagIndexes = { -1, 5, 6, 7, 8, 9, 10, 11 }
	self.reagentBankIndexes = { -3 }

	self.bagIndexes = self.bankBagIndexes

	self.frame = self:CreateMainFrame("OneBankFrame")
	self.frame.handler = self
	self:UpdateFrameHeader()

	self.frame:SetPosition(self.db.profile.position)
	self.frame:CustomizeFrame(self.db.profile)
	self.frame:SetSize(200, 200)

	self.frame:SetScript("OnShow", function()
		if not self.frame.slots then
			self.frame.slots = {}
		end

		self:BuildFrame()
		self:OrganizeFrame()
		self:UpdateFrame()

		local UpdateBag = function(event, bag)
			-- This is a work around of the fact that bank slots work different than all other slots.
			if event == "PLAYERREAGENTBANKSLOTS_CHANGED" then
				if not self.frame.bags[-3] then
					return
				end

				if not self.frame.bags[-3].colorLocked then
					for slot = 1, self.frame.bags[-3].size do
						self:ColorSlotBorder(self:GetSlot(-3, slot))
					end
				end

				local slot = self.frame.slots["-3:" .. bag]
				if slot then
					BankFrameItemButton_Update(slot)
				end
			elseif event == 'PLAYERBANKSLOTS_CHANGED' then
				if (bag <= NUM_BANKGENERIC_SLOTS) then

					if not self.frame.bags[-1].colorLocked then
						for slot = 1, self.frame.bags[-1].size do
							self:ColorSlotBorder(self:GetSlot(-1, slot))
						end
					end

					BankFrameItemButton_Update(self.frame.slots["-1:" .. bag])
				else
					if self.sidebar and self.sidebar.buttons then
						BankFrameItemButton_Update(self.sidebar.buttons[bag - NUM_BANKGENERIC_SLOTS]);
					end
				end
				return
			end

			self:UpdateBag(bag)
		end

		local DelayedUpdateBag = function(event, bag)
			self:ScheduleTimer(UpdateBag, 0.05, event, bag)
		end

		self:RegisterEvent("BAG_UPDATE", DelayedUpdateBag)
		self:RegisterEvent("BAG_UPDATE_COOLDOWN", UpdateBag)
		self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", UpdateBag)

		self:RegisterEvent("ITEM_LOCK_CHANGED", "UpdateItemLock")

		self:RegisterEvent("PLAYER_MONEY", "UpdateBagSlotStatus")
		self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED", function()
			self:UpdateBagSlotStatus()
			DelayedUpdateBag()
		end)

		if self.IsRetail then
			self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED", UpdateBag)
			self:RegisterEvent("REAGENTBANK_PURCHASED", function()
				self.depositReagentsButtons:Show()

				if self.reagentBankButton:GetChecked() then
					self.bagIndexes = self.reagentBankIndexes
					self.frame.name:SetText(L["%s's Reagent Bank"]:format(UnitName("player")))

					self:BuildFrame()
					self:OrganizeFrame(true)
					self:UpdateFrame()
				end
			end)
		end

		if self.reagentBankButton and self.reagentBankButton:GetChecked() then
			self.frame.name:SetText(L["%s's Reagent Bank"]:format(UnitName("player")))
		else
			self.frame.name:SetText(L["%s's Bank Bags"]:format(UnitName("player")))
		end

		if self.frame.sidebarButton:GetChecked() then
			self.frame.sidebar:Show()
		end

		if OneBag3 and not self.db.profile.moved then
			self.frame:ClearAllPoints()
			self.frame:SetPoint("BOTTOMLEFT", OneBag3.frame, "TOPLEFT")
		end
	end)

	self.frame:SetScript("OnHide", function()
		self:UnregisterEvent("BAG_UPDATE")
		self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
		self:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
		self:UnregisterEvent("ITEM_LOCK_CHANGED")

		if self.IsRetail then
			self:UnregisterEvent("REAGENTBANK_PURCHASED")
			self:UnregisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
		end

		self:UnregisterEvent("PLAYER_MONEY")
		self:UnregisterEvent("PLAYERBANKBAGSLOTS_CHANGED")

		self.sidebar:Hide()
		CloseBankFrame()
	end)

	self.sidebar = self:CreateSideBar("OneBankSideFrame", self.frame)
	self.sidebar.handler = self
	self.frame.sidebar = self.sidebar

	local sidebarRows = self.IsClassic and 3 or 4

	self.sidebar:CustomizeFrame(self.db.profile)
	self.sidebar:SetHeight(sidebarRows * self.rowHeight + self.bottomBorder + self.topBorder - 7)
	self.sidebar:SetWidth(2 * self.colWidth + self.leftBorder + self.rightBorder)

	self.sidebar:SetScript("OnShow", function()
		if not self.sidebar.buttons then
			self.sidebar.buttons = {}

			for row = 1, 3 do
				local b1ID, b2ID = row * 2 - 1, row * 2
				local yOffset = 0 - 10 - ((row - 1) * self.rowHeight)

				local button = self:CreateBagButton(b1ID, self.sidebar)
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", self.sidebar, "TOPLEFT", self.leftBorder, yOffset)
				self.sidebar.buttons[b1ID] = button

				local button2 = self:CreateBagButton(b2ID, self.sidebar)
				button2:ClearAllPoints()
				button2:SetPoint("TOPLEFT", self.sidebar, "TOPLEFT", self.leftBorder + self.colWidth, yOffset)
				self.sidebar.buttons[b2ID] = button2
			end

			if sidebarRows == 4 then
				local button = self:CreateBagButton(7, self.sidebar)
				button:ClearAllPoints()
				button:SetPoint("TOP", self.sidebar, "TOP", 0, 0 - 10 - (3 * self.rowHeight))
				self.sidebar.buttons[7] = button
			end

			for _, button in pairs(self.sidebar.buttons) do
				BankFrameItemButton_Update(button)
			end
		end

		self:UpdateBagSlotStatus()
	end)

	self.sidebar:SetScript("OnHide", function()
		self.purchase:Hide()
	end)

	self.purchase = self:CreateBaseFrame('OneBankPurchaseFrame')
	self.purchase.handler = self
	self.frame.purchase = self.purchase

	self.purchase:CustomizeFrame(self.db.profile)
	self.purchase:SetSize(self.sidebar:GetWidth(), 50)

	self.purchase:ClearAllPoints()
	self.purchase:SetPoint("TOP", self.sidebar, "BOTTOM", 0, 2)

	self.purchase.label = self:CreateFontString(self.purchase, nil, 11)
	self.purchase.label:SetWidth(30)
	self.purchase.label:SetText(COSTS_LABEL)

	self.purchase.label:ClearAllPoints()
	self.purchase.label:SetPoint("TOPLEFT", self.purchase, "TOPLEFT", 12, -7)

	self.purchase.cost = self:CreateSmallMoneyFrame("MoneyFrame", self.purchase)
	self.purchase.cost:SetPoint("LEFT", self.purchase.label, "RIGHT", 6, 0)
	MoneyFrame_SetType(self.purchase.cost, "STATIC")

	self.purchase.button = CreateFrame('Button', nil, self.purchase, "UIPanelButtonTemplate")
	self.purchase.button:SetHeight(20)
	self.purchase.button:SetWidth(77)

	self.purchase.button:SetText(BANKSLOTPURCHASE)
	self.purchase.button:SetPoint("TOPLEFT", self.purchase, "TOPLEFT", 7, -22)

	self.purchase.button:SetScript("OnClick", function()
		PlaySound(852, "SFX")
		StaticPopup_Show("CONFIRM_BUY_BANK_SLOT")
	end)

	self.purchase:Hide()

	if self.IsRetail then
		self.reagentBankButton = CreateFrame("CheckButton", nil, self.frame, "UIPanelButtonTemplate")
		self.reagentBankButton:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 5, 5)
		self.reagentBankButton:SetText(L["Reagent Bank"])
		self.reagentBankButton:SetWidth(105)
		self.reagentBankButton:SetHeight(21)

		local selectedTexture = self.reagentBankButton:CreateTexture(nil, "OVERLAY")
		selectedTexture:SetHeight(19)
		selectedTexture:SetWidth(103)

		selectedTexture:SetPoint("CENTER", self.reagentBankButton, "CENTER", 0, 0)
		selectedTexture:SetTexture("Interface\\HelpFrame\\HelpButtons")
		selectedTexture:SetTexCoord(0.00390625, 0.68359375, 0.66015625, 0.87109375)
		selectedTexture:Hide()

		self.reagentBankButton.selectedTexture = selectedTexture

		self.reagentBankButton:SetScript("OnClick", function()
			if self.reagentBankButton:GetChecked() then
				selectedTexture:Show()
				self.reagentBankButton:SetNormalFontObject(GameFontHighlight)
				if IsReagentBankUnlocked() then
					self.bagIndexes = self.reagentBankIndexes
					self.frame.name:SetText(L["%s's Reagent Bank"]:format(UnitName("player")))
					self.depositReagentsButtons:Show()
				else
					PlaySound(852, "SFX")
					StaticPopup_Show("CONFIRM_BUY_REAGENTBANK_TAB")
				end
			else
				self.bagIndexes = self.bankBagIndexes
				self.frame.name:SetText(L["%s's Bank Bags"]:format(UnitName("player")))

				selectedTexture:Hide()
				self.reagentBankButton:SetNormalFontObject(GameFontNormal)
			end

			self:BuildFrame()
			self:OrganizeFrame(true)
			self:UpdateFrame()
		end)

		StaticPopupDialogs.CONFIRM_BUY_REAGENTBANK_TAB.OnCancel = function()
			self.reagentBankButton:Click()
		end

		self.depositReagentsButtons = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate")
		self.depositReagentsButtons:SetPoint("LEFT", self.reagentBankButton, "RIGHT", 0, 0)
		self.depositReagentsButtons:SetText(L["Deposit Reagents"])
		self.depositReagentsButtons:SetHeight(21)
		self.depositReagentsButtons:SetWidth(128)

		self.depositReagentsButtons:SetScript("OnClick", function()
			PlaySound(852, "SFX")
			DepositReagentBank();
		end)

		local hideDepositButton = function()
			if IsReagentBankUnlocked() then
				self.depositReagentsButtons:Show()
			else
				self.depositReagentsButtons:Hide()
			end
		end

		self:ScheduleTimer(hideDepositButton, 0.05)
	end

	self:InitializeConfiguration()
end

--- Sets up hooks and registers events
function OneBank3:OnEnable()

	local show = function()
		self.frame:Show()
		self.isOpened = true
	end

	local hide = function()
		self.frame:Hide()
		self.isOpened = false
	end

	self:RegisterEvent("BANKFRAME_OPENED", show)
	self:RegisterEvent("BANKFRAME_CLOSED", hide)
	self:SecureHook("CloseBankFrame", hide)

	self:RawHookScript(BankFrame, "OnEvent", function() end)
end

--- Provides the custom config options for OneConfig
-- @param baseconfig the base configuration table into which the custom options are injected
function OneBank3:LoadCustomConfig(baseconfig)
	local bagvisibility = {
		type = "group",
		name = L["Specific Bag Filters"],
		order = 2,
		inline = true,
		args = {}
	}

	local names = {
		[-1] = 'Bank Bag',
		[5] = 'First Bank Bag',
		[6] = 'Second Bank Bag',
		[7] = 'Third Bank Bag',
		[8] = 'Fourth Bank Bag',
		[9] = 'Fifth Bank Bag',
		[10] = 'Sixth Bank Bag',
		[11] = 'Seventh Bank Bag',
	}

	for id, text in pairs(names) do
		bagvisibility.args[tostring(id)] = {
			order = 5 * id + 5,
			type = "toggle",
			name = L[text],
			desc = L[("Toggles the display of your %s."):format(text)],
			get = function(_info)
				return self.db.profile.show[id]
			end,
			set = function(_info, value)
				self.db.profile.show[id] = value
				self:OrganizeFrame(true)
			end
		}
	end

	baseconfig.args.showbags.args.bag = bagvisibility
end

--- Handles Bag Sorting
function OneBank3:SortBags()
	if self.bagIndexes == self.bankBagIndexes then
		SortBankBags()
	elseif self.bagIndexes == self.reagentBankIndexes then
		SortReagentBankBags()
	end
end

-- Hooks handlers
function OneBank3:IsBagOpen(bag)
	if type(bag) == "number" and ((bag < 5 and bag ~= -1) or bag > 11) then
		return
	end

	return self.isOpened and bag or nil
end

function OneBank3:CreateBagButton(bag, parent)
	local frameType = self.IsRetail and "ItemButton" or "CheckButton"
	local button = CreateFrame(frameType, "OneBankSBBag" .. bag, parent, 'BankItemButtonBagTemplate')
	local highlight = self:CreateButtonHighlight(button)
	button:SetID(bag)

	button.GetContainerID = function(this)
		return this:GetID() + ITEM_INVENTORY_BANK_BAG_OFFSET
	end

	self:SecureHookScript(button, "OnEnter", function(this)
		self:HighlightBagSlots(this:GetContainerID())
		highlight:Show()
	end)

	button:SetScript("OnLeave", function(this)
		local index = this:GetContainerID()

		if not self.frame.bags[index].checked then
			self:UnhighlightBagSlots(index)
			highlight:Hide()
			self.frame.bags[index].colorLocked = false
		else
			self.frame.bags[index].colorLocked = true
		end

		GameTooltip:Hide()
	end)

	button:SetScript("OnClick", function(this)
		local haditem = PutItemInBag(this:GetInventorySlot())

		if not haditem then
			local index = this:GetContainerID()
			self.frame.bags[index].checked = not self.frame.bags[index].checked
		end
	end)

	return button
end

function OneBank3:UpdateBagSlotStatus()
	if not self.sidebar.buttons then
		return
	end

	local numSlots, full, _button = GetNumBankSlots()
	for i = 1, NUM_BANKBAGSLOTS, 1 do
		local button = self.sidebar.buttons[i]
		if (button) then
			if (i <= numSlots) then
				SetItemButtonTextureVertexColor(button, 1.0, 1.0, 1.0)
				button.tooltipText = BANK_BAG
			else
				SetItemButtonTextureVertexColor(button, 1.0, 0.1, 0.1)
				button.tooltipText = BANK_BAG_PURCHASE
			end
		end
	end

	if full or not self.sidebar:IsVisible() then
		return self.purchase:Hide()
	else
		self.purchase:Show()
	end

	local cost = GetBankSlotCost(numSlots)
	BankFrame.nextSlotCost = cost -- Updated because of the confirmation dialog uses it.
	MoneyFrame_Update(self.purchase.cost, cost)

	if (GetMoney() >= cost) then
		SetMoneyFrameColor(self.purchase.cost:GetName(), 1.0, 1.0, 1.0)
	else
		SetMoneyFrameColor(self.purchase.cost:GetName(), 1.0, 0.1, 0.1)
	end
end
