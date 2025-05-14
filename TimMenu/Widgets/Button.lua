local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")

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
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- Generate a unique ID for this button instance for stateful interaction
	-- win.id should be unique per window. label provides uniqueness within the window for the button.
	local widgetUniqueId = win.id .. "##Button##" .. label

	-- Process interaction using the new common function
	local areaRect = { x = absX, y = absY, w = width, h = height }
	local interactionState = Common.ProcessInteraction(widgetUniqueId, areaRect)

	win:QueueDrawAtLayer(2, function()
		local px, py = win.X + x, win.Y + y
		local bgColor = Globals.Colors.Item
		-- Use new interaction state for visual feedback
		if interactionState.isPressed then
			bgColor = Globals.Colors.ItemActive
		elseif interactionState.isHovered then
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

	-- Return true if the button was clicked this frame
	return interactionState.isClicked
end

return Button
