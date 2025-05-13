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
		entry = { selected = selectedIndex or 1, changed = false }
	else
		entry.changed = false
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

	local prevKey, nextKey, centerKey = key .. ":prev", key .. ":next", key .. ":center"
	local mX, mY = table.unpack(input.GetMousePos())

	local prevHover = Interaction.IsHovered(win, { x = absX, y = absY, w = btnW, h = totalHeight })
	-- Next arrow hover region, include previous arrow width
	local nextHover =
		Interaction.IsHovered(win, { x = absX + btnW + sepW + fixedTextW + sepW, y = absY, w = btnW, h = totalHeight })

	if prevHover and Interaction.IsPressed(prevKey) then
		entry.selected = entry.selected - 1
		if entry.selected < 1 then
			entry.selected = #options
		end
		entry.changed = true
	end
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(prevKey)
	end
	if nextHover and Interaction.IsPressed(nextKey) then
		entry.selected = entry.selected + 1
		if entry.selected > #options then
			entry.selected = 1
		end
		entry.changed = true
	end
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(nextKey)
	end

	local textBounds = { x = absX + btnW + sepW, y = absY, w = fixedTextW, h = totalHeight }
	if Interaction.IsHovered(win, textBounds) and Interaction.IsPressed(centerKey) then
		if mX < textBounds.x + textBounds.w / 2 then
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
		entry.changed = true
	end
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(centerKey)
	end

	win:QueueDrawAtLayer(2, function()
		local cx, cy = win.X + x, win.Y + y
		-- Prev arrow background and text
		local prevBg = Globals.Colors.Item
		if Interaction._PressState[prevKey] then
			prevBg = Globals.Colors.ItemActive
		elseif prevHover then
			prevBg = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(prevBg))
		Common.DrawFilledRect(cx, cy, cx + btnW, cy + btnH)
		-- Calculate arrow symbol size for centering
		draw.SetFont(Globals.Style.Font)
		local symW, symH = draw.GetTextSize("<")
		local sym2W, sym2H = draw.GetTextSize(">")
		draw.Color(table.unpack(Globals.Colors.Text))
		Common.DrawText(cx + (btnW - symW) / 2, cy + (btnH - symH) / 2, "<")
		local display = tostring(options[entry.selected])
		local halfW = fixedTextW / 2
		local leftBounds = { x = cx + btnW + sepW, y = cy, w = halfW, h = totalHeight }
		local rightBounds = { x = cx + btnW + sepW + halfW, y = cy, w = halfW, h = totalHeight }
		local lh = Interaction.IsHovered(win, leftBounds)
		draw.Color(table.unpack(lh and Globals.Colors.ItemHover or Globals.Colors.Item))
		Common.DrawFilledRect(leftBounds.x, leftBounds.y, leftBounds.x + leftBounds.w, leftBounds.y + leftBounds.h)
		local rh = Interaction.IsHovered(win, rightBounds)
		draw.Color(table.unpack(rh and Globals.Colors.ItemHover or Globals.Colors.Item))
		Common.DrawFilledRect(
			rightBounds.x,
			rightBounds.y,
			rightBounds.x + rightBounds.w,
			rightBounds.y + rightBounds.h
		)
		draw.Color(table.unpack(Globals.Colors.Text))
		local dispW, dispH = draw.GetTextSize(display)
		Common.DrawText(cx + btnW + sepW + (fixedTextW - dispW) / 2, cy + (totalHeight - dispH) / 2, display)
		local nextX = cx + btnW + sepW + fixedTextW + sepW
		local nextBg = Globals.Colors.Item
		if Interaction._PressState[nextKey] then
			nextBg = Globals.Colors.ItemActive
		elseif nextHover then
			nextBg = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(nextBg))
		Common.DrawFilledRect(nextX, cy, nextX + btnW, cy + btnH)
		draw.Color(table.unpack(Globals.Colors.Text))
		Common.DrawText(nextX + (btnW - sym2W) / 2, cy + (btnH - sym2H) / 2, ">")
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawOutlinedRect(cx, cy, cx + totalWidth, cy + totalHeight)
	end)

	return entry.selected, entry.changed
end

return Selector
