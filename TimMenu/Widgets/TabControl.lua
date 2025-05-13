local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

local function TabControl(win, id, tabs, defaultSelection, isHeader)
	assert(type(win) == "table", "TabControl: win must be a table")
	assert(type(id) == "string", "TabControl: id must be a string")
	assert(type(tabs) == "table", "TabControl: tabs must be a table of strings")
	-- Auto-header detection: merge with title bar when first widget or explicit flag
	local _pad = Globals.Defaults.WINDOW_CONTENT_PADDING
	local _titleH = Globals.Defaults.TITLE_BAR_HEIGHT
	local headerMode = (isHeader == true) or (isHeader == nil and win.cursorX == _pad and win.cursorY == _titleH + _pad)
	if not headerMode then
		-- ensure on its own line
		if win.cursorX > _pad then
			win:NextLine(0)
		end
	end
	-- resolve default
	local function resolveDefault()
		if type(defaultSelection) == "number" and defaultSelection >= 1 and defaultSelection <= #tabs then
			return defaultSelection
		end
		if type(defaultSelection) == "string" then
			for i, v in ipairs(tabs) do
				if v == defaultSelection then
					return i
				end
			end
		end
		return 1
	end

	win._tabControls = win._tabControls or {}
	local key = tostring(win.id) .. ":tabctrl:" .. id
	local entry = win._tabControls[key]
	if not entry then
		entry = { selected = resolveDefault(), changed = false }
	else
		entry.changed = false
	end
	win._tabControls[key] = entry

	local current = entry.selected
	local selectedInfo

	-- Header mode: draw tabs in title bar and signal Window to left-align title
	if headerMode then
		win._hasHeaderTabs = true
		-- Measurement for header tabs
		local pad = Globals.Style.ItemPadding
		local spacing = Globals.Defaults.ITEM_SPACING
		draw.SetFont(Globals.Style.FontBold) -- Use bold font
		local items = {}
		local totalW, lineH = 0, 0
		for i, lbl in ipairs(tabs) do
			local w, h = draw.GetTextSize(lbl)
			local bw, bh = w + pad * 2, h + pad * 2
			items[i] = { lbl = lbl, w = w, h = h, bw = bw, bh = bh }
			totalW = totalW + bw + (i < #tabs and spacing or 0)
			lineH = math.max(lineH, bh)
		end
		-- Compute starting cursor based on window title width, clamped to window bounds
		draw.SetFont(Globals.Style.Font) -- Use title font for measuring the title text width
		local titleW = draw.GetTextSize(win.title)
		local contentPad = Globals.Defaults.WINDOW_CONTENT_PADDING
		local startX = win.X + contentPad + titleW + spacing
		-- Expand window width if header tabs exceed current minimum width
		local neededW = (startX - win.X) + totalW + contentPad
		if neededW > win.W then
			win.W = neededW
		end
		local maxX = win.X + win.W - contentPad - totalW
		local cursorX = math.min(startX, maxX)
		local startY = win.Y + (Globals.Defaults.TITLE_BAR_HEIGHT - lineH) / 2
		-- Draw each tab
		for i, item in ipairs(items) do
			local isSel = (i == entry.selected)
			local keyBtn = id .. ":tab:" .. item.lbl
			local absX, absY = cursorX, startY
			local offsetX, offsetY = absX - win.X, absY - win.Y
			-- Interaction
			local hover = Interaction.IsHovered(win, { x = absX, y = absY, w = item.bw, h = item.bh })
			if hover and Interaction.IsPressed(keyBtn) then
				entry.selected = i
				entry.changed = true
			end
			if not input.IsButtonDown(MOUSE_LEFT) then
				Interaction.Release(keyBtn)
			end
			-- Hover underline for non-selected tabs (dynamic positioning)
			if hover and not isSel then
				win:QueueDrawAtLayer(1, function(offX, offY, bw)
					local px = win.X + offX
					local py = win.Y + offY
					local uy = py + item.bh
					draw.Color(table.unpack(Globals.Colors.Highlight))
					Common.DrawFilledRect(px, uy, px + bw, uy + 2)
				end, offsetX, offsetY, item.bw)
			end
			-- Tab text (dynamic positioning)
			win:QueueDrawAtLayer(2, function(lbl, w, h, bw, bh, sel, offX, offY)
				local px = win.X + offX
				local py = win.Y + offY
				local txtColor = sel and Globals.Colors.Text or { 180, 180, 180, 255 }
				draw.SetFont(Globals.Style.FontBold)
				draw.Color(table.unpack(txtColor))
				Common.DrawText(px + (bw - w) / 2, py + (bh - h) / 2, lbl)
			end, item.lbl, item.w, item.h, item.bw, item.bh, isSel, offsetX, offsetY)
			-- Underline for selected tab (dynamic positioning)
			if isSel then
				win:QueueDrawAtLayer(3, function(offX, offY, bw)
					local px = win.X + offX
					local py = win.Y + offY
					local uy = py + item.bh
					draw.Color(table.unpack(Globals.Colors.TabSelectedUnderline))
					Common.DrawFilledRect(px, uy, px + bw, uy + 2)
				end, offsetX, offsetY, item.bw)
			end
			cursorX = cursorX + item.bw + spacing
		end
		return entry.selected, entry.changed
	end

	-- measure total width
	local totalW, pad = 0, Globals.Style.ItemPadding
	draw.SetFont(Globals.Style.FontBold) -- Use bold font
	for i, lbl in ipairs(tabs) do
		local w, _ = draw.GetTextSize(lbl)
		totalW = totalW + w + pad * 2 + (i < #tabs and Globals.Defaults.ITEM_SPACING or 0)
	end
	local contentPad = Globals.Defaults.WINDOW_CONTENT_PADDING
	local startX = contentPad + math.max(0, (win.W - contentPad * 2 - totalW) / 2)
	local startY = win.cursorY
	win.cursorX = startX
	local lineH = 0

	for i, lbl in ipairs(tabs) do
		local isSel = (i == current)
		local keyBtn = id .. ":tab:" .. lbl
		draw.SetFont(Globals.Style.FontBold) -- Use bold font
		local w, h = draw.GetTextSize(lbl)
		local bw, bh = w + pad * 2, h + pad * 2
		local bx, by = win.cursorX, startY
		win.cursorX = win.cursorX + bw + Globals.Defaults.ITEM_SPACING
		lineH = math.max(lineH, bh)
		local absX, absY = win.X + bx, win.Y + by
		local hover = Interaction.IsHovered(win, { x = absX, y = absY, w = bw, h = bh })
		if hover and Interaction.IsPressed(keyBtn) then
			entry.selected = i
			entry.changed = true
		end
		if not input.IsButtonDown(MOUSE_LEFT) then
			Interaction.Release(keyBtn)
		end
		if isSel then
			selectedInfo = { x = bx, y = by, w = bw, h = bh }
		end

		win:QueueDrawAtLayer(1, function() -- Layer 1 for backgrounds
			local cx, cy = win.X + bx, win.Y + by
			local bgColor
			if isSel then
				bgColor = Globals.Colors.Title -- Blue for selected
			elseif hover then
				bgColor = Globals.Colors.ItemHover -- Hover color for non-selected
			else
				bgColor = Globals.Colors.Item -- Default item color for non-selected
			end
			draw.Color(table.unpack(bgColor))
			Common.DrawFilledRect(cx, cy, cx + bw, cy + bh)
		end)

		win:QueueDrawAtLayer(2, function() -- Layer 2 for text
			local cx, cy = win.X + bx, win.Y + by
			-- Selected tab text is bright white, others are slightly dimmer
			local txtColor = isSel and Globals.Colors.Text or { 180, 180, 180, 255 }
			draw.SetFont(Globals.Style.FontBold) -- Ensure bold font is set for drawing text
			draw.Color(table.unpack(txtColor))
			Common.DrawText(cx + (bw - w) / 2, cy + (bh - h) / 2, lbl)
		end)
	end

	-- separator line below all tabs (kept)
	win:QueueDrawAtLayer(1, function()
		local sy = win.Y + startY + lineH + 2 -- Adjusted spacing a bit
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawLine(win.X + contentPad, sy, win.X + win.W - contentPad, sy)
	end)
	win.cursorY = startY + lineH + 2 + 1 + 12 -- Adjusted spacing a bit
	win.cursorX = contentPad
	win.lineHeight = 0
	return entry.selected, entry.changed
end

return TabControl
