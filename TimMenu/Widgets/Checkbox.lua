local WidgetBase = require("TimMenu.WidgetBase")
local Draw = require("TimMenu.Draw")
local Globals = require("TimMenu.Globals")

local function Checkbox(win, label, currentState)
	assert(type(win) == "table", "Checkbox: win must be a table")
	assert(type(label) == "string", "Checkbox: label must be a string")
	assert(type(currentState) == "boolean", "Checkbox: currentState must be a boolean")

	-- Measure dimensions
	local textWidth, textHeight = WidgetBase.MeasureText(label)
	local padding = Globals.Style.ItemPadding
	local boxSize = textHeight + (padding * 2)
	local totalWidth = boxSize + padding + textWidth
	local height = math.max(boxSize, textHeight + (padding * 2))

	-- Common widget setup
	local ctx = WidgetBase.Setup(win, "Checkbox", label, totalWidth, height)

	-- Process interaction
	local hovered, pressed, clicked = WidgetBase.ProcessInteraction(ctx, false)

	-- Update state on click
	local newState = currentState
	if clicked then
		newState = not currentState
	end

	-- Draw checkbox box
	local state = WidgetBase.GetDrawState(hovered, pressed)
	Draw.WidgetBackground(win, ctx.absX, ctx.absY, boxSize, boxSize, state)

	-- Draw checkmark if checked
	if newState then
		local margin = 8
		Draw.WidgetHighlight(
			win,
			ctx.absX + margin,
			ctx.absY + margin,
			boxSize - (margin * 2),
			boxSize - (margin * 2),
			false
		)
	end

	-- Draw label text
	Draw.WidgetText(win, ctx.absX + boxSize + padding, ctx.absY + padding, label)

	return newState, clicked
end

return Checkbox
