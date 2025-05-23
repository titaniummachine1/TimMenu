-- menudemo1.lua
local TimMenu = require("TimMenu")

-- Script state
local cbState1 = false
local sliderVal1 = 25
local options1 = { "Option A", "Option B", "Option C" }
local selectedIndex1 = 1
local dropdownIndex1 = 1
local comboState1 = { false, false, false }
-- Keybind demo state
local bindKey1 = 0
-- Color picker demo state
local pickerColor1 = { 255, 0, 0, 255 }

-- TabControl demo state
local tabOptions1 = { "Tab 1", "Tab 2", "Tab 3" }
local selectedTab1 = 1

-- Showcase Tab State
local showcaseTabNames = { "Showcase Alpha", "Showcase Beta", "Showcase Gamma" }
local showcaseSelectedTab = 1
local showcaseCbX = false
local showcaseSliderP = 50
local showcaseKeyK = 0
local showcaseDropdownOptions = { "Opt D-One", "Opt D-Two", "Opt D-Three" }
local showcaseDropdownD = 1
local showcaseComboOptions = { "Item C-X", "Item C-Y", "Item C-Z" }
local showcaseComboC = { false, false, false }
local showcaseSelectorOptions = { "Sel Foo", "Sel Bar", "Sel Baz Qux" }
local showcaseSelectorS = 1
local showcaseTextT = "Edit this showcase text!"
local showcaseButtonClicks = 0

local function OnDraw_Menudemo1()
	if TimMenu.Begin("Demo Window 1") then
		-- NEW Showcase Header TabControl
		showcaseSelectedTab = TimMenu.TabControl("ShowcaseHeaderTabs", showcaseTabNames, showcaseSelectedTab, true)

		if showcaseSelectedTab == 1 then
			TimMenu.Text("Widgets in Showcase Alpha:")
			TimMenu.NextLine()
			showcaseCbX = TimMenu.Checkbox("Alpha Checkbox", showcaseCbX)
			TimMenu.Tooltip("Toggle this checkbox to test the widget functionality")
			TimMenu.SameLine()
			if TimMenu.Button("Alpha Button") then
				showcaseButtonClicks = showcaseButtonClicks + 1
			end
			TimMenu.Tooltip("Click me to increment the counter!")
			TimMenu.NextLine()
			showcaseSliderP = TimMenu.Slider("Alpha Slider", showcaseSliderP, 0, 200, 5)
			TimMenu.Tooltip("Drag this slider to adjust the value between 0 and 200")
			TimMenu.Text("Button Clicks: " .. showcaseButtonClicks)
			TimMenu.Separator()
		elseif showcaseSelectedTab == 2 then
			TimMenu.Text("Demonstrating more widgets in Beta:")
			TimMenu.NextLine()
			showcaseKeyK = TimMenu.Keybind("Beta Keybind", showcaseKeyK)
			TimMenu.Tooltip("Click to bind a key, then press any key to capture it")
			showcaseDropdownD = TimMenu.Dropdown("Beta Dropdown", showcaseDropdownD, showcaseDropdownOptions)
			TimMenu.Tooltip("Click to open dropdown and select an option")
			showcaseComboC = TimMenu.Combo("Beta Combo", showcaseComboC, showcaseComboOptions)
			TimMenu.Tooltip("Multi-selection box - toggle multiple options")
			TimMenu.Separator()
		elseif showcaseSelectedTab == 3 then
			TimMenu.Text("Input and Selection in Gamma:")
			TimMenu.NextLine()
			showcaseSelectorS = TimMenu.Selector("Gamma Selector", showcaseSelectorS, showcaseSelectorOptions)
			showcaseTextT = TimMenu.TextInput("Gamma Text Input", showcaseTextT)
			if TimMenu.Button("Gamma Action Button") then
				print("[Menudemo1] Gamma action button clicked!")
			end
			TimMenu.Separator()
		end
		TimMenu.NextLine() -- Ensure content below header tabs starts on a new line.

		-- Color Picker demonstration
		pickerColor1 = TimMenu.ColorPicker("Pick Color", pickerColor1)
		TimMenu.Tooltip("Click the color box to open the color picker")
		TimMenu.NextLine()

		-- First row: Demonstrate multiple widgets and alignment
		TimMenu.BeginSector("Multi-Widget Area")
		TimMenu.Text("Content in A")
		TimMenu.NextLine()
		cbState1 = TimMenu.Checkbox("Checkbox in A", cbState1)
		TimMenu.NextLine()
		TimMenu.Text("More text...")
		TimMenu.EndSector()

		TimMenu.BeginSector("Single Button")
		if TimMenu.Button("Button in B") then
			print("[Menudemo1] Button B clicked!")
		end
		TimMenu.EndSector()
		TimMenu.NextLine() -- End of the first row of sectors

		-- Nested Sector Example
		TimMenu.BeginSector("Nesting Container")
		TimMenu.Text("Inside Outer Container")
		TimMenu.NextLine()
		TimMenu.BeginSector("Nested Slider Area")
		sliderVal1 = TimMenu.Slider("Slider in Nested Area", sliderVal1, 0, 100, 5)
		TimMenu.Tooltip("This slider is nested inside a sector container")
		if TimMenu.Button("Action Button 1") then
			print("[Menudemo1] Action Button 1 clicked!")
		end
		if TimMenu.Button("Action Button 2") then
			print("[Menudemo1] Action Button 2 clicked!")
		end
		TimMenu.NextLine()
		if TimMenu.Button("Action Button 3") then
			print("[Menudemo1] Action Button 3 clicked!")
		end

		TimMenu.EndSector()
		TimMenu.NextLine()
		TimMenu.Text("Also inside Container")
		TimMenu.EndSector()
		TimMenu.NextLine() -- End of Nesting Container block

		-- Separator line (outside sectors)
		TimMenu.Separator()
		TimMenu.NextLine()

		-- Selector example using the dedicated widget (outside sectors)
		selectedIndex1 = TimMenu.Selector("Options Selector", selectedIndex1, options1)
		TimMenu.Tooltip("Use < > arrows or click left/right halves to cycle through options")

		TimMenu.NextLine()
		-- Dropdown example using the dedicated widget
		dropdownIndex1 = TimMenu.Dropdown("Dropdown in Demo1", dropdownIndex1, options1)
		TimMenu.Tooltip("Click to open dropdown and select an option")
		TimMenu.NextLine()

		comboState1 = TimMenu.Combo("Combo in Demo1", comboState1, options1)
		TimMenu.Tooltip("Multi-selection box - toggle multiple options")
		TimMenu.NextLine()

		TimMenu.Spacing(20) -- Add extra vertical space (custom amount)
		TimMenu.Text("Another line after custom spacing.")

		-- Tab control example
		selectedTab1 = TimMenu.TabControl("demo1_tabs", tabOptions1, selectedTab1)

		-- Keybind widget
		bindKey1 = TimMenu.Keybind("Demo1 Bind", bindKey1)

		TimMenu.NextLine()
	end
end

-- Correct callback registration for menudemo1
callbacks.Unregister("Draw", "Menudemo1_Draw")
callbacks.Register("Draw", "Menudemo1_Draw", OnDraw_Menudemo1)
