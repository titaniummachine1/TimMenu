-- menudemo2.lua
local TimMenu = require("TimMenu")

-- Script state
local cbState2 = true
local sliderVal2 = 75

local function OnDraw_Menudemo2()
	if TimMenu.Begin("Demo Window 2") then
		-- Header
		TimMenu.Text("Demo Script 2: More Widgets")
		TimMenu.NextLine()

		-- Show debug information
		TimMenu.ShowDebug()
		TimMenu.NextLine()

		-- Checkbox example
		cbState2 = TimMenu.Checkbox("Toggle Option", cbState2)
		TimMenu.NextLine()

		-- Slider example
		sliderVal2, changed2 = TimMenu.Slider("Volume", sliderVal2, 0, 100, 10)
		if changed2 then
			print("[Menudemo2] Volume -> " .. sliderVal2)
		end
		TimMenu.NextLine()

		-- Button example
		if TimMenu.Button("Reset Values") then
			cbState2 = false
			sliderVal2 = 0
			print("[Menudemo2] Values reset")
		end

		TimMenu.End()
	end
end

callbacks.Unregister("Draw", "Menudemo2_Draw")
callbacks.Register("Draw", "Menudemo2_Draw", OnDraw_Menudemo2)
