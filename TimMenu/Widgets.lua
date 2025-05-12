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
		-- Add outline around button
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawOutlinedRect(absX, absY, absX + width, absY + height)
		-- Ensure text color is white
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
	local boxSize = txtH * 1.5
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
	local checkBounds = { x = absX, y = absY, w = width, h = height }
	local hovered = canInteract(win, checkBounds)

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
			local margin = math.floor(boxSize * 0.25)
			Common.DrawFilledRect(absX + margin, absY + margin, absX + boxSize - margin, absY + boxSize - margin)
		end
		-- Ensure text color is white
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
		-- Add outline around slider track
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawOutlinedRect(absX, absY, absX + width, absY + height)
		-- Ensure text color is white
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
	local textInputBounds = { x = absX, y = absY, w = width, h = height }
	-- Properly unpack mouse coordinates for hit test
	local mX, mY = table.unpack(input.GetMousePos())
	local hovered = isInBounds(mX, mY, textInputBounds)
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
	local arrowW, arrowH = draw.GetTextSize("v")
	local width = txtW + arrowW + pad * 3
	local height = txtH + pad * 2
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + pad
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y
	local dropBounds = { x = absX, y = absY, w = width, h = height }
	-- Unpack mouse position for hit test
	local mX2, mY2 = table.unpack(input.GetMousePos())
	local hovered = isInBounds(mX2, mY2, dropBounds)
		and not Utils.IsPointBlocked(TimMenuGlobal.order, TimMenuGlobal.windows, mX2, mY2, win.id)
	-- Interaction: press to open/select, debounce until release
	local listX, listY = absX + width, absY
	local itemH = height
	local listH = #options * itemH
	local pressKey = key .. ":press"
	local pressed = input.IsButtonPressed(MOUSE_LEFT)
	if pressed and not buttonPressState[pressKey] then
		if not entry.open and hovered then
			-- Open dropdown on click press when cursor is over control
			entry.open = true
		elseif entry.open then
			-- Select option if click press is on an item
			if isInBounds(mX2, mY2, { x = listX, y = listY, w = width, h = listH }) then
				local idx = math.floor((mY2 - listY) / itemH) + 1
				if idx >= 1 and idx <= #options then
					entry.selected = idx
					entry.changed = true
				end
			end
			-- Close dropdown on any click press when open
			entry.open = false
		end
		buttonPressState[pressKey] = true
	end
	-- Reset debounce on release
	if buttonPressState[pressKey] and not input.IsButtonDown(MOUSE_LEFT) then
		buttonPressState[pressKey] = false
	end
	-- Draw field
	win:QueueDrawAtLayer(2, function()
		-- Background and outline
		local bg = Globals.Colors.Item
		if entry.open then
			bg = Globals.Colors.ItemActive
		elseif hovered then
			bg = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(bg))
		Common.DrawFilledRect(absX, absY, absX + width, absY + height)
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawOutlinedRect(absX, absY, absX + width, absY + height)
		-- Ensure text color is white
		draw.Color(table.unpack(Globals.Colors.Text))
		-- Display selected option text
		local displayText = label
		local _, txtH = draw.GetTextSize(displayText) -- Measure text height inside closure
		Common.DrawText(absX + pad, absY + (height - txtH) / 2, displayText) -- Center vertically
		-- Dynamic dropdown arrow
		local arrowChar = entry.open and "▲" or "▼"
		local aw, ah = draw.GetTextSize(arrowChar) -- Measure arrow inside closure
		Common.DrawText(absX + width - pad - aw, absY + (height - ah) / 2, arrowChar) -- Use measured size
	end)
	-- Popup list
	if entry.open then
		-- Position popup to the right, aligned to control
		local listX, listY = absX + width, absY
		local itemH = height
		local listH = #options * itemH
		-- Draw popup background at topmost layer
		win:QueueDrawAtLayer(5, function()
			draw.Color(table.unpack(Globals.Colors.Window))
			Common.DrawFilledRect(listX, listY, listX + width, listY + listH)
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawOutlinedRect(listX, listY, listX + width, listY + listH)
		end)
		-- Draw items at topmost layer
		for i, opt in ipairs(options) do
			local optY = listY + (i - 1) * itemH
			local hoverOpt = input.GetMousePos()[1] >= listX
				and input.GetMousePos()[1] <= listX + width
				and input.GetMousePos()[2] >= optY
				and input.GetMousePos()[2] <= optY + itemH
			win:QueueDrawAtLayer(5, function()
				draw.Color(table.unpack(hoverOpt and Globals.Colors.ItemHover or Globals.Colors.Item))
				Common.DrawFilledRect(listX, optY, listX + width, optY + itemH)
				draw.Color(table.unpack(Globals.Colors.Text))
				-- Center popup item text vertically
				local _, optH = draw.GetTextSize(opt)
				Common.DrawText(listX + pad, optY + (itemH - optH) / 2, opt)
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

	-- Use relative coords for hit testing, absolute will be calculated in draw closure
	local relativePrevBounds = { x = 0, y = 0, w = btnW, h = totalHeight }
	local relativeTextBounds = { x = btnW + sepW, y = 0, w = fixedTextW, h = totalHeight }
	local relativeNextBounds = { x = btnW + sepW + fixedTextW + sepW, y = 0, w = btnW, h = totalHeight }

	local prevHovered = canInteract(win, {
		x = absX + relativePrevBounds.x,
		y = absY + relativePrevBounds.y,
		w = relativePrevBounds.w,
		h = relativePrevBounds.h,
	})
	local nextHovered = canInteract(win, {
		x = absX + relativeNextBounds.x,
		y = absY + relativeNextBounds.y,
		w = relativeNextBounds.w,
		h = relativeNextBounds.h,
	})

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

		-- Calculate absolute bounds *inside* the drawing closure
		local prevBounds = {
			x = currentAbsX + relativePrevBounds.x,
			y = currentAbsY + relativePrevBounds.y,
			w = relativePrevBounds.w,
			h = relativePrevBounds.h,
		}
		local textBounds = {
			x = currentAbsX + relativeTextBounds.x,
			y = currentAbsY + relativeTextBounds.y,
			w = relativeTextBounds.w,
			h = relativeTextBounds.h,
		}
		local nextBounds = {
			x = currentAbsX + relativeNextBounds.x,
			y = currentAbsY + relativeNextBounds.y,
			w = relativeNextBounds.w,
			h = relativeNextBounds.h,
		}

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
			prevBounds.y, -- Use calculated bounds Y for consistency
			currentAbsX + btnW + sepW + fixedTextW,
			prevBounds.y + totalHeight
		)
		-- Outer Outline
		Common.DrawOutlinedRect(currentAbsX, currentAbsY, currentAbsX + totalWidth, currentAbsY + totalHeight)
	end)

	return entry.selected, entry.changed
end

--- Draws a row of tabs and handles selection.
---@param win table The current window object.
---@param id string A unique identifier for this tab control.
---@param tabs table A list of strings representing the tab labels.
---@param currentTabIndex integer The 1-based index of the currently selected tab.
---@return integer newCurrentTabIndex The potentially updated selected tab index.
function Widgets.TabControl(win, id, tabs, currentTabIndex)
	assert(type(id) == "string", "Widgets.TabControl: id must be a string")
	assert(type(tabs) == "table", "Widgets.TabControl: tabs must be a table")
	assert(type(currentTabIndex) == "number", "Widgets.TabControl: currentTabIndex must be a number")

	local newIndex = currentTabIndex
	local selectedTabInfo = nil -- To store position/size of the selected tab button

	-- Calculate total width required for tabs to center them
	local totalTabsWidth = 0
	local padding = Globals.Style.ItemPadding
	draw.SetFont(Globals.Style.Font) -- Set font once for measurement
	for i, tabLabel in ipairs(tabs) do
		local textWidth, _ = draw.GetTextSize(tabLabel)
		local btnWidth = textWidth + (padding * 2)
		totalTabsWidth = totalTabsWidth + btnWidth
		if i < #tabs then
			totalTabsWidth = totalTabsWidth + Globals.Defaults.ITEM_SPACING
		end
	end

	-- Calculate starting X position for centering
	local windowContentPadding = Globals.Defaults.WINDOW_CONTENT_PADDING
	local contentWidth = win.W - (windowContentPadding * 2)
	local startXOffset = math.max(0, (contentWidth - totalTabsWidth) / 2) -- Don't go negative if tabs wider than window
	local initialCursorX = windowContentPadding + startXOffset

	-- Store original cursor position to reset for drawing the underline later
	local initialCursorY = win.cursorY
	local startY = initialCursorY -- Remember the Y position of the tab row

	-- We need to manually handle SameLine logic within the widget
	local currentLineMaxHeight = 0
	win.cursorX = initialCursorX -- Start cursor at calculated centered position

	for i, tabLabel in ipairs(tabs) do
		local isSelected = (i == currentTabIndex)
		-- Use a unique key for each tab button within this control
		local buttonKey = id .. ":tab:" .. tabLabel

		-- Calculate button dimensions (similar to Widgets.Button)
		draw.SetFont(Globals.Style.Font)
		local textWidth, textHeight = draw.GetTextSize(tabLabel)
		local btnWidth = textWidth + (padding * 2)
		local btnHeight = textHeight + (padding * 2)

		-- Manually reserve space (like win:AddWidget but simpler for this context)
		local currentButtonX = win.cursorX
		local currentButtonY = startY
		win.cursorX = win.cursorX + btnWidth
		currentLineMaxHeight = math.max(currentLineMaxHeight, btnHeight)

		local absX, absY = win.X + currentButtonX, win.Y + currentButtonY
		local bounds = { x = absX, y = absY, w = btnWidth, h = btnHeight }

		-- Interaction (similar to Widgets.Button but without unique index)
		local hovered = canInteract(win, bounds)
		buttonPressState = buttonPressState or {}
		local buttonKeyInternal = tostring(win.id) .. ":" .. buttonKey -- Match button's internal key format
		local clicked = false
		if hovered and input.IsButtonPressed(MOUSE_LEFT) and not buttonPressState[buttonKeyInternal] then
			clicked = true
			buttonPressState[buttonKeyInternal] = true
			newIndex = i -- Update selection on click
		end
		if buttonPressState[buttonKeyInternal] and not input.IsButtonDown(MOUSE_LEFT) then
			buttonPressState[buttonKeyInternal] = false
		end

		-- Store info for the selected tab to draw underline later
		if isSelected then
			selectedTabInfo = { x = currentButtonX, y = currentButtonY, w = btnWidth, h = btnHeight }
		end

		-- Queue drawing for the button (slightly modified from Widgets.Button)
		win:QueueDrawAtLayer(2, function(cx, cy, cw, ch, clabel, ckey, cIsSelected, cHovered)
			local currentAbsX, currentAbsY = win.X + cx, win.Y + cy
			-- Background (no special hover/active color for tabs, maybe adjust later?)
			-- Let's make selected tab text slightly brighter?
			local textColor = Globals.Colors.Text
			if cIsSelected then
				-- Maybe slightly brighter or different color? For now, same.
				textColor = Globals.Colors.Text -- Ensure selected is full white
			else
				-- Dimmer color for non-selected tabs
				textColor = { 180, 180, 180, 255 }
			end

			-- NO background fill for tabs like the image
			--[[ draw.Color(table.unpack(bgColor))
			Common.DrawFilledRect(currentAbsX, currentAbsY, currentAbsX + cw, currentAbsY + ch) ]]

			-- NO outline for tabs like the image
			--[[ draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawOutlinedRect(currentAbsX, currentAbsY, currentAbsX + cw, currentAbsY + ch) ]]

			-- Label text (centered)
			draw.Color(table.unpack(textColor))
			draw.SetFont(Globals.Style.Font)
			local actualTxtW, actualTxtH = draw.GetTextSize(clabel)
			Common.DrawText(currentAbsX + (cw - actualTxtW) / 2, currentAbsY + (ch - actualTxtH) / 2, clabel)
		end, currentButtonX, currentButtonY, btnWidth, btnHeight, tabLabel, buttonKeyInternal, isSelected, hovered)
	end

	-- After drawing all buttons, draw the underline if a tab is selected
	if selectedTabInfo then
		win:QueueDrawAtLayer(3, function(sInfo)
			local underlineY = win.Y + sInfo.y + sInfo.h -- Position below the button
			local underlineStartX = win.X + sInfo.x
			local underlineEndX = underlineStartX + sInfo.w
			local underlineHeight = 2 -- Thickness of the underline
			-- Use WindowBorder color for the underline
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawFilledRect(underlineStartX, underlineY, underlineEndX, underlineY + underlineHeight)
		end, selectedTabInfo)
	end

	-- Add a separator line below the tabs/underline
	win:QueueDrawAtLayer(1, function()
		local sepY = win.Y + startY + currentLineMaxHeight + (selectedTabInfo and 2 or 0) + 2 -- Position below tabs/underline + padding
		local sepStartX = win.X + Globals.Defaults.WINDOW_CONTENT_PADDING
		local sepEndX = win.X + win.W - Globals.Defaults.WINDOW_CONTENT_PADDING
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawLine(sepStartX, sepY, sepEndX, sepY)
	end)

	-- Update the window's cursor Y position based on the tallest element in the row + underline space
	-- Add space for underline (2px) + separator (1px) + increased padding (e.g., 12px)
	win.cursorY = startY + currentLineMaxHeight + (selectedTabInfo and 2 or 0) + 1 + 12
	-- Reset cursorX for the next line (standard behavior after a row)
	win.cursorX = Globals.Defaults.WINDOW_CONTENT_PADDING
	win.lineHeight = 0 -- Reset line height as this widget manually managed it

	return newIndex
end

--- Draws a multi-selection combo box; returns a table of booleans and whether changed.
function Widgets.Combo(win, label, selected, options)
	-- Setup
	win._widgetCounter = (win._widgetCounter or 0) + 1
	win._combos = win._combos or {}
	local key = tostring(win.id) .. ":combo:" .. label
	local entry = win._combos[key]
	if not entry then
		entry = { selected = {}, open = false, changed = false }
		for i = 1, #options do
			entry.selected[i] = selected[i] == true
		end
		win._combos[key] = entry
	else
		entry.changed = false
	end
	-- Measure sizes
	draw.SetFont(Globals.Style.Font)
	local _, txtH = draw.GetTextSize(label)
	local pad = Globals.Style.ItemPadding
	local boxSize = txtH * 1.5
	local maxOptW = 0
	for _, opt in ipairs(options) do
		local w, _ = draw.GetTextSize(opt)
		if w > maxOptW then
			maxOptW = w
		end
	end
	local width = pad + boxSize + pad + maxOptW + pad
	local height = boxSize + pad * 2
	-- Layout and positioning
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + pad
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y
	local dropX, dropY = absX + width, absY
	-- Input handling with debounce
	local mX, mY = table.unpack(input.GetMousePos())
	local hovered = isInBounds(mX, mY, { x = absX, y = absY, w = width, h = height })
		and not Utils.IsPointBlocked(TimMenuGlobal.order, TimMenuGlobal.windows, mX, mY, win.id)
	local listH = #options * height
	local pressKey = key .. ":press"
	if input.IsButtonPressed(MOUSE_LEFT) and not buttonPressState[pressKey] then
		if not entry.open and hovered then
			entry.open = true
		elseif entry.open then
			if isInBounds(mX, mY, { x = dropX, y = dropY, w = width, h = listH }) then
				local idx = math.floor((mY - dropY) / height) + 1
				if idx >= 1 and idx <= #options then
					entry.selected[idx] = not entry.selected[idx]
					entry.changed = true
				end
			elseif not hovered then
				entry.open = false
			end
		end
		buttonPressState[pressKey] = true
	end
	if buttonPressState[pressKey] and not input.IsButtonDown(MOUSE_LEFT) then
		buttonPressState[pressKey] = false
	end
	-- Draw the combo button
	win:QueueDrawAtLayer(2, function()
		-- Background and outline
		local bg = Globals.Colors.Item
		if entry.open then
			bg = Globals.Colors.ItemActive
		elseif hovered then
			bg = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(bg))
		Common.DrawFilledRect(absX, absY, absX + width, absY + height)
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawOutlinedRect(absX, absY, absX + width, absY + height)
		-- Ensure text color is white
		draw.Color(table.unpack(Globals.Colors.Text))
		-- Text summary of selections
		local displayText = label
		Common.DrawText(absX + pad, absY + (height - txtH) / 2, displayText)
		-- Dynamic arrow indicator
		local arrowChar = entry.open and "▲" or "▼"
		local aw, ah = draw.GetTextSize(arrowChar)
		Common.DrawText(absX + width - pad - aw, absY + (height - ah) / 2, arrowChar)
	end)
	-- Draw popup items when open
	if entry.open then
		win:QueueDrawAtLayer(5, function()
			draw.Color(table.unpack(Globals.Colors.Window))
			Common.DrawFilledRect(dropX, dropY, dropX + width, dropY + listH)
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawOutlinedRect(dropX, dropY, dropX + width, dropY + listH)
		end)
		for i, opt in ipairs(options) do
			local itemY = dropY + (i - 1) * height
			win:QueueDrawAtLayer(5, function()
				local hoverItem = isInBounds(
					input.GetMousePos()[1],
					input.GetMousePos()[2],
					{ x = dropX, y = itemY, w = width, h = height }
				) and not Utils.IsPointBlocked(
					TimMenuGlobal.order,
					TimMenuGlobal.windows,
					input.GetMousePos()[1],
					input.GetMousePos()[2],
					win.id
				)
				draw.Color(table.unpack(hoverItem and Globals.Colors.ItemHover or Globals.Colors.Item))
				Common.DrawFilledRect(dropX, itemY, dropX + width, itemY + height)
				-- Checkbox
				local bx, by = dropX + pad, itemY + pad
				draw.Color(table.unpack(Globals.Colors.WindowBorder))
				Common.DrawOutlinedRect(bx, by, bx + boxSize, by + boxSize)
				if entry.selected[i] then
					draw.Color(table.unpack(Globals.Colors.Highlight))
					local m = math.floor(boxSize * 0.25)
					Common.DrawFilledRect(bx + m, by + m, bx + boxSize - m, by + boxSize - m)
				end
				-- Text
				draw.Color(table.unpack(Globals.Colors.Text))
				Common.DrawText(bx + boxSize + pad, by, opt)
			end)
		end
	end
	return entry.selected, entry.changed
end

return Widgets
