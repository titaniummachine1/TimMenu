local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

local function Button(win, label)
	assert(type(win) == "table", "Button: win must be a table")
	assert(type(label) == "string", "Button: label must be a string")

	-- Calculate dimensions
	draw.SetFont(Globals.Style.Font)
	local textWidth, textHeight = draw.GetTextSize(label)
	local padding = Globals.Style.ItemPadding
	local width = textWidth + (padding * 2)
	local height = textHeight + (padding * 2)

	-- Handle padding between widgets (This layout logic might better belong in Window:AddWidget or a layout manager)
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + padding
	end

	-- Get widget position
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- Unified interaction processing
	local widgetKey = win.id .. ":Button:" .. label .. ":" .. widgetIndex
	local bounds = { x = absX, y = absY, w = width, h = height }
	local hovered, pressed, clicked = Interaction.Process(win, widgetKey, bounds, false)

	-- Schedule button rectangle and text with Common.Queue* helpers
	local px, py = win.X + x, win.Y + y
	local bgColor = Globals.Colors.Item
	if pressed then
		bgColor = Globals.Colors.ItemActive
	elseif hovered then
		bgColor = Globals.Colors.ItemHover
	end

	-- Draw button background at WidgetBackground
	Common.QueueRect(win, Globals.Layers.WidgetBackground, px, py, px + width, py + height, bgColor)
	-- Draw button outline at WidgetOutline
	Common.QueueOutlinedRect(
		win,
		Globals.Layers.WidgetOutline,
		px,
		py,
		px + width,
		py + height,
		Globals.Colors.WindowBorder
	)
	-- Draw button text at WidgetText
	Common.QueueText(win, Globals.Layers.WidgetText, px + padding, py + padding, label, Globals.Colors.Text)

	return clicked
end

return Button
