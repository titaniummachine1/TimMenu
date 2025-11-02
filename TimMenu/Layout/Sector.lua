local Globals = require("TimMenu.Globals")
local DrawManager = require("TimMenu.DrawManager") -- EndSector will need this
local Common = require("TimMenu.Common") -- EndSector might need this for DrawLine etc.

local Sector = {}

-- Spacing between rows of sectors (adjust this to change vertical gap)
local ROW_VERTICAL_GAP = Globals.Defaults.WINDOW_CONTENT_PADDING
-- Horizontal spacing after a sector completes (mirrors widget spacing)
local HORIZONTAL_ITEM_SPACING = Globals.Defaults.ITEM_SPACING or 0

--[[----------------------------------------------------------------------------
-- Private Helper Functions for Sector.End
------------------------------------------------------------------------------]]

local function _calculateDimensions(layoutState, pad)
	local currentWidth = (layoutState.maxX - layoutState.startX) + pad
	local currentHeight = (layoutState.maxY - layoutState.startY) + pad

	if type(layoutState.label) == "string" then
		draw.SetFont(Globals.Style.Font)
		local lw, _ = draw.GetTextSize(layoutState.label)
		local minContentWidthForLabel = lw + (pad * 2)
		if currentWidth < minContentWidthForLabel then
			currentWidth = minContentWidthForLabel
		end
	end
	return currentWidth, currentHeight
end

local function _registerRowEntry(win, layoutState, size)
	local row = layoutState.rowContext
	if not row then
		_prepareRowState(win, layoutState)
		row = layoutState.rowContext
	end

	table.insert(row.entries, size)

	if size.height > row.maxHeight then
		row.maxHeight = size.height
		for _, entry in ipairs(row.entries) do
			entry.height = row.maxHeight
		end
	else
		size.height = row.maxHeight
	end

	return row.maxHeight
end

local function _updatePersistentSize(win, layoutState, width, height)
	win._sectorSizes = win._sectorSizes or {}
	local persistent = win._sectorSizes[layoutState.label]
	-- Always update to current size to allow shrinking while keeping reference stable
	persistent = persistent or {}
	persistent.width = width
	persistent.height = height
	win._sectorSizes[layoutState.label] = persistent
	return persistent
end

local function _updateWindowBounds(win, layoutState, width, height, pad)
	local requiredW = layoutState.startX + width + pad
	local requiredH = layoutState.startY + height + pad
	win.W = math.max(win.W, requiredW)
	win.H = math.max(win.H, requiredH)
end

local function _enqueueBackgroundDraw(win, layoutState, depth, size)
	-- Use integer layers: each nested sector increments background layer
	local backgroundLayer = Globals.Layers.WidgetBackground + depth
	DrawManager.Enqueue(win.id, backgroundLayer, function()
		local baseBgColor = Globals.Colors.SectorBackground
		local totalLighten = math.min(40, depth * 10)
		local finalR = math.min(255, baseBgColor[1] + totalLighten)
		local finalG = math.min(255, baseBgColor[2] + totalLighten)
		local finalB = math.min(255, baseBgColor[3] + totalLighten)
		local finalColor = { finalR, finalG, finalB, baseBgColor[4] }

		local x0 = win.X + layoutState.startX
		local y0 = win.Y + layoutState.startY
		Common.SetColor(finalColor)
		Common.DrawFilledRect(x0, y0, x0 + size.width, y0 + size.height)
	end)
end

local function _enqueueBorderDraw(win, layoutState, depth, size)
	-- Use integer layers: each nested sector increments outline layer
	local borderLayer = Globals.Layers.WidgetOutline + depth
	DrawManager.Enqueue(win.id, borderLayer, function()
		local x0 = win.X + layoutState.startX
		local y0 = win.Y + layoutState.startY
		local w0 = size.width
		local h0 = size.height
		local pad0 = layoutState.padding

		Common.SetColor(Globals.Colors.WindowBorder)
		if type(layoutState.label) == "string" then
			draw.SetFont(Globals.Style.Font)
			local tw, th = draw.GetTextSize(layoutState.label)
			local labelX = x0 + (w0 - tw) / 2
			local lineY = y0
			Common.DrawLine(x0, lineY, labelX - pad0, lineY)
			Common.SetColor(Globals.Colors.Text)
			Common.DrawText(labelX, lineY - math.floor(th / 2), layoutState.label)
			Common.SetColor(Globals.Colors.WindowBorder)
			Common.DrawLine(labelX + tw + pad0, lineY, x0 + w0, lineY)
		else
			Common.DrawLine(x0, y0, x0 + w0, y0)
		end
		Common.DrawLine(x0, y0 + h0, x0 + w0, y0 + h0)
		Common.DrawLine(x0, y0, x0, y0 + h0)
		Common.DrawLine(x0 + w0, y0, x0 + w0, y0 + h0)
	end)
end

local function _finalizeCursorAndLayout(win, layoutState, width, rowHeight)
	-- Treat sector as a single widget occupying the computed width/height
	win.cursorX = layoutState.startX + width + HORIZONTAL_ITEM_SPACING
	win.cursorY = layoutState.startY
	win.lineHeight = math.max(layoutState.preLineHeight or 0, rowHeight + ROW_VERTICAL_GAP)

	if #win._sectorStack > 0 then
		local parentSector = win._sectorStack[#win._sectorStack]
		parentSector.maxX = math.max(parentSector.maxX, layoutState.startX + width)
		parentSector.maxY = math.max(parentSector.maxY, layoutState.startY + rowHeight)
	end
end

local function _prepareRowState(win, layoutState)
	win._sectorRows = win._sectorRows or {}
	local depth = #win._sectorStack
	local rows = win._sectorRows
	local padding = Globals.Defaults.WINDOW_CONTENT_PADDING

	local row = rows[depth]
	local startY = layoutState.startY
	local needsReset = false

	if not row then
		needsReset = true
	elseif math.abs(row.currentStartY - startY) > 0.5 then
		needsReset = true
	elseif layoutState.startX <= padding + 0.5 then
		needsReset = true
	end

	if needsReset then
		row = {
			currentStartY = startY,
			entries = {},
			maxHeight = 0,
		}
		rows[depth] = row
	else
		row.currentStartY = startY
	end

	layoutState.rowContext = row
end

--[[----------------------------------------------------------------------------
-- Public Sector API
------------------------------------------------------------------------------]]

function Sector.Begin(win, label)
	-- initialize sector stack if not already
	win._sectorStack = win._sectorStack or {}
	-- persistent storage for sector sizes
	win._sectorSizes = win._sectorSizes or {}

	-- Internal padding for content inside sector borders
	local pad = Globals.Defaults.WINDOW_CONTENT_PADDING
	-- Sector starts at current cursor position
	local startX, startY = win.cursorX, win.cursorY

	-- Start with current cursor position as initial extents (no stored sizes)
	-- Layout data tracks cursor origin, extents, and original functions
	local layoutState = {
		startX = startX,
		startY = startY,
		maxX = startX,
		maxY = startY,
		label = label,
		padding = pad,
		origAdd = win.AddWidget, -- Store original AddWidget
		preLineHeight = win.lineHeight,
	}
	table.insert(win._sectorStack, layoutState)
	_prepareRowState(win, layoutState)

	-- Reset lineHeight for clean sector start
	win.lineHeight = 0

	-- override AddWidget & NextLine to track extents within this sector
	layoutState.origNext = win.NextLine -- Store original NextLine
	win.AddWidget = function(self, w, h)
		local x, y = layoutState.origAdd(self, w, h)
		-- track widest and tallest widget positions relative to window origin
		layoutState.maxX = math.max(layoutState.maxX, x + w)
		layoutState.maxY = math.max(layoutState.maxY, y + h)
		return x, y
	end

	win.NextLine = function(self, spacing)
		-- Advance to next line within sector
		local baseSpacing = spacing or Globals.Defaults.WINDOW_CONTENT_PADDING
		self.cursorY = self.cursorY + self.lineHeight + baseSpacing
		-- Keep cursor aligned to sector's left edge
		self.cursorX = layoutState.startX + layoutState.padding
		-- Reset lineHeight for new line
		self.lineHeight = 0
	end

	-- indent cursor for sector padding
	win.cursorX = layoutState.startX + layoutState.padding
	win.cursorY = layoutState.startY + layoutState.padding

	-- Override QueueDrawAtLayer to apply per-sector layer offset
	local depth = #win._sectorStack
	local groupBase = depth * Globals.LayersPerGroup
	layoutState.origQueue = win.QueueDrawAtLayer
	win.QueueDrawAtLayer = function(self, layer, fn, ...)
		-- offset layer by groupBase for this sector
		return layoutState.origQueue(self, layer + groupBase, fn, ...)
	end
end

function Sector.End(win)
	if not win._sectorStack or #win._sectorStack == 0 then
		return
	end

	local depth = #win._sectorStack
	local layoutState = win._sectorStack[depth]
	table.remove(win._sectorStack)

	win.AddWidget = layoutState.origAdd
	win.NextLine = layoutState.origNext
	local pad = layoutState.padding

	local currentWidth, currentHeight = _calculateDimensions(layoutState, pad)
	local persistentSize = _updatePersistentSize(win, layoutState, currentWidth, currentHeight)
	local rowHeight = _registerRowEntry(win, layoutState, persistentSize)
	_updateWindowBounds(win, layoutState, persistentSize.width, persistentSize.height, pad)

	-- Enqueue sector background at relative layer 0
	_enqueueBackgroundDraw(win, layoutState, depth, persistentSize)
	-- Enqueue sector border at relative layer 1
	_enqueueBorderDraw(win, layoutState, depth, persistentSize)

	-- Restore original QueueDrawAtLayer
	win.QueueDrawAtLayer = layoutState.origQueue

	-- Use calculated currentWidth/Height for layout/cursor updates, but persistent for drawing.
	_finalizeCursorAndLayout(win, layoutState, persistentSize.width, rowHeight)
end

return Sector
