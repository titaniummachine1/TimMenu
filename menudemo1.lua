-- menudemo1.lua
local TimMenu = require("TimMenu")

-- Script state
local cbState1 = false
local sliderVal1 = 25
local options1 = { "Option A", "Option B", "Option C" }
local selectedIndex1 = 1

local function OnDraw_Menudemo1()
	if TimMenu.Begin("Demo Window 1") then
		-- Display header text
		TimMenu.Text("Demo Script 1: Basic Widgets")
		TimMenu.NextLine()

		-- Button example
		if TimMenu.Button("Click Me") then
			print("[Menudemo1] Button clicked!")
		end
		TimMenu.NextLine()

		-- Checkbox example
		cbState1 = TimMenu.Checkbox("Enable Feature", cbState1)
		TimMenu.NextLine()

		-- Slider example
		sliderVal1, changed1 = TimMenu.Slider("Adjust Value", sliderVal1, 0, 100, 5)
		if changed1 then
			print("[Menudemo1] Slider value -> " .. sliderVal1)
		end
		TimMenu.NextLine()

		-- Separator line
		TimMenu.Separator()
		TimMenu.NextLine()

		-- 2×2 grid of sectors
		-- Row 1
		TimMenu.BeginSector("Sector 1")
		TimMenu.Text("Content 1")
		TimMenu.EndSector("Sector 1")
		TimMenu.BeginSector("Sector 2")
		TimMenu.Text("Content 2")
		TimMenu.EndSector("Sector 2")
		TimMenu.NextLine()
		-- Row 2
		TimMenu.BeginSector("Sector 3")
		TimMenu.Text("Content 3")
		TimMenu.EndSector("Sector 3")
		TimMenu.BeginSector("Sector 4")
		TimMenu.Text("Content 4")
		TimMenu.EndSector("Sector 4")
		TimMenu.NextLine()

		TimMenu.End()
	end
end

callbacks.Unregister("Draw", "Menudemo1_Draw")
callbacks.Register("Draw", "Menudemo1_Draw", OnDraw_Menudemo1)
