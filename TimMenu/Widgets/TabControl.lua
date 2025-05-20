local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

-- Light-blue outline, 20% lighter than WindowBorder
local WB = Globals.Colors.WindowBorder
local LIGHT_TAB_OUTLINE = {
	math.min(255, WB[1] + math.floor((255 - WB[1]) * 0.2)),
	math.min(255, WB[2] + math.floor((255 - WB[2]) * 0.2)),
	math.min(255, WB[3] + math.floor((255 - WB[3]) * 0.2)),
	WB[4],
}

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
			-- Unified interaction for header tab
			local widgetKey = keyBtn .. ":" .. win._widgetCounter
			local bounds = { x = absX, y = absY, w = item.bw, h = item.bh }
			local hover, press, click = Interaction.Process(win, widgetKey, bounds, false)
			if click then
				entry.selected = i
				entry.changed = true
			end
			-- Hover underline for non-selected tabs (dynamic positioning)
			if hover and not isSel then
				win:QueueDrawAtLayer(1, function(offX, offY, bw)
					local px, py = win.X + offX, win.Y + offY
					local uy = py + item.bh
					Common.SetColor(Globals.Colors.Highlight)
					Common.DrawFilledRect(px, uy, px + bw, uy + 2)
				end, offsetX, offsetY, item.bw)
			end
			-- Tab text (dynamic positioning)
			win:QueueDrawAtLayer(2, function(lbl, w, h, bw, bh, sel, offX, offY)
				local px, py = win.X + offX, win.Y + offY
				local txtColor = sel and Globals.Colors.Text or { 180, 180, 180, 255 }
				draw.SetFont(Globals.Style.FontBold)
				Common.SetColor(txtColor)
				Common.DrawText(px + (bw - w) / 2, py + (bh - h) / 2, lbl)
			end, item.lbl, item.w, item.h, item.bw, item.bh, isSel, offsetX, offsetY)
			-- Underline for selected tab (dynamic positioning)
			if isSel then
				win:QueueDrawAtLayer(3, function(offX, offY, bw)
					local px, py = win.X + offX, win.Y + offY
					local uy = py + item.bh
					Common.SetColor(Globals.Colors.TabSelectedUnderline)
					Common.DrawFilledRect(px, uy, px + bw, uy + 2)
				end, offsetX, offsetY, item.bw)
			end
			cursorX = cursorX + item.bw + spacing
		end
		return entry.selected, entry.changed
	end

	-- Non-header TabControl: regular widget behavior
	local pad = Globals.Style.ItemPadding
	local spacing = math.floor(pad * 0.5)
	local contentPad = Globals.Defaults.WINDOW_CONTENT_PADDING

	draw.SetFont(Globals.Style.FontBold)

	-- Compute text sizes and total width for group outline
	local totalW = 0
	local textSizes = {}
	for i, lbl in ipairs(tabs) do
		local tw, th = draw.GetTextSize(lbl)
		textSizes[i] = { w = tw, h = th }
		totalW = totalW + tw + pad * 2 + (i < #tabs and spacing or 0)
	end

	-- Layout start positions
	local startX = win.cursorX
	local startY = win.cursorY + pad
	win.cursorX = startX
	local lineH = 0

	-- Draw each tab button
	for i, lbl in ipairs(tabs) do
		local ts = textSizes[i]
		local tw, th = ts.w, ts.h
		local bw, bh = tw + pad * 2, th + pad * 2
		local bx, by = win.cursorX, startY
		local absX, absY = win.X + bx, win.Y + by

		-- Unified interaction for non-header tab
		local widgetKey = id .. ":tab:" .. lbl .. ":" .. win._widgetCounter
		local bounds = { x = absX, y = absY, w = bw, h = bh }
		local hover, press, click = Interaction.Process(win, widgetKey, bounds, false)
		if click then
			entry.selected = i
			entry.changed = true
		end

		-- Background (layer 1) using relative offsets
		win:QueueDrawAtLayer(1, function(offX, offY, w, h, sel, hv)
			local px, py = win.X + offX, win.Y + offY
			local bg = sel and Globals.Colors.Title or (hv and Globals.Colors.ItemHover or Globals.Colors.Item)
			draw.Color(table.unpack(bg))
			Common.DrawFilledRect(px, py, px + w, py + h)
		end, bx, by, bw, bh, entry.selected == i, hover)

		-- Per-button outline (layer 2) using relative offsets
		win:QueueDrawAtLayer(2, function(offX, offY, w, h)
			local px, py = win.X + offX, win.Y + offY
			draw.Color(table.unpack(LIGHT_TAB_OUTLINE))
			Common.DrawOutlinedRect(px, py, px + w, py + h)
		end, bx, by, bw, bh)

		-- Text (layer 3) using relative offsets
		win:QueueDrawAtLayer(3, function(offX, offY, txt, tw, th, sel)
			local px, py = win.X + offX, win.Y + offY
			draw.SetFont(Globals.Style.FontBold)
			local txtC = sel and Globals.Colors.Text or { 180, 180, 180, 255 }
			draw.Color(table.unpack(txtC))
			Common.DrawText(px + (bw - tw) / 2, py + (bh - th) / 2, txt)
		end, bx, by, lbl, tw, th, entry.selected == i)

		-- Advance cursor
		win.cursorX = win.cursorX + bw + spacing
		lineH = math.max(lineH, bh)
	end

	-- Advance cursor to below the tab control
	win.cursorY = startY + lineH + pad
	win.cursorX = contentPad
	win.lineHeight = 0
	return entry.selected, entry.changed
end

return TabControl
