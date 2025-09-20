-- Test for Menu Shrinking Fix
-- This example demonstrates that menus can now shrink when widgets are removed or hidden

local TimMenu = require("TimMenu")

-- Toggle states for different content (use global variables to persist across frames)
if showWideContent == nil then
	showWideContent = false
end
if showTallContent == nil then
	showTallContent = false
end
if showSector == nil then
	showSector = false
end
if selectedDropdown == nil then
	selectedDropdown = 1
end
if comboSelected == nil then
	comboSelected = { false, false, false }
end

local function ShrinkingTest()
	if TimMenu.Begin("Shrinking Test", true) then
		TimMenu.Text("Menu Shrinking Test")
		TimMenu.Text("Toggle content to see menu shrink/expand:")

		-- Toggles for different content types
		showWideContent = TimMenu.Checkbox("Show Wide Content", showWideContent)
		showTallContent = TimMenu.Checkbox("Show Tall Content", showTallContent)
		showSector = TimMenu.Checkbox("Show Sector", showSector)

		-- Add a dropdown and combo with tooltips
		local dropdownOptions = { "Option 1", "Option 2", "Option 3" }
		selectedDropdown = TimMenu.Dropdown("Test Dropdown", selectedDropdown, dropdownOptions)
		TimMenu.Tooltip("This is a tooltip for the dropdown!")

		comboSelected = TimMenu.Combo("Test Combo", comboSelected, dropdownOptions)
		TimMenu.Tooltip("This is a tooltip for the combo!")

		TimMenu.Separator()

		-- Wide content that expands menu horizontally
		if showWideContent then
			TimMenu.Text("This is some very long text that makes the menu much wider than normal")
			TimMenu.Button("Very Long Button Label That Expands Width")
		end

		-- Tall content that expands menu vertically
		if showTallContent then
			TimMenu.Text("Line 1")
			TimMenu.Text("Line 2")
			TimMenu.Text("Line 3")
			TimMenu.Text("Line 4")
			TimMenu.Text("Line 5")
			TimMenu.Text("Line 6")
			TimMenu.Text("Line 7")
			TimMenu.Text("Line 8")
		end

		-- Sector content that should also shrink
		if showSector then
			TimMenu.SectorBegin("Test Sector")
			TimMenu.Text("Content inside sector")
			if showWideContent then
				TimMenu.Text("Wide sector content that makes sector bigger")
				TimMenu.Button("Wide Sector Button")
			end
			if showTallContent then
				TimMenu.Text("Tall sector line 1")
				TimMenu.Text("Tall sector line 2")
				TimMenu.Text("Tall sector line 3")
			end
			TimMenu.SectorEnd()
		end

		TimMenu.Separator()
		TimMenu.Text("Notice how the menu shrinks when you")
		TimMenu.Text("disable content above!")

		TimMenu.End()
	end
end

-- Register the test
callbacks.Register("Draw", "ShrinkingTest", ShrinkingTest)

return ShrinkingTest
