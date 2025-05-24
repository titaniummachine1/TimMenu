local WidgetBase = require("TimMenu.WidgetBase")
local Draw = require("TimMenu.Draw")
local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")
local Tooltip = require("TimMenu.Widgets.Tooltip")

-- Internal drag state per-slider
local sliderDragState = {}

local function Slider(win, label, currentValue, minValue, maxValue, stepValue)
	assert(type(win) == "table", "Slider: win must be a table")
	assert(type(label) == "string", "Slider: label must be a string")
	assert(type(currentValue) == "number", "Slider: currentValue must be a number")
	assert(type(minValue) == "number", "Slider: minValue must be a number")
	assert(type(maxValue) == "number", "Slider: maxValue must be a number")
	assert(type(stepValue) == "number", "Slider: stepValue must be a number")

	-- Assign a per-window unique index to avoid collisions in layout
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter

	-- Measure and layout
	draw.SetFont(Globals.Style.Font)
	local labelText = label .. ": " .. tostring(currentValue)
	local txtW, txtH = draw.GetTextSize(labelText)
	local padding = Globals.Style.ItemPadding
	local height = txtH + (padding * 2)
	local width = Globals.Defaults.SLIDER_WIDTH

	-- Ensure minimum width to fit text
	if width < txtW + (padding * 4) then
		width = txtW + (padding * 4)
	end

	-- Handle horizontal spacing between widgets
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + padding
	end

	-- Get widget position from layout system
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- Normalize current value
	local normalizedValue = (currentValue - minValue) / (maxValue - minValue)
	normalizedValue = math.min(1, math.max(0, normalizedValue))

	-- Unified interaction processing
	local widgetKey = win.id .. ":slider:" .. label .. ":" .. widgetIndex
	local bounds = { x = absX, y = absY, w = width, h = height }
	local hovered, down, clicked = Interaction.Process(win, widgetKey, bounds, false)

	-- Store widget bounds for tooltip detection
	Tooltip.StoreWidgetBounds(win, widgetIndex, bounds)

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
	local newValue = currentValue
	local changed = false
	if dragging then
		local t = math.min(1, math.max(0, (mX - absX) / width))
		local raw = minValue + ((maxValue - minValue) * t)
		local stepped = minValue + (Common.RoundNearest((raw - minValue) / stepValue) * stepValue)
		stepped = math.min(maxValue, math.max(minValue, stepped))
		if stepped ~= currentValue then
			newValue = stepped
			changed = true
			-- Update label text with new value
			labelText = label .. ": " .. tostring(newValue)
			txtW, txtH = draw.GetTextSize(labelText)
		end
	end

	-- Recalculate normalized value with new value
	normalizedValue = (newValue - minValue) / (maxValue - minValue)
	normalizedValue = math.min(1, math.max(0, normalizedValue))

	-- Draw slider using layered drawing system
	local px, py = win.X + x, win.Y + y

	-- Draw slider background at its background layer
	local bgColor = hovered and Globals.Colors.ItemHover or Globals.Colors.Item
	Common.QueueRect(win, Globals.Layers.WidgetBackground, px, py, px + width, py + height, bgColor, nil)

	-- Draw fill at its fill layer
	local fillColor = dragging and Globals.Colors.HighlightActive or Globals.Colors.Highlight
	Common.QueueRect(
		win,
		Globals.Layers.WidgetFill,
		px,
		py,
		px + (width * normalizedValue),
		py + height,
		fillColor,
		nil
	)

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

	-- Draw label text centered on the slider at its text layer
	Common.QueueText(
		win,
		Globals.Layers.WidgetText,
		px + (width - txtW) * 0.5,
		py + (height - txtH) * 0.5,
		labelText,
		Globals.Colors.Text
	)

	return newValue, changed
end

return Slider
