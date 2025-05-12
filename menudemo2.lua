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
		-- Tab control at top
		for _, tab in ipairs(tabs) do
			if TimMenu.Button(tab) then
				currentTab = tab
			end
		end
		TimMenu.NextLine()
		-- Separator under tabs
		TimMenu.Separator()
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
			TimMenu.BeginSector("Prev")
			if TimMenu.Button("<") then
				selectedOption2 = selectedOption2 - 1
				if selectedOption2 < 1 then
					selectedOption2 = #options2
				end
			end
			TimMenu.EndSector("Prev")
			TimMenu.BeginSector("Choice")
			TimMenu.Text(options2[selectedOption2])
			TimMenu.EndSector("Choice")
			TimMenu.BeginSector("Next")
			if TimMenu.Button(">") then
				selectedOption2 = selectedOption2 + 1
				if selectedOption2 > #options2 then
					selectedOption2 = 1
				end
			end
			TimMenu.EndSector("Next")
		elseif currentTab == "Debug" then
			TimMenu.ShowDebug()
		end

		TimMenu.End()
	end
end

callbacks.Unregister("Draw", "Menudemo2_Draw")
callbacks.Register("Draw", "Menudemo2_Draw", OnDraw_Menudemo2)
