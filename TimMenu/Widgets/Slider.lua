local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

-- Internal drag state per-slider
local sliderDragState = {}

local function Slider(win, label, value, min, max, step)
	assert(type(win) == "table", "Slider: win must be a table")
	assert(type(label) == "string", "Slider: label must be a string")
	assert(type(value) == "number", "Slider: value must be a number")
	assert(type(min) == "number", "Slider: min must be a number")
	assert(type(max) == "number", "Slider: max must be a number")
	assert(type(step) == "number", "Slider: step must be a number")
	-- assign a per-window unique index to avoid collisions in layout
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter

	-- Measure and layout
	draw.SetFont(Globals.Style.Font)
	local labelText = label .. ": " .. tostring(value)
	local txtW, txtH = draw.GetTextSize(labelText)
	local padding = Globals.Style.ItemPadding
	local height = txtH + (padding * 2)
	local width = Globals.Defaults.SLIDER_WIDTH
	if width < txtW + (padding * 4) then
		width = txtW + (padding * 4)
	end
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + padding
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- Normalize current value
	local norm = (value - min) / (max - min)
	norm = math.min(1, math.max(0, norm))

	-- Unified interaction processing
	local widgetKey = win.id .. ":slider:" .. label .. ":" .. widgetIndex
	local hovered, down, clicked =
		Interaction.Process(win, widgetKey, { x = absX, y = absY, w = width, h = height }, false)
	-- Retrieve mouse position for dragging computations
	local mX, mY = table.unpack(input.GetMousePos())
	local dragging = sliderDragState[widgetKey] or false
	if clicked then
		dragging = true
	elseif not down then
		dragging = false
	end
	sliderDragState[widgetKey] = dragging

	-- Compute new stepped value
	local changed = false
	if dragging then
		local t = math.min(1, math.max(0, (mX - absX) / width))
		local raw = min + ((max - min) * t)
		local stepped = min + (Common.RoundNearest((raw - min) / step) * step)
		stepped = math.min(max, math.max(min, stepped))
		if stepped ~= value then
			value = stepped
			changed = true
		end
	end

	-- Draw slider background at its background layer
	local px, py = win.X + x, win.Y + y
	local bgColor = hovered and Globals.Colors.ItemHover or Globals.Colors.Item
	Common.QueueRect(win, Globals.Layers.WidgetBackground, px, py, px + width, py + height, bgColor)
	-- Draw fill at its fill layer
	local fillColor = dragging and Globals.Colors.HighlightActive or Globals.Colors.Highlight
	Common.QueueRect(win, Globals.Layers.WidgetFill, px, py, px + (width * norm), py + height, fillColor)
	-- Draw outline at its outline layer
	Common.QueueOutlinedRect(
		win,
		Globals.Layers.WidgetOutline,
		px,
		py,
		px + width,
		py + height,
		Globals.Colors.WindowBorder
	)
	-- Draw label text at its text layer
	Common.QueueText(
		win,
		Globals.Layers.WidgetText,
		px + (width - txtW) * 0.5,
		py + (height - txtH) * 0.5,
		labelText,
		Globals.Colors.Text
	)

	return value, changed
end

return Slider
