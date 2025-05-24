local WidgetBase = require("TimMenu.WidgetBase")
local Draw = require("TimMenu.Draw")

local function Button(win, label)
	assert(type(win) == "table", "Button: win must be a table")
	assert(type(label) == "string", "Button: label must be a string")

	-- Measure dimensions
	local textWidth, textHeight = WidgetBase.MeasureText(label)
	local padding = require("TimMenu.Globals").Style.ItemPadding
	local width = textWidth + (padding * 2)
	local height = textHeight + (padding * 2)

	-- Common widget setup
	local ctx = WidgetBase.Setup(win, "Button", label, width, height)

	-- Process interaction
	local hovered, pressed, clicked = WidgetBase.ProcessInteraction(ctx, false)

	-- Draw widget
	local state = WidgetBase.GetDrawState(hovered, pressed)
	Draw.WidgetBackground(win, ctx.absX, ctx.absY, ctx.width, ctx.height, state)
	Draw.WidgetText(win, ctx.absX + padding, ctx.absY + padding, label)

	return clicked
end

return Button
