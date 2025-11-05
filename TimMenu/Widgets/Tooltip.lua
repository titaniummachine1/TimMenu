local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Popup = require("TimMenu.Layout.Popup")

local Tooltip = {}

local function pointInBounds(bounds, x, y)
	return x >= bounds.x and x <= bounds.x + bounds.w and y >= bounds.y and y <= bounds.y + bounds.h
end

local function isBlockedByPopup(win, x, y)
	local blockedRegions = win._widgetBlockedRegions
	if not blockedRegions then
		return false
	end
	for _, region in ipairs(blockedRegions) do
		if pointInBounds(region, x, y) then
			return true
		end
	end
	return false
end

--- Wraps text to multiple lines with a maximum line length
---@param text string The text to wrap
---@param maxLength number Maximum characters per line (default 40)
---@return table lines Array of wrapped text lines
local function wrapText(text, maxLength)
	maxLength = maxLength or 40
	local lines = {}
	local words = {}

	-- Split text into words
	for word in text:gmatch("%S+") do
		table.insert(words, word)
	end

	local currentLine = ""
	for i, word in ipairs(words) do
		local testLine = currentLine == "" and word or (currentLine .. " " .. word)

		if #testLine <= maxLength then
			currentLine = testLine
		else
			-- Add current line and start new one
			if currentLine ~= "" then
				table.insert(lines, currentLine)
			end
			currentLine = word
		end
	end

	-- Add the last line
	if currentLine ~= "" then
		table.insert(lines, currentLine)
	end

	-- Ensure at least one line
	if #lines == 0 then
		table.insert(lines, "")
	end

	return lines
end

--- Calculates tooltip dimensions for wrapped text
---@param lines table Array of text lines
---@return number width, number height
local function calculateTooltipSize(lines)
	draw.SetFont(Globals.Style.Font)
	local maxWidth = 0
	local totalHeight = 0
	local padding = Globals.Style.ItemPadding

	for _, line in ipairs(lines) do
		local w, h = draw.GetTextSize(line)
		maxWidth = math.max(maxWidth, w)
		totalHeight = totalHeight + h
	end

	-- Add padding and line spacing
	local lineSpacing = 2
	totalHeight = totalHeight + (lineSpacing * math.max(0, #lines - 1))

	return maxWidth + (padding * 2), totalHeight + (padding * 2)
end

--- Renders tooltip content using the popup system
---@param win table Window object
---@param x number Tooltip x position
---@param y number Tooltip y position
---@param lines table Array of wrapped text lines
local function renderTooltip(win, x, y, lines)
	local width, height = calculateTooltipSize(lines)

	-- Begin popup for tooltip
	Popup.Begin(win, x, y, width, height)

	-- Draw each line of text
	local padding = Globals.Style.ItemPadding
	local lineSpacing = 2
	local currentY = 0

	draw.SetFont(Globals.Style.Font)
	for i, line in ipairs(lines) do
		local _, lineHeight = draw.GetTextSize(line)
		local textX = padding
		local textY = currentY + padding

		-- Queue text drawing at tooltip layer
		local absX = x + textX
		local absY = y + textY

		win:QueueDrawAtLayer(Globals.Layers.Popup + 1, function()
			Common.SetColor(Globals.Colors.Text)
			Common.DrawText(absX, absY, line)
		end)

		currentY = currentY + lineHeight + lineSpacing
	end

	-- End popup (draws background and border)
	Popup.End(win)
end

--- Processes all tooltips for the window and displays one if a widget is hovered
---@param win table Window object
function Tooltip.ProcessWindowTooltips(win)
	local boundsList = win._widgetBounds
	if not boundsList then
		return
	end

	local mouseX, mouseY = table.unpack(input.GetMousePos())
	local Utils = require("TimMenu.Utils")

	for index = #boundsList, 1, -1 do
		local bounds = boundsList[index]
		if bounds and type(bounds.tooltip) == "string" and bounds.tooltip ~= "" then
			if pointInBounds(bounds, mouseX, mouseY) then
				if isBlockedByPopup(win, mouseX, mouseY) then
					goto continue
				end
				if Utils.IsPointBlocked(TimMenuGlobal.order, TimMenuGlobal.windows, mouseX, mouseY, win.id) then
					goto continue
				end

				local lines = wrapText(bounds.tooltip, 40)
				local tooltipX = mouseX + 10
				local tooltipY = mouseY + 10

				local screenW, screenH = draw.GetScreenSize()
				local tooltipW, tooltipH = calculateTooltipSize(lines)

				if tooltipX + tooltipW > screenW then
					tooltipX = mouseX - tooltipW - 10
				end
				if tooltipY + tooltipH > screenH then
					tooltipY = mouseY - tooltipH - 10
				end

				renderTooltip(win, tooltipX, tooltipY, lines)
				return
			end
		end
		::continue::
	end
end

--- Stores widget bounds for tooltip detection
---@param win table Window object
---@param widgetIndex number Widget index
---@param bounds table Widget bounds {x, y, w, h}
function Tooltip.StoreWidgetBounds(win, widgetIndex, bounds)
	if not win._widgetBounds then
		win._widgetBounds = {}
	end

	local existing = win._widgetBounds[widgetIndex]
	if existing and existing.tooltip and bounds.tooltip == nil then
		bounds.tooltip = existing.tooltip
	end

	win._widgetBounds[widgetIndex] = bounds
end

--- Attaches a tooltip to the last widget added to the window
---@param win table Window object
---@param text string Tooltip text description
function Tooltip.AttachToLastWidget(win, text)
	assert(type(text) == "string", "Tooltip text must be a string")

	local widgetIndex = win._widgetCounter or 0
	if widgetIndex == 0 then
		return
	end

	local boundsList = win._widgetBounds
	if not boundsList then
		return
	end

	local bounds = boundsList[widgetIndex]
	if not bounds then
		return
	end

	bounds.tooltip = text
end

return Tooltip
