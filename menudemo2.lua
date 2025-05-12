-- menudemo2.lua
local TimMenu = require("TimMenu")

-- Script state
local cbState2 = true
local sliderVal2 = 75
local balanceVal2 = 0
local selectedOption2 = 1
local options2 = { "Option A", "Option B", "Option C", "Option D" }
local tabs = { "Main", "Audio", "Options", "Debug" }
local currentTab = tabs[1]

local function OnDraw_Menudemo2()
	if TimMenu.Begin("Demo Window 2 - Advanced") then
		-- Tab bar
		for i, tab in ipairs(tabs) do
			if TimMenu.Button(tab) then
				currentTab = tab
			end
			if i < #tabs then
				TimMenu.SameLine()
			end
		end
		TimMenu.NextLine()

		-- Separator under tabs
		TimMenu.Separator("separator1")
		TimMenu.NextLine()

		if currentTab == "Main" then
			TimMenu.Text("Welcome to the Main Tab")
			TimMenu.NextLine()
			cbState2 = TimMenu.Checkbox("Enable Feature", cbState2)
			TimMenu.NextLine()
			if TimMenu.Button("Run Action") then
				print("[Menudemo2] Action executed")
			end
		elseif currentTab == "Audio" then
			sliderVal2, changed2 = TimMenu.Slider("Volume", sliderVal2, 0, 100, 5)
			if changed2 then
				print("[Menudemo2] Volume -> " .. sliderVal2)
			end
			TimMenu.NextLine()
			balanceVal2, changed3 = TimMenu.Slider("Balance", balanceVal2, -50, 50, 1)
			if changed3 then
				print("[Menudemo2] Balance -> " .. balanceVal2)
			end
		elseif currentTab == "Options" then
			TimMenu.Text("Select Option:")
			TimMenu.NextLine()

			-- Use the dedicated Selector widget
			selectedOption2, changedOption = TimMenu.Selector(nil, selectedOption2, options2)
			if changedOption then
				print("[Menudemo2] Option selected: " .. options2[selectedOption2])
			end
			TimMenu.NextLine()
		elseif currentTab == "Debug" then
			TimMenu.ShowDebug()
		end

		TimMenu.End()
	end
end

-- Register draw callback
callbacks.Unregister("Draw", "Menudemo22_Draw")
callbacks.Register("Draw", "Menudemo22_Draw", OnDraw_Menudemo2)
