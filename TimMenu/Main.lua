local TimMenu = {}

-- Monkey-patch draw.* to ensure integer coordinates in all draw calls
do
	local origFilled = draw.FilledRect
	draw.FilledRect = function(x1, y1, x2, y2)
		origFilled(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
	end
	local origOutlined = draw.OutlinedRect
	draw.OutlinedRect = function(x1, y1, x2, y2)
		origOutlined(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
	end
	local origLine = draw.Line
	if origLine then
		draw.Line = function(x1, y1, x2, y2)
			origLine(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
		end
	end
	local origText = draw.Text
	draw.Text = function(x, y, text)
		origText(math.floor(x), math.floor(y), text)
	end
	local origTextured = draw.TexturedRect
	if origTextured then
		draw.TexturedRect = function(id, x1, y1, x2, y2)
			origTextured(id, math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
		end
	end
end

-- Simplified global state
local function Setup()
	TimMenuGlobal = {
		windows = {}, -- Stores window objects, keyed by ID
		order = {}, -- Array of window IDs, defining Z-order (last = topmost)
	}
end

Setup()

-- Local variable to track the window currently being defined by Begin/End
local _currentWindow = nil

local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local Utils = require("TimMenu.Utils")
local Window = require("TimMenu.Window")
local Widgets = require("TimMenu.Widgets")

print("[TimMenu/Main.lua] Utils loaded:", type(Utils), Utils) -- See if Utils is a table
if Utils then
	print("[TimMenu/Main.lua] Utils.BeginFrame type:", type(Utils.BeginFrame)) -- See if BeginFrame is a function
end

local function getOrCreateWindow(key, title, visible)
	local win = TimMenuGlobal.windows[key]
	if not win then
		win = Window.new({ title = title, id = key, visible = visible })
		TimMenuGlobal.windows[key] = win
		table.insert(TimMenuGlobal.order, key) -- Add to end (top) by default
	else
		win.visible = visible -- Update visibility if it already exists
	end
	return win
end

function TimMenu.Begin(title, visible, id)
	assert(type(title) == "string", "TimMenu.Begin requires a string title")
	visible = (visible == nil) and true or visible
	if type(visible) == "string" then -- Handle shorthand TimMenu.Begin("Title", "id")
		id, visible = visible, true
	end
	local key = (id or title)

	local win = getOrCreateWindow(key, title, visible)
	win:update() -- This will now mark it as touched this frame

	_currentWindow = win -- Set for widget calls

	-- Reset window's internal layout cursor for this frame's widgets
	win:resetCursor()

	-- Clear per-frame widget counter for unique widget IDs
	win._widgetCounter = 0

	-- Clear any previously recorded sectors for this window each frame
	win._sectorStack = {}

	if not win.visible or (gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot()) then
		return false
	end

	return true, win
end

function TimMenu.End()
	-- This is now a no-op. Drawing and main logic are handled by _TimMenu_GlobalDraw.
	_currentWindow = nil -- Clear current window context
end

function TimMenu.GetCurrentWindow()
	return _currentWindow
end

--- Calls the Widgets.Button API on the current window.
function TimMenu.Button(label)
	assert(type(label) == "string", "TimMenu.Button: 'label' must be a string, got " .. type(label))
	local win = TimMenu.GetCurrentWindow()
	assert(win, "TimMenu.Button: no active window. Ensure TimMenu.Begin() was called before using widget functions.")
	return Widgets.Button(win, label)
end

--- Draws a checkbox and returns its new state.
function TimMenu.Checkbox(label, state)
	assert(type(label) == "string", "TimMenu.Checkbox: 'label' must be a string, got " .. type(label))
	assert(type(state) == "boolean", "TimMenu.Checkbox: 'state' must be boolean, got " .. type(state))
	local win = TimMenu.GetCurrentWindow()
	assert(win, "TimMenu.Checkbox: no active window. Ensure TimMenu.Begin() was called before using widget functions.")
	return Widgets.Checkbox(win, label, state)
end

--- Draws static text in the current window.
--- @param text string The string to display.
function TimMenu.Text(text)
	assert(type(text) == "string", "TimMenu.Text: 'text' must be a string, got " .. type(text))
	local win = TimMenu.GetCurrentWindow()
	assert(win, "TimMenu.Text: no active window. Ensure TimMenu.Begin() was called before drawing text.")
	-- Measure text
	draw.SetFont(Globals.Style.Font)
	local w, h = draw.GetTextSize(text)
	-- Reserve space in layout
	local x, y = win:AddWidget(w, h)
	-- Queue drawing at base layer
	win:QueueDrawAtLayer(1, function()
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		draw.Text(win.X + x, win.Y + y, text)
	end)
end

--- Displays debug information.
function TimMenu.ShowDebug()
	local currentFrame = globals.FrameCount()
	draw.SetFont(Globals.Style.Font)
	draw.Color(255, 255, 255, 255)
	local headerX, headerY = 20, 20
	local lineSpacing = 20

	local windowCount = 0
	for _ in pairs(TimMenuGlobal.windows) do
		windowCount = windowCount + 1
	end
	draw.Text(headerX, headerY, "Active Windows (" .. windowCount .. "):")

	local yOffset = headerY + lineSpacing
	-- Iterate in Z-order for debug display
	for i = 1, #TimMenuGlobal.order do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win then
			local delay = currentFrame - (win._lastFrameTouched or currentFrame)
			local info = "ID: " .. key .. " | " .. win.title .. " (Z: " .. i .. ", Delay: " .. delay .. ")"
			if not win.visible then
				info = info .. " (Hidden)"
			end
			draw.Text(headerX, yOffset, info)
			yOffset = yOffset + lineSpacing
		end
	end
end

--- Moves the cursor to the next line in the current window, respecting sectors.
function TimMenu.NextLine(spacing)
	local win = TimMenu.GetCurrentWindow()
	if win then
		win:NextLine(spacing) -- Pass optional spacing to window method
		-- Apply sector indentation after moving to the new line
		local depth = win._sectorStack and #win._sectorStack or 0
		local pad = Globals.Defaults.WINDOW_CONTENT_PADDING
		win.cursorX = pad + (depth * pad)
	end
end

--- Advances the cursor horizontally to place the next widget on the same line.
function TimMenu.SameLine(spacing)
	local win = TimMenu.GetCurrentWindow()
	if win then
		win:SameLine(spacing)
	end
end

--- Adds vertical spacing without resetting the horizontal cursor position.
function TimMenu.Spacing(verticalSpacing)
	local win = TimMenu.GetCurrentWindow()
	if win then
		win:Spacing(verticalSpacing)
	end
end

--- Draws a slider and returns the new value and whether it changed.
function TimMenu.Slider(label, value, min, max, step)
	assert(type(label) == "string", "TimMenu.Slider: 'label' must be a string, got " .. type(label))
	assert(type(value) == "number", "TimMenu.Slider: 'value' must be a number, got " .. type(value))
	assert(type(min) == "number", "TimMenu.Slider: 'min' must be a number, got " .. type(min))
	assert(type(max) == "number", "TimMenu.Slider: 'max' must be a number, got " .. type(max))
	assert(type(step) == "number", "TimMenu.Slider: 'step' must be a number, got " .. type(step))
	local win = TimMenu.GetCurrentWindow()
	assert(win, "TimMenu.Slider: no active window. Ensure TimMenu.Begin() was called before using widget functions.")
	return Widgets.Slider(win, label, value, min, max, step)
end

--- Draws a horizontal separator in the current window; optional centered label.
function TimMenu.Separator(label)
	assert(
		label == nil or type(label) == "string",
		"TimMenu.Separator: 'label' must be a string or nil, got " .. type(label)
	)
	local win = TimMenu.GetCurrentWindow()
	assert(win, "TimMenu.Separator: no active window. Ensure TimMenu.Begin() was called before using widget functions.")
	return Widgets.Separator(win, label)
end

--- Single-line text input; returns new string and whether it changed.
function TimMenu.TextInput(label, text)
	assert(type(label) == "string", "TimMenu.TextInput: 'label' must be a string, got " .. type(label))
	assert(type(text) == "string", "TimMenu.TextInput: 'text' must be a string, got " .. type(text))
	local win = TimMenu.GetCurrentWindow()
	assert(win, "TimMenu.TextInput: no active window. Ensure TimMenu.Begin() was called before using widget functions.")
	return Widgets.TextInput(win, label, text)
end

--- Dropdown list; returns new index and whether it changed.
function TimMenu.Dropdown(label, selectedIndex, options)
	-- Assert argument types
	assert(type(label) == "string", "TimMenu.Dropdown: 'label' must be a string, got " .. type(label))
	assert(
		type(selectedIndex) == "number",
		"TimMenu.Dropdown: 'selectedIndex' must be a number, got " .. type(selectedIndex)
	)
	assert(type(options) == "table", "TimMenu.Dropdown: 'options' must be a table, got " .. type(options))
	local win = TimMenu.GetCurrentWindow()
	-- Assert active window context
	assert(win, "TimMenu.Dropdown: no active window. Ensure TimMenu.Begin() was called before using widget functions.")
	return Widgets.Dropdown(win, label, selectedIndex, options)
end

--- Draws a multi-selection combo box; returns a table of booleans and whether changed.
function TimMenu.Combo(label, selectedTable, options)
	assert(type(label) == "string", "TimMenu.Combo: 'label' must be a string, got " .. type(label))
	assert(
		type(selectedTable) == "table",
		"TimMenu.Combo: 'selectedTable' must be a table, got " .. type(selectedTable)
	)
	assert(type(options) == "table", "TimMenu.Combo: 'options' must be a table, got " .. type(options))
	local win = TimMenu.GetCurrentWindow()
	assert(win, "TimMenu.Combo: no active window. Ensure TimMenu.Begin() was called before using widget functions.")
	return Widgets.Combo(win, label, selectedTable, options)
end

--- Cyclic selector (< value >); returns new index and whether it changed.
function TimMenu.Selector(label, selectedIndex, options)
	assert(
		label == nil or type(label) == "string",
		"TimMenu.Selector: 'label' must be a string or nil, got " .. type(label)
	)
	assert(
		type(selectedIndex) == "number",
		"TimMenu.Selector: 'selectedIndex' must be a number, got " .. type(selectedIndex)
	)
	assert(type(options) == "table", "TimMenu.Selector: 'options' must be a table, got " .. type(options))
	local win = TimMenu.GetCurrentWindow()
	assert(win, "TimMenu.Selector: no active window. Ensure TimMenu.Begin() was called before using widget functions.")
	return Widgets.Selector(win, label, selectedIndex, options)
end

--- Draws a tab control row and returns the newly selected tab index.
---@param id string A unique identifier for this specific tab control instance.
---@param tabs table A list of strings for the tab labels.
---@param currentTabIndex integer The 1-based index of the currently active tab.
---@return integer newTabIndex The index of the tab that is now selected (might be the same as currentTabIndex).
function TimMenu.TabControl(id, tabs, currentTabIndex)
	assert(type(id) == "string", "TimMenu.TabControl: 'id' must be a string, got " .. type(id))
	assert(type(tabs) == "table", "TimMenu.TabControl: 'tabs' must be a table, got " .. type(tabs))
	assert(
		type(currentTabIndex) == "number",
		"TimMenu.TabControl: 'currentTabIndex' must be a number, got " .. type(currentTabIndex)
	)
	local win = TimMenu.GetCurrentWindow()
	assert(
		win,
		"TimMenu.TabControl: no active window. Ensure TimMenu.Begin() was called before using widget functions."
	)
	return Widgets.TabControl(win, id, tabs, currentTabIndex)
end

--- Begins a visual sector grouping; widgets until EndSector are enclosed.
---@param label string optional title for the sector
function TimMenu.BeginSector(label)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return
	end
	-- initialize sector stack
	win._sectorStack = win._sectorStack or {}
	-- persistent storage for sector sizes
	win._sectorSizes = win._sectorSizes or {}
	-- capture current cursor as sector origin
	local startX, startY = win.cursorX, win.cursorY
	local pad = Globals.Defaults.WINDOW_CONTENT_PADDING
	-- restore previous max extents if available
	local stored = win._sectorSizes[label]
	local sector = {
		startX = startX,
		startY = startY,
		maxX = stored and (startX + stored.width - pad) or startX,
		maxY = stored and (startY + stored.height - pad) or startY,
		label = label,
		padding = pad,
		origAdd = win.AddWidget,
	}
	table.insert(win._sectorStack, sector)
	-- override AddWidget & NextLine to track extents within this sector
	sector.origNext = win.NextLine
	win.AddWidget = function(self, w, h)
		local x, y = sector.origAdd(self, w, h)
		-- track widest and tallest widget positions relative to window origin
		sector.maxX = math.max(sector.maxX, x + w)
		sector.maxY = math.max(sector.maxY, y + h)
		return x, y
	end
	win.NextLine = function(self, spacing)
		-- Call original to handle vertical advance and line height
		sector.origNext(self, spacing)
		-- Crucially, reset cursorX to the sector's indented start position
		self.cursorX = sector.startX + sector.padding
		-- track y position after line break relative to window origin
		sector.maxY = math.max(sector.maxY, self.cursorY + self.lineHeight)
	end
	-- indent cursor for sector padding
	win.cursorX = sector.startX + sector.padding
	win.cursorY = sector.startY + sector.padding
end

--- Ends the named sector, drawing its background and border and restoring layout.
---@param label string sector name to end
function TimMenu.EndSector(label)
	local win = TimMenu.GetCurrentWindow()
	if not win or not win._sectorStack or #win._sectorStack == 0 then
		return
	end
	-- Compute depth before popping
	local depth = #win._sectorStack
	-- Capture the sector table before removing it
	local sector = win._sectorStack[depth]
	-- pop last sector
	table.remove(win._sectorStack)

	-- restore AddWidget and NextLine
	win.AddWidget = sector.origAdd
	win.NextLine = sector.origNext
	local pad = sector.padding
	-- compute sector dimensions (+padding)
	local width = (sector.maxX - sector.startX) + pad
	local height = (sector.maxY - sector.startY) + pad

	-- ensure minimum width to fit header label plus padding
	if type(sector.label) == "string" then
		draw.SetFont(Globals.Style.Font)
		local lw, lh = draw.GetTextSize(sector.label)
		local minW = lw + (pad * 2)
		if width < minW then
			width = minW
		end
	end
	-- store persistent sector size to avoid shrinking below max content size
	win._sectorSizes = win._sectorSizes or {}
	local prev = win._sectorSizes[sector.label]
	if not prev or width > prev.width or height > prev.height then -- Update if wider or taller
		win._sectorSizes[sector.label] = { width = width, height = height }
	end

	-- *** Explicitly update window bounds to contain this sector ***
	local requiredW = sector.startX + width + sector.padding -- Sector start + width + right padding
	local requiredH = sector.startY + height + sector.padding -- Sector start + height + bottom padding
	win.W = math.max(win.W, requiredW)
	win.H = math.max(win.H, requiredH)

	local absX = win.X + sector.startX
	local absY = win.Y + sector.startY
	-- Prepare for background draw: capture variables local to this scope
	local captureStartX = sector.startX
	local captureStartY = sector.startY
	local captureW = prev and prev.width or ((sector.maxX - sector.startX) + sector.padding)
	local captureH = prev and prev.height or ((sector.maxY - sector.startY) + sector.padding)

	-- dynamic draw background behind sector, adjusting for nesting depth
	-- Add to the FRONT of Layer 1 queue to ensure correct draw order (outermost first)
	table.insert(win.Layers[1], 1, {
		fn = function()
			local windowBgColor = Globals.Colors.Window
			-- Use captured depth (1-based, so depth 1 means first-level sector)
			local totalLighten = math.min(40, depth * 10)
			local finalR = math.min(255, windowBgColor[1] + totalLighten)
			local finalG = math.min(255, windowBgColor[2] + totalLighten)
			local finalB = math.min(255, windowBgColor[3] + totalLighten)
			local finalColor = { finalR, finalG, finalB, windowBgColor[4] }

			local x0 = win.X + captureStartX
			local y0 = win.Y + captureStartY
			draw.Color(table.unpack(finalColor))
			Common.DrawFilledRect(x0, y0, x0 + captureW, y0 + captureH)
		end,
		args = {},
	})
	-- dynamic draw border and optional header label
	win:QueueDrawAtLayer(5, function()
		local x0 = win.X + sector.startX
		local y0 = win.Y + sector.startY
		local w0 = (sector.maxX - sector.startX) + sector.padding
		local h0 = (sector.maxY - sector.startY) + sector.padding
		local pad0 = sector.padding
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		if type(sector.label) == "string" then
			draw.SetFont(Globals.Style.Font)
			local tw, th = draw.GetTextSize(sector.label)
			local labelX = x0 + (w0 - tw) / 2
			local lineY = y0
			-- left border segment
			Common.DrawLine(x0, lineY, labelX - pad0, lineY)
			-- label text
			draw.Color(table.unpack(Globals.Colors.Text))
			Common.DrawText(labelX, lineY - math.floor(th / 2), sector.label)
			-- right border segment
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawLine(labelX + tw + pad0, lineY, x0 + w0, lineY)
		else
			Common.DrawLine(x0, y0, x0 + w0, y0)
		end
		-- bottom border
		Common.DrawLine(x0, y0 + h0, x0 + w0, y0 + h0)
		-- left border
		Common.DrawLine(x0, y0, x0, y0 + h0)
		-- right border
		Common.DrawLine(x0 + w0, y0, x0 + w0, y0 + h0)
	end)
	-- move parent cursor to right of this sector (allow horizontal stacking)
	win.cursorX = sector.startX + width + pad
	win.cursorY = sector.startY

	-- Update window's layout state based on the ended sector
	win.cursorX = sector.startX + width + pad -- Move cursor right for potential next element on same line
	-- Update the line height to accommodate the sector's vertical extent
	win.lineHeight = math.max(win.lineHeight or 0, height)

	-- Update parent sector's bounds if nested
	if #win._sectorStack > 0 then
		local parentSector = win._sectorStack[#win._sectorStack]
		-- Update parent's max X based on this sector's right edge
		parentSector.maxX = math.max(parentSector.maxX, sector.startX + width)
		-- Update parent's max Y based on this sector's bottom edge (cursorY already advanced)
		parentSector.maxY = math.max(parentSector.maxY, win.cursorY + win.lineHeight)
	end

	-- Do NOT reset cursorY here; let the next NextLine handle vertical advancement based on updated lineHeight.
end

-- Named function for the global draw callback
local function _TimMenu_GlobalDraw()
	local mouseX, mouseY = table.unpack(input.GetMousePos())
	local focusedWindowKey = nil

	-- 1. Pruning Pass: Remove windows not updated this frame
	local currentFrame = globals.FrameCount()
	local keysToRemove = {}
	for key, win in pairs(TimMenuGlobal.windows) do
		if not win._lastFrameTouched or (currentFrame - win._lastFrameTouched) > 1 then
			table.insert(keysToRemove, key)
		end
	end
	for _, key in ipairs(keysToRemove) do
		TimMenuGlobal.windows[key] = nil
		for i = #TimMenuGlobal.order, 1, -1 do
			if TimMenuGlobal.order[i] == key then
				table.remove(TimMenuGlobal.order, i)
				break
			end
		end
	end

	-- 2. Determine Focused Window (topmost under mouse)
	-- Iterate from top of z-order (end of table) downwards
	for i = #TimMenuGlobal.order, 1, -1 do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win and win.visible and win:_HitTest(mouseX, mouseY) then
			focusedWindowKey = key
			break -- Found the topmost, stop searching
		end
	end

	-- 3. Interaction Logic Pass (iterate all windows, but only focused one interacts fully)
	for i = 1, #TimMenuGlobal.order do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win and win.visible then
			local isFocused = (key == focusedWindowKey)
			win:_UpdateLogic(
				mouseX,
				mouseY,
				isFocused,
				input.IsButtonPressed(MOUSE_LEFT),
				input.IsButtonDown(MOUSE_LEFT),
				input.IsButtonReleased(MOUSE_LEFT)
			)

			-- Click-to-front and start drag
			if isFocused and input.IsButtonPressed(MOUSE_LEFT) then
				-- Bring to front
				if TimMenuGlobal.order[#TimMenuGlobal.order] ~= key then -- if not already at front
					for j, v_key in ipairs(TimMenuGlobal.order) do
						if v_key == key then
							table.remove(TimMenuGlobal.order, j)
							break
						end
					end
					table.insert(TimMenuGlobal.order, key)
				end
				-- Start dragging if click was in title bar (logic inside _UpdateLogic)
			end
		end
	end

	-- 4. Draw Pass (iterate in new Z-order)
	for i = 1, #TimMenuGlobal.order do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win and win.visible then
			win:_Draw()
		end
	end
end

-- Register the global draw callback
callbacks.Unregister("Draw", "TimMenu_GlobalDraw")
callbacks.Register("Draw", "TimMenu_GlobalDraw", _TimMenu_GlobalDraw)

--[[ Play sound when loaded -- consider if this is still desired with centralized model ]]
engine.PlaySound("hl1/fvox/activated.wav")

-- Alias for backward compatibility: Textbox
function TimMenu.Textbox(label, text)
	return TimMenu.TextInput(label, text)
end

return TimMenu
