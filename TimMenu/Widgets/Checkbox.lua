local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

local function Checkbox(win, label, state)
	assert(type(win) == "table", "Checkbox: win must be a table")
	assert(type(label) == "string", "Checkbox: label must be a string")
	assert(type(state) == "boolean", "Checkbox: state must be a boolean")
	-- assign a per-window unique index to avoid collisions
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter
	-- Font and sizing
	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(label)
	local padding = Globals.Style.ItemPadding
	-- Use Globals.Style.ItemSize for the checkbox square's base size
	local boxSize = Globals.Style.ItemSize + (padding * 2)
	local width = boxSize + padding + txtW
	local height = boxSize

	-- Horizontal spacing between widgets
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + padding
	end

	-- Widget position
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- Interaction bounds
	local bounds = { x = absX, y = absY, w = width, h = height }
	-- Unified interaction processing
	local widgetKey = win.id .. ":Checkbox:" .. label .. ":" .. widgetIndex
	local hovered, pressed, clicked = Interaction.Process(win, widgetKey, bounds, false)
	if clicked then
		state = not state
	end

	-- Draw checkbox background at WidgetBackground
	local px, py = win.X + x, win.Y + y
	local bgColor = Globals.Colors.Item
	if pressed then
		bgColor = Globals.Colors.ItemActive
	elseif hovered then
		bgColor = Globals.Colors.ItemHover
	end
	Common.QueueRect(win, Globals.Layers.WidgetBackground, px, py, px + boxSize, py + boxSize, bgColor)
	-- Draw checkmark fill at WidgetFill if checked
	if state then
		local margin = math.floor(boxSize * 0.25)
		Common.QueueRect(
			win,
			Globals.Layers.WidgetFill,
			px + margin,
			py + margin,
			px + boxSize - margin,
			py + boxSize - margin,
			Globals.Colors.Highlight
		)
	end
	-- Draw checkbox outline with stronger WindowBorder color
	Common.QueueOutlinedRect(
		win,
		Globals.Layers.WidgetOutline,
		px,
		py,
		px + boxSize,
		py + boxSize,
		Globals.Colors.WindowBorder
	)
	-- Draw label text at WidgetText
	Common.QueueText(
		win,
		Globals.Layers.WidgetText,
		px + boxSize + padding,
		py + (boxSize // 2) - (txtH // 2),
		label,
		Globals.Colors.Text
	)

	return state, clicked
end

return Checkbox
