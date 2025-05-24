local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local DrawManager = require("TimMenu.DrawManager")

local Popup = {}

--- Begin a popup layout inside the current window.
--- @param win table Window object
--- @param x number Absolute x position of the popup
--- @param y number Absolute y position of the popup
--- @param w number Width of the popup
--- @param h number Height of the popup
function Popup.Begin(win, x, y, w, h)
	win._popupStack = win._popupStack or {}
	-- Auto-close any existing popup
	if #win._popupStack > 0 then
		Popup.End(win)
	end
	-- Save state
	local data = {
		bounds = { x = x, y = y, w = w, h = h },
		localX = 0,
		localY = 0,
		lineHeight = 0,
		origAdd = win.AddWidget,
		origNext = win.NextLine,
		origQueue = win.QueueDrawAtLayer,
		origCursorX = win.cursorX,
		origCursorY = win.cursorY,
		origLineHeight = win.lineHeight,
	}
	table.insert(win._popupStack, data)
	-- Override AddWidget for popup-local layout
	win.AddWidget = function(self, widgetW, widgetH)
		local relX = data.bounds.x - win.X + data.localX
		local relY = data.bounds.y - win.Y + data.localY
		data.localX = data.localX + widgetW + (Globals.Defaults.ITEM_SPACING or 0)
		data.lineHeight = math.max(data.lineHeight, widgetH)
		return relX, relY
	end
	-- Override NextLine for popup layout
	win.NextLine = function(self, spacing)
		spacing = spacing or Globals.Defaults.WINDOW_CONTENT_PADDING
		data.localY = data.localY + data.lineHeight + spacing
		data.localX = 0
		data.lineHeight = 0
	end
	-- Override drawing layers to render on top
	local layerBase = Globals.Layers.Popup + Globals.LayersPerGroup * 100
	win.QueueDrawAtLayer = function(self, layer, fn, ...)
		return data.origQueue(self, layerBase + layer, fn, ...)
	end
end

--- End the popup layout and draw its background and outline.
--- @param win table Window object
function Popup.End(win)
	if not win._popupStack or #win._popupStack == 0 then
		return
	end
	local data = table.remove(win._popupStack)
	-- Restore methods and cursor
	win.AddWidget = data.origAdd
	win.NextLine = data.origNext
	win.QueueDrawAtLayer = data.origQueue
	win.cursorX = data.origCursorX
	win.cursorY = data.origCursorY
	win.lineHeight = data.origLineHeight
	-- Draw popup frame on top layer
	local lb = Globals.Layers.Popup + Globals.LayersPerGroup * 100
	DrawManager.Enqueue(win.id, lb, function()
		Common.SetColor(Globals.Colors.Window)
		Common.DrawFilledRect(
			data.bounds.x,
			data.bounds.y,
			data.bounds.x + data.bounds.w,
			data.bounds.y + data.bounds.h
		)
		Common.SetColor(Globals.Colors.WindowBorder)
		Common.DrawOutlinedRect(
			data.bounds.x,
			data.bounds.y,
			data.bounds.x + data.bounds.w,
			data.bounds.y + data.bounds.h
		)
	end)
end

return Popup
