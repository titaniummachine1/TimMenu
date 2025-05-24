-- Widget Base Utility
-- Reduces common boilerplate in widget creation
local Globals = require("TimMenu.Globals")
local Interaction = require("TimMenu.Interaction")
local Tooltip = require("TimMenu.Widgets.Tooltip")

local WidgetBase = {}

--- Handles common widget setup: counter, spacing, positioning, bounds
---@param win table Window object
---@param widgetType string Widget type name (for unique keys)
---@param label string Widget label/identifier
---@param width number Widget width
---@param height number Widget height
---@return table context Object with widget context data
function WidgetBase.Setup(win, widgetType, label, width, height)
	-- Increment widget counter
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter

	-- Handle horizontal spacing between widgets
	local padding = Globals.Style.ItemPadding
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + padding
	end

	-- Get widget position from layout system
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- Create unique widget key
	local widgetKey = win.id .. ":" .. widgetType .. ":" .. label .. ":" .. widgetIndex

	-- Widget bounds for interaction and tooltips
	local bounds = { x = absX, y = absY, w = width, h = height }

	-- Store bounds for tooltip detection
	Tooltip.StoreWidgetBounds(win, widgetIndex, bounds)

	return {
		win = win,
		widgetIndex = widgetIndex,
		widgetKey = widgetKey,
		bounds = bounds,
		x = x,
		y = y,
		absX = absX,
		absY = absY,
		width = width,
		height = height,
		padding = padding,
	}
end

--- Processes widget interaction (hover, press, click)
---@param ctx table Widget context from Setup()
---@param isPopupOpen boolean Whether widget has an open popup
---@return boolean hovered, boolean pressed, boolean clicked
function WidgetBase.ProcessInteraction(ctx, isPopupOpen)
	return Interaction.Process(ctx.win, ctx.widgetKey, ctx.bounds, isPopupOpen or false)
end

--- Gets interaction state as a string for drawing
---@param hovered boolean Whether widget is hovered
---@param pressed boolean Whether widget is pressed
---@return string state "normal", "hover", or "active"
function WidgetBase.GetDrawState(hovered, pressed)
	if pressed then
		return "active"
	elseif hovered then
		return "hover"
	else
		return "normal"
	end
end

--- Common text measurement with current font
---@param text string Text to measure
---@return number width, number height
function WidgetBase.MeasureText(text)
	draw.SetFont(Globals.Style.Font)
	return draw.GetTextSize(text)
end

return WidgetBase
