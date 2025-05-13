local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

local function TabControl(win, id, tabs, defaultSelection)
	assert(type(win) == "table", "TabControl: win must be a table")
	assert(type(id) == "string", "TabControl: id must be a string")
	assert(type(tabs) == "table", "TabControl: tabs must be a table of strings")
	-- ensure on its own line
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win:NextLine(0)
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
