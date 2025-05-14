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

	-- Interaction logic
	local mX, mY = table.unpack(input.GetMousePos())
	local hovered = Interaction.IsHovered(win, { x = absX, y = absY, w = width, h = height })
	local pressed = input.IsButtonPressed(MOUSE_LEFT)
	local down = input.IsButtonDown(MOUSE_LEFT)
	local key = tostring(win.id) .. ":slider:" .. label
	local dragging = sliderDragState[key] or false
	if hovered and pressed then
		dragging = true
	elseif not down then
		dragging = false
	end
	sliderDragState[key] = dragging

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

	-- Draw slider
	win:QueueDrawAtLayer(2, function(hv)
		local px, py = win.X + x, win.Y + y
		local bg = hv and Globals.Colors.ItemHover or Globals.Colors.Item
		draw.Color(table.unpack(bg))
		Common.DrawFilledRect(px, py, px + width, py + height)
		local fillCol = dragging and Globals.Colors.HighlightActive or Globals.Colors.Highlight
		draw.Color(table.unpack(fillCol))
		Common.DrawFilledRect(px, py, px + (width * norm), py + height)
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawOutlinedRect(px, py, px + width, py + height)
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		Common.DrawText(px + (width - txtW) * 0.5, py + (height - txtH) * 0.5, labelText)
	end, hovered)

	return value, changed
end

return Slider
