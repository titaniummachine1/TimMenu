local WidgetBase = require("TimMenu.WidgetBase")
local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")
local DrawHelpers = require("TimMenu.DrawHelpers")

-- Draw helpers for dropdown field and popup
local function DrawDropdownField(win, relX, relY, width, height, pad, label, entryOpen, hovered, arrowW, arrowH)
	local absX, absY = win.X + relX, win.Y + relY
	draw.SetFont(Globals.Style.Font)
	local arrowBoxW = height
	local arrowBoxX = absX + width - arrowBoxW
	local mainBgWidth = width - arrowBoxW
	local bgColor = Globals.Colors.Item
	if entryOpen then
		bgColor = Globals.Colors.ItemActive
	elseif hovered then
		bgColor = Globals.Colors.ItemHover
	end
	Common.SetColor(bgColor)
	Common.DrawFilledRect(absX, absY, absX + mainBgWidth, absY + height)
	Common.SetColor(Globals.Colors.ArrowBoxBg)
	Common.DrawFilledRect(arrowBoxX, absY, arrowBoxX + arrowBoxW, absY + height)
	Common.SetColor(Globals.Colors.WindowBorder)
	Common.DrawOutlinedRect(absX, absY, absX + width, absY + height)
	Common.SetColor(Globals.Colors.Text)
	local _, txtH = draw.GetTextSize(label)
	Common.DrawText(absX + pad, absY + (height - txtH) / 2, label)
	local actualArrowW, actualArrowH = arrowW * 0.5, arrowH * 0.5
	local triX = arrowBoxX + (arrowBoxW - actualArrowW) / 2
	local triY = absY + (height - actualArrowH) / 2
	DrawHelpers.DrawArrow(triX, triY, actualArrowW, actualArrowH, entryOpen and "up" or "down", Globals.Colors.Text)
end

local function DrawDropdownPopupBackground(win, relX, relY, width, listH)
	local absX, absY = win.X + relX, win.Y + relY
	Common.SetColor(Globals.Colors.Window)
	Common.DrawFilledRect(absX, absY, absX + width, absY + listH)
end

local function DrawDropdownPopupItem(win, relX, relY, width, itemH, pad, opt, isHovered)
	local absX, absY = win.X + relX, win.Y + relY
	draw.SetFont(Globals.Style.Font)
	Common.SetColor(isHovered and Globals.Colors.ItemHover or Globals.Colors.Item)
	Common.DrawFilledRect(absX, absY, absX + width, absY + itemH)
	Common.SetColor(Globals.Colors.Text)
	local _, optH = draw.GetTextSize(opt)
	Common.DrawText(absX + pad, absY + (itemH - optH) / 2, opt)
end

local function DrawDropdownPopupOutline(win, relX, relY, width, listH)
	local absX, absY = win.X + relX, win.Y + relY
	Common.SetColor(Globals.Colors.WindowBorder)
	Common.DrawOutlinedRect(absX, absY, absX + width, absY + listH)
end

local function Dropdown(win, label, selectedIndex, options)
	assert(type(win) == "table", "Dropdown: win must be a table")
	assert(type(label) == "string", "Dropdown: label must be a string")
	assert(type(options) == "table", "Dropdown: options must be a table")

	-- State management
	win._dropdowns = win._dropdowns or {}
	local key = tostring(win.id) .. ":dropdown:" .. label
	local entry = win._dropdowns[key]
	if not entry then
		entry = { selected = selectedIndex or 1, open = false }
	end
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

	-- Use WidgetBase for setup (layout, counter, bounds, key)
	local ctx = WidgetBase.Setup(win, "Dropdown", label, width, height)

	-- Unified interaction processing for main field
	local hovered, pressed, clicked = WidgetBase.ProcessInteraction(ctx, entry.open)
	local listH = #options * height
	local popupBounds = { x = ctx.absX, y = ctx.absY + height, w = width, h = listH }

	-- Close popup on outside click using cached mouse position
	Interaction.ClosePopupOnOutsideClick(
		entry,
		TimMenuGlobal.mouseX,
		TimMenuGlobal.mouseY,
		ctx.bounds,
		popupBounds,
		win
	)

	if clicked then
		if not entry.open and hovered then
			-- Open popup and block its region
			entry.open = true
			win._widgetBlockedRegions = { popupBounds }
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
					entry.selected = idx
				end
			else
				entry.open = false
				win._widgetBlockedRegions = {}
			end
		end
	end

	-- Draw main dropdown field
	win:QueueDrawAtLayer(
		2,
		DrawDropdownField,
		win,
		ctx.x,
		ctx.y,
		width,
		height,
		pad,
		label,
		entry.open,
		hovered,
		arrowW,
		arrowH
	)

	-- Draw popup if open - use dedicated popup layer that's always on top
	if entry.open then
		local popupX, popupY = ctx.x, ctx.y + height
		local popupLayer = Globals.POPUP_LAYER_BASE

		-- Popup background
		win:QueueDrawAtLayer(popupLayer, DrawDropdownPopupBackground, win, popupX, popupY, width, listH)

		-- Popup items
		for i, opt in ipairs(options) do
			local isH = Interaction.IsHovered(win, {
				x = ctx.absX,
				y = ctx.absY + height + (i - 1) * height,
				w = width,
				h = height,
			})
			win:QueueDrawAtLayer(
				popupLayer,
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

		-- Popup outline
		win:QueueDrawAtLayer(popupLayer, DrawDropdownPopupOutline, win, popupX, popupY, width, listH)
	end

	return entry.selected
end

return Dropdown
