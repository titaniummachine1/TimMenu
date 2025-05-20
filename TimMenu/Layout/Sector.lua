local Globals = require("TimMenu.Globals")
local DrawManager = require("TimMenu.DrawManager") -- EndSector will need this
local Common = require("TimMenu.Common") -- EndSector might need this for DrawLine etc.

local Sector = {}

-- Forward declaration for helper usage if needed, though likely not for static helpers

--[[----------------------------------------------------------------------------
-- Private Helper Functions for Sector.End
------------------------------------------------------------------------------]]

local function _calculateDimensions(sector_data, pad)
	local currentWidth = (sector_data.maxX - sector_data.startX) + pad
	local currentHeight = (sector_data.maxY - sector_data.startY) + pad

	if type(sector_data.label) == "string" then
		draw.SetFont(Globals.Style.Font)
		local lw, _ = draw.GetTextSize(sector_data.label)
		local minContentWidthForLabel = lw + (pad * 2)
		if currentWidth < minContentWidthForLabel then
			currentWidth = minContentWidthForLabel
		end
	end
	return currentWidth, currentHeight
end

local function _updatePersistentSize(win, sector_data, width, height)
	win._sectorSizes = win._sectorSizes or {}
	local persistent = win._sectorSizes[sector_data.label]
	if not persistent or width > persistent.width or height > persistent.height then
		win._sectorSizes[sector_data.label] = { width = width, height = height }
	end
	return win._sectorSizes[sector_data.label] -- Return the, possibly updated, persistent size
end

local function _updateWindowBounds(win, sector_data, width, height, pad)
	local requiredW = sector_data.startX + width + pad
	local requiredH = sector_data.startY + height + pad
	win.W = math.max(win.W, requiredW)
	win.H = math.max(win.H, requiredH)
end

local function _enqueueBackgroundDraw(win, sector_data, depth, persistentWidth, persistentHeight)
	local backgroundLayer = 0.1 + (depth - 1) * 0.01
	DrawManager.Enqueue(win.id, backgroundLayer, function()
		local baseBgColor = Globals.Colors.SectorBackground
		local totalLighten = math.min(40, depth * 10)
		local finalR = math.min(255, baseBgColor[1] + totalLighten)
		local finalG = math.min(255, baseBgColor[2] + totalLighten)
		local finalB = math.min(255, baseBgColor[3] + totalLighten)
		local finalColor = { finalR, finalG, finalB, baseBgColor[4] }

		local x0 = win.X + sector_data.startX
		local y0 = win.Y + sector_data.startY
		Common.SetColor(finalColor)
		Common.DrawFilledRect(x0, y0, x0 + persistentWidth, y0 + persistentHeight)
	end)
end

local function _enqueueBorderDraw(win, sector_data, depth, persistentWidth, persistentHeight)
	local borderLayer = 2.1 + (depth - 1) * 0.01
	DrawManager.Enqueue(win.id, borderLayer, function()
		local x0 = win.X + sector_data.startX
		local y0 = win.Y + sector_data.startY
		local w0 = persistentWidth
		local h0 = persistentHeight
		local pad0 = sector_data.padding

		Common.SetColor(Globals.Colors.WindowBorder)
		if type(sector_data.label) == "string" then
			draw.SetFont(Globals.Style.Font)
			local tw, th = draw.GetTextSize(sector_data.label)
			local labelX = x0 + (w0 - tw) / 2
			local lineY = y0
			Common.DrawLine(x0, lineY, labelX - pad0, lineY)
			Common.SetColor(Globals.Colors.Text)
			Common.DrawText(labelX, lineY - math.floor(th / 2), sector_data.label)
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

local function _finalizeCursorAndLayout(win, sector_data, width, height, pad)
	win.cursorX = sector_data.startX + width + pad
	win.cursorY = sector_data.startY
	win.lineHeight = math.max(win.lineHeight or 0, height)

	if #win._sectorStack > 0 then
		local parentSector = win._sectorStack[#win._sectorStack]
		parentSector.maxX = math.max(parentSector.maxX, sector_data.startX + width)
		parentSector.maxY = math.max(parentSector.maxY, win.cursorY + win.lineHeight)
	end
end

--[[----------------------------------------------------------------------------
-- Public Sector API
------------------------------------------------------------------------------]]

function Sector.Begin(win, label)
	-- initialize sector stack if not already
	win._sectorStack = win._sectorStack or {}
	-- persistent storage for sector sizes
	win._sectorSizes = win._sectorSizes or {}

	-- capture current cursor as sector origin
	local startX, startY = win.cursorX, win.cursorY
	local pad = Globals.Defaults.WINDOW_CONTENT_PADDING

	-- restore previous max extents if available
	local stored = win._sectorSizes[label]
	local sector_data = {
		startX = startX,
		startY = startY,
		maxX = stored and (startX + stored.width - pad) or startX,
		maxY = stored and (startY + stored.height - pad) or startY,
		label = label,
		padding = pad,
		origAdd = win.AddWidget, -- Store original AddWidget
	}
	table.insert(win._sectorStack, sector_data)

	-- override AddWidget & NextLine to track extents within this sector
	sector_data.origNext = win.NextLine -- Store original NextLine
	win.AddWidget = function(self, w, h)
		local x, y = sector_data.origAdd(self, w, h)
		-- track widest and tallest widget positions relative to window origin
		sector_data.maxX = math.max(sector_data.maxX, x + w)
		sector_data.maxY = math.max(sector_data.maxY, y + h)
		return x, y
	end

	win.NextLine = function(self, spacing)
		-- Call original to handle vertical advance and line height
		sector_data.origNext(self, spacing)
		-- Crucially, reset cursorX to the sector's indented start position
		self.cursorX = sector_data.startX + sector_data.padding
		-- track y position after line break relative to window origin
		sector_data.maxY = math.max(sector_data.maxY, self.cursorY + self.lineHeight)
	end

	-- indent cursor for sector padding
	win.cursorX = sector_data.startX + sector_data.padding
	win.cursorY = sector_data.startY + sector_data.padding
end

function Sector.End(win)
	if not win._sectorStack or #win._sectorStack == 0 then
		return
	end

	local depth = #win._sectorStack
	local sector_data = win._sectorStack[depth]
	table.remove(win._sectorStack)

	win.AddWidget = sector_data.origAdd
	win.NextLine = sector_data.origNext
	local pad = sector_data.padding

	local currentWidth, currentHeight = _calculateDimensions(sector_data, pad)
	local persistentSize = _updatePersistentSize(win, sector_data, currentWidth, currentHeight)
	_updateWindowBounds(win, sector_data, persistentSize.width, persistentSize.height, pad)

	-- Use persistent W/H for drawing to prevent flicker and maintain size
	_enqueueBackgroundDraw(win, sector_data, depth, persistentSize.width, persistentSize.height)
	_enqueueBorderDraw(win, sector_data, depth, persistentSize.width, persistentSize.height)

	-- Use calculated currentWidth/Height for layout/cursor updates, but persistent for drawing.
	_finalizeCursorAndLayout(win, sector_data, persistentSize.width, persistentSize.height, pad)
end

return Sector
