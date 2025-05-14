local Globals = require("TimMenu.Globals")
local DrawManager = require("TimMenu.DrawManager") -- EndSector will need this
local Common = require("TimMenu.Common") -- EndSector might need this for DrawLine etc.

local Sector = {}

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
	local sector = {
		startX = startX,
		startY = startY,
		maxX = stored and (startX + stored.width - pad) or startX,
		maxY = stored and (startY + stored.height - pad) or startY,
		label = label,
		padding = pad,
		origAdd = win.AddWidget, -- Store original AddWidget
	}
	table.insert(win._sectorStack, sector)

	-- override AddWidget & NextLine to track extents within this sector
	sector.origNext = win.NextLine -- Store original NextLine
	win.AddWidget = function(self, w, h)
		local x, y = sector.origAdd(self, w, h)
		-- track widest and tallest widget positions relative to window origin
		sector.maxX = math.max(sector.maxX, x + w)
		sector.maxY = math.max(sector.maxY, y + h)
		return x, y
	end

	win.NextLine = function(self, spacing)
		-- Call original to handle vertical advance and line height
		sector.origNext(self, spacing)
		-- Crucially, reset cursorX to the sector's indented start position
		self.cursorX = sector.startX + sector.padding
		-- track y position after line break relative to window origin
		sector.maxY = math.max(sector.maxY, self.cursorY + self.lineHeight)
	end

	-- indent cursor for sector padding
	win.cursorX = sector.startX + sector.padding
	win.cursorY = sector.startY + sector.padding
end

function Sector.End(win)
	if not win._sectorStack or #win._sectorStack == 0 then
		return
	end

	-- Compute depth before popping
	local depth = #win._sectorStack
	-- Capture the sector table before removing it
	local sector = win._sectorStack[depth]
	-- pop last sector
	table.remove(win._sectorStack)

	-- restore AddWidget and NextLine
	win.AddWidget = sector.origAdd
	win.NextLine = sector.origNext
	local pad = sector.padding

	-- compute sector dimensions (+padding)
	local width = (sector.maxX - sector.startX) + pad
	local height = (sector.maxY - sector.startY) + pad

	-- ensure minimum width to fit header label plus padding
	if type(sector.label) == "string" then
		draw.SetFont(Globals.Style.Font) -- Ensure Globals is accessible or font is passed
		local lw, lh = draw.GetTextSize(sector.label)
		local minW = lw + (pad * 2)
		if width < minW then
			width = minW
		end
	end

	-- store persistent sector size to avoid shrinking below max content size
	win._sectorSizes = win._sectorSizes or {}
	local prev = win._sectorSizes[sector.label]
	if not prev or width > prev.width or height > prev.height then -- Update if wider or taller
		win._sectorSizes[sector.label] = { width = width, height = height }
	end

	-- *** Explicitly update window bounds to contain this sector ***
	local requiredW = sector.startX + width + sector.padding -- Sector start + width + right padding
	local requiredH = sector.startY + height + sector.padding -- Sector start + height + bottom padding
	win.W = math.max(win.W, requiredW)
	win.H = math.max(win.H, requiredH)

	local absX = win.X + sector.startX
	local absY = win.Y + sector.startY

	-- Prepare for background draw: capture variables local to this scope
	local captureStartX = sector.startX
	local captureStartY = sector.startY
	local captureW = prev and prev.width or ((sector.maxX - sector.startX) + sector.padding)
	local captureH = prev and prev.height or ((sector.maxY - sector.startY) + sector.padding)

	-- dynamic draw background behind sector, adjusting for nesting depth
	local backgroundLayer = 0.1 + (depth - 1) * 0.01
	DrawManager.Enqueue(win.id, backgroundLayer, function()
		local baseBgColor = Globals.Colors.SectorBackground
		local totalLighten = math.min(40, depth * 10)
		local finalR = math.min(255, baseBgColor[1] + totalLighten)
		local finalG = math.min(255, baseBgColor[2] + totalLighten)
		local finalB = math.min(255, baseBgColor[3] + totalLighten)
		local finalColor = { finalR, finalG, finalB, baseBgColor[4] }

		local x0 = win.X + captureStartX
		local y0 = win.Y + captureStartY
		draw.Color(table.unpack(finalColor))
		Common.DrawFilledRect(x0, y0, x0 + captureW, y0 + captureH) -- Requires Common
	end)

	-- dynamic draw border and optional header label
	local borderLayer = 2.1 + (depth - 1) * 0.01
	DrawManager.Enqueue(win.id, borderLayer, function()
		local x0 = win.X + sector.startX
		local y0 = win.Y + sector.startY
		local w0 = (sector.maxX - sector.startX) + sector.padding
		local h0 = (sector.maxY - sector.startY) + sector.padding
		local pad0 = sector.padding
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		if type(sector.label) == "string" then
			draw.SetFont(Globals.Style.Font)
			local tw, th = draw.GetTextSize(sector.label)
			local labelX = x0 + (w0 - tw) / 2
			local lineY = y0
			Common.DrawLine(x0, lineY, labelX - pad0, lineY) -- Requires Common
			draw.Color(table.unpack(Globals.Colors.Text))
			Common.DrawText(labelX, lineY - math.floor(th / 2), sector.label) -- Requires Common
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawLine(labelX + tw + pad0, lineY, x0 + w0, lineY) -- Requires Common
		else
			Common.DrawLine(x0, y0, x0 + w0, y0) -- Requires Common
		end
		Common.DrawLine(x0, y0 + h0, x0 + w0, y0 + h0) -- Requires Common
		Common.DrawLine(x0, y0, x0, y0 + h0) -- Requires Common
		Common.DrawLine(x0 + w0, y0, x0 + w0, y0 + h0) -- Requires Common
	end)

	-- move parent cursor to right of this sector (allow horizontal stacking)
	win.cursorX = sector.startX + width + pad
	win.cursorY = sector.startY

	-- Update window's layout state based on the ended sector
	win.lineHeight = math.max(win.lineHeight or 0, height)

	-- Update parent sector's bounds if nested
	if #win._sectorStack > 0 then
		local parentSector = win._sectorStack[#win._sectorStack]
		parentSector.maxX = math.max(parentSector.maxX, sector.startX + width)
		parentSector.maxY = math.max(parentSector.maxY, win.cursorY + win.lineHeight)
	end
end

-- EndSector function will be added next

return Sector
