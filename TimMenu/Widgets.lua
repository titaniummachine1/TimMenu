local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Utils = require("TimMenu.Utils")

local Widgets = {}

-- Track last pressed state per widget key to debounce clicks
local lastPressState = {}

-- Track last pressed state per button key to debounce clicks
local buttonPressState = {}

-- Helper function to check if a point is within bounds
local function isInBounds(x, y, bounds)
	return x >= bounds.x and x <= bounds.x + bounds.w and y >= bounds.y and y <= bounds.y + bounds.h
end

-- Helper to check if widget can be interacted with
local function canInteract(win, bounds)
	-- Only allow interaction if the mouse is within this widget and not blocked by windows above
	local mX, mY = table.unpack(input.GetMousePos())
	if not isInBounds(mX, mY, bounds) then
		return false
	end
	if Utils.IsPointBlocked(TimMenuGlobal.order, TimMenuGlobal.windows, mX, mY, win.id) then
		return false
	end
	return true
end

function Widgets.Button(win, label)
	-- Calculate dimensions
	draw.SetFont(Globals.Style.Font)
	local textWidth, textHeight = draw.GetTextSize(label)
	local padding = Globals.Style.ItemPadding
	local width = textWidth + (padding * 2)
	local height = textHeight + (padding * 2)

	-- Handle padding between widgets
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + padding
	end

	-- Get widget position
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- Define bounds for interaction checking
	local bounds = {
		x = absX,
		y = absY,
		w = width,
		h = height,
	}

	-- Handle interaction
	local hovered = canInteract(win, bounds)
	local key = tostring(win.id) .. ":" .. label
	local clicked = false
	-- On press (edge-trigger), fire click immediately
	if hovered and input.IsButtonPressed(MOUSE_LEFT) and not buttonPressState[key] then
		clicked = true
		buttonPressState[key] = true
	end
	-- Reset when mouse button is fully released
	if buttonPressState[key] and not input.IsButtonDown(MOUSE_LEFT) then
		buttonPressState[key] = false
	end

	-- Queue drawing
	win:QueueDrawAtLayer(2, function()
		-- Determine background color: pressed > hovered > normal
		local bgColor = hovered and { 100, 100, 100, 255 } or { 80, 80, 80, 255 }
		if buttonPressState[key] then
			bgColor = { 120, 120, 120, 255 }
		end
		draw.Color(table.unpack(bgColor))
		-- Round button background rectangle
		draw.FilledRect(math.floor(absX), math.floor(absY), math.floor(absX + width), math.floor(absY + height))
		-- Draw label text in white at integer position
		draw.Color(255, 255, 255, 255)
		draw.Text(math.floor(absX + padding), math.floor(absY + padding), label)
	end)

	return clicked
end

--- Draws a checkbox widget within a window
--- @param win table current window object
--- @param label string text label for the checkbox
--- @param state boolean current checkbox state
--- @return boolean new state after click
function Widgets.Checkbox(win, label, state)
	-- Font and sizing
	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(label)
	local padding = Globals.Style.ItemPadding
	local boxSize = txtH
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
	local hovered = canInteract(win, bounds)

	-- Debounce: immediate toggle on press, reset on release
	local key = tostring(win.id) .. ":" .. label
	local clicked = false
	-- On press, toggle immediately (edge-trigger)
	if hovered and input.IsButtonPressed(MOUSE_LEFT) and not lastPressState[key] then
		state = not state
		clicked = true
		lastPressState[key] = true
	end
	-- Reset once the button is fully released
	if lastPressState[key] and not input.IsButtonDown(MOUSE_LEFT) then
		lastPressState[key] = false
	end

	-- Queue drawing
	win:QueueDrawAtLayer(2, function()
		-- Draw box outline
		draw.Color(255, 255, 255, 255)
		-- Outline the checkbox at integer coordinates
		draw.OutlinedRect(math.floor(absX), math.floor(absY), math.floor(absX + boxSize), math.floor(absY + boxSize))
		-- Fill check if checked at integer coordinates
		if state then
			draw.Color(255, 255, 255, 255)
			draw.FilledRect(
				math.floor(absX + 2),
				math.floor(absY + 2),
				math.floor(absX + boxSize - 2),
				math.floor(absY + boxSize - 2)
			)
		end
		-- Draw label text at integer position
		draw.Color(255, 255, 255, 255)
		draw.Text(math.floor(absX + boxSize + padding), math.floor(absY + (boxSize // 2) - (txtH // 2)), label)
	end)

	return state, clicked
end

--- Draws a slider widget, returning the new value and whether it changed.
function Widgets.Slider(win, label, value, min, max, step)
	local Common = require("TimMenu.Common")
	local Globals = require("TimMenu.Globals")
	-- Set font and measure label
	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(label)
	local padding = Globals.Style.ItemPadding
	local height = txtH + (padding * 2)
	-- Determine slider width to fill remaining space
	local xOffset = win.cursorX
	local width = math.max(Globals.Defaults.DEFAULT_W, win.W) - xOffset - Globals.Defaults.WINDOW_CONTENT_PADDING
	if width < txtW + (padding * 4) then
		width = txtW + (padding * 4)
	end
	-- Handle spacing
	if xOffset > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + padding
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- Track dimensions
	local trackX = absX + txtW + padding
	local trackY = absY + padding + math.floor((txtH - 4) / 2)
	local trackW = width - (txtW + (padding * 3))
	local trackH = 4
	-- Handle size and position
	local handleSize = txtH
	local norm = (value - min) / (max - min)
	if norm < 0 then
		norm = 0
	elseif norm > 1 then
		norm = 1
	end
	local handleX = trackX + (trackW * norm) - (handleSize / 2)
	local handleY = absY + padding

	-- Interaction logic
	local mX, mY = table.unpack(input.GetMousePos())
	local hovered = (mX >= trackX and mX <= trackX + trackW and mY >= absY and mY <= absY + height)
	local pressed = input.IsButtonPressed(MOUSE_LEFT)
	local down = input.IsButtonDown(MOUSE_LEFT)
	local key = tostring(win.id) .. ":" .. label
	Widgets._sliderDragging = Widgets._sliderDragging or {}
	local dragging = Widgets._sliderDragging[key] or false
	if hovered and pressed then
		dragging = true
	elseif not down then
		dragging = false
	end
	Widgets._sliderDragging[key] = dragging

	local changed = false
	if dragging then
		local t = (mX - trackX) / trackW
		if t < 0 then
			t = 0
		elseif t > 1 then
			t = 1
		end
		local raw = min + ((max - min) * t)
		local stepped = min + (Common.Clamp((raw - min) / step) * step)
		if stepped < min then
			stepped = min
		elseif stepped > max then
			stepped = max
		end
		if stepped ~= value then
			value = stepped
			changed = true
		end
	end

	-- Queue drawing layers
	win:QueueDrawAtLayer(1, function()
		-- Label
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		-- Draw label at integer position
		draw.Text(math.floor(absX), math.floor(absY + padding), label)
		-- Track background at integer bounds
		draw.Color(table.unpack(Globals.Colors.Item))
		draw.FilledRect(
			math.floor(trackX),
			math.floor(trackY),
			math.floor(trackX + trackW),
			math.floor(trackY + trackH)
		)
	end)
	win:QueueDrawAtLayer(2, function()
		local color = Globals.Colors.Item
		if dragging then
			color = Globals.Colors.ItemActive
		elseif hovered then
			color = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(color))
		-- Draw handle at integer coordinates
		draw.FilledRect(
			math.floor(handleX),
			math.floor(handleY),
			math.floor(handleX + handleSize),
			math.floor(handleY + handleSize)
		)
	end)

	return value, changed
end

return Widgets
