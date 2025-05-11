local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Utils = require("TimMenu.Utils")

local Widgets = {}

-- Track last pressed state per widget key to debounce clicks
local lastPressState = {}

-- Helper function to check if a point is within bounds
local function isInBounds(x, y, bounds)
	return x >= bounds.x and x <= bounds.x + bounds.w and y >= bounds.y and y <= bounds.y + bounds.h
end

-- Helper to check if widget can be interacted with
local function canInteract(win, bounds)
	-- First check if window is active
	if TimMenuGlobal.ActiveWindow ~= win.id then
		return false
	end

	local mX, mY = table.unpack(input.GetMousePos())

	-- Check if mouse is within bounds
	if not isInBounds(mX, mY, bounds) then
		return false
	end

	-- Check if point is blocked by any window above this one
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
	local clicked = hovered and input.IsButtonPressed(MOUSE_LEFT)

	-- Queue drawing
	win:QueueDrawAtLayer(2, function()
		draw.Color(table.unpack(hovered and { 100, 100, 100, 255 } or { 80, 80, 80, 255 }))
		draw.FilledRect(absX, absY, absX + width, absY + height)
		draw.Color(255, 255, 255, 255)
		draw.Text(absX + padding, absY + padding, label)
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

	-- Track last pressed state per widget key to debounce
	local key = tostring(win.id) .. ":" .. label
	-- On press, capture if clicked inside
	if hovered and input.IsButtonPressed(MOUSE_LEFT) then
		lastPressState[key] = true
	end
	local clicked = false
	-- On release, if we had captured press, toggle and clear
	if lastPressState[key] and input.IsButtonReleased(MOUSE_LEFT) then
		if hovered then
			state = not state
			clicked = true
		end
		lastPressState[key] = false
	end

	-- Queue drawing
	win:QueueDrawAtLayer(2, function()
		-- Draw box outline
		draw.Color(255, 255, 255, 255)
		draw.OutlinedRect(absX, absY, absX + boxSize, absY + boxSize)
		-- Fill check if checked
		if state then
			draw.Color(255, 255, 255, 255)
			draw.FilledRect(absX + 2, absY + 2, absX + boxSize - 2, absY + boxSize - 2)
		end
		-- Draw label text
		draw.Color(255, 255, 255, 255)
		draw.Text(absX + boxSize + padding, absY + (boxSize // 2) - (txtH // 2), label)
	end)

	return state, clicked
end

return Widgets
