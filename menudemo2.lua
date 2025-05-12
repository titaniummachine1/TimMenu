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
local dropdownIndex2 = 1
local comboIndex2 = 1

local function OnDraw_Menudemo2()
	if TimMenu.Begin("Demo Window 2 - Advanced") then
		-- Find current tab index
		local currentTabIndex = 1
		for i, tabName in ipairs(tabs) do
			if tabName == currentTab then
				currentTabIndex = i
				break
			end
		end

		-- Use the new TabControl widget
		local newTabIndex = TimMenu.TabControl("DemoTabs", tabs, currentTabIndex)

		-- Update state if selection changed
		if newTabIndex ~= currentTabIndex then
			currentTab = tabs[newTabIndex]
		end

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

			-- Selector example using the dedicated widget
			selectedOption2, changedOption = TimMenu.Selector(nil, selectedOption2, options2)
			if changedOption then
				print("[Menudemo2] Selector selected: " .. options2[selectedOption2])
			end
			TimMenu.NextLine()

			-- Dropdown example using the dedicated widget
			dropdownIndex2, changedOption = TimMenu.Dropdown("Dropdown in Demo2", dropdownIndex2, options2)
			if changedOption then
				print("[Menudemo2] Dropdown selected: " .. options2[dropdownIndex2])
			end
			TimMenu.NextLine()

			-- Combo example using alias for Dropdown
			comboIndex2, changedOption = TimMenu.Combo("Combo in Demo2", comboIndex2, options2)
			if changedOption then
				print("[Menudemo2] Combo selected: " .. options2[comboIndex2])
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
