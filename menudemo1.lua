-- menudemo1.lua
local TimMenu = require("TimMenu")

-- Counter for toggling button visibility
local frameCounter = 0

-- Script state
local cbState1 = false
local sliderVal1 = 25
local options1 = { "Option A", "Option B", "Option C" }
local selectedIndex1 = 1

local function OnDraw_Menudemo1()
	-- update frame counter and compute visibility toggle (66 frames per half-cycle)
	frameCounter = frameCounter + 1
	local showButton = (frameCounter % 132) < 66

	if TimMenu.Begin("Demo Window 1") then
		-- First row: two sectors side by side
		TimMenu.BeginSector("sectorA")
		-- show/hide button every half second (approx. 66 frames)
		if showButton and TimMenu.Button("Click Me") then
			print("[Menudemo1] Button clicked!")
		end
		TimMenu.EndSector("sectorA")
		TimMenu.BeginSector("sectorB")
		if TimMenu.Button("Click Me") then
		end
		TimMenu.EndSector("sectorB")
		TimMenu.NextLine()

		-- Second row: two more sectors
		TimMenu.BeginSector("sectorC")
		if TimMenu.Button("Click Me") then
		end
		TimMenu.EndSector("sectorC")
		TimMenu.BeginSector("sectorD")
		if TimMenu.Button("Click Me") then
		end
		TimMenu.EndSector("sectorD")
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

		-- Selector example (simple)
		TimMenu.Text("Selected: " .. options1[selectedIndex1])
		TimMenu.NextLine()
		if TimMenu.Button("<") then
			selectedIndex1 = selectedIndex1 - 1
			if selectedIndex1 < 1 then
				selectedIndex1 = #options1
			end
		end
		if TimMenu.Button(">") then
			selectedIndex1 = selectedIndex1 + 1
			if selectedIndex1 > #options1 then
				selectedIndex1 = 1
			end
		end

		TimMenu.End()
	end
end

callbacks.Unregister("Draw", "Menudemo1_Draw")
callbacks.Register("Draw", "Menudemo1_Draw", OnDraw_Menudemo1)
