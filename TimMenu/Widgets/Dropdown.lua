local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")
local DrawHelpers = require("TimMenu.DrawHelpers")

-- Draw helpers for dropdown field and popup
local function DrawDropdownField(win, relX, relY, width, height, pad, label, entryOpen, hovered, arrowW, arrowH)
	local absX, absY = win.X + relX, win.Y + relY
	local arrowBoxW = height
	local arrowBoxX = absX + width - arrowBoxW
	local mainBgWidth = width - arrowBoxW
	local bgColor = Globals.Colors.Item
	if entryOpen then
		bgColor = Globals.Colors.ItemActive
	elseif hovered then
		bgColor = Globals.Colors.ItemHover
	end
	draw.Color(table.unpack(bgColor))
	Common.DrawFilledRect(absX, absY, absX + mainBgWidth, absY + height)
	draw.Color(table.unpack(Globals.Colors.ArrowBoxBg))
	Common.DrawFilledRect(arrowBoxX, absY, arrowBoxX + arrowBoxW, absY + height)
	draw.Color(table.unpack(Globals.Colors.WindowBorder))
	Common.DrawOutlinedRect(absX, absY, absX + width, absY + height)
	draw.Color(table.unpack(Globals.Colors.Text))
	local _, txtH = draw.GetTextSize(label)
	Common.DrawText(absX + pad, absY + (height - txtH) / 2, label)
	local actualArrowW, actualArrowH = arrowW * 0.5, arrowH * 0.5
	local triX = arrowBoxX + (arrowBoxW - actualArrowW) / 2
	local triY = absY + (height - actualArrowH) / 2
	DrawHelpers.DrawArrow(triX, triY, actualArrowW, actualArrowH, entryOpen and "up" or "down", Globals.Colors.Text)
end

local function DrawDropdownPopupBackground(win, relX, relY, width, listH)
	local absX, absY = win.X + relX, win.Y + relY
	draw.Color(table.unpack(Globals.Colors.Window))
	Common.DrawFilledRect(absX, absY, absX + width, absY + listH)
end

local function DrawDropdownPopupItem(win, relX, relY, width, itemH, pad, opt, isHovered)
	local absX, absY = win.X + relX, win.Y + relY
	draw.Color(table.unpack(isHovered and Globals.Colors.ItemHover or Globals.Colors.Item))
	Common.DrawFilledRect(absX, absY, absX + width, absY + itemH)
	draw.Color(table.unpack(Globals.Colors.Text))
	local _, optH = draw.GetTextSize(opt)
	Common.DrawText(absX + pad, absY + (itemH - optH) / 2, opt)
end

local function DrawDropdownPopupOutline(win, relX, relY, width, listH)
	local absX, absY = win.X + relX, win.Y + relY
	draw.Color(table.unpack(Globals.Colors.WindowBorder))
	Common.DrawOutlinedRect(absX, absY, absX + width, absY + listH)
end

local function Dropdown(win, label, selectedIndex, options)
	assert(type(win) == "table", "Dropdown: win must be a table")
	assert(type(label) == "string", "Dropdown: label must be a string")
	assert(type(options) == "table", "Dropdown: options must be a table")
	win._widgetCounter = (win._widgetCounter or 0) + 1
	win._dropdowns = win._dropdowns or {}
	local key = tostring(win.id) .. ":dropdown:" .. label
	local entry = win._dropdowns[key]
	if not entry then
		entry = { selected = selectedIndex or 1, open = false, changed = false }
	end
	entry.changed = false
	if selectedIndex and selectedIndex ~= entry.selected then
		entry.selected = selectedIndex
	end
	win._dropdowns[key] = entry

	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(label)
	local pad = Globals.Style.ItemPadding
	local arrowChar = "▼"
	local arrowW, arrowH = draw.GetTextSize(arrowChar)
	local height = math.max(txtH, arrowH) + pad * 2
	local arrowBoxW = height
	local width = txtW + pad * 2 + arrowBoxW

	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + pad
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- Unified interaction processing for main field
	local widgetKey = key .. ":" .. win._widgetCounter
	local bounds = { x = absX, y = absY, w = width, h = height }
	local hovered, pressed, clicked = Interaction.Process(win, widgetKey, bounds, entry.open)
	local listH = #options * height
	local popupBounds = { x = absX, y = absY + height, w = width, h = listH }
	-- Retain existing logic for closing popup on outside click
	local mX, mY = table.unpack(input.GetMousePos())
	Interaction.ClosePopupOnOutsideClick(entry, mX, mY, bounds, popupBounds, win)

	if clicked then
		if not entry.open and hovered then
			-- Open popup and block its region
			entry.open, win._widgetBlockedRegions = true, { popupBounds }
			-- Bring this window to front so popup renders above all
			for i, id in ipairs(TimMenuGlobal.order) do
				if id == win.id then
					table.remove(TimMenuGlobal.order, i)
					break
				end
			end
			table.insert(TimMenuGlobal.order, win.id)
		elseif entry.open then
			if Interaction.IsHovered(win, popupBounds) then
				local idx = math.floor((input.GetMousePos()[2] - popupBounds.y) / height) + 1
				if idx >= 1 and idx <= #options then
					entry.selected, entry.changed = idx, true
				end
			else
				entry.open, win._widgetBlockedRegions = false, {}
			end
		end
	end

	win:QueueDrawAtLayer(
		2,
		DrawDropdownField,
		win,
		x,
		y,
		width,
		height,
		pad,
		label,
		entry.open,
		hovered,
		arrowW,
		arrowH
	)
	if entry.open then
		local popupX, popupY = x, y + height
		-- Popup background at Popup layer
		win:QueueDrawAtLayer(Globals.Layers.Popup, DrawDropdownPopupBackground, win, popupX, popupY, width, listH)
		-- Popup items at Popup layer
		for i, opt in ipairs(options) do
			local isH =
				Interaction.IsHovered(win, { x = absX, y = absY + height + (i - 1) * height, w = width, h = height })
			win:QueueDrawAtLayer(
				Globals.Layers.Popup,
				DrawDropdownPopupItem,
				win,
				popupX,
				popupY + (i - 1) * height,
				width,
				height,
				pad,
				opt,
				isH
			)
		end
		-- Popup outline at Popup layer
		win:QueueDrawAtLayer(Globals.Layers.Popup, DrawDropdownPopupOutline, win, popupX, popupY, width, listH)
	end
	return entry.selected, entry.changed
end

return Dropdown
