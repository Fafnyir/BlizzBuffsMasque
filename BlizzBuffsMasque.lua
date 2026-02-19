local LMB = LibStub("Masque", true)
if not LMB then return end

local Buffs = LMB:Group("Blizzard Buffs", "Buffs")
local Debuffs = LMB:Group("Blizzard Buffs", "Debuffs")

if AuraButtonMixin then
	-- Dragonflight+ handling
	local skinned = {}

	local function makeHook(group)
		return function(self)
			local function updateFrames(frames)
				for _, frame in ipairs(frames) do
					if not skinned[frame] and frame.Icon and frame.Icon.GetTexture then
						skinned[frame] = true

						-- Create a wrapper for the skinnable components
						local skinWrapper = CreateFrame("Frame", nil, frame)
						skinWrapper:SetSize(30, 30)
						skinWrapper:SetPoint("BOTTOM")

						-- Hide Blizzard's icon and use a new one
						frame.Icon:Hide()
						frame.SkinnedIcon = skinWrapper:CreateTexture(nil, "BACKGROUND")
						frame.SkinnedIcon:SetSize(30, 30)
						frame.SkinnedIcon:SetPoint("CENTER")
						frame.SkinnedIcon:SetTexture(frame.Icon:GetTexture())

						hooksecurefunc(frame.Icon, "SetTexture", function(_, tex)
							frame.SkinnedIcon:SetTexture(tex)
						end)

						-- Adjust other components
						if frame.Count then
							frame.Count:SetParent(skinWrapper)
						end
						if frame.DebuffBorder then
							frame.DebuffBorder:SetParent(skinWrapper)
						end
						if frame.TempEnchantBorder then
							frame.TempEnchantBorder:SetParent(skinWrapper)
							frame.TempEnchantBorder:SetVertexColor(0.75, 0, 1)
						end
						if frame.Symbol then
							frame.Symbol:SetParent(skinWrapper)
						end

						-- Determine aura type
						local bType = frame.auraType or "Aura"
						if bType == "DeadlyDebuff" then
							bType = "Debuff"
						end

						-- Add to Masque
						group:AddButton(skinWrapper, {
							Icon = frame.SkinnedIcon,
							DebuffBorder = frame.DebuffBorder,
							EnchantBorder = frame.TempEnchantBorder,
							Count = frame.Count,
							HotKey = frame.Symbol,
						}, bType)
					end
				end
			end

			updateFrames(self.auraFrames or {})
			if self.exampleAuraFrames then
				updateFrames(self.exampleAuraFrames)
			end
		end
	end

	-- Hook Blizzard's functions
	hooksecurefunc(BuffFrame, "UpdateAuraButtons", makeHook(Buffs))
	hooksecurefunc(BuffFrame, "OnEditModeEnter", makeHook(Buffs))
	hooksecurefunc(DebuffFrame, "UpdateAuraButtons", makeHook(Debuffs))
	hooksecurefunc(DebuffFrame, "OnEditModeEnter", makeHook(Debuffs))
else
	-- Fallback for older API
	local f = CreateFrame("Frame")
	local TempEnchant = LMB:Group("Blizzard Buffs", "TempEnchant")

	local function OnEvent()
		-- Handle Buffs
		for i = 1, BUFF_MAX_DISPLAY do
			local buff = _G["BuffButton" .. i]
			if buff then
				Buffs:AddButton(buff, nil, "Buff")
			end
		end

		-- Handle Debuffs
		for i = 1, BUFF_MAX_DISPLAY do
			local debuff = _G["DebuffButton" .. i]
			if debuff then
				Debuffs:AddButton(debuff, nil, "Debuff")
			end
		end

		-- Handle Temporary Enchants
		for i = 1, (NUM_TEMP_ENCHANT_FRAMES or 3) do
			local enchant = _G["TempEnchant" .. i]
			if enchant then
				TempEnchant:AddButton(enchant, nil, "Enchant")
			end
			_G["TempEnchant" .. i .. "Border"]:SetVertexColor(0.75, 0, 1)
		end

		-- Remove event after initialization
		f:SetScript("OnEvent", nil)
	end

	-- Hook for dynamically created frames
	hooksecurefunc("CreateFrame", function(_, name, parent)
		if parent ~= BuffFrame or type(name) ~= "string" then return end
		if strfind(name, "^DebuffButton%d+$") then
			Debuffs:AddButton(_G[name], nil, "Debuff")
			Debuffs:ReSkin()
		elseif strfind(name, "^BuffButton%d+$") then
			Buffs:AddButton(_G[name], nil, "Buff")
			Buffs:ReSkin()
		end
	end)

	f:SetScript("OnEvent", OnEvent)
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
end
