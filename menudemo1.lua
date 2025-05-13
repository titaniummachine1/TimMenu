-- menudemo1.lua
local TimMenu = require("TimMenu")

-- Script state
local cbState1 = false
local sliderVal1 = 25
local options1 = { "Option A", "Option B", "Option C" }
local selectedIndex1 = 1
local dropdownIndex1 = 1
local comboState1 = { false, false, false }

-- TabControl demo state
local tabOptions1 = { "Tab 1", "Tab 2", "Tab 3" }
local selectedTab1 = 1

local function OnDraw_Menudemo1()
	if TimMenu.Begin("Demo Window 1") then
		-- First row: Demonstrate multiple widgets and alignment
		TimMenu.BeginSector("Multi-Widget Area")
		TimMenu.Text("Content in A")
		TimMenu.NextLine()
		cbState1 = TimMenu.Checkbox("Checkbox in A", cbState1)
		TimMenu.NextLine()
		TimMenu.Text("More text...")
		TimMenu.EndSector("Multi-Widget Area")

		TimMenu.BeginSector("Single Button")
		if TimMenu.Button("Button in B") then
			print("[Menudemo1] Button B clicked!XD")
		end
		TimMenu.EndSector("Single Button")
		TimMenu.NextLine() -- End of the first row of sectors

		-- Nested Sector Example
		TimMenu.BeginSector("Nesting Container")
		TimMenu.Text("Inside Outer Container")
		TimMenu.NextLine()
		TimMenu.BeginSector("Nested Slider Area")
		sliderVal1, changed1 = TimMenu.Slider("Slider in Nested Area", sliderVal1, 0, 100, 5)
		if changed1 then
			print("[Menudemo1] Slider value -> " .. sliderVal1)
		end
		if TimMenu.Button("Button in B") then
			print("[Menudemo1] Button B clicked!XD")
		end
		if TimMenu.Button("Button in B") then
			print("[Menudemo1] Button B clicked!XD")
		end
		TimMenu.NextLine()
		if TimMenu.Button("Button in B") then
			print("[Menudemo1] Button B clicked!XD")
		end

		TimMenu.EndSector("Nested Slider Area")
		TimMenu.NextLine()
		TimMenu.Text("Also inside Container")
		TimMenu.EndSector("Nesting Container")
		TimMenu.NextLine() -- End of Nesting Container block

		-- Separator line (outside sectors)
		TimMenu.Separator()
		TimMenu.NextLine()

		-- Selector example using the dedicated widget (outside sectors)
		selectedIndex1, changed1 = TimMenu.Selector(nil, selectedIndex1, options1)
		if changed1 then
			print("[Menudemo1] Selector changed to index: ", selectedIndex1)
		end

		TimMenu.NextLine()
		-- Dropdown example using the dedicated widget
		dropdownIndex1, changed1 = TimMenu.Dropdown("Dropdown in Demo1", dropdownIndex1, options1)
		if changed1 then
			print("[Menudemo1] Dropdown selected: " .. options1[dropdownIndex1])
		end
		TimMenu.NextLine()

		comboState1, changed1 = TimMenu.Combo("Combo in Demo1", comboState1, options1)
		if changed1 then
			print("[Menudemo1] Combo selections:")
		end
		TimMenu.NextLine()

		TimMenu.Spacing(20) -- Add extra vertical space (custom amount)
		TimMenu.Text("Another line after custom spacing.")

		-- Tab control example
		selectedTab1, changed1 = TimMenu.TabControl("demo1_tabs", tabOptions1, selectedTab1)
		if changed1 then
			print("[Menudemo1] Tab changed to: " .. tabOptions1[selectedTab1])
		end
		TimMenu.NextLine()

		TimMenu.End()
	end
end

-- Correct callback registration for menudemo1
callbacks.Unregister("Draw", "Menudemo1_Draw")
callbacks.Register("Draw", "Menudemo1_Draw", OnDraw_Menudemo1)
