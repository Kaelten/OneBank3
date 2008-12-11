
local OneCore3 = LibStub('AceAddon-3.0'):GetAddon('OneCore3')
OneBank3 = OneCore3:NewModule("OneBank3")
local AceDB3 = LibStub('AceDB-3.0')

function OneBank3:OnInitialize()
	self.db = AceDB3:New("OneBank3DB")
	self.db:RegisterDefaults(self.defaults)
	
	self.displayName = "OneBank3"
	self.core = OneCore3
	
	self.bagIndexes = {-1, 5, 6, 7, 8, 9, 10, 11}
	
	self.frame = self.core:BuildFrame("OneBankFrame")
	self.frame.handler = self
	
	self.frame:SetPosition(self.db.profile.position)
	self.frame:CustomizeFrame(self.db.profile)
	self.frame:SetSize(200, 200)
	
	self.Show = function() self.frame:Show() end
	
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
				if ( bag <= NUM_BANKGENERIC_SLOTS ) then
					bag = -1
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

--[[	
	self.sidebar:SetScript("OnShow", function()
		if not self.sidebar.buttons then
			self.sidebar.buttons = {}
			local button = self:GetBackbackButton(self.sidebar)
			button:ClearAllPoints()
			button:SetPoint("TOP", self.sidebar, "TOP", 0, -15)
			
			self.sidebar.buttons[-1] = button
			for bag=0, 3 do
				local button = self:GetBagButton(bag, self.sidebar)
				button:ClearAllPoints()
				button:SetPoint("TOP", self.sidebar, "TOP", 0, (bag + 1) * -31 - 10)
				
				self.sidebar.buttons[bag] = button
			end
		end
	end)
	]]
	
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

