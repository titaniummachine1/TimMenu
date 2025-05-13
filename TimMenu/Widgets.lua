local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Utils = require("TimMenu.Utils")
local Interaction = require("TimMenu.Interaction")
local DrawHelpers = require("TimMenu.DrawHelpers")

local Widgets = {}

-- Local table to track slider dragging state (replaces former Widgets._sliderDragging)
local sliderDragState = {}

-- Helper to check if widget can be interacted with
local function canInteract(win, bounds)
	return Interaction.IsHovered(win, bounds)
end

-- Add named draw helpers for Dropdown and Combo widgets
local function DrawDropdownField(win, relX, relY, width, height, pad, label, entryOpen, hovered, arrowW, arrowH)
	-- Compute absolute position
	local absX = win.X + relX
	local absY = win.Y + relY

	-- Define arrow box dimensions (square, using widget height)
	local arrowBoxW = height
	local arrowBoxX = absX + width - arrowBoxW

	-- Background for the main part (excluding arrow box)
	local mainBgWidth = width - arrowBoxW
	local bgColor = Globals.Colors.Item
	if entryOpen then
		bgColor = Globals.Colors.ItemActive
	elseif hovered then
		bgColor = Globals.Colors.ItemHover
	end
	draw.Color(table.unpack(bgColor))
	Common.DrawFilledRect(absX, absY, absX + mainBgWidth, absY + height)

	-- Background for the arrow box
	draw.Color(table.unpack(Globals.Colors.ArrowBoxBg))
	Common.DrawFilledRect(arrowBoxX, absY, arrowBoxX + arrowBoxW, absY + height)

	-- Outline for the entire widget
	draw.Color(table.unpack(Globals.Colors.WindowBorder))
	Common.DrawOutlinedRect(absX, absY, absX + width, absY + height)

	-- Label text
	draw.Color(table.unpack(Globals.Colors.Text))
	local _, txtH = draw.GetTextSize(label)
	Common.DrawText(absX + pad, absY + (height - txtH) / 2, label)

	-- Arrow (chevron) via DrawHelpers
	local actualArrowW = arrowW * 0.5
	local actualArrowH = arrowH * 0.5
	local triX = arrowBoxX + (arrowBoxW - actualArrowW) / 2
	local triY = absY + (height - actualArrowH) / 2
	DrawHelpers.DrawArrow(triX, triY, actualArrowW, actualArrowH, entryOpen and "up" or "down", Globals.Colors.Text)
end

-- Corrected DrawDropdownPopupBackground
local function DrawDropdownPopupBackground(win, relX, relY, width, listH)
	-- Compute absolute position
	local absX = win.X + relX
	local absY = win.Y + relY

	-- Draw the popup background
	draw.Color(table.unpack(Globals.Colors.Window)) -- Use the standard window/popup background color
	Common.DrawFilledRect(absX, absY, absX + width, absY + listH)
end

local function DrawDropdownPopupItem(win, relX, relY, width, itemH, pad, opt, isHovered)
	-- Compute absolute position
	local absX = win.X + relX
	local absY = win.Y + relY
	draw.Color(table.unpack(isHovered and Globals.Colors.ItemHover or Globals.Colors.Item))
	Common.DrawFilledRect(absX, absY, absX + width, absY + itemH)
	draw.Color(table.unpack(Globals.Colors.Text))
	local _, optH = draw.GetTextSize(opt)
	Common.DrawText(absX + pad, absY + (itemH - optH) / 2, opt)
end

local function DrawDropdownPopupOutline(win, relX, relY, width, listH)
	-- Compute absolute position
	local absX = win.X + relX
	local absY = win.Y + relY
	draw.Color(table.unpack(Globals.Colors.WindowBorder))
	Common.DrawOutlinedRect(absX, absY, absX + width, absY + listH)
end

local function DrawComboField(win, relX, relY, width, height, pad, label, entryOpen, hovered, arrowW, arrowH)
	-- Compute absolute position
	local absX = win.X + relX
	local absY = win.Y + relY

	-- Define arrow box dimensions (square, using widget height)
	local arrowBoxW = height
	local arrowBoxX = absX + width - arrowBoxW

	-- Background for the main part (excluding arrow box)
	local mainBgWidth = width - arrowBoxW
	local bgColor = Globals.Colors.Item
	if entryOpen then
		bgColor = Globals.Colors.ItemActive
	elseif hovered then
		bgColor = Globals.Colors.ItemHover
	end
	draw.Color(table.unpack(bgColor))
	Common.DrawFilledRect(absX, absY, absX + mainBgWidth, absY + height)

	-- Background for the arrow box
	draw.Color(table.unpack(Globals.Colors.ArrowBoxBg))
	Common.DrawFilledRect(arrowBoxX, absY, arrowBoxX + arrowBoxW, absY + height)

	-- Outline for the entire widget
	draw.Color(table.unpack(Globals.Colors.WindowBorder))
	Common.DrawOutlinedRect(absX, absY, absX + width, absY + height)

	-- Label text
	draw.Color(table.unpack(Globals.Colors.Text))
	local _, txtH = draw.GetTextSize(label)
	Common.DrawText(absX + pad, absY + (height - txtH) / 2, label)

	-- Arrow via DrawHelpers
	local actualArrowW = arrowW * 0.5
	local actualArrowH = arrowH * 0.5
	local triX = arrowBoxX + (arrowBoxW - actualArrowW) / 2
	local triY = absY + (height - actualArrowH) / 2
	DrawHelpers.DrawArrow(triX, triY, actualArrowW, actualArrowH, entryOpen and "up" or "down", Globals.Colors.Text)
end

local function DrawComboPopupBackground(win, relX, relY, width, listH)
	-- Compute absolute position
	local absX = win.X + relX
	local absY = win.Y + relY
	draw.Color(table.unpack(Globals.Colors.Window))
	Common.DrawFilledRect(absX, absY, absX + width, absY + listH)
end

local function DrawComboPopupItem(win, relX, relY, width, height, pad, opt, isHovered, popupBoxSize, isSelected)
	-- Compute absolute position
	local absX = win.X + relX
	local absY = win.Y + relY
	draw.Color(table.unpack(isHovered and Globals.Colors.ItemHover or Globals.Colors.Item))
	Common.DrawFilledRect(absX, absY, absX + width, absY + height)
	local bx = absX + pad
	local by = absY + (height / 2) - (popupBoxSize / 2)
	draw.Color(table.unpack(Globals.Colors.WindowBorder))
	Common.DrawOutlinedRect(bx, by, bx + popupBoxSize, by + popupBoxSize)
	if isSelected then
		draw.Color(table.unpack(Globals.Colors.Highlight))
		local m = math.floor(popupBoxSize * 0.25)
		Common.DrawFilledRect(bx + m, by + m, bx + popupBoxSize - m, by + popupBoxSize - m)
	end
	draw.Color(table.unpack(Globals.Colors.Text))
	local _, optH = draw.GetTextSize(opt)
	Common.DrawText(bx + popupBoxSize + pad, absY + (height / 2) - (optH / 2), opt)
end

local function DrawComboPopupOutline(win, relX, relY, width, listH)
	-- Compute absolute position
	local absX = win.X + relX
	local absY = win.Y + relY
	draw.Color(table.unpack(Globals.Colors.WindowBorder))
	Common.DrawOutlinedRect(absX, absY, absX + width, absY + listH)
end

function Widgets.Button(win, label)
	assert(type(win) == "table", "Widgets.Button: win must be a table")
	assert(type(label) == "string", "Widgets.Button: label must be a string")
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
	local clicked = hovered and Interaction.IsPressed(key)
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(key)
	end

	win:QueueDrawAtLayer(2, function()
		-- Calculate position inside window so it follows dragging
		absX = win.X + x
		absY = win.Y + y
		-- Background using ImMenu style
		local bgColor = Globals.Colors.Item
		if Interaction._PressState[key] then
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
	assert(type(win) == "table", "Widgets.Checkbox: win must be a table")
	assert(type(label) == "string", "Widgets.Checkbox: label must be a string")
	assert(type(state) == "boolean", "Widgets.Checkbox: state must be a boolean")
	-- assign a per-window unique index to avoid collisions
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter
	-- Font and sizing
	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(label)
	local padding = Globals.Style.ItemPadding
	local boxSize = txtH -- smaller checkbox for better visual separation
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

	-- Debounce using Interaction helpers
	local key = tostring(win.id) .. ":" .. label .. ":" .. widgetIndex
	local clicked = false
	if hovered and Interaction.IsPressed(key) then
		state = not state
		clicked = true
	end
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(key)
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

		-- Add semi-transparent outline using the dedicated color
		draw.Color(table.unpack(Globals.Colors.WidgetOutline))
		Common.DrawOutlinedRect(absX, absY, absX + boxSize, absY + boxSize)

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
	assert(type(win) == "table", "Widgets.Slider: win must be a table")
	assert(type(label) == "string", "Widgets.Slider: label must be a string")
	assert(type(value) == "number", "Widgets.Slider: value must be a number")
	assert(type(min) == "number", "Widgets.Slider: min must be a number")
	assert(type(max) == "number", "Widgets.Slider: max must be a number")
	assert(type(step) == "number", "Widgets.Slider: step must be a number")
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
	local hovered = Interaction.IsHovered(win, { x = absX, y = absY, w = width, h = height })
	local pressed = input.IsButtonPressed(MOUSE_LEFT)
	local down = input.IsButtonDown(MOUSE_LEFT)
	local key = tostring(win.id) .. ":slider:" .. label
	local dragging = sliderDragState[key] or false
	if hovered and pressed then
		dragging = true
	elseif not down then
		dragging = false
	end
	sliderDragState[key] = dragging

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

	-- Draw slider background, fill, and centered label (with hover effect)
	win:QueueDrawAtLayer(2, function(hv)
		-- Calculate position inside window so it follows dragging
		local absX = win.X + x
		local absY = win.Y + y
		-- Background with hover highlight
		local bg = hv and Globals.Colors.ItemHover or Globals.Colors.Item
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
	end, hovered)

	return value, changed
end

--- Draws a horizontal separator line across the current window's content area.
--- It reserves minimal height but does not expand the window width.
---@param win table current window object
---@param label string optional text label in center
function Widgets.Separator(win, label)
	assert(type(win) == "table", "Widgets.Separator: win must be a table")
	assert(label == nil or type(label) == "string", "Widgets.Separator: label must be a string or nil")
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
	assert(type(win) == "table", "Widgets.TextInput: win must be a table")
	assert(type(label) == "string", "Widgets.TextInput: label must be a string")
	assert(text == nil or type(text) == "string", "Widgets.TextInput: text must be a string or nil")
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
	local hovered = Interaction.IsHovered(win, textInputBounds)
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
	assert(type(win) == "table", "Widgets.Dropdown: win must be a table")
	assert(type(label) == "string", "Widgets.Dropdown: label must be a string")
	assert(
		selectedIndex == nil or type(selectedIndex) == "number",
		"Widgets.Dropdown: selectedIndex must be a number or nil"
	)
	assert(type(options) == "table", "Widgets.Dropdown: options must be a table")
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
	-- Measure based on label and arrow size
	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(label)
	local pad = Globals.Style.ItemPadding
	local arrowChar = "▼"
	local arrowW, arrowH = draw.GetTextSize(arrowChar)
	-- Calculate height first
	local height = math.max(txtH, arrowH) + pad * 2
	-- Calculate width including text, padding, and square arrow box
	local arrowBoxW = height -- Arrow box is square
	local width = txtW + pad * 2 + arrowBoxW -- Text + Padding + ArrowBox

	-- Layout and positioning
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + pad
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y
	local dropBounds = { x = absX, y = absY, w = width, h = height }
	-- Unpack mouse position for hit test
	local mX2, mY2 = table.unpack(input.GetMousePos())
	local hovered = Interaction.IsHovered(win, dropBounds)
	-- Close dropdown popup on outside click
	local popupX, popupY = absX, absY + height
	local popupBounds = { x = popupX, y = popupY, w = width, h = #options * height }
	Interaction.ClosePopupOnOutsideClick(entry, mX2, mY2, dropBounds, popupBounds, win)
	-- Interaction: single-click consumption to toggle, select, or close
	local clicked = Interaction.ConsumeWidgetClick(win, hovered, entry.open)
	if clicked then
		local mX, mY = table.unpack(input.GetMousePos())
		local popupX, popupY = absX, absY + height
		local listH = #options * height
		local popupBounds = { x = popupX, y = popupY, w = width, h = listH }
		if not entry.open and hovered then
			entry.open = true
			win._widgetBlockedRegions = win._widgetBlockedRegions or {}
			win._widgetBlockedRegions[#win._widgetBlockedRegions + 1] = popupBounds
		elseif entry.open then
			if Interaction.IsHovered(win, popupBounds) then
				-- Toggle selection inside popup
				local idx = math.floor((mY - popupY) / height) + 1
				if idx >= 1 and idx <= #options then
					entry.selected = idx
					entry.changed = true
				end
			else
				-- Click outside field and popup: close
				entry.open = false
				win._widgetBlockedRegions = {}
			end
		end
	end
	-- Draw field
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
	-- Popup list
	if entry.open then
		-- Position popup list below the main field
		local popupX, popupY = x, y + height -- Use relative coords for QueueDraw
		local itemH = height -- Recalculate itemH based on field height
		local listH = #options * itemH
		-- Draw popup background at topmost layer
		win:QueueDrawAtLayer(5, DrawDropdownPopupBackground, win, popupX, popupY, width, listH)
		-- Draw items at topmost layer
		for i, opt in ipairs(options) do
			-- Calculate absolute position of item for hover check
			local itemAbsX = absX
			local itemAbsY = absY + height + (i - 1) * itemH
			local hoverOpt = Interaction.IsHovered(win, { x = itemAbsX, y = itemAbsY, w = width, h = itemH })
			win:QueueDrawAtLayer(
				5,
				DrawDropdownPopupItem,
				win,
				popupX, -- Use relative X
				popupY + (i - 1) * itemH, -- Use relative Y + offset
				width,
				itemH,
				pad,
				opt,
				hoverOpt
			)
		end
		-- Outline popup box after drawing items
		win:QueueDrawAtLayer(5, DrawDropdownPopupOutline, win, popupX, popupY, width, listH)
	end
	return entry.selected, entry.changed
end

--- Draws a cyclic selector (< [value] >); returns new index and whether changed.
function Widgets.Selector(win, label, selectedIndex, options)
	assert(type(win) == "table", "Widgets.Selector: win must be a table")
	assert(label == nil or type(label) == "string", "Widgets.Selector: label must be a string or nil")
	assert(type(selectedIndex) == "number", "Widgets.Selector: selectedIndex must be a number")
	assert(type(options) == "table", "Widgets.Selector: options must be a table")
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
	-- press-state handled by Interaction module

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
	if prevHovered and Interaction.IsPressed(prevBtnKey) then
		entry.selected = entry.selected - 1
		if entry.selected < 1 then
			entry.selected = #options
		end
		entry.changed = true
	end
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(prevBtnKey)
	end

	-- Handle Next Button Click
	if nextHovered and Interaction.IsPressed(nextBtnKey) then
		entry.selected = entry.selected + 1
		if entry.selected > #options then
			entry.selected = 1
		end
		entry.changed = true
	end
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(nextBtnKey)
	end

	-- Handle central region click (left/right half)
	local centralKey = key .. ":center"
	local textAbsBounds = {
		x = absX + relativeTextBounds.x,
		y = absY + relativeTextBounds.y,
		w = relativeTextBounds.w,
		h = relativeTextBounds.h,
	}
	if Interaction.IsHovered(win, textAbsBounds) and Interaction.IsPressed(centralKey) then
		local mXc, mYc = table.unpack(input.GetMousePos())
		local centerX = textAbsBounds.x + textAbsBounds.w * 0.5
		if mXc < centerX then
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
		Interaction.Release(centralKey)
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
		if Interaction._PressState[prevBtnKey] then
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

		-- Text Area Drawing with half-region hover highlight
		local displayText = tostring(options[entry.selected])
		draw.SetFont(Globals.Style.Font)
		local dispTxtW, dispTxtH = draw.GetTextSize(displayText)
		local halfW = textBounds.w * 0.5
		-- Left half highlight
		local leftBounds = { x = textBounds.x, y = textBounds.y, w = halfW, h = textBounds.h }
		local leftHover = Interaction.IsHovered(win, leftBounds)
		draw.Color(table.unpack(leftHover and Globals.Colors.ItemHover or Globals.Colors.Item))
		Common.DrawFilledRect(leftBounds.x, leftBounds.y, leftBounds.x + leftBounds.w, leftBounds.y + leftBounds.h)
		-- Right half highlight
		local rightBounds = { x = textBounds.x + halfW, y = textBounds.y, w = halfW, h = textBounds.h }
		local rightHover = Interaction.IsHovered(win, rightBounds)
		draw.Color(table.unpack(rightHover and Globals.Colors.ItemHover or Globals.Colors.Item))
		draw.Color(table.unpack(Globals.Colors.Text))
		Common.DrawText(
			textBounds.x + (textBounds.w - dispTxtW) / 2,
			textBounds.y + (textBounds.h - dispTxtH) / 2,
			displayText
		)

		-- Next Button Drawing
		local nextBgColor = Globals.Colors.Item
		if Interaction._PressState[nextBtnKey] then
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
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
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
---@param defaultSelection integer The 1-based index of the currently selected tab.
---@return integer newCurrentTabIndex The potentially updated selected tab index.
function Widgets.TabControl(win, id, tabs, defaultSelection)
	assert(type(win) == "table", "Widgets.TabControl: win must be a table")
	assert(type(id) == "string", "Widgets.TabControl: id must be a string")
	assert(type(tabs) == "table", "Widgets.TabControl: tabs must be a table of strings")

	-- ensure TabControl starts on its own line
	local padding = Globals.Defaults.WINDOW_CONTENT_PADDING
	if win.cursorX > padding then
		win:NextLine(0)
	end

	-- Resolve default selection index (may be string or number or nil)
	local function resolveDefault()
		if type(defaultSelection) == "number" then
			if defaultSelection >= 1 and defaultSelection <= #tabs then
				return defaultSelection
			end
		elseif type(defaultSelection) == "string" then
			for i, lbl in ipairs(tabs) do
				if lbl == defaultSelection then
					return i
				end
			end
		end
		return 1 -- fallback
	end

	-- Per-window persistent storage
	win._tabControls = win._tabControls or {}
	local key = tostring(win.id) .. ":tabctrl:" .. id
	local entry = win._tabControls[key]
	if not entry then
		entry = { selected = resolveDefault(), changed = false }
		win._tabControls[key] = entry
	else
		entry.changed = false -- reset per frame
	end

	local currentTabIndex = entry.selected
	local selectedTabInfo = nil -- To store position/size of the selected tab button

	-- Calculate total width required for tabs to center them
	local totalTabsWidth = 0
	local pad = Globals.Style.ItemPadding
	draw.SetFont(Globals.Style.Font) -- Set font once for measurement
	for i, tabLabel in ipairs(tabs) do
		local textWidth, _ = draw.GetTextSize(tabLabel)
		local btnWidth = textWidth + (pad * 2)
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
		local btnWidth = textWidth + (pad * 2)
		local btnHeight = textHeight + (pad * 2)

		-- Manually reserve space (like win:AddWidget but simpler for this context)
		local currentButtonX = win.cursorX
		local currentButtonY = startY
		win.cursorX = win.cursorX + btnWidth
		currentLineMaxHeight = math.max(currentLineMaxHeight, btnHeight)

		local absX, absY = win.X + currentButtonX, win.Y + currentButtonY
		local bounds = { x = absX, y = absY, w = btnWidth, h = btnHeight }

		-- Interaction (similar to Widgets.Button but without unique index)
		local hovered = canInteract(win, bounds)
		if hovered and Interaction.IsPressed(buttonKey) then
			entry.selected = i -- Update selection on click
			entry.changed = true
		end
		if not input.IsButtonDown(MOUSE_LEFT) then
			Interaction.Release(buttonKey)
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

			-- Add conditional background fill for tabs
			if Globals.Style.TabBackground then
				local bgColor = cIsSelected and Globals.Colors.ItemActive
					or (cHovered and Globals.Colors.ItemHover or Globals.Colors.Item)
				draw.Color(table.unpack(bgColor))
				Common.DrawFilledRect(currentAbsX, currentAbsY, currentAbsX + cw, currentAbsY + ch)
			end

			-- Label text (centered)
			draw.Color(table.unpack(textColor))
			draw.SetFont(Globals.Style.Font)
			local actualTxtW, actualTxtH = draw.GetTextSize(clabel)
			Common.DrawText(currentAbsX + (cw - actualTxtW) / 2, currentAbsY + (ch - actualTxtH) / 2, clabel)
		end, currentButtonX, currentButtonY, btnWidth, btnHeight, tabLabel, buttonKey, isSelected, hovered)
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
	local underlineOffset = selectedTabInfo and 2 or 0
	local separatorThickness = 1
	local bottomSpacing = Globals.Style.ItemPadding * 2
	win.cursorY = startY + currentLineMaxHeight + underlineOffset + separatorThickness + bottomSpacing
	-- Reset cursorX for the next line (standard behavior after a row)
	win.cursorX = Globals.Defaults.WINDOW_CONTENT_PADDING
	win.lineHeight = 0 -- Reset line height as this widget manually managed it

	return entry.selected, entry.changed
end

--- Draws a multi-selection combo box; returns a table of booleans and whether changed.
function Widgets.Combo(win, label, selected, options)
	assert(type(win) == "table", "Widgets.Combo: win must be a table")
	assert(type(label) == "string", "Widgets.Combo: label must be a string")
	assert(type(selected) == "table", "Widgets.Combo: selected must be a table of booleans")
	assert(type(options) == "table", "Widgets.Combo: options must be a table")
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
	-- Measure based on label and arrow size
	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(label)
	local pad = Globals.Style.ItemPadding
	-- checkbox size for popup
	local boxSize = math.floor(txtH * 0.75) -- smaller checkbox for better visual separation
	-- arrow triangle size (used for height calculation)
	local arrowChar = "▼"
	local arrowW, arrowH = draw.GetTextSize(arrowChar)
	-- Calculate height first
	local height = math.max(txtH, arrowH) + pad * 2
	-- Calculate width including text, padding, and square arrow box
	local arrowBoxW = height -- Arrow box is square
	local width = txtW + pad * 2 + arrowBoxW -- Text + Padding + ArrowBox

	-- Layout and positioning
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + pad
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y
	local dropX, dropY = absX + width, absY -- Note: dropX/Y are for popup list position, not used for field drawing
	-- Input handling
	local mX, mY = table.unpack(input.GetMousePos())
	local hovered = Interaction.IsHovered(win, { x = absX, y = absY, w = width, h = height })
	local listH = #options * height
	local dropBounds = { x = absX, y = absY, w = width, h = height }
	-- Close combo popup on outside click
	local mXc, mYc = table.unpack(input.GetMousePos())
	local popupX, popupY = absX, absY + height
	local popupBounds = { x = popupX, y = popupY, w = width, h = listH }
	Interaction.ClosePopupOnOutsideClick(entry, mXc, mYc, dropBounds, popupBounds, win)
	-- Interaction: single-click consumption to toggle, multi-select, or close
	local clicked = Interaction.ConsumeWidgetClick(win, hovered, entry.open)
	if clicked then
		local popupX, popupY = absX, absY + height
		local popupBounds = { x = popupX, y = popupY, w = width, h = listH }
		if not entry.open and hovered then
			entry.open = true
			win._widgetBlockedRegions = win._widgetBlockedRegions or {}
			win._widgetBlockedRegions[#win._widgetBlockedRegions + 1] = popupBounds
		elseif entry.open then
			if Interaction.IsHovered(win, popupBounds) then
				-- Toggle selection inside popup
				local idx = math.floor((mY - popupY) / height) + 1
				if idx >= 1 and idx <= #options then
					entry.selected[idx] = not entry.selected[idx]
					entry.changed = true
				end
			else
				-- Click outside field and popup: close
				entry.open = false
				win._widgetBlockedRegions = {}
			end
		end
	end
	-- Draw the combo button
	win:QueueDrawAtLayer(2, DrawComboField, win, x, y, width, height, pad, label, entry.open, hovered, arrowW, arrowH)
	-- Draw popup items when open
	if entry.open then
		-- Position popup list below the main field
		local popupX, popupY = x, y + height -- Use relative coords for QueueDraw
		local itemH = height -- Recalculate itemH based on field height
		local listH = #options * itemH
		-- Draw popup background at topmost layer
		win:QueueDrawAtLayer(5, DrawComboPopupBackground, win, popupX, popupY, width, listH)
		-- Draw items at topmost layer
		for i, opt in ipairs(options) do
			-- Calculate absolute position of item for hover check
			local itemAbsX = absX
			local itemAbsY = absY + height + (i - 1) * itemH
			local hoverOpt = Interaction.IsHovered(win, { x = itemAbsX, y = itemAbsY, w = width, h = itemH })
			local isSelectedFlag = entry.selected[i]
			win:QueueDrawAtLayer(
				5,
				DrawComboPopupItem,
				win,
				popupX, -- Use relative X
				popupY + (i - 1) * itemH, -- Use relative Y + offset
				width,
				itemH,
				pad,
				opt,
				hoverOpt,
				boxSize,
				isSelectedFlag
			)
		end
		-- Outline combo popup box after drawing items
		win:QueueDrawAtLayer(5, DrawComboPopupOutline, win, popupX, popupY, width, listH)
	end
	return entry.selected, entry.changed
end

-- Widgets index module: import and expose individual widget modules
local Button = require("TimMenu.Widgets.Button")
local Checkbox = require("TimMenu.Widgets.Checkbox")
local Slider = require("TimMenu.Widgets.Slider")
local Separator = require("TimMenu.Widgets.Separator")
local TextInput = require("TimMenu.Widgets.TextInput")
local Dropdown = require("TimMenu.Widgets.Dropdown")
local Combo = require("TimMenu.Widgets.Combo")
local Selector = require("TimMenu.Widgets.Selector")
local TabControl = require("TimMenu.Widgets.TabControl")

return {
	Button = Button,
	Checkbox = Checkbox,
	Slider = Slider,
	Separator = Separator,
	TextInput = TextInput,
	Dropdown = Dropdown,
	Combo = Combo,
	Selector = Selector,
	TabControl = TabControl,
}
