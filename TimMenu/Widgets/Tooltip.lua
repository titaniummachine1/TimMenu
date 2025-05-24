local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Popup = require("TimMenu.Layout.Popup")

local Tooltip = {}

-- Store tooltip data per window and widget
local tooltipData = {}

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
	local windowData = tooltipData[win.id]
	if not windowData then
		return
	end

	local mouseX, mouseY = table.unpack(input.GetMousePos())

	-- Check each widget that has a tooltip to see if it's hovered
	for widgetKey, tooltipText in pairs(windowData) do
		-- Extract widget index from key
		local widgetIndex = widgetKey:match(":Widget:(%d+)")
		if widgetIndex then
			widgetIndex = tonumber(widgetIndex)

			-- Check if we have widget bounds stored for this widget
			local widgetBounds = win._widgetBounds and win._widgetBounds[widgetIndex]
			if widgetBounds then
				-- Check if mouse is hovering this widget
				local inBounds = mouseX >= widgetBounds.x
					and mouseX <= widgetBounds.x + widgetBounds.w
					and mouseY >= widgetBounds.y
					and mouseY <= widgetBounds.y + widgetBounds.h

				if inBounds then
					-- Check if this widget is not blocked by a higher window
					local Utils = require("TimMenu.Utils")
					if not Utils.IsPointBlocked(TimMenuGlobal.order, TimMenuGlobal.windows, mouseX, mouseY, win.id) then
						-- Show tooltip
						local lines = wrapText(tooltipText, 40)

						-- Position tooltip to the right and down from cursor
						local tooltipX = mouseX + 10
						local tooltipY = mouseY + 10

						-- Ensure tooltip doesn't go off screen (basic bounds checking)
						local screenW, screenH = draw.GetScreenSize()
						local tooltipW, tooltipH = calculateTooltipSize(lines)

						if tooltipX + tooltipW > screenW then
							tooltipX = mouseX - tooltipW - 10 -- Position to the left instead
						end
						if tooltipY + tooltipH > screenH then
							tooltipY = mouseY - tooltipH - 10 -- Position above instead
						end

						renderTooltip(win, tooltipX, tooltipY, lines)
						return -- Only show one tooltip at a time
					end
				end
			end
		end
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
	win._widgetBounds[widgetIndex] = bounds
end

--- Attaches a tooltip to the last widget added to the window
---@param win table Window object
---@param text string Tooltip text description
function Tooltip.AttachToLastWidget(win, text)
	assert(type(text) == "string", "Tooltip text must be a string")

	-- Create tooltip data structure for this window if it doesn't exist
	if not tooltipData[win.id] then
		tooltipData[win.id] = {}
	end

	-- Generate a key for the last widget (this assumes widgets increment _widgetCounter)
	local widgetIndex = win._widgetCounter or 0
	if widgetIndex == 0 then
		return -- No widgets added yet
	end

	-- Store tooltip for the most recently added widget
	-- We'll use the widget index for tracking
	local widgetKey = win.id .. ":Widget:" .. widgetIndex
	tooltipData[win.id][widgetKey] = text

	-- Store the tooltip key on the window for the last widget
	win._lastWidgetTooltipKey = widgetKey
	win._lastWidgetIndex = widgetIndex
end

--- Gets the tooltip key for the last widget (used by widgets to check for tooltips)
---@param win table Window object
---@return string|nil tooltipKey The tooltip key if tooltip exists for last widget
function Tooltip.GetLastWidgetKey(win)
	return win._lastWidgetTooltipKey
end

--- Checks if a widget has a tooltip and returns the text
---@param win table Window object
---@param widgetKey string Widget identifier
---@return string|nil tooltipText The tooltip text if it exists
function Tooltip.GetTooltipForWidget(win, widgetKey)
	local windowData = tooltipData[win.id]
	if not windowData then
		return nil
	end
	return windowData[widgetKey]
end

--- Cleans up tooltip data for orphaned windows
---@param activeWindowIds table Array of active window IDs
function Tooltip.CleanupOrphanedData(activeWindowIds)
	local activeSet = {}
	for _, id in ipairs(activeWindowIds) do
		activeSet[id] = true
	end

	for windowId in pairs(tooltipData) do
		if not activeSet[windowId] then
			tooltipData[windowId] = nil
		end
	end
end

return Tooltip
