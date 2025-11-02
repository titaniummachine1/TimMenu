local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")
local DrawHelpers = require("TimMenu.DrawHelpers")
local WidgetBase = require("TimMenu.WidgetBase")

-- Draw helpers for combo field and popup
local function DrawComboField(win, relX, relY, width, height, pad, label, entryOpen, hovered, arrowW, arrowH)
	local absX, absY = win.X + relX, win.Y + relY
	draw.SetFont(Globals.Style.Font)
	local arrowBoxW, arrowBoxX = height, absX + width - height
	local mainBgW = width - arrowBoxW
	local bgColor = Globals.Colors.Item
	if entryOpen then
		bgColor = Globals.Colors.ItemActive
	elseif hovered then
		bgColor = Globals.Colors.ItemHover
	end
	Common.SetColor(bgColor)
	Common.DrawFilledRect(absX, absY, absX + mainBgW, absY + height)
	Common.SetColor(Globals.Colors.ArrowBoxBg)
	Common.DrawFilledRect(arrowBoxX, absY, arrowBoxX + arrowBoxW, absY + height)
	Common.SetColor(Globals.Colors.WindowBorder)
	Common.DrawOutlinedRect(absX, absY, absX + width, absY + height)
	Common.SetColor(Globals.Colors.Text)
	local _, txtH = draw.GetTextSize(label)
	Common.DrawText(absX + pad, absY + (height - txtH) / 2, label)
	DrawHelpers.DrawArrow(
		arrowBoxX + (arrowBoxW - arrowW * 0.5) / 2,
		absY + (height - arrowH * 0.5) / 2,
		arrowW * 0.5,
		arrowH * 0.5,
		entryOpen and "up" or "down",
		Globals.Colors.Text
	)
end

local function DrawComboPopupBackground(win, relX, relY, width, listH)
	local absX, absY = win.X + relX, win.Y + relY
	Common.SetColor(Globals.Colors.Window)
	Common.DrawFilledRect(absX, absY, absX + width, absY + listH)
end

local function DrawComboPopupItem(win, relX, relY, width, height, pad, opt, isHovered, boxSize, isSelected)
	local absX, absY = win.X + relX, win.Y + relY
	draw.SetFont(Globals.Style.Font)
	Common.SetColor(isHovered and Globals.Colors.ItemHover or Globals.Colors.Item)
	Common.DrawFilledRect(absX, absY, absX + width, absY + height)
	local bx, by = absX + pad, absY + (height / 2) - (boxSize / 2)
	Common.SetColor(Globals.Colors.WindowBorder)
	Common.DrawOutlinedRect(bx, by, bx + boxSize, by + boxSize)
	if isSelected then
		Common.SetColor(Globals.Colors.Highlight)
		local m = math.floor(boxSize * 0.25)
		Common.DrawFilledRect(bx + m, by + m, bx + boxSize - m, by + boxSize - m)
	end
	Common.SetColor(Globals.Colors.Text)
	local _, optH = draw.GetTextSize(opt)
	Common.DrawText(bx + boxSize + pad, absY + (height / 2) - (optH / 2), opt)
end

local function DrawComboPopupOutline(win, relX, relY, width, listH)
	local absX, absY = win.X + relX, win.Y + relY
	Common.SetColor(Globals.Colors.WindowBorder)
	Common.DrawOutlinedRect(absX, absY, absX + width, absY + listH)
end

local function Combo(win, label, selected, options)
	assert(type(win) == "table", "Combo: win must be a table")
	assert(type(label) == "string", "Combo: label must be a string")
	assert(type(selected) == "table", "Combo: selected must be a table of booleans")
	assert(type(options) == "table", "Combo: options must be a table")

	-- State management
	win._combos = win._combos or {}
	local key = tostring(win.id) .. ":combo:" .. label
	local entry = win._combos[key]
	if not entry then
		entry = { selected = {}, open = false }
		for i = 1, #options do
			entry.selected[i] = selected[i] == true
		end
	end
	win._combos[key] = entry

	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(label)
	local pad = Globals.Style.ItemPadding
	local boxSize = txtH -- checkbox size for popup
	local arrowChar = "▼"
	local arrowW, arrowH = draw.GetTextSize(arrowChar)
	local height = math.max(txtH, arrowH) + pad * 2
	local arrowBoxW = height
	local width = txtW + pad * 2 + arrowBoxW

	-- Use WidgetBase for setup
	local ctx = WidgetBase.Setup(win, "Combo", label, width, height)

	-- Unified interaction for main combo field
	local hovered, pressed, clicked = WidgetBase.ProcessInteraction(ctx, entry.open)
	local listH = #options * height
	local popupBounds = { x = ctx.absX, y = ctx.absY + height, w = width, h = listH }

	-- Maintain popup blocked regions while open
	if entry.open then
		win._widgetBlockedRegions = { popupBounds }
	end

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
			-- Open combo popup
			entry.open = true
			-- Bring window to front
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
					entry.selected[idx] = not entry.selected[idx]
				end
			else
				entry.open = false
				win._widgetBlockedRegions = {}
			end
		end
	end

	-- Draw main combo field
	win:QueueDrawAtLayer(
		2,
		DrawComboField,
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
		local px, py = ctx.x, ctx.y + height
		local popupLayer = Globals.POPUP_LAYER_BASE

		-- Popup background
		win:QueueDrawAtLayer(popupLayer, DrawComboPopupBackground, win, px, py, width, listH)

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
				DrawComboPopupItem,
				win,
				px,
				py + (i - 1) * height,
				width,
				height,
				pad,
				opt,
				isH,
				boxSize,
				entry.selected[i]
			)
		end

		-- Popup outline
		win:QueueDrawAtLayer(popupLayer, DrawComboPopupOutline, win, px, py, width, listH)
	end

	return entry.selected
end

return Combo
