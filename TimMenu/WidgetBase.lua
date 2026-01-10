-- Widget Base Utility
-- Reduces common boilerplate in widget creation
local Globals = require("TimMenu.Globals")
local Interaction = require("TimMenu.Interaction")
local Tooltip = require("TimMenu.Widgets.Tooltip")
local ShapeUtils = require("TimMenu.ShapeUtils")

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

	-- Register click shape for precise hit testing
	win:AddClickShape(widgetKey, {
		type = "rectangle",
		x = absX,
		y = absY,
		w = width,
		h = height,
	}, 1, { widgetType = widgetType, label = label })

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

--- Processes widget interaction (hover, press, click) using shape-aware testing
---@param ctx table Widget context from Setup()
---@param isPopupOpen boolean Whether widget has an open popup
---@return boolean hovered, boolean pressed, boolean clicked
function WidgetBase.ProcessInteraction(ctx, isPopupOpen)
	return Interaction.Process(ctx.win, ctx.widgetKey, ctx.bounds, isPopupOpen or false)
end

--- Get the hover state using window's shape-aware hit testing
---@param win table Window object
---@param mouseX number Mouse X coordinate
---@param mouseY number Mouse Y coordinate
---@return string|nil shapeId, table|nil shapeData
function WidgetBase.GetHoveredPart(win, mouseX, mouseY)
	return win:GetClickShapeAt(mouseX, mouseY)
end

--- Register a custom click shape for a widget
---@param win table Window object
---@param widgetKey string Unique widget identifier
---@param shape table Shape definition
---@param focusWeight number Focus priority (optional, defaults to 1)
---@param metadata table Additional metadata (optional)
function WidgetBase.RegisterClickShape(win, widgetKey, shape, focusWeight, metadata)
	win:AddClickShape(widgetKey, shape, focusWeight, metadata)
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
