
local OneCore3 = LibStub('AceAddon-3.0'):GetAddon('OneCore3')
OneBank3 = OneCore3:NewModule("OneBank3")
local AceDB3 = LibStub('AceDB-3.0')

function OneBank3:OnInitialize()
	self.db = AceDB3:New("OneBank3DB")
	self.db:RegisterDefaults(self.defaults)
	
	self.displayName = "OneBank3"
	self.core = OneCore3
	self.isBank = true
	
	self.bagIndexes = {-1, 5, 6, 7, 8, 9, 10, 11}
	
	self.frame = self.core:BuildFrame("OneBankFrame")
	self.frame.handler = self
	
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
			if event == 'PLAYERBANKSLOTS_CHANGED' then
				if 	( bag <= NUM_BANKGENERIC_SLOTS ) then
					BankFrameItemButton_Update(self.frame.slots["-1:"..bag])
				else
					BankFrameItemButton_Update(self.sidebar.buttons[bag-NUM_BANKGENERIC_SLOTS]);
				end
			end
			
			self:UpdateBag(bag)
		end
		
		self:RegisterEvent("BAG_UPDATE", UpdateBag)
		self:RegisterEvent("BAG_UPDATE_COOLDOWN", UpdateBag)
		
		self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", UpdateBag)
		
		self.frame.name:SetText(UnitName("player").."'s Bank Bags")
		
		if self.frame.sidebarButton:GetChecked() then
			self.frame.sidebar:Show()
		end
	end)
	
	self.frame:SetScript("OnHide", function()
		self:UnregisterEvent("BAG_UPDATE")
		self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
		
		self.sidebar:Hide()
		CloseBankFrame()
	end)
	
	self.sidebar = OneCore3:BuildSideBar("OneBankSideFrame", self.frame)
	self.sidebar.handler = self
	self.frame.sidebar = self.sidebar
	
	self.sidebar:CustomizeFrame(self.db.profile)
	self.sidebar:SetHeight(4 * self.rowHeight + self.bottomBorder + self.topBorder) 
	self.sidebar:SetWidth(2 * self.colWidth + self.leftBorder + self.rightBorder)
	
	
	self.sidebar:SetScript("OnShow", function()
		if not self.sidebar.buttons then
			self.sidebar.buttons = {}
			
			for row=1, 3 do
				local b1ID, b2ID = row * 2 - 1, row * 2
				local yOffset = 0 - 10 - ((row - 1) * self.rowHeight)
				
				local button = self:GetBagButton(b1ID, self.sidebar)
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", self.sidebar, "TOPLEFT", self.leftBorder, yOffset)
				self.sidebar.buttons[b1ID] = button
				
				local button2 = self:GetBagButton(b2ID, self.sidebar)
				button2:ClearAllPoints()
				button2:SetPoint("TOPLEFT", self.sidebar, "TOPLEFT", self.leftBorder + self.colWidth , yOffset)
				self.sidebar.buttons[b2ID] = button2
			end
			
			local button = self:GetBagButton(7, self.sidebar)
			button:ClearAllPoints()
			button:SetPoint("TOP", self.sidebar, "TOP", 0, 0 - 10 - (3 * self.rowHeight))
			self.sidebar.buttons[7] = button	
			
			for _, button in pairs(self.sidebar.buttons) do
				BankFrameItemButton_Update(button)
			end
			
		end
		self:UpdateBagSlotStatus()
	end)
	
	self.sidebar:Hide()
	
	self:InitializeConfiguration()
	self:EnablePlugins()
--	self:OpenConfig()
	
end

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
end

--[[ TODO: Fix this shit 
-- Custom Configuration
function OneBank3:LoadCustomConfig(baseconfig)
	local bagvisibility = {
		type = "group",
		name = "Specific Bag Filters",
		order = 2,
		inline = true,
		args = {}
	}

	local names = {
		[0] = 'Backpack',
		[1] = 'First Bag',
		[2] = 'Second Bag',
		[3] = 'Third Bag',
		[4] = 'Fourth Bag',
	}
	
	for id, text in pairs(names) do
		bagvisibility.args[tostring(id)] = {
			order = 5 * id + 5,
			type = "toggle",
			name = text,
			desc = ("Toggles the display of your %s."):format(text),
			get = function(info)
				return self.db.profile.show[id]
			end,
			set = function(info, value)
				self.db.profile.show[id] = value
				self:OrganizeFrame(true)
			end
		}
	end
	
	baseconfig.args.showbags.args.bag = bagvisibility
end
]]

-- Hooks handlers
function OneBank3:IsBagOpen(bag)
	if type(bag) == "number" and ((bag < 5 and bag ~= -1) or bag > 11) then
		return
	end
	
	return self.isOpened and bag or nil
end

function OneBank3:GetBagButton(bag, parent)

	local button = CreateFrame("CheckButton", "OneBankSBBag"..bag, parent, 'BankItemButtonBagTemplate')
	button:SetID(bag+4)
	
	--[[
	self:SecureHookScript(button, "OnEnter", function(button)
		self:HighlightBagSlots(button:GetID())
	end)
	
	button:SetScript("OnLeave", function(button)
		if not button:GetChecked() then
			self:UnhighlightBagSlots(button:GetID())
			self.frame.bags[button:GetID()].colorLocked = false
		else
			self.frame.bags[button:GetID()].colorLocked = true
		end
		GameTooltip:Hide()
	end)
	
	button:SetScript("OnClick", function(button) 
		local haditem = PutItemInBag(button:GetInventorySlot())

		if haditem then
			button:SetChecked(not button:GetChecked())
		end 
	end)
	
	button:SetScript("OnReceiveDrag", function(button) 
		PutItemInBag(button:GetID())
	end)
	]]
	
	return button
end

function OneBank3:UpdateBagSlotStatus() 
	--[[
	local purchaseFrame = OBBBagFraPurchaseInfo
	if( purchaseFrame == nil ) then
		return
	end
	]]
	
	local numSlots,full = GetNumBankSlots()
	local button
	for i=1, NUM_BANKBAGSLOTS, 1 do
		button = self.sidebar.buttons[i]
		if ( button ) then
			if ( i <= numSlots ) then
				SetItemButtonTextureVertexColor(button, 1.0,1.0,1.0)
				button.tooltipText = BANK_BAG
			else
				SetItemButtonTextureVertexColor(button, 1.0,0.1,0.1)
				button.tooltipText = BANK_BAG_PURCHASE
			end
		end
	end
	--[[
	-- pass in # of current slots, returns cost of next slot
	local cost = GetBankSlotCost(numSlots)
	BankFrame.nextSlotCost = cost
	if( GetMoney() >= cost ) then
		SetMoneyFrameColor("OBBBagFraPurchaseInfoDetailMoneyFrame", 1.0, 1.0, 1.0)
	else
		SetMoneyFrameColor("OBBBagFraPurchaseInfoDetailMoneyFrame", 1.0, 0.1, 0.1)
	end
	MoneyFrame_Update("OBBBagFraPurchaseInfoDetailMoneyFrame", cost)

	if( full ) then
		purchaseFrame:Hide()
	else
		purchaseFrame:Show()
	end
	]]
end


