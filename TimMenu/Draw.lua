-- Simplified Drawing API
-- Makes it immediately clear what drawing functions to use
local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")

local Draw = {}

--- Draw a filled rectangle (most common widget background)
---@param win table Window object
---@param layer number Draw layer
---@param x number Left position
---@param y number Top position
---@param w number Width
---@param h number Height
---@param color table Color {r,g,b,a}
function Draw.FilledRect(win, layer, x, y, w, h, color)
	Common.QueueRect(win, layer, x, y, x + w, y + h, color, nil)
end

--- Draw a rectangle with both fill and border
---@param win table Window object
---@param layer number Draw layer
---@param x number Left position
---@param y number Top position
---@param w number Width
---@param h number Height
---@param fillColor table Fill color {r,g,b,a}
---@param borderColor table Border color {r,g,b,a}
function Draw.BorderedRect(win, layer, x, y, w, h, fillColor, borderColor)
	Common.QueueRect(win, layer, x, y, x + w, y + h, fillColor, borderColor)
end

--- Draw just a rectangle outline (no fill)
---@param win table Window object
---@param layer number Draw layer
---@param x number Left position
---@param y number Top position
---@param w number Width
---@param h number Height
---@param color table Border color {r,g,b,a}
function Draw.OutlineRect(win, layer, x, y, w, h, color)
	Common.QueueOutlinedRect(win, layer, x, y, x + w, y + h, color)
end

--- Draw text at a position
---@param win table Window object
---@param layer number Draw layer
---@param x number X position
---@param y number Y position
---@param text string Text to draw
---@param color table Text color {r,g,b,a}
function Draw.Text(win, layer, x, y, text, color)
	Common.QueueText(win, layer, x, y, text, color)
end

--- Draw a line between two points
---@param win table Window object
---@param layer number Draw layer
---@param x1 number Start X
---@param y1 number Start Y
---@param x2 number End X
---@param y2 number End Y
---@param color table Line color {r,g,b,a}
function Draw.Line(win, layer, x1, y1, x2, y2, color)
	Common.QueueLine(win, layer, x1, y1, x2, y2, color)
end

--- Quick widget background (fill + outline)
---@param win table Window object
---@param x number Left position
---@param y number Top position
---@param w number Width
---@param h number Height
---@param state string Widget state: "normal", "hover", "active"
function Draw.WidgetBackground(win, x, y, w, h, state)
	local fillColor = Globals.Colors.Item
	if state == "active" then
		fillColor = Globals.Colors.ItemActive
	elseif state == "hover" then
		fillColor = Globals.Colors.ItemHover
	end

	Draw.FilledRect(win, Globals.Layers.WidgetBackground, x, y, w, h, fillColor)
	Draw.OutlineRect(win, Globals.Layers.WidgetOutline, x, y, w, h, Globals.Colors.WindowBorder)
end

--- Quick widget text
---@param win table Window object
---@param x number X position
---@param y number Y position
---@param text string Text to draw
function Draw.WidgetText(win, x, y, text)
	Draw.Text(win, Globals.Layers.WidgetText, x, y, text, Globals.Colors.Text)
end

--- Quick highlight fill (for checkboxes, sliders, etc.)
---@param win table Window object
---@param x number Left position
---@param y number Top position
---@param w number Width
---@param h number Height
---@param active boolean Whether it's actively being used
function Draw.WidgetHighlight(win, x, y, w, h, active)
	local color = active and Globals.Colors.HighlightActive or Globals.Colors.Highlight
	Draw.FilledRect(win, Globals.Layers.WidgetFill, x, y, w, h, color)
end

return Draw
