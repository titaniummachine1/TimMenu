local Static = require("TimMenu.Static")
local WidgetStack = require("TimMenu.widgets.WidgetStack")  -- new widget stack

local Button = {}

-- Draws a button and fires its callback on click.
-- params: { x, y, width, height, label, callback }
function Button.Draw(params)
	-- Use provided coordinates or get them from the widget stack
	local pos = WidgetStack.top()
	local x = params.x or pos.x
	local y = params.y or pos.y
	local width = params.width or 100
	local height = params.height or 30
	local label = params.label or "Button"
	local callback = params.callback or function() end

	-- Check mouse hover
	local mX, mY = table.unpack(input.GetMousePos())
	local hovered = mX >= x and mX <= x + width and mY >= y and mY <= y + height

	if hovered then
		draw.Color(table.unpack(Static.Colors.ButtonHover or {60, 60, 60, 255}))
	else
		draw.Color(table.unpack(Static.Colors.Button or {50, 50, 50, 255}))
	end
	draw.FilledRect(x, y, x + width, y + height)

	-- Draw label
	draw.Color(255, 255, 255, 255)
	local txtWidth, txtHeight = draw.GetTextSize(label)
	local textX = x + (width - txtWidth) / 2
	local textY = y + (height - txtHeight) / 2
	draw.Text(textX, textY, label)

	-- Simple click detection
	local clicked = hovered and input.IsButtonDown(MOUSE_LEFT) and not input.WasButtonDown(MOUSE_LEFT)
	if clicked then
		callback()
	end

	return hovered, clicked
end

return Button
