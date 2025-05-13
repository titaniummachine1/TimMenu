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

	-- Header mode: draw tabs in title bar and return early
	if headerMode then
		-- Measurement for header tabs
		local pad = Globals.Style.ItemPadding
		local spacing = Globals.Defaults.ITEM_SPACING
		draw.SetFont(Globals.Style.Font)
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
		draw.SetFont(Globals.Style.Font)
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
			-- Interaction
			local hover = Interaction.IsHovered(win, { x = absX, y = absY, w = item.bw, h = item.bh })
			if hover and Interaction.IsPressed(keyBtn) then
				entry.selected = i
				entry.changed = true
			end
			if not input.IsButtonDown(MOUSE_LEFT) then
				Interaction.Release(keyBtn)
			end
			-- Hover underline for non-selected tabs
			if hover and not isSel then
				win:QueueDrawAtLayer(1, function(px, py, bw)
					local uy = py + item.bh
					draw.Color(table.unpack(Globals.Colors.Highlight))
					Common.DrawFilledRect(px, uy, px + bw, uy + 2)
				end, absX, absY, item.bw)
			end
			-- Tab text
			win:QueueDrawAtLayer(2, function(lbl, w, h, bw, bh, sel, px, py)
				local txtColor = sel and Globals.Colors.Text or { 180, 180, 180, 255 }
				draw.Color(table.unpack(txtColor))
				Common.DrawText(px + (bw - w) / 2, py + (bh - h) / 2, lbl)
			end, item.lbl, item.w, item.h, item.bw, item.bh, isSel, absX, absY)
			-- Underline for selected tab
			if isSel then
				win:QueueDrawAtLayer(3, function(px, py, bw)
					local uy = py + item.bh
					draw.Color(table.unpack(Globals.Colors.TabSelectedUnderline))
					Common.DrawFilledRect(px, uy, px + bw, uy + 2)
				end, absX, absY, item.bw)
			end
			cursorX = cursorX + item.bw + spacing
		end
		return entry.selected, entry.changed
	end

	-- measure total width
	local totalW, pad = 0, Globals.Style.ItemPadding
	draw.SetFont(Globals.Style.Font)
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
		draw.SetFont(Globals.Style.Font)
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
		win:QueueDrawAtLayer(2, function()
			local cx, cy = win.X + bx, win.Y + by
			local txtColor = isSel and Globals.Colors.Text or { 180, 180, 180, 255 }
			draw.Color(table.unpack(txtColor))
			Common.DrawText(cx + (bw - w) / 2, cy + (bh - h) / 2, lbl)
		end)
	end
	-- underline
	if selectedInfo then
		win:QueueDrawAtLayer(3, function(si)
			local uy = win.Y + si.y + si.h
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawFilledRect(win.X + si.x, uy, win.X + si.x + si.w, uy + 2)
		end, selectedInfo)
	end
	-- separator line below
	win:QueueDrawAtLayer(1, function()
		local sy = win.Y + startY + lineH + (selectedInfo and 2 or 0) + 2
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawLine(win.X + contentPad, sy, win.X + win.W - contentPad, sy)
	end)
	win.cursorY = startY + lineH + (selectedInfo and 2 or 0) + 1 + 12
	win.cursorX = contentPad
	win.lineHeight = 0
	return entry.selected, entry.changed
end

return TabControl
