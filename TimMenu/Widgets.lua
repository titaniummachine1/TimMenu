local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Utils = require("TimMenu.Utils")

local Widgets = {}

-- Track last pressed state per widget key to debounce clicks
local lastPressState = {}

-- Track last pressed state per button key to debounce clicks
local buttonPressState = {}

-- Helper function to check if a point is within bounds
local function isInBounds(x, y, bounds)
	return x >= bounds.x and x <= bounds.x + bounds.w and y >= bounds.y and y <= bounds.y + bounds.h
end

-- Helper to check if widget can be interacted with
local function canInteract(win, bounds)
	-- Only allow interaction if the mouse is within this widget and not blocked by windows above
	local mX, mY = table.unpack(input.GetMousePos())
	if not isInBounds(mX, mY, bounds) then
		return false
	end
	if Utils.IsPointBlocked(TimMenuGlobal.order, TimMenuGlobal.windows, mX, mY, win.id) then
		return false
	end
	return true
end

function Widgets.Button(win, label)
	-- assign a per-window unique index to avoid collisions
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter
	-- Calculate dimensions
	draw.SetFont(Globals.Style.Font)
	local textWidth, textHeight = draw.GetTextSize(label)
	local padding = Globals.Style.ItemPadding
	local width = textWidth + (padding * 2)
	local height = textHeight + (padding * 2)

	-- Handle padding between widgets
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + padding
	end

	-- Get widget position
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- Define bounds for interaction checking
	local bounds = {
		x = absX,
		y = absY,
		w = width,
		h = height,
	}

	-- Handle interaction
	local hovered = canInteract(win, bounds)
	local key = tostring(win.id) .. ":" .. label .. ":" .. widgetIndex
	local clicked = false
	if hovered and input.IsButtonPressed(MOUSE_LEFT) and not buttonPressState[key] then
		clicked = true
		buttonPressState[key] = true
	end
	if buttonPressState[key] and not input.IsButtonDown(MOUSE_LEFT) then
		buttonPressState[key] = false
	end

	win:QueueDrawAtLayer(2, function()
		-- Calculate position inside window so it follows dragging
		absX = win.X + x
		absY = win.Y + y
		-- Background using ImMenu style
		local bgColor = Globals.Colors.Item
		if buttonPressState[key] then
			bgColor = Globals.Colors.ItemActive
		elseif hovered then
			bgColor = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(bgColor))
		Common.DrawFilledRect(absX, absY, absX + width, absY + height)
		-- Label text
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		Common.DrawText(absX + padding, absY + padding, label)
	end)

	return clicked
end

--- Draws a checkbox widget within a window
--- @param win table current window object
--- @param label string text label for the checkbox
--- @param state boolean current checkbox state
--- @return boolean new state after click
function Widgets.Checkbox(win, label, state)
	-- assign a per-window unique index to avoid collisions
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter
	-- Font and sizing
	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(label)
	local padding = Globals.Style.ItemPadding
	local boxSize = txtH
	local width = boxSize + padding + txtW
	local height = boxSize

	-- Horizontal spacing between widgets
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + padding
	end

	-- Widget position
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- Interaction bounds
	local bounds = { x = absX, y = absY, w = width, h = height }
	local hovered = canInteract(win, bounds)

	-- Debounce: immediate toggle on press, reset on release
	local key = tostring(win.id) .. ":" .. label .. ":" .. widgetIndex
	local clicked = false
	if hovered and input.IsButtonPressed(MOUSE_LEFT) and not lastPressState[key] then
		state = not state
		clicked = true
		lastPressState[key] = true
	end
	if lastPressState[key] and not input.IsButtonDown(MOUSE_LEFT) then
		lastPressState[key] = false
	end

	win:QueueDrawAtLayer(2, function()
		-- Calculate position inside window so it follows dragging
		absX = win.X + x
		absY = win.Y + y
		-- Background using ImMenu style
		local bgColor = Globals.Colors.Item
		local active = hovered and input.IsButtonDown(MOUSE_LEFT)
		if active then
			bgColor = Globals.Colors.ItemActive
		elseif hovered then
			bgColor = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(bgColor))
		Common.DrawFilledRect(absX, absY, absX + boxSize, absY + boxSize)
		-- Check mark fill
		if state then
			draw.Color(table.unpack(Globals.Colors.Highlight))
			Common.DrawFilledRect(absX + 2, absY + 2, absX + boxSize - 2, absY + boxSize - 2)
		end
		-- Label text
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		Common.DrawText(absX + boxSize + padding, absY + (boxSize // 2) - (txtH // 2), label)
	end)

	return state, clicked
end

--- Draws a slider widget, returning the new value and whether it changed.
function Widgets.Slider(win, label, value, min, max, step)
	-- mark last widget type for specialized spacing
	win._lastWidgetType = "slider"
	-- assign a per-window unique index to avoid collisions in layout (but not for dragging)
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter
	-- Set font and measure label text
	draw.SetFont(Globals.Style.Font)
	local labelText = label .. ": " .. tostring(value)
	local txtW, txtH = draw.GetTextSize(labelText)
	local padding = Globals.Style.ItemPadding
	local height = txtH + (padding * 2)
	-- Fixed slider width from ImMenu default
	local width = Globals.Defaults.SLIDER_WIDTH
	-- Ensure it fits label
	if width < txtW + (padding * 4) then
		width = txtW + (padding * 4)
	end
	-- Horizontal spacing
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + padding
	end
	-- Reserve layout space
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- Determine normalized fill percent
	local norm = (value - min) / (max - min)
	if norm < 0 then
		norm = 0
	elseif norm > 1 then
		norm = 1
	end

	-- Interaction logic: click+drag across full slider
	local mX, mY = table.unpack(input.GetMousePos())
	local hovered = (mX >= absX and mX <= absX + width and mY >= absY and mY <= absY + height)
	local pressed = input.IsButtonPressed(MOUSE_LEFT)
	local down = input.IsButtonDown(MOUSE_LEFT)
	local key = tostring(win.id) .. ":slider:" .. label
	Widgets._sliderDragging = Widgets._sliderDragging or {}
	local dragging = Widgets._sliderDragging[key] or false
	if hovered and pressed then
		dragging = true
	elseif not down then
		dragging = false
	end
	Widgets._sliderDragging[key] = dragging

	-- Compute new value when dragging
	local changed = false
	if dragging then
		local t = (mX - absX) / width
		if t < 0 then
			t = 0
		elseif t > 1 then
			t = 1
		end
		local raw = min + ((max - min) * t)
		local stepped = min + (Common.Clamp((raw - min) / step) * step)
		if stepped < min then
			stepped = min
		elseif stepped > max then
			stepped = max
		end
		if stepped ~= value then
			value = stepped
			changed = true
		end
	end

	-- Draw slider background, fill, and centered label
	win:QueueDrawAtLayer(2, function()
		-- Calculate position inside window so it follows dragging
		local absX = win.X + x
		local absY = win.Y + y
		-- Background
		local bg = Globals.Colors.Item
		draw.Color(table.unpack(bg))
		Common.DrawFilledRect(absX, absY, absX + width, absY + height)
		-- Fill portion
		local fillCol = dragging and Globals.Colors.HighlightActive or Globals.Colors.Highlight
		draw.Color(table.unpack(fillCol))
		Common.DrawFilledRect(absX, absY, absX + (width * norm), absY + height)
		-- Label centered
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		Common.DrawText(absX + (width - txtW) * 0.5, absY + (height - txtH) * 0.5, labelText)
	end)

	return value, changed
end

--- Draws a horizontal separator line across the current window's content area.
--- It reserves minimal height but does not expand the window width.
---@param win table current window object
---@param label string optional text label in center
function Widgets.Separator(win, label)
	local padding = Globals.Defaults.WINDOW_CONTENT_PADDING
	local vpad = Globals.Style.ItemPadding
	-- ensure separator starts on its own line and add top padding
	if win.cursorX > padding then
		win:NextLine(0)
	end
	win:NextLine(vpad)
	local totalWidth = win.W - (padding * 2)
	if type(label) == "string" then
		-- Labeled separator: center text with lines on either side
		draw.SetFont(Globals.Style.Font)
		local textWidth, textHeight = draw.GetTextSize(label)
		local x, y = win:AddWidget(totalWidth, textHeight)
		win:QueueDrawAtLayer(1, function()
			local absX = win.X + x
			local absY = win.Y + y
			local centerY = absY + math.floor(textHeight / 2)
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			-- Left line
			Common.DrawLine(absX, centerY, absX + (totalWidth - textWidth) / 2 - Globals.Style.ItemPadding, centerY)
			-- Label
			draw.Color(table.unpack(Globals.Colors.Text))
			Common.DrawText(absX + (totalWidth - textWidth) / 2, absY, label)
			-- Right line
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawLine(
				absX + (totalWidth + textWidth) / 2 + Globals.Style.ItemPadding,
				centerY,
				absX + totalWidth,
				centerY
			)
		end)
	else
		-- Simple separator
		local x, y = win:AddWidget(totalWidth, 1)
		win:QueueDrawAtLayer(1, function()
			local absX = win.X + x
			local absY = win.Y + y
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawLine(absX, absY, absX + totalWidth, absY)
		end)
	end
	-- add bottom padding
	win:NextLine(vpad)
end

--- Draws a single-line text input; returns new text and whether it changed.
function Widgets.TextInput(win, label, text)
	win._widgetCounter = (win._widgetCounter or 0) + 1
	win._textInputs = win._textInputs or {}
	local key = tostring(win.id) .. ":textinput:" .. label
	local entry = win._textInputs[key]
	if not entry then
		entry = { text = text or "", active = false }
		win._textInputs[key] = entry
	elseif text and text ~= entry.text then
		entry.text = text
	end
	-- Calculate size
	local display = entry.text == "" and label or entry.text
	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(display)
	local pad = Globals.Style.ItemPadding
	local width = txtW + pad * 2
	local height = txtH + pad * 2
	-- Layout
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + pad
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y
	local bounds = { x = absX, y = absY, w = width, h = height }
	local hovered = isInBounds(input.GetMousePos(), bounds)
	-- Activate on click
	if hovered and input.IsButtonPressed(MOUSE_LEFT) then
		entry.active = true
	elseif entry.active and input.IsButtonPressed(MOUSE_LEFT) and not hovered then
		entry.active = false
	end
	local changed = false
	-- Handle key input when active
	if entry.active then
		-- Backspace
		if input.IsButtonPressed(KEY_BACKSPACE) then
			entry.text = entry.text:sub(1, -2)
			changed = true
		end
		-- Space
		if input.IsButtonPressed(KEY_SPACE) then
			entry.text = entry.text .. " "
			changed = true
		end
		-- Letters A-Z
		for code = 65, 90 do
			if input.IsButtonPressed(code) then
				entry.text = entry.text .. string.char(code)
				changed = true
			end
		end
		-- Digits 0-9
		for code = 48, 57 do
			if input.IsButtonPressed(code) then
				entry.text = entry.text .. string.char(code)
				changed = true
			end
		end
	end
	-- Draw box and text
	win:QueueDrawAtLayer(2, function()
		local bg = Globals.Colors.Item
		if entry.active then
			bg = Globals.Colors.ItemActive
		elseif hovered then
			bg = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(bg))
		Common.DrawFilledRect(absX, absY, absX + width, absY + height)
		draw.Color(table.unpack(Globals.Colors.Text))
		Common.DrawText(absX + pad, absY + pad, entry.text)
	end)
	return entry.text, changed
end

--- Draws a dropdown list; returns selected index and whether changed.
function Widgets.Dropdown(win, label, selectedIndex, options)
	win._widgetCounter = (win._widgetCounter or 0) + 1
	win._dropdowns = win._dropdowns or {}
	local key = tostring(win.id) .. ":dropdown:" .. label
	local entry = win._dropdowns[key]
	if not entry then
		entry = { selected = selectedIndex or 1, open = false, changed = false }
		win._dropdowns[key] = entry
	else
		entry.changed = false
		if selectedIndex and selectedIndex ~= entry.selected then
			entry.selected = selectedIndex
		end
	end
	-- Measure
	draw.SetFont(Globals.Style.Font)
	local text = options[entry.selected] or ""
	local txtW, txtH = draw.GetTextSize(text)
	local pad = Globals.Style.ItemPadding
	local arrowW, _ = draw.GetTextSize("v")
	local width = txtW + arrowW + pad * 3
	local height = txtH + pad * 2
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + pad
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y
	local bounds = { x = absX, y = absY, w = width, h = height }
	local hovered = isInBounds(input.GetMousePos(), bounds)
		and not Utils.IsPointBlocked(TimMenuGlobal.order, TimMenuGlobal.windows, unpack(input.GetMousePos()), win.id)
	-- Toggle open
	if hovered and input.IsButtonPressed(MOUSE_LEFT) then
		entry.open = not entry.open
	end
	-- Close if clicked outside
	if entry.open and input.IsButtonPressed(MOUSE_LEFT) and not hovered then
		entry.open = false
	end
	-- Draw field
	win:QueueDrawAtLayer(2, function()
		local bg = Globals.Colors.Item
		if entry.open then
			bg = Globals.Colors.ItemActive
		elseif hovered then
			bg = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(bg))
		Common.DrawFilledRect(absX, absY, absX + width, absY + height)
		draw.Color(table.unpack(Globals.Colors.Text))
		Common.DrawText(absX + pad, absY + pad, text)
		Common.DrawText(absX + width - pad - arrowW, absY + pad, "v")
	end)
	-- Popup list
	if entry.open then
		local listX, listY = absX, absY + height
		local itemH = height
		local listH = #options * itemH
		-- Background
		win:QueueDrawAtLayer(1, function()
			draw.Color(table.unpack(Globals.Colors.Window))
			Common.DrawFilledRect(listX, listY, listX + width, listY + listH)
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawOutlinedRect(listX, listY, listX + width, listY + listH)
		end)
		-- Items
		for i, opt in ipairs(options) do
			local optY = listY + (i - 1) * itemH
			local hoverOpt = input.GetMousePos()[1] >= listX
				and input.GetMousePos()[1] <= listX + width
				and input.GetMousePos()[2] >= optY
				and input.GetMousePos()[2] <= optY + itemH
			if hoverOpt and input.IsButtonPressed(MOUSE_LEFT) then
				entry.selected = i
				entry.open = false
				entry.changed = true
			end
			win:QueueDrawAtLayer(2, function()
				draw.Color(table.unpack(hoverOpt and Globals.Colors.ItemHover or Globals.Colors.Item))
				Common.DrawFilledRect(listX, optY, listX + width, optY + itemH)
				draw.Color(table.unpack(Globals.Colors.Text))
				Common.DrawText(listX + pad, optY + pad, opt)
			end)
		end
	end
	return entry.selected, entry.changed
end

--- Draws a cyclic selector (< [value] >); returns new index and whether changed.
function Widgets.Selector(win, label, selectedIndex, options)
	win._widgetCounter = (win._widgetCounter or 0) + 1
	win._selectors = win._selectors or {}
	local safeLabel = label or "<nil_selector_label>"
	local key = tostring(win.id) .. ":selector:" .. safeLabel
	local entry = win._selectors[key]
	if not entry then
		entry = { selected = selectedIndex or 1, changed = false }
		win._selectors[key] = entry
	else
		entry.changed = false
		if selectedIndex and selectedIndex ~= entry.selected then
			entry.selected = selectedIndex
		end
	end

	-- --- Styling & Calculation ---
	draw.SetFont(Globals.Style.Font)
	local pad = Globals.Style.ItemPadding
	local _, btnSymH = draw.GetTextSize("<") -- Use symbol height for consistency
	local btnW = btnSymH + (pad * 2) -- Make buttons square-ish based on text height
	local btnH = btnSymH + (pad * 2)

	-- Estimate max text width or use a fixed width? Let's try fixed for now.
	local fixedTextW = 100 -- Adjust as needed
	local _, fixedTextH = draw.GetTextSize("Placeholder")
	local textDisplayH = fixedTextH + (pad * 2)

	local sepW = 1 -- Separator line width
	local totalWidth = btnW + sepW + fixedTextW + sepW + btnW
	local totalHeight = math.max(btnH, textDisplayH) -- Use max height

	-- Reserve space for the whole widget
	local x, y = win:AddWidget(totalWidth, totalHeight)
	local absX, absY = win.X + x, win.Y + y

	-- --- Interaction --- (Needs internal state like Button)
	local prevBtnKey = key .. ":prev"
	local nextBtnKey = key .. ":next"
	buttonPressState = buttonPressState or {}

	local mX, mY = input.GetMousePos()

	-- Define interaction bounds for internal buttons
	local prevBounds = { x = absX, y = absY, w = btnW, h = totalHeight }
	local textBounds = { x = absX + btnW + sepW, y = absY, w = fixedTextW, h = totalHeight }
	local nextBounds = { x = absX + btnW + sepW + fixedTextW + sepW, y = absY, w = btnW, h = totalHeight }

	local prevHovered = canInteract(win, prevBounds)
	local nextHovered = canInteract(win, nextBounds)

	-- Handle Prev Button Click
	if prevHovered and input.IsButtonPressed(MOUSE_LEFT) and not buttonPressState[prevBtnKey] then
		buttonPressState[prevBtnKey] = true
		entry.selected = entry.selected - 1
		if entry.selected < 1 then
			entry.selected = #options
		end
		entry.changed = true
	end
	if buttonPressState[prevBtnKey] and not input.IsButtonDown(MOUSE_LEFT) then
		buttonPressState[prevBtnKey] = false
	end

	-- Handle Next Button Click
	if nextHovered and input.IsButtonPressed(MOUSE_LEFT) and not buttonPressState[nextBtnKey] then
		buttonPressState[nextBtnKey] = true
		entry.selected = entry.selected + 1
		if entry.selected > #options then
			entry.selected = 1
		end
		entry.changed = true
	end
	if buttonPressState[nextBtnKey] and not input.IsButtonDown(MOUSE_LEFT) then
		buttonPressState[nextBtnKey] = false
	end

	-- --- Drawing --- (Draw all parts manually)
	win:QueueDrawAtLayer(2, function()
		local currentAbsX, currentAbsY = win.X + x, win.Y + y -- Recalculate in case window moved

		-- Overall background (optional, could just rely on item backgrounds)
		-- draw.Color(table.unpack(Globals.Colors.Item))
		-- Common.DrawFilledRect(currentAbsX, currentAbsY, currentAbsX + totalWidth, currentAbsY + totalHeight)

		-- Prev Button Drawing
		local prevBgColor = Globals.Colors.Item
		if buttonPressState[prevBtnKey] then
			prevBgColor = Globals.Colors.ItemActive
		elseif prevHovered then
			prevBgColor = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(prevBgColor))
		Common.DrawFilledRect(prevBounds.x, prevBounds.y, prevBounds.x + prevBounds.w, prevBounds.y + prevBounds.h)
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		local prevTxtW, prevTxtH = draw.GetTextSize("<")
		Common.DrawText(prevBounds.x + (prevBounds.w - prevTxtW) / 2, prevBounds.y + (prevBounds.h - prevTxtH) / 2, "<")

		-- Text Area Drawing
		local displayText = tostring(options[entry.selected])
		local textBgColor = Globals.Colors.Item -- Use standard item background
		draw.Color(table.unpack(textBgColor))
		Common.DrawFilledRect(textBounds.x, textBounds.y, textBounds.x + textBounds.w, textBounds.y + textBounds.h)
		draw.Color(table.unpack(Globals.Colors.Text))
		local dispTxtW, dispTxtH = draw.GetTextSize(displayText)
		-- Center text horizontally and vertically in its area
		Common.DrawText(
			textBounds.x + (textBounds.w - dispTxtW) / 2,
			textBounds.y + (textBounds.h - dispTxtH) / 2,
			displayText
		)

		-- Next Button Drawing
		local nextBgColor = Globals.Colors.Item
		if buttonPressState[nextBtnKey] then
			nextBgColor = Globals.Colors.ItemActive
		elseif nextHovered then
			nextBgColor = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(nextBgColor))
		Common.DrawFilledRect(nextBounds.x, nextBounds.y, nextBounds.x + nextBounds.w, nextBounds.y + nextBounds.h)
		draw.Color(table.unpack(Globals.Colors.Text))
		local nextTxtW, nextTxtH = draw.GetTextSize(">")
		Common.DrawText(nextBounds.x + (nextBounds.w - nextTxtW) / 2, nextBounds.y + (nextBounds.h - nextTxtH) / 2, ">")

		-- Separator Lines & Outline
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		-- Left Separator
		Common.DrawLine(currentAbsX + btnW, currentAbsY, currentAbsX + btnW, currentAbsY + totalHeight)
		-- Right Separator
		Common.DrawLine(
			currentAbsX + btnW + sepW + fixedTextW,
			currentAbsY,
			currentAbsX + btnW + sepW + fixedTextW,
			currentAbsY + totalHeight
		)
		-- Outer Outline
		Common.DrawOutlinedRect(currentAbsX, currentAbsY, currentAbsX + totalWidth, currentAbsY + totalHeight)
	end)

	return entry.selected, entry.changed
end

return Widgets
