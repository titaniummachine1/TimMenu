local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

local function canInteract(win, bounds)
	return Interaction.IsHovered(win, bounds)
end

local function Button(win, label)
	assert(type(win) == "table", "Button: win must be a table")
	assert(type(label) == "string", "Button: label must be a string")
	-- assign a per-window unique index to avoid collisions
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter
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

	-- Interaction bounds
	local bounds = { x = absX, y = absY, w = width, h = height }
	local hovered = canInteract(win, bounds)
	local key = tostring(win.id) .. ":" .. label .. ":" .. widgetIndex
	local clicked = hovered and Interaction.IsPressed(key)
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(key)
	end

	win:QueueDrawAtLayer(2, function()
		local px, py = win.X + x, win.Y + y
		local bgColor = Globals.Colors.Item
		if Interaction._PressState[key] then
			bgColor = Globals.Colors.ItemActive
		elseif hovered then
			bgColor = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(bgColor))
		Common.DrawFilledRect(px, py, px + width, py + height)
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawOutlinedRect(px, py, px + width, py + height)
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		Common.DrawText(px + padding, py + padding, label)
	end)

	return clicked
end

return Button
