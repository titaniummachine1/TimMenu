-- menudemo2.lua
local TimMenu = require("TimMenu")

-- Script state
local cbState2 = true
local sliderVal2 = 75
local balanceVal2 = 0
local selectedOption2 = 1
local options2 = { "Option A", "Option B", "Option C", "Option D" }
local tabs = { "Main", "Audio", "Options", "Debug" }
local currentTab = 1 -- Use index instead of label
local dropdownIndex2 = 1
local comboState2 = { false, false, false, false }
-- Keybind demo state
local bindKey2 = 0
-- Color picker demo state
local pickerColor2 = { 0, 255, 0, 255 }

local function OnDraw_Menudemo2()
	if TimMenu.Begin("Demo Window 2 - Advanced") then
		-- Use simplified TabControl (returns selected index)
		currentTab = TimMenu.TabControl("DemoTabs", tabs, currentTab)

		if currentTab == 1 then -- Main tab
			TimMenu.Text("Welcome to the Main Tab")
			TimMenu.NextLine()
			cbState2 = TimMenu.Checkbox("Enable Feature", cbState2)
			TimMenu.NextLine()
			if TimMenu.Button("Run Action") then
				print("[Menudemo2] Action executed")
			end
			-- Color Picker in Main tab
			pickerColor2 = TimMenu.ColorPicker("Main Color", pickerColor2)
			TimMenu.NextLine()

			TimMenu.NextLine()
			-- Keybind widget
			bindKey2 = TimMenu.Keybind("Demo2 Bind", bindKey2)
		elseif currentTab == 2 then -- Audio tab
			sliderVal2 = TimMenu.Slider("Volume", sliderVal2, 0, 100, 5)
			TimMenu.Tooltip("Adjust the audio volume from 0 to 100")
			TimMenu.NextLine()
			balanceVal2 = TimMenu.Slider("Balance", balanceVal2, -50, 50, 1)
			TimMenu.Tooltip("Adjust audio balance: negative = left, positive = right")
		elseif currentTab == 3 then -- Options tab
			TimMenu.Text("Select Option:")
			TimMenu.NextLine()

			-- Selector example using the dedicated widget
			selectedOption2 = TimMenu.Selector("Option Selector", selectedOption2, options2)
			TimMenu.NextLine()

			-- Dropdown example using the dedicated widget
			dropdownIndex2 = TimMenu.Dropdown("Dropdown in Demo2", dropdownIndex2, options2)
			TimMenu.NextLine()

			-- Multi-selection Combo example
			comboState2 = TimMenu.Combo("Combo in Demo2", comboState2, options2)
			TimMenu.NextLine()
		elseif currentTab == 4 then -- Debug tab
			TimMenu.ShowDebug()
		end
	end
end

-- Register draw callback
callbacks.Unregister("Draw", "Menudemo22_Draw")
callbacks.Register("Draw", "Menudemo22_Draw", OnDraw_Menudemo2)
