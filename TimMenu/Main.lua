local TimMenu = {}

-- Alias Lmaobox globals
local lmbx = globals

-- Simplified global state
local function Setup()
	TimMenuGlobal = {
		windows = {}, -- Stores window objects, keyed by ID
		order = {}, -- Array of window IDs, defining Z-order (last = topmost)
		InputState = { -- ADDED: To manage mouse button state across frames
			isLeftMouseDown = false,
			wasLeftMouseDownLastFrame = false,
		},
	}
end

Setup()

-- Next-widget font override state
local nextWidgetFont = nil

--- Override font for the next widget only.
---@param name string Font name (Globals.Style.FontName)
---@param size number Font size
---@param weight number Font weight
function TimMenu.SetFontNext(name, size, weight)
	nextWidgetFont = { name = name, size = size, weight = weight }
end

local function applyNextWidgetFont()
	if nextWidgetFont then
		local s = Globals.Style
		local prev = { name = s.FontName, size = s.FontSize, weight = s.FontWeight }
		s.FontName = nextWidgetFont.name
		s.FontSize = nextWidgetFont.size
		s.FontWeight = nextWidgetFont.weight
		Globals.ReloadFonts()
		nextWidgetFont = nil
		return prev
	end
end

local function restoreWidgetFont(prev)
	if prev then
		local s = Globals.Style
		s.FontName = prev.name
		s.FontSize = prev.size
		s.FontWeight = prev.weight
		Globals.ReloadFonts()
	end
end

-- Local variable to track the window currently being defined by Begin/End
local _currentWindow = nil

local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local Utils = require("TimMenu.Utils")
local Window = require("TimMenu.Window")
local Widgets = require("TimMenu.Widgets")
-- Explicitly require Keybind module so bundler includes it
local _ = require("TimMenu.Widgets.Keybind")
local SectorWidget = require("TimMenu.Layout.Sector")
local SeparatorLayout = require("TimMenu.Layout.Separator")
local DrawManager = require("TimMenu.DrawManager")

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
	-- Auto-reset fonts to defaults at the start of this frame
	TimMenu.FontReset()
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
	local prevFont = applyNextWidgetFont()
	local clicked = Widgets.Button(win, label)
	restoreWidgetFont(prevFont)
	return clicked
end

--- Draws a checkbox and returns its new state.
function TimMenu.Checkbox(label, state)
	assert(type(label) == "string", "TimMenu.Checkbox: 'label' must be a string, got " .. type(label))
	assert(type(state) == "boolean", "TimMenu.Checkbox: 'state' must be boolean, got " .. type(state))
	local win = TimMenu.GetCurrentWindow()
	assert(win, "TimMenu.Checkbox: no active window. Ensure TimMenu.Begin() was called before using widget functions.")
	local prevFont = applyNextWidgetFont()
	local newState, clicked = Widgets.Checkbox(win, label, state)
	restoreWidgetFont(prevFont)
	return newState, clicked
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
	-- Queue drawing at base layer using Common.QueueText
	Common.QueueText(win, 1, win.X + x, win.Y + y, text, Globals.Colors.Text)
end

--- Displays debug information.
function TimMenu.ShowDebug()
	local currentFrame = lmbx.FrameCount()
	draw.SetFont(Globals.Style.Font)
	Common.SetColor(Globals.Colors.Text)
	local headerX, headerY = Globals.Defaults.DebugHeaderX, Globals.Defaults.DebugHeaderY
	local lineSpacing = Globals.Defaults.DebugLineSpacing

	local windowCount = 0
	for _ in pairs(TimMenuGlobal.windows) do
		windowCount = windowCount + 1
	end
	Common.DrawText(headerX, headerY, "Active Windows (" .. windowCount .. "):")

	local yOffset = headerY + lineSpacing
	-- Iterate in Z-order for debug display
	for i = 1, #TimMenuGlobal.order do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win then
			local delay = currentFrame - (win._lastFrameTouched or currentFrame)
			local info = string.format("ID: %s | %s (Z: %d, Delay: %d)", key, win.title, i, delay)
			if not win.visible then
				info = info .. " (Hidden)"
			end
			Common.DrawText(headerX, yOffset, info)
			yOffset = yOffset + lineSpacing
		end
	end
end

--- Moves the cursor to the next line in the current window, respecting sectors.
function TimMenu.NextLine(spacing)
	local win = TimMenu.GetCurrentWindow()
	if win then
		win:NextLine(spacing) -- Pass optional spacing to window method
		-- Apply sector indentation after moving to the new line -- This logic is now managed by SectorWidget
		-- local depth = win._sectorStack and #win._sectorStack or 0
		-- local pad = Globals.Defaults.WINDOW_CONTENT_PADDING
		-- win.cursorX = pad + (depth * pad)
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
	local prevFont = applyNextWidgetFont()
	local newValue, changed = Widgets.Slider(win, label, value, min, max, step)
	restoreWidgetFont(prevFont)
	return newValue, changed
end

--- Draws a horizontal separator in the current window; optional centered label.
function TimMenu.Separator(label)
	assert(
		label == nil or type(label) == "string",
		"TimMenu.Separator: 'label' must be a string or nil, got " .. type(label)
	)
	local win = TimMenu.GetCurrentWindow()
	assert(win, "TimMenu.Separator: no active window. Ensure TimMenu.Begin() was called before using widget functions.")
	return SeparatorLayout.Draw(win, label)
end

--- Single-line text input; returns new string and whether it changed.
function TimMenu.TextInput(label, text)
	assert(type(label) == "string", "TimMenu.TextInput: 'label' must be a string, got " .. type(label))
	assert(type(text) == "string", "TimMenu.TextInput: 'text' must be a string, got " .. type(text))
	local win = TimMenu.GetCurrentWindow()
	assert(win, "TimMenu.TextInput: no active window. Ensure TimMenu.Begin() was called before using widget functions.")
	local prevFont = applyNextWidgetFont()
	local newText, changed = Widgets.TextInput(win, label, text)
	restoreWidgetFont(prevFont)
	return newText, changed
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
	local prevFont = applyNextWidgetFont()
	local newIdx, changed = Widgets.Dropdown(win, label, selectedIndex, options)
	restoreWidgetFont(prevFont)
	return newIdx, changed
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
	local prevFont = applyNextWidgetFont()
	local newTable, changed = Widgets.Combo(win, label, selectedTable, options)
	restoreWidgetFont(prevFont)
	return newTable, changed
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
	local prevFont = applyNextWidgetFont()
	local newIdx, changed = Widgets.Selector(win, label, selectedIndex, options)
	restoreWidgetFont(prevFont)
	return newIdx, changed
end

--- Draws a tab control row and returns the newly selected tab index.
---@param id string A unique identifier for this specific tab control instance.
---@param tabs table A list of strings for the tab labels.
---@param currentTabIndex integer The 1-based index of the currently active tab.
---@return integer newTabIndex The index of the tab that is now selected (might be the same as currentTabIndex).
function TimMenu.TabControl(id, tabs, defaultSelection)
	assert(type(id) == "string", "TimMenu.TabControl: 'id' must be a string, got " .. type(id))
	assert(type(tabs) == "table", "TimMenu.TabControl: 'tabs' must be a table, got " .. type(tabs))
	local win = TimMenu.GetCurrentWindow()
	assert(
		win,
		"TimMenu.TabControl: no active window. Ensure TimMenu.Begin() was called before using widget functions."
	)
	-- Call core TabControl to get index and changed flag
	local prevFont = applyNextWidgetFont()
	local newIndex, changed = Widgets.TabControl(win, id, tabs, defaultSelection)
	restoreWidgetFont(prevFont)
	-- If defaultSelection was a string, return label instead of index for backward compatibility
	if type(defaultSelection) == "string" then
		return tabs[newIndex], changed
	end
	-- Otherwise, return numeric index
	return newIndex, changed
end

--- Begins a visual sector grouping; widgets until EndSector are enclosed.
---@param label string optional title for the sector
function TimMenu.BeginSector(label)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return
	end
	SectorWidget.Begin(win, label) -- Delegated to SectorWidget
end

--- Ends the most recently begun sector, drawing its background and border and restoring layout.
function TimMenu.EndSector()
	local win = TimMenu.GetCurrentWindow()
	if not win or not win._sectorStack or #win._sectorStack == 0 then -- Keep basic check here
		return
	end
	SectorWidget.End(win) -- Delegated to SectorWidget
end

-- Named function for the global draw callback
local reRegistered = false
local function _TimMenu_GlobalDraw()
	-- Update global input state ONCE per frame, before any interaction processing
	TimMenuGlobal.InputState.wasLeftMouseDownLastFrame = TimMenuGlobal.InputState.isLeftMouseDown
	TimMenuGlobal.InputState.isLeftMouseDown = input.IsButtonDown(MOUSE_LEFT)

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

	-- 4. Draw Pass (per-window widget flush)
	for i = 1, #TimMenuGlobal.order do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win and win.visible then
			win:_Draw()
			-- Flush only this window's widget draw calls, in layer order
			DrawManager.FlushWindow(key)
		end
	end

	-- One-time re-registration to ensure this draw callback runs after user callbacks
	if not reRegistered then
		callbacks.Unregister("Draw", "zTimMenu_GlobalDraw")
		callbacks.Register("Draw", "zTimMenu_GlobalDraw", _TimMenu_GlobalDraw)
		reRegistered = true
	end
end

-- Ensure old callback is removed, then register this after user callbacks (name changed to be last alphabetically)
callbacks.Unregister("Draw", "TimMenu_GlobalDraw")
callbacks.Unregister("Draw", "zTimMenu_GlobalDraw")
callbacks.Register("Draw", "zTimMenu_GlobalDraw", _TimMenu_GlobalDraw)

--[[ Play sound when loaded -- consider if this is still desired with centralized model ]]
engine.PlaySound("hl1/fvox/activated.wav")

-- Alias for backward compatibility: Textbox
function TimMenu.Textbox(label, text)
	return TimMenu.TextInput(label, text)
end

--- Runs a keybinding widget; returns new key code and whether changed.
function TimMenu.Keybind(label, currentKey)
	assert(type(label) == "string", "TimMenu.Keybind: 'label' must be a string, got " .. type(label))
	local win = TimMenu.GetCurrentWindow()
	assert(win, "TimMenu.Keybind: no active window. Ensure TimMenu.Begin() was called before using widget functions.")
	local prevFont = applyNextWidgetFont()
	local keycode, changed = Widgets.Keybind(win, label, currentKey)
	restoreWidgetFont(prevFont)
	return keycode, changed
end

--- Change the normal font for widgets at runtime
function TimMenu.FontSet(name, size, weight)
	Globals.Style.FontName = name
	Globals.Style.FontSize = size
	Globals.Style.FontWeight = weight
	Globals.ReloadFonts()
end

--- Change the bold font for widgets at runtime (e.g. TabControl)
function TimMenu.FontSetBold(name, size, weight)
	Globals.Style.FontBoldName = name
	Globals.Style.FontBoldSize = size
	Globals.Style.FontBoldWeight = weight
	Globals.ReloadFonts()
end

--- Reset fonts to the defaults loaded at startup
function TimMenu.FontReset()
	local d = Globals.DefaultFontSettings
	Globals.Style.FontName = d.FontName
	Globals.Style.FontSize = d.FontSize
	Globals.Style.FontWeight = d.FontWeight
	Globals.Style.FontBoldName = d.FontBoldName
	Globals.Style.FontBoldSize = d.FontBoldSize
	Globals.Style.FontBoldWeight = d.FontBoldWeight
	Globals.ReloadFonts()
end

-- expose TimMenu globally for convenience
_G.TimMenu = TimMenu
return TimMenu
