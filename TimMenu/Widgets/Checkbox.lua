local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

local function canInteract(win, bounds)
	return Interaction.IsHovered(win, bounds)
end

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
	-- increase checkbox square to match button height (text height + vertical padding)
	local boxSize = txtH + (padding * 2)
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

	-- Debounce using Interaction helpers
	local key = tostring(win.id) .. ":" .. label .. ":" .. widgetIndex
	local clicked = false
	if hovered and Interaction.IsPressed(key) then
		state = not state
		clicked = true
	end
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(key)
	end

	win:QueueDrawAtLayer(2, function()
		local px, py = win.X + x, win.Y + y
		local bgColor = Globals.Colors.Item
		local active = hovered and input.IsButtonDown(MOUSE_LEFT)
		if active then
			bgColor = Globals.Colors.ItemActive
		elseif hovered then
			bgColor = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(bgColor))
		Common.DrawFilledRect(px, py, px + boxSize, py + boxSize)

		-- Outline
		draw.Color(table.unpack(Globals.Colors.WidgetOutline))
		Common.DrawOutlinedRect(px, py, px + boxSize, py + boxSize)

		-- Check mark fill
		if state then
			draw.Color(table.unpack(Globals.Colors.Highlight))
			local margin = math.floor(boxSize * 0.25)
			Common.DrawFilledRect(px + margin, py + margin, px + boxSize - margin, py + boxSize - margin)
		end
		-- Text label
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		Common.DrawText(px + boxSize + padding, py + (boxSize // 2) - (txtH // 2), label)
	end)

	return state, clicked
end

return Checkbox
