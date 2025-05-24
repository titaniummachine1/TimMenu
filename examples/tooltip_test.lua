-- Simple tooltip test example
local TimMenu = require("TimMenu")

local function main()
	if TimMenu.Begin("Tooltip Test") then
		-- Button with tooltip
		if TimMenu.Button("Click Me") then
			print("Button clicked!")
		end
		TimMenu.Tooltip(
			"This is a simple button tooltip that demonstrates text wrapping when the description is longer than 40 characters"
		)

		TimMenu.NextLine()

		-- Checkbox with tooltip
		local checkboxState = TimMenu.Checkbox("Enable Feature", false)
		TimMenu.Tooltip("Toggle this checkbox to enable or disable the feature")

		TimMenu.NextLine()

		-- Text with tooltip
		TimMenu.Text("Hover over me")
		TimMenu.Tooltip("This is just static text with a tooltip")

		TimMenu.NextLine()

		-- Slider with tooltip
		local sliderValue = TimMenu.Slider("Volume", 50, 0, 100, 1)
		TimMenu.Tooltip("Adjust the volume level from 0 to 100")
	end
	TimMenu.End()
end

-- Register the callback
callbacks.Register("Draw", "TooltipTest", main)
