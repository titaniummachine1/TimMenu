local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

local function Selector(win, label, selectedIndex, options)
	assert(type(win) == "table", "Selector: win must be a table")
	assert(label == nil or type(label) == "string", "Selector: label must be a string or nil")
	assert(type(selectedIndex) == "number", "Selector: selectedIndex must be a number")
	assert(type(options) == "table", "Selector: options must be a table")
	win._widgetCounter = (win._widgetCounter or 0) + 1
	win._selectors = win._selectors or {}
	local safeLabel = label or "<nil_selector_label>"
	local key = tostring(win.id) .. ":selector:" .. safeLabel
	local entry = win._selectors[key]
	if not entry then
		entry = { selected = selectedIndex or 1 }
	else
		if selectedIndex and selectedIndex ~= entry.selected then
			entry.selected = selectedIndex
		end
	end
	win._selectors[key] = entry

	-- Styling & Calculation
	draw.SetFont(Globals.Style.Font)
	local pad = Globals.Style.ItemPadding
	local _, btnSymH = draw.GetTextSize("<")
	local btnW = btnSymH + (pad * 2)
	local btnH = btnSymH + (pad * 2)
	local fixedTextW = 100
	local textDisplayH = btnH
	local sepW = 1
	local totalWidth = btnW + sepW + fixedTextW + sepW + btnW
	local totalHeight = math.max(btnH, textDisplayH)

	local x, y = win:AddWidget(totalWidth, totalHeight)
	local absX, absY = win.X + x, win.Y + y

	-- Cached mouse position for click logic
	local mX, mY = TimMenuGlobal.mouseX, TimMenuGlobal.mouseY

	-- Unified interaction for prev arrow
	local prevBounds = { x = absX, y = absY, w = btnW, h = totalHeight }
	local widgetKeyPrev = key .. ":prev:" .. win._widgetCounter
	local prevHovered, prevDown, prevClicked = Interaction.Process(win, widgetKeyPrev, prevBounds, false)
	if prevClicked then
		entry.selected = entry.selected - 1
		if entry.selected < 1 then
			entry.selected = #options
		end
	end

	-- Unified interaction for next arrow
	local nextBounds = { x = absX + btnW + sepW + fixedTextW + sepW, y = absY, w = btnW, h = totalHeight }
	local widgetKeyNext = key .. ":next:" .. win._widgetCounter
	local nextHovered, nextDown, nextClicked = Interaction.Process(win, widgetKeyNext, nextBounds, false)
	if nextClicked then
		entry.selected = entry.selected + 1

		if entry.selected > #options then
			entry.selected = 1
		end
	end

	-- Unified interaction for center area
	local centerBounds = { x = absX + btnW + sepW, y = absY, w = fixedTextW, h = totalHeight }
	local widgetKeyCenter = key .. ":center:" .. win._widgetCounter
	local centerHovered, centerDown, centerClicked = Interaction.Process(win, widgetKeyCenter, centerBounds, false)
	if centerClicked then
		if mX < centerBounds.x + centerBounds.w / 2 then
			entry.selected = entry.selected - 1
			if entry.selected < 1 then
				entry.selected = #options
			end
		else
			entry.selected = entry.selected + 1
			if entry.selected > #options then
				entry.selected = 1
			end
		end
	end

	win:QueueDrawAtLayer(2, function()
		local cx, cy = win.X + x, win.Y + y
		-- Prev arrow background and text
		local prevBg = Globals.Colors.Item
		if prevDown then
			prevBg = Globals.Colors.ItemActive
		elseif prevHovered then
			prevBg = Globals.Colors.ItemHover
		end
		Common.SetColor(prevBg)
		Common.DrawFilledRect(cx, cy, cx + btnW, cy + btnH)
		-- Calculate arrow symbol size for centering
		draw.SetFont(Globals.Style.Font)
		local symW, symH = draw.GetTextSize("<")
		local sym2W, sym2H = draw.GetTextSize(">")
		Common.SetColor(Globals.Colors.Text)
		Common.DrawText(cx + (btnW - symW) / 2, cy + (btnH - symH) / 2, "<")
		local display = tostring(options[entry.selected])
		local halfW = fixedTextW / 2
		local leftBounds = { x = cx + btnW + sepW, y = cy, w = halfW, h = totalHeight }
		local rightBounds = { x = cx + btnW + sepW + halfW, y = cy, w = halfW, h = totalHeight }
		local lh = Interaction.IsHovered(win, leftBounds)
		Common.SetColor(lh and Globals.Colors.ItemHover or Globals.Colors.Item)
		Common.DrawFilledRect(leftBounds.x, leftBounds.y, leftBounds.x + leftBounds.w, leftBounds.y + leftBounds.h)
		local rh = Interaction.IsHovered(win, rightBounds)
		Common.SetColor(rh and Globals.Colors.ItemHover or Globals.Colors.Item)
		Common.DrawFilledRect(
			rightBounds.x,
			rightBounds.y,
			rightBounds.x + rightBounds.w,
			rightBounds.y + rightBounds.h
		)
		Common.SetColor(Globals.Colors.Text)
		local dispW, dispH = draw.GetTextSize(display)
		Common.DrawText(cx + btnW + sepW + (fixedTextW - dispW) / 2, cy + (totalHeight - dispH) / 2, display)
		local nextX = cx + btnW + sepW + fixedTextW + sepW
		local nextBg = Globals.Colors.Item
		if nextDown then
			nextBg = Globals.Colors.ItemActive
		elseif nextHovered then
			nextBg = Globals.Colors.ItemHover
		end
		Common.SetColor(nextBg)
		Common.DrawFilledRect(nextX, cy, nextX + btnW, cy + btnH)
		Common.SetColor(Globals.Colors.Text)
		Common.DrawText(nextX + (btnW - sym2W) / 2, cy + (btnH - sym2H) / 2, ">")
		Common.SetColor(Globals.Colors.WindowBorder)
		Common.DrawOutlinedRect(cx, cy, cx + totalWidth, cy + totalHeight)
	end)

	return entry.selected
end

return Selector
