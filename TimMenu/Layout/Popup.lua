local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local DrawManager = require("TimMenu.DrawManager")

local Popup = {}

--- Creates a transient popup layout helper.
--- Widgets rendered while the popup is active should call methods on the returned layout.
--- @param win table Window object
--- @param x number Absolute x position of the popup
--- @param y number Absolute y position of the popup
--- @param w number Width of the popup
--- @param h number Height of the popup
--- @return table popupLayout
function Popup.Begin(win, x, y, w, h)
	local bounds = { x = x, y = y, w = w, h = h }
	local localX, localY, lineHeight = 0, 0, 0

	local layout = {}
	local layerBase = Globals.Layers.Popup + Globals.LayersPerGroup * 100

	function layout:AddWidget(widgetW, widgetH)
		local relX = bounds.x - win.X + localX
		local relY = bounds.y - win.Y + localY
		localX = localX + widgetW + (Globals.Defaults.ITEM_SPACING or 0)
		lineHeight = math.max(lineHeight, widgetH)
		return relX, relY
	end

	function layout:NextLine(spacing)
		spacing = spacing or Globals.Defaults.WINDOW_CONTENT_PADDING
		localY = localY + lineHeight + spacing
		localX = 0
		lineHeight = 0
	end

	function layout:QueueDraw(layer, fn, ...)
		DrawManager.Enqueue(win.id, layerBase + layer, fn, ...)
	end

	function layout:Close()
		DrawManager.Enqueue(win.id, layerBase, function()
			Common.SetColor(Globals.Colors.Window)
			Common.DrawFilledRect(bounds.x, bounds.y, bounds.x + bounds.w, bounds.y + bounds.h)
			Common.SetColor(Globals.Colors.WindowBorder)
			Common.DrawOutlinedRect(bounds.x, bounds.y, bounds.x + bounds.w, bounds.y + bounds.h)
		end)
	end

	return layout
end

return Popup
