local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
local TimMenu = {}

-- Alias Lmaobox globals
local lmbx = globals

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
-- Explicitly require Keybind module so bundler includes it
local _ = require("TimMenu.Widgets.Keybind")
local SectorWidget = require("TimMenu.Layout.Sector")
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
	local currentFrame = lmbx.FrameCount()
	draw.SetFont(Globals.Style.Font)
	draw.Color(table.unpack(Globals.Colors.Text))
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
function TimMenu.TabControl(id, tabs, defaultSelection)
	assert(type(id) == "string", "TimMenu.TabControl: 'id' must be a string, got " .. type(id))
	assert(type(tabs) == "table", "TimMenu.TabControl: 'tabs' must be a table, got " .. type(tabs))
	local win = TimMenu.GetCurrentWindow()
	assert(
		win,
		"TimMenu.TabControl: no active window. Ensure TimMenu.Begin() was called before using widget functions."
	)
	-- Call core TabControl to get index and changed flag
	local newIndex, changed = Widgets.TabControl(win, id, tabs, defaultSelection)
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
	return Widgets.Keybind(win, label, currentKey)
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

end)
__bundle_register("TimMenu.DrawManager", function(require, _LOADED, __bundle_register, __bundle_modules)
local DrawManager = { queue = {} }

--- Enqueue a draw call under a given window and layer
---@param windowId string the ID of the window
---@param layer number draw layer for ordering
---@param fn function the draw function
---@param ... any additional arguments for fn
function DrawManager.Enqueue(windowId, layer, fn, ...)
	table.insert(DrawManager.queue, {
		windowId = windowId,
		layer = layer,
		fn = fn,
		args = { ... },
	})
end

--- Flush all queued draw calls in proper back-to-front order
---@param zOrder table an array of window IDs in z-order (back to front)
function DrawManager.Flush(zOrder)
	-- Sort by window z-order then layer
	table.sort(DrawManager.queue, function(a, b)
		local za, zb
		for i, id in ipairs(zOrder) do
			if id == a.windowId then
				za = i
			end
			if id == b.windowId then
				zb = i
			end
		end
		if za ~= zb then
			return za < zb
		end
		return a.layer < b.layer
	end)

	-- Execute all draw functions
	for _, entry in ipairs(DrawManager.queue) do
		entry.fn(table.unpack(entry.args))
	end

	-- Clear queue for next frame
	DrawManager.queue = {}
end

--- Flush queued draw calls for a single window, sorted by layer
---@param windowId string the ID of the window to flush
function DrawManager.FlushWindow(windowId)
	local keep = {}
	local toFlush = {}
	-- Separate entries for this window
	for _, entry in ipairs(DrawManager.queue) do
		if entry.windowId == windowId then
			table.insert(toFlush, entry)
		else
			table.insert(keep, entry)
		end
	end
	-- Sort this window's entries by layer
	table.sort(toFlush, function(a, b)
		return a.layer < b.layer
	end)
	-- Execute draw calls for this window
	for _, entry in ipairs(toFlush) do
		entry.fn(table.unpack(entry.args))
	end
	-- Retain entries for other windows
	DrawManager.queue = keep
end

return DrawManager

end)
__bundle_register("TimMenu.Layout.Sector", function(require, _LOADED, __bundle_register, __bundle_modules)
local Globals = require("TimMenu.Globals")
local DrawManager = require("TimMenu.DrawManager") -- EndSector will need this
local Common = require("TimMenu.Common") -- EndSector might need this for DrawLine etc.

local Sector = {}

-- Forward declaration for helper usage if needed, though likely not for static helpers

--[[----------------------------------------------------------------------------
-- Private Helper Functions for Sector.End
------------------------------------------------------------------------------]]

local function _calculateDimensions(sector_data, pad)
	local currentWidth = (sector_data.maxX - sector_data.startX) + pad
	local currentHeight = (sector_data.maxY - sector_data.startY) + pad

	if type(sector_data.label) == "string" then
		draw.SetFont(Globals.Style.Font)
		local lw, _ = draw.GetTextSize(sector_data.label)
		local minContentWidthForLabel = lw + (pad * 2)
		if currentWidth < minContentWidthForLabel then
			currentWidth = minContentWidthForLabel
		end
	end
	return currentWidth, currentHeight
end

local function _updatePersistentSize(win, sector_data, width, height)
	win._sectorSizes = win._sectorSizes or {}
	local persistent = win._sectorSizes[sector_data.label]
	if not persistent or width > persistent.width or height > persistent.height then
		win._sectorSizes[sector_data.label] = { width = width, height = height }
	end
	return win._sectorSizes[sector_data.label] -- Return the, possibly updated, persistent size
end

local function _updateWindowBounds(win, sector_data, width, height, pad)
	local requiredW = sector_data.startX + width + pad
	local requiredH = sector_data.startY + height + pad
	win.W = math.max(win.W, requiredW)
	win.H = math.max(win.H, requiredH)
end

local function _enqueueBackgroundDraw(win, sector_data, depth, persistentWidth, persistentHeight)
	local backgroundLayer = 0.1 + (depth - 1) * 0.01
	DrawManager.Enqueue(win.id, backgroundLayer, function()
		local baseBgColor = Globals.Colors.SectorBackground
		local totalLighten = math.min(40, depth * 10)
		local finalR = math.min(255, baseBgColor[1] + totalLighten)
		local finalG = math.min(255, baseBgColor[2] + totalLighten)
		local finalB = math.min(255, baseBgColor[3] + totalLighten)
		local finalColor = { finalR, finalG, finalB, baseBgColor[4] }

		local x0 = win.X + sector_data.startX
		local y0 = win.Y + sector_data.startY
		draw.Color(table.unpack(finalColor))
		Common.DrawFilledRect(x0, y0, x0 + persistentWidth, y0 + persistentHeight)
	end)
end

local function _enqueueBorderDraw(win, sector_data, depth, persistentWidth, persistentHeight)
	local borderLayer = 2.1 + (depth - 1) * 0.01
	DrawManager.Enqueue(win.id, borderLayer, function()
		local x0 = win.X + sector_data.startX
		local y0 = win.Y + sector_data.startY
		local w0 = persistentWidth
		local h0 = persistentHeight
		local pad0 = sector_data.padding

		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		if type(sector_data.label) == "string" then
			draw.SetFont(Globals.Style.Font)
			local tw, th = draw.GetTextSize(sector_data.label)
			local labelX = x0 + (w0 - tw) / 2
			local lineY = y0
			Common.DrawLine(x0, lineY, labelX - pad0, lineY)
			draw.Color(table.unpack(Globals.Colors.Text))
			Common.DrawText(labelX, lineY - math.floor(th / 2), sector_data.label)
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawLine(labelX + tw + pad0, lineY, x0 + w0, lineY)
		else
			Common.DrawLine(x0, y0, x0 + w0, y0)
		end
		Common.DrawLine(x0, y0 + h0, x0 + w0, y0 + h0)
		Common.DrawLine(x0, y0, x0, y0 + h0)
		Common.DrawLine(x0 + w0, y0, x0 + w0, y0 + h0)
	end)
end

local function _finalizeCursorAndLayout(win, sector_data, width, height, pad)
	win.cursorX = sector_data.startX + width + pad
	win.cursorY = sector_data.startY
	win.lineHeight = math.max(win.lineHeight or 0, height)

	if #win._sectorStack > 0 then
		local parentSector = win._sectorStack[#win._sectorStack]
		parentSector.maxX = math.max(parentSector.maxX, sector_data.startX + width)
		parentSector.maxY = math.max(parentSector.maxY, win.cursorY + win.lineHeight)
	end
end

--[[----------------------------------------------------------------------------
-- Public Sector API
------------------------------------------------------------------------------]]

function Sector.Begin(win, label)
	-- initialize sector stack if not already
	win._sectorStack = win._sectorStack or {}
	-- persistent storage for sector sizes
	win._sectorSizes = win._sectorSizes or {}

	-- capture current cursor as sector origin
	local startX, startY = win.cursorX, win.cursorY
	local pad = Globals.Defaults.WINDOW_CONTENT_PADDING

	-- restore previous max extents if available
	local stored = win._sectorSizes[label]
	local sector_data = {
		startX = startX,
		startY = startY,
		maxX = stored and (startX + stored.width - pad) or startX,
		maxY = stored and (startY + stored.height - pad) or startY,
		label = label,
		padding = pad,
		origAdd = win.AddWidget, -- Store original AddWidget
	}
	table.insert(win._sectorStack, sector_data)

	-- override AddWidget & NextLine to track extents within this sector
	sector_data.origNext = win.NextLine -- Store original NextLine
	win.AddWidget = function(self, w, h)
		local x, y = sector_data.origAdd(self, w, h)
		-- track widest and tallest widget positions relative to window origin
		sector_data.maxX = math.max(sector_data.maxX, x + w)
		sector_data.maxY = math.max(sector_data.maxY, y + h)
		return x, y
	end

	win.NextLine = function(self, spacing)
		-- Call original to handle vertical advance and line height
		sector_data.origNext(self, spacing)
		-- Crucially, reset cursorX to the sector's indented start position
		self.cursorX = sector_data.startX + sector_data.padding
		-- track y position after line break relative to window origin
		sector_data.maxY = math.max(sector_data.maxY, self.cursorY + self.lineHeight)
	end

	-- indent cursor for sector padding
	win.cursorX = sector_data.startX + sector_data.padding
	win.cursorY = sector_data.startY + sector_data.padding
end

function Sector.End(win)
	if not win._sectorStack or #win._sectorStack == 0 then
		return
	end

	local depth = #win._sectorStack
	local sector_data = win._sectorStack[depth]
	table.remove(win._sectorStack)

	win.AddWidget = sector_data.origAdd
	win.NextLine = sector_data.origNext
	local pad = sector_data.padding

	local currentWidth, currentHeight = _calculateDimensions(sector_data, pad)
	local persistentSize = _updatePersistentSize(win, sector_data, currentWidth, currentHeight)
	_updateWindowBounds(win, sector_data, persistentSize.width, persistentSize.height, pad)

	-- Use persistent W/H for drawing to prevent flicker and maintain size
	_enqueueBackgroundDraw(win, sector_data, depth, persistentSize.width, persistentSize.height)
	_enqueueBorderDraw(win, sector_data, depth, persistentSize.width, persistentSize.height)

	-- Use calculated currentWidth/Height for layout/cursor updates, but persistent for drawing.
	_finalizeCursorAndLayout(win, sector_data, persistentSize.width, persistentSize.height, pad)
end

return Sector

end)
__bundle_register("TimMenu.Common", function(require, _LOADED, __bundle_register, __bundle_modules)
---@diagnostic disable: duplicate-set-field, undefined-field

-- Localize global APIs to satisfy linters
local http = http
local input = input
local draw = draw
local engine = engine
local callbacks = callbacks
local TimMenuGlobal = TimMenuGlobal

local Utils = require("TimMenu.Utils")

local Common = {}

--local Globals = require("TimMenu.Globals") -- Import the Globals module for Colors and Style.

--------------------------------------------------------------------------------------
--Library loading--
--------------------------------------------------------------------------------------

-- Function to download content from a URL
local function downloadFile(url)
	local body = http.Get(url)
	if body and body ~= "" then
		return body
	else
		error("Failed to download file from " .. url)
	end
end

local latestReleaseURL = "https://github.com/lnx00/Lmaobox-Library/releases/latest/download/lnxLib.lua"

-- Load and validate LNXlib
local function loadLNXlib()
	local libLoaded, Lib = pcall(require, "LNXlib")
	if not libLoaded or not Lib.GetVersion or Lib.GetVersion() < 1.0 then
		print("LNXlib not found or version is too old. Attempting to download the latest version...")

		-- Download and load lnxLib.lua
		local lnxLibContent = downloadFile(latestReleaseURL)
		local lnxLibFunction, loadError = load(lnxLibContent)
		if lnxLibFunction then
			lnxLibFunction()
			libLoaded, Lib = pcall(require, "LNXlib")
			if not libLoaded then
				error("Failed to load LNXlib after downloading: " .. loadError)
			end
		else
			error("Error loading lnxLib: " .. loadError)
		end
	end

	return Lib
end

-- Initialize library
local Lib = loadLNXlib()

-- Expose required functionality
Common.Lib = Lib
Common.Fonts = Lib.UI.Fonts
Common.KeyHelper = Lib.Utils.KeyHelper
Common.Input = Lib.Utils.Input
Common.Timer = Lib.Utils.Timer
Common.Log = Lib.Utils.Logger.new("TimMenu")
Common.Notify = Lib.UI.Notify
Common.Math = Lib.Utils.Math
Common.Conversion = Lib.Utils.Conversion

--------------------------------------------------------------------------------
-- Common Functions
--------------------------------------------------------------------------------

-- Remove the direct nil assignment and package reloading from Refresh().
function Common.Refresh()
	package.loaded["TimMenu"] = nil
end

--- Rounds a floating-point value to the nearest integer.
---@param value number
---@return number
function Common.RoundNearest(value)
	return math.floor(value + 0.5)
end

-- Alias Clamp for backwards compatibility; prefer RoundNearest for clarity
Common.Clamp = Common.RoundNearest

-- Track button state globally
local wasPressed = false

-- New: Helper function for mouse interaction within a rectangle.
function Common.GetInteraction(x, y, w, h)
	local mX, mY = table.unpack(input.GetMousePos())
	local hovered = (mX >= x) and (mX <= x + w) and (mY >= y) and (mY <= y + h)
	local isPressed = input.IsButtonDown(MOUSE_LEFT)

	-- Only trigger click when button is pressed and wasn't pressed last frame
	local clicked = hovered and isPressed and not wasPressed

	-- Update state for next frame
	wasPressed = isPressed

	return hovered, clicked
end

--------------------------------------------------------------------------------
-- Draw Wrappers
--------------------------------------------------------------------------------

--- Draws a filled rectangle with integer coordinates.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function Common.DrawFilledRect(x1, y1, x2, y2)
	draw.FilledRect(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
end

--- Draws an outlined rectangle with integer coordinates.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function Common.DrawOutlinedRect(x1, y1, x2, y2)
	draw.OutlinedRect(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
end

--- Draws a line with integer coordinates.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function Common.DrawLine(x1, y1, x2, y2)
	if draw.Line then
		draw.Line(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
	end
end

--- Draws text at an integer position.
---@param x number
---@param y number
---@param text string
function Common.DrawText(x, y, text)
	draw.Text(math.floor(x), math.floor(y), text)
end

--- Draws a textured rectangle with integer coordinates.
---@param id any
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function Common.DrawTexturedRect(id, x1, y1, x2, y2)
	if draw.TexturedRect then
		draw.TexturedRect(id, math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
	end
end

--------------------------------------------------------------------------------
-- Unload Callback: Clean up the module on unload.
--------------------------------------------------------------------------------

local function OnUnload() -- Called when a script using TimMenu is unloaded
	--ensure o leave mosue input enabled(api is inverted)
	input.SetMouseInputEnabled(false)
	engine.PlaySound("hl1/fvox/deactivated.wav") -- deactivated sound
	-- Prune windows from unloaded scripts
	Utils.PruneOrphanedWindows(TimMenuGlobal.windows, TimMenuGlobal.order)

	print("Unloading TimMenu")
	-- Unload the TimMenu module so next require reinitializes it
	package.loaded["TimMenu"] = nil
end

callbacks.Unregister("Unload", "TimMenu_Unload")
callbacks.Register("Unload", "TimMenu_Unload", OnUnload)

-- [[ Ensure all draw positions are integers ]]
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

return Common

end)
__bundle_register("TimMenu.Utils", function(require, _LOADED, __bundle_register, __bundle_modules)
local lmbx = globals -- alias for Lmaobox API
local Utils = {}

function Utils.GetWindowCount()
	return windowsThisFrame
end

-- Prune windows that haven't been drawn for a specified frame threshold.
-- Updated: Prune windows and clean the order array.
function Utils.PruneOrphanedWindows(windows, order)
	-- Prune windows not updated in the last 2 frames
	local currentFrame = lmbx.FrameCount()
	local threshold = 2
	for key, win in pairs(windows) do
		if not win.lastFrame or (currentFrame - win.lastFrame) >= threshold then
			windows[key] = nil
		end
	end
	-- Clean up window order to remove missing windows
	for i = #order, 1, -1 do
		if not windows[order[i]] then
			table.remove(order, i)
		end
	end
end

function Utils.IsMouseOverWindow(win, mouseX, mouseY, titleHeight)
	return mouseX >= win.X and mouseX <= win.X + win.W and mouseY >= win.Y and mouseY <= win.Y + win.H
end

-- Add new function to check if a point is blocked by any window above
function Utils.IsPointBlocked(order, windows, x, y, currentWindowKey)
	-- Check all windows above current window in z-order
	local foundCurrent = false
	for i = #order, 1, -1 do
		local key = order[i]
		if key == currentWindowKey then
			foundCurrent = true
			break
		end
		local win = windows[key]
		if win and win.visible and Utils.IsMouseOverWindow(win, x, y, win.H) then
			return true -- Point is blocked by a window above
		end
	end
	return false
end

-- Returns the top window key at a given point.
function Utils.GetWindowUnderMouse(order, windows, x, y, titleBarHeight)
	-- Return the first (topmost) window under the point
	for i = #order, 1, -1 do
		local key = order[i]
		local win = windows[key]
		if win and Utils.IsMouseOverWindow(win, x, y, titleBarHeight) then
			input.SetMouseInputEnabled(false) -- disable game UI
			return key
		end
	end

	input.SetMouseInputEnabled(false) -- enable game UI

	return nil
end

-- Click consumption: returns true once per press until release
local clickConsumed = false
function Utils.ConsumeClick()
	if input.IsButtonPressed(MOUSE_LEFT) and not clickConsumed then
		clickConsumed = true
		return true
	elseif not input.IsButtonDown(MOUSE_LEFT) then
		clickConsumed = false
	end
	return false
end

return Utils

end)
__bundle_register("TimMenu.Globals", function(require, _LOADED, __bundle_register, __bundle_modules)
local Globals = {}

-- Color definitions
Globals.Colors = {
	Title = { 55, 100, 215, 255 },
	Text = { 255, 255, 255, 255 },
	Window = { 30, 30, 30, 255 },
	Item = { 50, 50, 50, 255 },
	ItemHover = { 60, 60, 60, 255 },
	ItemActive = { 70, 70, 70, 255 },
	Highlight = { 180, 180, 180, 100 },
	HighlightActive = { 240, 240, 200, 140 },
	WindowBorder = { 55, 100, 215, 255 },
	FrameBorder = { 0, 0, 0, 200 },
	SectorBackground = { 30, 30, 30, 255 },
	Border = { 0, 0, 0, 200 },
	TabSelectedUnderline = { 255, 255, 255, 255 }, -- Default to white, adjust as needed
	WidgetOutline = { 100, 100, 100, 77 }, -- Based on WindowBorder with custom alpha
	ArrowBoxBg = { 55, 100, 215, 255 }, -- Background for the dropdown/combo arrow box
}

-- Style settings
Globals.Style = {
	-- Font configuration (user can change and call Globals.ReloadFonts)
	FontName = "Verdana",
	FontSize = 14,
	FontWeight = 700,
	FontBoldName = "Arial Black",
	FontBoldSize = 17,
	FontBoldWeight = 400,
	ItemPadding = 7, -- Increased from 5 to 7 for potentially wider tab label font
	ItemMargin = 5,
	ItemSize = 10,
	EnableWindowBorder = true,
	FrameBorder = false,
	ButtonBorder = false,
	CheckboxBorder = false,
	SliderBorder = false,
	Border = false,
	Popup = false,
	Alignment = "left", -- or "center"
	Scale = 1.2, -- Scaling factor for UI elements (1 = 100%)
	TabBackground = true, -- Enable background fill for tabs; disable via this flag if needed
}

Globals.Defaults = {
	DEFAULT_X = 100,
	DEFAULT_Y = 100,
	DEFAULT_W = 300,
	DEFAULT_H = 200,
	SLIDER_WIDTH = 250, -- Default slider width from ImMenu
	TITLE_BAR_HEIGHT = 30,
	WINDOW_CONTENT_PADDING = 10,
	ITEM_SPACING = 8, -- Increased from 5 to 8 for better header tab spacing
	DebugHeaderX = 20,
	DebugHeaderY = 20,
	DebugLineSpacing = 20,
}

-- Font cache to avoid recreating fonts every tick
local fontCache = {}
local function GetOrCreateFont(name, size, weight)
	local key = name .. ":" .. size .. ":" .. weight
	if not fontCache[key] then
		fontCache[key] = draw.CreateFont(name, size, weight)
	end
	return fontCache[key]
end

-- Setup scalable fonts based on Style.Font* and Scale with caching
local function SetupFonts()
	local scale = Globals.Style.Scale or 1
	local fSize = math.ceil(Globals.Style.FontSize * scale)
	local bSize = math.ceil(Globals.Style.FontBoldSize * scale)
	Globals.Style.Font = GetOrCreateFont(Globals.Style.FontName, fSize, Globals.Style.FontWeight)
	Globals.Style.FontBold = GetOrCreateFont(Globals.Style.FontBoldName, bSize, Globals.Style.FontBoldWeight)
end
SetupFonts()
Globals.ReloadFonts = SetupFonts

-- Preserve default font settings for quick reset
Globals.DefaultFontSettings = {
	FontName = Globals.Style.FontName,
	FontSize = Globals.Style.FontSize,
	FontWeight = Globals.Style.FontWeight,
	FontBoldName = Globals.Style.FontBoldName,
	FontBoldSize = Globals.Style.FontBoldSize,
	FontBoldWeight = Globals.Style.FontBoldWeight,
}

-- Scale style metrics
local scale = Globals.Style.Scale or 1
Globals.Style.ItemPadding = math.ceil(Globals.Style.ItemPadding * scale) -- This will apply scaling to the new base value
Globals.Style.ItemMargin = math.ceil(Globals.Style.ItemMargin * scale)
Globals.Style.ItemSize = math.ceil(Globals.Style.ItemSize * scale)
-- Scale default dimensions
Globals.Defaults.DEFAULT_W = math.ceil(Globals.Defaults.DEFAULT_W * scale)
Globals.Defaults.DEFAULT_H = math.ceil(Globals.Defaults.DEFAULT_H * scale)
Globals.Defaults.SLIDER_WIDTH = math.ceil(Globals.Defaults.SLIDER_WIDTH * scale)
Globals.Defaults.TITLE_BAR_HEIGHT = math.ceil(Globals.Defaults.TITLE_BAR_HEIGHT * scale)
Globals.Defaults.WINDOW_CONTENT_PADDING = math.ceil(Globals.Defaults.WINDOW_CONTENT_PADDING * scale)
Globals.Defaults.ITEM_SPACING = math.ceil(Globals.Defaults.ITEM_SPACING * scale) -- Will apply scaling to the new base value
Globals.Defaults.DebugHeaderX = math.ceil(Globals.Defaults.DebugHeaderX * scale)
Globals.Defaults.DebugHeaderY = math.ceil(Globals.Defaults.DebugHeaderY * scale)
Globals.Defaults.DebugLineSpacing = math.ceil(Globals.Defaults.DebugLineSpacing * scale)

return Globals

end)
__bundle_register("TimMenu.Widgets.Keybind", function(require, _LOADED, __bundle_register, __bundle_modules)
local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

-- Draws a keybinding widget; returns new key code and whether it changed.
local function Keybind(win, label, currentKey)
	assert(type(win) == "table", "Keybind: win must be a table")
	assert(type(label) == "string", "Keybind: label must be a string")
	-- Prepare persistent state
	win._widgetCounter = (win._widgetCounter or 0) + 1
	win._keybinds = win._keybinds or {}
	local key = tostring(win.id) .. ":keybind:" .. label
	local entry = win._keybinds[key]
	if not entry then
		entry = { keycode = currentKey or 0, listening = false, changed = false, waitingRelease = false }
		win._keybinds[key] = entry
	else
		entry.changed = false
	end

	-- Determine displayed label
	local display
	if entry.listening then
		display = "<press key>"
	elseif entry.keycode > 0 then
		local name = Common.Input.GetKeyName(entry.keycode)
		display = (name ~= "UNKNOWN") and name or tostring(entry.keycode)
	else
		display = "<none>"
	end
	local fullLabel = label .. ": " .. display

	-- Measure
	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(fullLabel)
	local pad = Globals.Style.ItemPadding
	local width = txtW + pad * 2
	local height = txtH + pad * 2

	-- Layout spacing
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + pad
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y
	local bounds = { x = absX, y = absY, w = width, h = height }

	-- Interaction: click to start listening
	local hovered = Interaction.IsHovered(win, bounds)
	local clicked = Interaction.ConsumeWidgetClick(win, hovered, entry.listening)
	if clicked and not entry.listening then
		entry.listening = true
		entry.waitingRelease = true
	end

	-- Capture key when listening
	if entry.listening then
		-- Wait for M1 release before capturing, then bind on next press
		if entry.waitingRelease then
			if not input.IsButtonDown(MOUSE_LEFT) then
				entry.waitingRelease = false
			end
		else
			for code = 1, 255 do
				if input.IsButtonPressed(code) then
					entry.keycode = code
					entry.changed = true
					entry.listening = false
					break
				end
			end
		end
	end

	-- Release click state for this widget
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(key)
	end

	-- Update fullLabel to reflect any key changes immediately
	do
		local newDisplay
		if entry.listening then
			newDisplay = "<press key>"
		elseif entry.keycode > 0 then
			local name = Common.Input.GetKeyName(entry.keycode)
			newDisplay = (name ~= "UNKNOWN") and name or tostring(entry.keycode)
		else
			newDisplay = "<none>"
		end
		fullLabel = label .. ": " .. newDisplay
	end

	-- Draw
	win:QueueDrawAtLayer(2, function()
		local px, py = win.X + x, win.Y + y
		local bg = Globals.Colors.Item
		if entry.listening then
			bg = Globals.Colors.ItemActive
		elseif hovered then
			bg = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(bg))
		Common.DrawFilledRect(px, py, px + width, py + height)
		-- Border
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawOutlinedRect(px, py, px + width, py + height)
		-- Text
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		Common.DrawText(px + pad, py + pad, fullLabel)
	end)

	return entry.keycode, entry.changed
end

return Keybind

end)
__bundle_register("TimMenu.Interaction", function(require, _LOADED, __bundle_register, __bundle_modules)
local Utils = require("TimMenu.Utils")
local Globals = require("TimMenu.Globals")

--[[ Imported by: Widgets, Utils, others ]]
--

local Interaction = {}

-- Internal debouncing table shared by all widgets
local PressState = {}

----------------------------------------------------
-- Helper: point-in-bounds (small, local only)
----------------------------------------------------
local function inBounds(x, y, b)
	return x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h
end

----------------------------------------------------
-- Public: Z-aware hover check
----------------------------------------------------
function Interaction.IsHovered(win, bounds)
	local mX, mY = table.unpack(input.GetMousePos())
	if not inBounds(mX, mY, bounds) then
		return false
	end

	-- Block if covered by higher windows
	if Utils.IsPointBlocked(TimMenuGlobal.order, TimMenuGlobal.windows, mX, mY, win.id) then
		return false
	end

	-- Block if inside any widget-level exclusion region (e.g. dropdown pop-ups)
	if win._widgetBlockedRegions then
		for _, region in ipairs(win._widgetBlockedRegions) do
			if inBounds(mX, mY, region) then
				return false
			end
		end
	end

	return true
end

----------------------------------------------------
-- Public: one-shot click that respects hover/open state
----------------------------------------------------
function Interaction.ConsumeWidgetClick(win, hovered, isOpen)
	-- Only consume if the widget is interactable from here
	if not hovered and not isOpen then
		return false
	end
	return Utils.ConsumeClick()
end

----------------------------------------------------
-- Public: close a popup if user clicks outside both field & popup
----------------------------------------------------
function Interaction.ClosePopupOnOutsideClick(entry, mouseX, mouseY, fieldBounds, popupBounds, win)
	if not entry.open then
		return
	end

	-- If click is outside both field & popup, close and clear block regions
	if not inBounds(mouseX, mouseY, fieldBounds) and not inBounds(mouseX, mouseY, popupBounds) then
		entry.open = false
		win._widgetBlockedRegions = {}
	end
end

----------------------------------------------------
-- Optional helpers for manual debouncing (rarely needed now)
----------------------------------------------------
function Interaction.IsPressed(key)
	if input.IsButtonPressed(MOUSE_LEFT) and not PressState[key] then
		PressState[key] = true
		return true
	end
	return false
end

function Interaction.Release(key)
	PressState[key] = false
end

Interaction._PressState = PressState -- expose for debugging

return Interaction

end)
__bundle_register("TimMenu.Widgets", function(require, _LOADED, __bundle_register, __bundle_modules)
-- Widgets aggregator: delegate to individual widget modules
local Button = require("TimMenu.Widgets.Button")
local Checkbox = require("TimMenu.Widgets.Checkbox")
local Slider = require("TimMenu.Widgets.Slider")
local Separator = require("TimMenu.Widgets.Separator")
local TextInput = require("TimMenu.Widgets.TextInput")
local Dropdown = require("TimMenu.Widgets.Dropdown")
local Combo = require("TimMenu.Widgets.Combo")
local Selector = require("TimMenu.Widgets.Selector")
local TabControl = require("TimMenu.Widgets.TabControl")
local Keybind = require("TimMenu.Widgets.Keybind")

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
	Keybind = Keybind,
}

end)
__bundle_register("TimMenu.Widgets.TabControl", function(require, _LOADED, __bundle_register, __bundle_modules)
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
			-- Interaction
			local hover = Interaction.IsHovered(win, { x = absX, y = absY, w = item.bw, h = item.bh })
			if hover and Interaction.IsPressed(keyBtn) then
				entry.selected = i
				entry.changed = true
			end
			if not input.IsButtonDown(MOUSE_LEFT) then
				Interaction.Release(keyBtn)
			end
			-- Hover underline for non-selected tabs (dynamic positioning)
			if hover and not isSel then
				win:QueueDrawAtLayer(1, function(offX, offY, bw)
					local px = win.X + offX
					local py = win.Y + offY
					local uy = py + item.bh
					draw.Color(table.unpack(Globals.Colors.Highlight))
					Common.DrawFilledRect(px, uy, px + bw, uy + 2)
				end, offsetX, offsetY, item.bw)
			end
			-- Tab text (dynamic positioning)
			win:QueueDrawAtLayer(2, function(lbl, w, h, bw, bh, sel, offX, offY)
				local px = win.X + offX
				local py = win.Y + offY
				local txtColor = sel and Globals.Colors.Text or { 180, 180, 180, 255 }
				draw.SetFont(Globals.Style.FontBold)
				draw.Color(table.unpack(txtColor))
				Common.DrawText(px + (bw - w) / 2, py + (bh - h) / 2, lbl)
			end, item.lbl, item.w, item.h, item.bw, item.bh, isSel, offsetX, offsetY)
			-- Underline for selected tab (dynamic positioning)
			if isSel then
				win:QueueDrawAtLayer(3, function(offX, offY, bw)
					local px = win.X + offX
					local py = win.Y + offY
					local uy = py + item.bh
					draw.Color(table.unpack(Globals.Colors.TabSelectedUnderline))
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

		-- Interaction
		local hover = Interaction.IsHovered(win, { x = absX, y = absY, w = bw, h = bh })
		local keyBtn = id .. ":tab:" .. lbl
		if hover and Interaction.IsPressed(keyBtn) then
			entry.selected = i
			entry.changed = true
		end
		if not input.IsButtonDown(MOUSE_LEFT) then
			Interaction.Release(keyBtn)
		end

		-- Background (layer 1)
		win:QueueDrawAtLayer(1, function(px, py, w, h, sel, hv)
			local bg = sel and Globals.Colors.Title or (hv and Globals.Colors.ItemHover or Globals.Colors.Item)
			draw.Color(table.unpack(bg))
			Common.DrawFilledRect(px, py, px + w, py + h)
		end, absX, absY, bw, bh, entry.selected == i, hover)

		-- Per-button outline (layer 2)
		win:QueueDrawAtLayer(2, function(px, py, w, h)
			draw.Color(table.unpack(LIGHT_TAB_OUTLINE))
			Common.DrawOutlinedRect(px, py, px + w, py + h)
		end, absX, absY, bw, bh)

		-- Text (layer 3)
		win:QueueDrawAtLayer(3, function(px, py, txt, tw, th, sel)
			draw.SetFont(Globals.Style.FontBold)
			local txtC = sel and Globals.Colors.Text or { 180, 180, 180, 255 }
			draw.Color(table.unpack(txtC))
			Common.DrawText(px + (bw - tw) / 2, py + (bh - th) / 2, txt)
		end, absX, absY, lbl, tw, th, entry.selected == i)

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

end)
__bundle_register("TimMenu.Widgets.Selector", function(require, _LOADED, __bundle_register, __bundle_modules)
local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

local function Selector(win, label, selectedIndex, options)
	assert(type(win) == "table", "Selector: win must be a table")
	assert(label == nil or type(label) == "string", "Selector: label must be a string or nil")
	assert(type(selectedIndex) == "number", "Selector: selectedIndex must be a number")
	assert(type(options) == "table", "Selector: options must be a table")
	win._widgetCounter = (win._widgetCounter or 0) + 1
	win._selectors = win._selectors or {}
	local safeLabel = label or "<nil_selector_label>"
	local key = tostring(win.id) .. ":selector:" .. safeLabel
	local entry = win._selectors[key]
	if not entry then
		entry = { selected = selectedIndex or 1, changed = false }
	else
		entry.changed = false
		if selectedIndex and selectedIndex ~= entry.selected then
			entry.selected = selectedIndex
		end
	end
	win._selectors[key] = entry

	-- Styling & Calculation
	draw.SetFont(Globals.Style.Font)
	local pad = Globals.Style.ItemPadding
	local _, btnSymH = draw.GetTextSize("<")
	local btnW = btnSymH + (pad * 2)
	local btnH = btnSymH + (pad * 2)
	local fixedTextW = 100
	local textDisplayH = btnH
	local sepW = 1
	local totalWidth = btnW + sepW + fixedTextW + sepW + btnW
	local totalHeight = math.max(btnH, textDisplayH)

	local x, y = win:AddWidget(totalWidth, totalHeight)
	local absX, absY = win.X + x, win.Y + y

	local prevKey, nextKey, centerKey = key .. ":prev", key .. ":next", key .. ":center"
	local mX, mY = table.unpack(input.GetMousePos())

	local prevHover = Interaction.IsHovered(win, { x = absX, y = absY, w = btnW, h = totalHeight })
	-- Next arrow hover region, include previous arrow width
	local nextHover =
		Interaction.IsHovered(win, { x = absX + btnW + sepW + fixedTextW + sepW, y = absY, w = btnW, h = totalHeight })

	if prevHover and Interaction.IsPressed(prevKey) then
		entry.selected = entry.selected - 1
		if entry.selected < 1 then
			entry.selected = #options
		end
		entry.changed = true
	end
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(prevKey)
	end
	if nextHover and Interaction.IsPressed(nextKey) then
		entry.selected = entry.selected + 1
		if entry.selected > #options then
			entry.selected = 1
		end
		entry.changed = true
	end
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(nextKey)
	end

	local textBounds = { x = absX + btnW + sepW, y = absY, w = fixedTextW, h = totalHeight }
	if Interaction.IsHovered(win, textBounds) and Interaction.IsPressed(centerKey) then
		if mX < textBounds.x + textBounds.w / 2 then
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
		Interaction.Release(centerKey)
	end

	win:QueueDrawAtLayer(2, function()
		local cx, cy = win.X + x, win.Y + y
		-- Prev arrow background and text
		local prevBg = Globals.Colors.Item
		if Interaction._PressState[prevKey] then
			prevBg = Globals.Colors.ItemActive
		elseif prevHover then
			prevBg = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(prevBg))
		Common.DrawFilledRect(cx, cy, cx + btnW, cy + btnH)
		-- Calculate arrow symbol size for centering
		draw.SetFont(Globals.Style.Font)
		local symW, symH = draw.GetTextSize("<")
		local sym2W, sym2H = draw.GetTextSize(">")
		draw.Color(table.unpack(Globals.Colors.Text))
		Common.DrawText(cx + (btnW - symW) / 2, cy + (btnH - symH) / 2, "<")
		local display = tostring(options[entry.selected])
		local halfW = fixedTextW / 2
		local leftBounds = { x = cx + btnW + sepW, y = cy, w = halfW, h = totalHeight }
		local rightBounds = { x = cx + btnW + sepW + halfW, y = cy, w = halfW, h = totalHeight }
		local lh = Interaction.IsHovered(win, leftBounds)
		draw.Color(table.unpack(lh and Globals.Colors.ItemHover or Globals.Colors.Item))
		Common.DrawFilledRect(leftBounds.x, leftBounds.y, leftBounds.x + leftBounds.w, leftBounds.y + leftBounds.h)
		local rh = Interaction.IsHovered(win, rightBounds)
		draw.Color(table.unpack(rh and Globals.Colors.ItemHover or Globals.Colors.Item))
		Common.DrawFilledRect(
			rightBounds.x,
			rightBounds.y,
			rightBounds.x + rightBounds.w,
			rightBounds.y + rightBounds.h
		)
		draw.Color(table.unpack(Globals.Colors.Text))
		local dispW, dispH = draw.GetTextSize(display)
		Common.DrawText(cx + btnW + sepW + (fixedTextW - dispW) / 2, cy + (totalHeight - dispH) / 2, display)
		local nextX = cx + btnW + sepW + fixedTextW + sepW
		local nextBg = Globals.Colors.Item
		if Interaction._PressState[nextKey] then
			nextBg = Globals.Colors.ItemActive
		elseif nextHover then
			nextBg = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(nextBg))
		Common.DrawFilledRect(nextX, cy, nextX + btnW, cy + btnH)
		draw.Color(table.unpack(Globals.Colors.Text))
		Common.DrawText(nextX + (btnW - sym2W) / 2, cy + (btnH - sym2H) / 2, ">")
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawOutlinedRect(cx, cy, cx + totalWidth, cy + totalHeight)
	end)

	return entry.selected, entry.changed
end

return Selector

end)
__bundle_register("TimMenu.Widgets.Combo", function(require, _LOADED, __bundle_register, __bundle_modules)
local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")
local DrawHelpers = require("TimMenu.DrawHelpers")

-- Draw helpers for combo field and popup
local function DrawComboField(win, relX, relY, width, height, pad, label, entryOpen, hovered, arrowW, arrowH)
	local absX, absY = win.X + relX, win.Y + relY
	local arrowBoxW, arrowBoxX = height, absX + width - height
	local mainBgW = width - arrowBoxW
	local bgColor = Globals.Colors.Item
	if entryOpen then
		bgColor = Globals.Colors.ItemActive
	elseif hovered then
		bgColor = Globals.Colors.ItemHover
	end
	draw.Color(table.unpack(bgColor))
	Common.DrawFilledRect(absX, absY, absX + mainBgW, absY + height)
	draw.Color(table.unpack(Globals.Colors.ArrowBoxBg))
	Common.DrawFilledRect(arrowBoxX, absY, arrowBoxX + arrowBoxW, absY + height)
	draw.Color(table.unpack(Globals.Colors.WindowBorder))
	Common.DrawOutlinedRect(absX, absY, absX + width, absY + height)
	draw.Color(table.unpack(Globals.Colors.Text))
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
	draw.Color(table.unpack(Globals.Colors.Window))
	Common.DrawFilledRect(absX, absY, absX + width, absY + listH)
end

local function DrawComboPopupItem(win, relX, relY, width, height, pad, opt, isHovered, boxSize, isSelected)
	local absX, absY = win.X + relX, win.Y + relY
	draw.Color(table.unpack(isHovered and Globals.Colors.ItemHover or Globals.Colors.Item))
	Common.DrawFilledRect(absX, absY, absX + width, absY + height)
	local bx, by = absX + pad, absY + (height / 2) - (boxSize / 2)
	draw.Color(table.unpack(Globals.Colors.WindowBorder))
	Common.DrawOutlinedRect(bx, by, bx + boxSize, by + boxSize)
	if isSelected then
		draw.Color(table.unpack(Globals.Colors.Highlight))
		local m = math.floor(boxSize * 0.25)
		Common.DrawFilledRect(bx + m, by + m, bx + boxSize - m, by + boxSize - m)
	end
	draw.Color(table.unpack(Globals.Colors.Text))
	local _, optH = draw.GetTextSize(opt)
	Common.DrawText(bx + boxSize + pad, absY + (height / 2) - (optH / 2), opt)
end

local function DrawComboPopupOutline(win, relX, relY, width, listH)
	local absX, absY = win.X + relX, win.Y + relY
	draw.Color(table.unpack(Globals.Colors.WindowBorder))
	Common.DrawOutlinedRect(absX, absY, absX + width, absY + listH)
end

local function Combo(win, label, selected, options)
	assert(type(win) == "table", "Combo: win must be a table")
	assert(type(label) == "string", "Combo: label must be a string")
	assert(type(selected) == "table", "Combo: selected must be a table of booleans")
	assert(type(options) == "table", "Combo: options must be a table")
	win._widgetCounter = (win._widgetCounter or 0) + 1
	win._combos = win._combos or {}
	local key = tostring(win.id) .. ":combo:" .. label
	local entry = win._combos[key]
	if not entry then
		entry = { selected = {}, open = false, changed = false }
		for i = 1, #options do
			entry.selected[i] = selected[i] == true
		end
	else
		entry.changed = false
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
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + pad
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y
	local hovered = Interaction.IsHovered(win, { x = absX, y = absY, w = width, h = height })
	local listH = #options * height
	local popupBounds = { x = absX, y = absY + height, w = width, h = listH }
	-- Close popup on outside click using explicit mouse coords and bounds
	local mX, mY = table.unpack(input.GetMousePos())
	Interaction.ClosePopupOnOutsideClick(entry, mX, mY, { x = absX, y = absY, w = width, h = height }, popupBounds, win)
	local clicked = Interaction.ConsumeWidgetClick(win, hovered, entry.open)
	if clicked then
		if not entry.open and hovered then
			entry.open, win._widgetBlockedRegions = true, { popupBounds }
		elseif entry.open then
			if Interaction.IsHovered(win, popupBounds) then
				local idx = math.floor((input.GetMousePos()[2] - popupBounds.y) / height) + 1
				if idx >= 1 and idx <= #options then
					entry.selected[idx] = not entry.selected[idx]
					entry.changed = true
				end
			else
				entry.open, win._widgetBlockedRegions = false, {}
			end
		end
	end
	win:QueueDrawAtLayer(2, DrawComboField, win, x, y, width, height, pad, label, entry.open, hovered, arrowW, arrowH)
	if entry.open then
		local px, py = x, y + height
		-- Background behind combo list
		win:QueueDrawAtLayer(3, DrawComboPopupBackground, win, px, py, width, listH)
		for i, opt in ipairs(options) do
			local isH =
				Interaction.IsHovered(win, { x = absX, y = absY + height + (i - 1) * height, w = width, h = height })
			-- Individual combo items
			win:QueueDrawAtLayer(
				4,
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
		-- Outline around the combo list
		win:QueueDrawAtLayer(5, DrawComboPopupOutline, win, px, py, width, listH)
	end
	return entry.selected, entry.changed
end

return Combo

end)
__bundle_register("TimMenu.DrawHelpers", function(require, _LOADED, __bundle_register, __bundle_modules)
local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")

--[[ Imported by: Widgets, TabControl, etc. ]]
--

local DrawHelpers = {}

----------------------------------------------------
-- DrawArrow : draws a simple filled arrow (up or down)
-- absX, absY : top-left corner of bounding box
-- w, h       : width / height of bounding box
-- direction  : "up" | "down"
-- colorTbl   : {r,g,b,a}
----------------------------------------------------
function DrawHelpers.DrawArrow(absX, absY, w, h, direction, colorTbl)
	draw.Color(table.unpack(colorTbl or Globals.Colors.Text))

	if direction == "up" then
		Common.DrawLine(absX, absY + h, absX + w / 2, absY) -- /\ left edge
		Common.DrawLine(absX + w / 2, absY, absX + w, absY + h) -- /\ right edge
	else -- default to down
		Common.DrawLine(absX, absY, absX + w / 2, absY + h) -- \/ left edge
		Common.DrawLine(absX + w / 2, absY + h, absX + w, absY) -- \/ right edge
	end
end

----------------------------------------------------
-- DrawLabeledBox : draws a filled rect with border + centered label
----------------------------------------------------
function DrawHelpers.DrawLabeledBox(absX, absY, w, h, label, bgCol, borderCol)
	draw.Color(table.unpack(bgCol or Globals.Colors.Item))
	Common.DrawFilledRect(absX, absY, absX + w, absY + h)

	draw.Color(table.unpack(borderCol or Globals.Colors.WindowBorder))
	Common.DrawOutlinedRect(absX, absY, absX + w, absY + h)

	draw.Color(table.unpack(Globals.Colors.Text))
	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(label)
	Common.DrawText(absX + (w - txtW) / 2, absY + (h - txtH) / 2, label)
end

return DrawHelpers

end)
__bundle_register("TimMenu.Widgets.Dropdown", function(require, _LOADED, __bundle_register, __bundle_modules)
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
	local hovered = Interaction.IsHovered(win, { x = absX, y = absY, w = width, h = height })
	local listH = #options * height
	local popupBounds = { x = absX, y = absY + height, w = width, h = listH }
	-- Close popup on outside click using explicit mouse coords and bounds
	local mX, mY = table.unpack(input.GetMousePos())
	Interaction.ClosePopupOnOutsideClick(entry, mX, mY, { x = absX, y = absY, w = width, h = height }, popupBounds, win)
	local clicked = Interaction.ConsumeWidgetClick(win, hovered, entry.open)
	if clicked then
		if not entry.open and hovered then
			entry.open, win._widgetBlockedRegions = true, { popupBounds }
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
		-- Background behind popup list
		win:QueueDrawAtLayer(3, DrawDropdownPopupBackground, win, popupX, popupY, width, listH)
		for i, opt in ipairs(options) do
			local isH =
				Interaction.IsHovered(win, { x = absX, y = absY + height + (i - 1) * height, w = width, h = height })
			-- Individual popup items
			win:QueueDrawAtLayer(
				4,
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
		-- Outline around the popup list
		win:QueueDrawAtLayer(5, DrawDropdownPopupOutline, win, popupX, popupY, width, listH)
	end
	return entry.selected, entry.changed
end

return Dropdown

end)
__bundle_register("TimMenu.Widgets.TextInput", function(require, _LOADED, __bundle_register, __bundle_modules)
local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

-- Helper for TextInput character mapping
local KeyCodeToCharTable = {
	[KEY_A] = { "a", "A" },
	[KEY_B] = { "b", "B" },
	[KEY_C] = { "c", "C" },
	[KEY_D] = { "d", "D" },
	[KEY_E] = { "e", "E" },
	[KEY_F] = { "f", "F" },
	[KEY_G] = { "g", "G" },
	[KEY_H] = { "h", "H" },
	[KEY_I] = { "i", "I" },
	[KEY_J] = { "j", "J" },
	[KEY_K] = { "k", "K" },
	[KEY_L] = { "l", "L" },
	[KEY_M] = { "m", "M" },
	[KEY_N] = { "n", "N" },
	[KEY_O] = { "o", "O" },
	[KEY_P] = { "p", "P" },
	[KEY_Q] = { "q", "Q" },
	[KEY_R] = { "r", "R" },
	[KEY_S] = { "s", "S" },
	[KEY_T] = { "t", "T" },
	[KEY_U] = { "u", "U" },
	[KEY_V] = { "v", "V" },
	[KEY_W] = { "w", "W" },
	[KEY_X] = { "x", "X" },
	[KEY_Y] = { "y", "Y" },
	[KEY_Z] = { "z", "Z" },

	[KEY_0] = { "0", ")" },
	[KEY_1] = { "1", "!" },
	[KEY_2] = { "2", "@" },
	[KEY_3] = { "3", "#" },
	[KEY_4] = { "4", "$" },
	[KEY_5] = { "5", "%" },
	[KEY_6] = { "6", "^" },
	[KEY_7] = { "7", "&" },
	[KEY_8] = { "8", "*" },
	[KEY_9] = { "9", "(" },

	[KEY_SPACE] = { " ", " " },
	[KEY_MINUS] = { "-", "_" },
	[KEY_EQUAL] = { "=", "+" },
	[KEY_LBRACKET] = { "[", "{" },
	[KEY_RBRACKET] = { "]", "}" },
	[KEY_BACKSLASH] = { "\\", "|" }, -- Escaped backslash
	[KEY_SEMICOLON] = { ";", ":" },
	[KEY_APOSTROPHE] = { "'", '"' }, -- Fixed: was single quote for both
	[KEY_COMMA] = { ",", "<" },
	[KEY_PERIOD] = { ".", ">" },
	[KEY_SLASH] = { "/", "?" },
	[KEY_BACKQUOTE] = { "`", "~" },

	[KEY_PAD_0] = { "0", "0" },
	[KEY_PAD_1] = { "1", "1" },
	[KEY_PAD_2] = { "2", "2" },
	[KEY_PAD_3] = { "3", "3" },
	[KEY_PAD_4] = { "4", "4" },
	[KEY_PAD_5] = { "5", "5" },
	[KEY_PAD_6] = { "6", "6" },
	[KEY_PAD_7] = { "7", "7" },
	[KEY_PAD_8] = { "8", "8" },
	[KEY_PAD_9] = { "9", "9" },
	[KEY_PAD_DECIMAL] = { ".", "." },
	[KEY_PAD_DIVIDE] = { "/", "/" },
	[KEY_PAD_MULTIPLY] = { "*", "*" },
	[KEY_PAD_MINUS] = { "-", "-" },
	[KEY_PAD_PLUS] = { "+", "+" },
}

local function MapKeyCodeToChar(keyCode, isShiftDown)
	local entry = KeyCodeToCharTable[keyCode]
	if entry then
		return isShiftDown and entry[2] or entry[1]
	end
	return nil
end

local function TextInput(win, label, text)
	assert(type(win) == "table", "TextInput: win must be a table")
	assert(type(label) == "string", "TextInput: label must be a string")
	assert(text == nil or type(text) == "string", "TextInput: text must be a string or nil")

	win._widgetCounter = (win._widgetCounter or 0) + 1
	win._textInputs = win._textInputs or {}
	local storageKey = tostring(win.id) .. ":textinput:" .. label
	local entry = win._textInputs[storageKey]

	if not entry then
		entry = {
			text = text or "",
			active = false,
			debouncedKeys = {}, -- For per-key press debouncing
			keyStates = {}, -- For key repeat logic (new)
		}
		win._textInputs[storageKey] = entry
	elseif text and text ~= entry.text and not entry.active then
		entry.text = text
	end

	draw.SetFont(Globals.Style.Font)
	local _, txtH = draw.GetTextSize("Ay") -- Base height on a character for consistent box height
	local pad = Globals.Style.ItemPadding
	-- Use a fixed width or calculate based on window, similar to other widgets.
	-- For now, let's make it take a good portion of the window width if not specified.
	-- local width = win.W - (Globals.Defaults.WINDOW_CONTENT_PADDING * 2) - (win.cursorX - Globals.Defaults.WINDOW_CONTENT_PADDING) - pad
	-- width = math.max(width, 100) -- Ensure a minimum width
	local width = Globals.Defaults.SLIDER_WIDTH -- Use a default fixed width like sliders
	local height = txtH + pad * 2

	local x, y = win:AddWidget(width, height) -- Reserve space
	local absX, absY = win.X + x, win.Y + y
	local bounds = { x = absX, y = absY, w = width, h = height }
	local hovered = Interaction.IsHovered(win, bounds)
	local changed = false

	if input.IsButtonPressed(MOUSE_LEFT) then
		if hovered then
			if not entry.active then
				entry.active = true
				for k, _ in pairs(entry.debouncedKeys) do
					entry.debouncedKeys[k] = false
				end
				entry.keyStates = {} -- Reset key repeat states on activation
			end
		elseif entry.active then
			entry.active = false
			for k, _ in pairs(entry.debouncedKeys) do
				entry.debouncedKeys[k] = false
			end
			entry.keyStates = {} -- Reset key repeat states on deactivation
		end
	end

	if entry.active then
		local lmbx_globals = _G.globals
		local currentTime = lmbx_globals and lmbx_globals.RealTime and lmbx_globals.RealTime() or 0
		local KEY_REPEAT_INITIAL_DELAY = 0.4 -- seconds
		local KEY_REPEAT_INTERVAL = 0.05 -- seconds

		local isShiftDown = input.IsButtonDown(KEY_LSHIFT) or input.IsButtonDown(KEY_RSHIFT)
		entry.keyStates = entry.keyStates or {} -- Ensure keyStates table exists

		-- Handle character keys from KeyCodeToCharTable with repeat
		for keyCode, _ in pairs(KeyCodeToCharTable) do
			local state = entry.keyStates[keyCode] or {}
			if input.IsButtonDown(keyCode) then
				if not state.firstDownTime then -- Key just pressed
					local char = MapKeyCodeToChar(keyCode, isShiftDown)
					if char then
						entry.text = entry.text .. char
						changed = true
					end
					state.firstDownTime = currentTime
					state.lastRepeatTime = currentTime
				elseif
					state.firstDownTime
					and (currentTime - state.firstDownTime > KEY_REPEAT_INITIAL_DELAY)
					and (currentTime - state.lastRepeatTime > KEY_REPEAT_INTERVAL)
				then -- Key held long enough for repeat
					local char = MapKeyCodeToChar(keyCode, isShiftDown)
					if char then
						entry.text = entry.text .. char
						changed = true
					end
					state.lastRepeatTime = currentTime
				end
				-- If key is down but not yet time for repeat, state.firstDownTime is already set, no specific action here.
			else -- Key is UP
				if state.firstDownTime then -- If it *was* pressed (had a firstDownTime)
					state.firstDownTime = nil
					state.lastRepeatTime = nil
				end
			end
			entry.keyStates[keyCode] = state -- Store the updated state (pressed, repeating, or reset)
		end

		-- Handle Backspace with repeat
		local backspaceKeyCode = KEY_BACKSPACE
		local bkspState = entry.keyStates[backspaceKeyCode] or {}
		if input.IsButtonDown(backspaceKeyCode) then
			if not bkspState.firstDownTime then -- Backspace just pressed
				if #entry.text > 0 then
					entry.text = string.sub(entry.text, 1, -2)
					changed = true
				end
				bkspState.firstDownTime = currentTime
				bkspState.lastRepeatTime = currentTime
			elseif
				bkspState.firstDownTime
				and (currentTime - bkspState.firstDownTime > KEY_REPEAT_INITIAL_DELAY)
				and (currentTime - bkspState.lastRepeatTime > KEY_REPEAT_INTERVAL)
			then -- Backspace held
				if #entry.text > 0 then
					entry.text = string.sub(entry.text, 1, -2)
					changed = true
				end
				bkspState.lastRepeatTime = currentTime
			end
		else -- Backspace is UP
			if bkspState.firstDownTime then -- If it *was* pressed
				bkspState.firstDownTime = nil
				bkspState.lastRepeatTime = nil
			end
		end
		entry.keyStates[backspaceKeyCode] = bkspState -- Store updated state

		-- Handle Enter, Escape (single action, no repeat using original debounce)
		local singleActionKeys = { KEY_ENTER, KEY_PAD_ENTER, KEY_ESCAPE }
		for _, keyCode in ipairs(singleActionKeys) do
			if input.IsButtonDown(keyCode) then
				if not entry.debouncedKeys[keyCode] then
					if keyCode == KEY_ENTER or keyCode == KEY_PAD_ENTER or keyCode == KEY_ESCAPE then
						entry.active = false
						for k, _ in pairs(entry.debouncedKeys) do
							entry.debouncedKeys[k] = false
						end
						entry.keyStates = {} -- Clear key repeat states
					end
					entry.debouncedKeys[keyCode] = true
				else
					if entry.debouncedKeys[keyCode] then
						entry.debouncedKeys[keyCode] = false
					end
					-- If key is up and was part of keyStates, clear it (though these aren't typically in keyStates)
					if entry.keyStates[keyCode] then
						entry.keyStates[keyCode] = nil
					end
				end
			end
		end
	else
		-- If not active, ensure all keys are marked as released for debounce and keyStates
		if entry.active == false then
			local resetAllKeyStates = false
			for k, state in pairs(entry.keyStates) do
				if state.firstDownTime ~= nil then -- if any key was active
					resetAllKeyStates = true
					break
				end
			end
			if resetAllKeyStates or next(entry.debouncedKeys) ~= nil then
				for k, _ in pairs(entry.debouncedKeys) do
					entry.debouncedKeys[k] = false
				end
				entry.keyStates = {} -- Clear all key repeat states
			end
		end
	end

	win:QueueDrawAtLayer(2, function()
		local px, py = win.X + x, win.Y + y
		local bg = Globals.Colors.Item
		if entry.active then
			bg = Globals.Colors.ItemActive
		elseif hovered then
			bg = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(bg))
		Common.DrawFilledRect(px, py, px + width, py + height)
		draw.SetFont(Globals.Style.Font)

		local textContentForDisplay -- This will be the text part (placeholder or actual entry.text)
		local textColor = Globals.Colors.Text

		if entry.text == "" and not entry.active then
			textContentForDisplay = label
			textColor = { 180, 180, 180, 255 }
		else
			textContentForDisplay = entry.text
		end

		local textDrawX = px + pad
		local textDrawY = py + (height - txtH) / 2

		-- Truncation Logic
		local availableWidthForText = width - (pad * 2)
		local cursorRenderWidth = 0
		if entry.active then
			cursorRenderWidth, _ = draw.GetTextSize("|")
			local wideCharExtraPadding, _ = draw.GetTextSize("O") -- Get width of a reference wide character
			availableWidthForText = availableWidthForText - cursorRenderWidth - wideCharExtraPadding - pad -- Added extra 'pad' for good measure
		end

		local finalDrawableText = textContentForDisplay
		local textContentWidth, _ = draw.GetTextSize(textContentForDisplay)

		if textContentWidth > availableWidthForText and availableWidthForText > 0 then
			local truncated = ""
			local currentAccumulatedWidth = 0
			for i = #textContentForDisplay, 1, -1 do
				local char = string.sub(textContentForDisplay, i, i)
				local charW, _ = draw.GetTextSize(char)
				if currentAccumulatedWidth + charW <= availableWidthForText then
					truncated = char .. truncated
					currentAccumulatedWidth = currentAccumulatedWidth + charW
				else
					break
				end
			end
			finalDrawableText = "..." .. truncated
		end

		-- Append Blinking cursor if active
		if entry.active then
			local lmbx = _G.globals
			if lmbx and lmbx.RealTime then
				if math.floor(lmbx.RealTime() * 2.5) % 2 == 0 then
					finalDrawableText = finalDrawableText .. "|"
				else
					finalDrawableText = finalDrawableText .. " "
				end
			else
				finalDrawableText = finalDrawableText .. "|"
			end
		end

		draw.Color(table.unpack(textColor))
		Common.DrawText(textDrawX, textDrawY, finalDrawableText)

		draw.Color(table.unpack(Globals.Colors.WidgetOutline))
		Common.DrawOutlinedRect(px, py, px + width, py + height)
	end)

	return entry.text, changed
end

return TextInput

end)
__bundle_register("TimMenu.Widgets.Separator", function(require, _LOADED, __bundle_register, __bundle_modules)
local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")

local function Separator(win, label)
	assert(type(win) == "table", "Separator: win must be a table")
	assert(label == nil or type(label) == "string", "Separator: label must be a string or nil")
	local pad = Globals.Defaults.WINDOW_CONTENT_PADDING
	local vpad = Globals.Style.ItemPadding
	-- ensure on its own line
	if win.cursorX > pad then
		win:NextLine(0)
	end
	win:NextLine(vpad)
	local totalWidth = win.W - (pad * 2)
	if type(label) == "string" then
		draw.SetFont(Globals.Style.Font)
		local textWidth, textHeight = draw.GetTextSize(label)
		local x, y = win:AddWidget(totalWidth, textHeight)
		win:QueueDrawAtLayer(1, function()
			local absX, absY = win.X + x, win.Y + y
			local centerY = absY + math.floor(textHeight / 2)
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawLine(absX, centerY, absX + (totalWidth - textWidth) / 2 - Globals.Style.ItemPadding, centerY)
			draw.Color(table.unpack(Globals.Colors.Text))
			Common.DrawText(absX + (totalWidth - textWidth) / 2, absY, label)
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawLine(
				absX + (totalWidth + textWidth) / 2 + Globals.Style.ItemPadding,
				centerY,
				absX + totalWidth,
				centerY
			)
		end)
	else
		local x, y = win:AddWidget(totalWidth, 1)
		win:QueueDrawAtLayer(1, function()
			local absX, absY = win.X + x, win.Y + y
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawLine(absX, absY, absX + totalWidth, absY)
		end)
	end
	win:NextLine(vpad)
end

return Separator

end)
__bundle_register("TimMenu.Widgets.Slider", function(require, _LOADED, __bundle_register, __bundle_modules)
local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

-- Internal drag state per-slider
local sliderDragState = {}

local function Slider(win, label, value, min, max, step)
	assert(type(win) == "table", "Slider: win must be a table")
	assert(type(label) == "string", "Slider: label must be a string")
	assert(type(value) == "number", "Slider: value must be a number")
	assert(type(min) == "number", "Slider: min must be a number")
	assert(type(max) == "number", "Slider: max must be a number")
	assert(type(step) == "number", "Slider: step must be a number")
	-- assign a per-window unique index to avoid collisions in layout
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter

	-- Measure and layout
	draw.SetFont(Globals.Style.Font)
	local labelText = label .. ": " .. tostring(value)
	local txtW, txtH = draw.GetTextSize(labelText)
	local padding = Globals.Style.ItemPadding
	local height = txtH + (padding * 2)
	local width = Globals.Defaults.SLIDER_WIDTH
	if width < txtW + (padding * 4) then
		width = txtW + (padding * 4)
	end
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + padding
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- Normalize current value
	local norm = (value - min) / (max - min)
	norm = math.min(1, math.max(0, norm))

	-- Interaction logic
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

	-- Compute new stepped value
	local changed = false
	if dragging then
		local t = math.min(1, math.max(0, (mX - absX) / width))
		local raw = min + ((max - min) * t)
		local stepped = min + (Common.RoundNearest((raw - min) / step) * step)
		stepped = math.min(max, math.max(min, stepped))
		if stepped ~= value then
			value = stepped
			changed = true
		end
	end

	-- Draw slider
	win:QueueDrawAtLayer(2, function(hv)
		local px, py = win.X + x, win.Y + y
		local bg = hv and Globals.Colors.ItemHover or Globals.Colors.Item
		draw.Color(table.unpack(bg))
		Common.DrawFilledRect(px, py, px + width, py + height)
		local fillCol = dragging and Globals.Colors.HighlightActive or Globals.Colors.Highlight
		draw.Color(table.unpack(fillCol))
		Common.DrawFilledRect(px, py, px + (width * norm), py + height)
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawOutlinedRect(px, py, px + width, py + height)
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		Common.DrawText(px + (width - txtW) * 0.5, py + (height - txtH) * 0.5, labelText)
	end, hovered)

	return value, changed
end

return Slider

end)
__bundle_register("TimMenu.Widgets.Checkbox", function(require, _LOADED, __bundle_register, __bundle_modules)
local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

local function canInteract(win, bounds)
	return Interaction.IsHovered(win, bounds)
end

local function Checkbox(win, label, state)
	assert(type(win) == "table", "Checkbox: win must be a table")
	assert(type(label) == "string", "Checkbox: label must be a string")
	assert(type(state) == "boolean", "Checkbox: state must be a boolean")
	-- assign a per-window unique index to avoid collisions
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter
	-- Font and sizing
	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(label)
	local padding = Globals.Style.ItemPadding
	-- Use Globals.Style.ItemSize for the checkbox square's base size
	local boxSize = Globals.Style.ItemSize + (padding * 2)
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
		local px, py = win.X + x, win.Y + y
		local bgColor = Globals.Colors.Item
		local active = hovered and input.IsButtonDown(MOUSE_LEFT)
		if active then
			bgColor = Globals.Colors.ItemActive
		elseif hovered then
			bgColor = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(bgColor))
		Common.DrawFilledRect(px, py, px + boxSize, py + boxSize)

		-- Outline
		draw.Color(table.unpack(Globals.Colors.WidgetOutline))
		Common.DrawOutlinedRect(px, py, px + boxSize, py + boxSize)

		-- Check mark fill
		if state then
			draw.Color(table.unpack(Globals.Colors.Highlight))
			local margin = math.floor(boxSize * 0.25)
			Common.DrawFilledRect(px + margin, py + margin, px + boxSize - margin, py + boxSize - margin)
		end
		-- Text label
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		Common.DrawText(px + boxSize + padding, py + (boxSize // 2) - (txtH // 2), label)
	end)

	return state, clicked
end

return Checkbox

end)
__bundle_register("TimMenu.Widgets.Button", function(require, _LOADED, __bundle_register, __bundle_modules)
local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

local function canInteract(win, bounds)
	return Interaction.IsHovered(win, bounds)
end

local function Button(win, label)
	assert(type(win) == "table", "Button: win must be a table")
	assert(type(label) == "string", "Button: label must be a string")
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

	-- Interaction bounds
	local bounds = { x = absX, y = absY, w = width, h = height }
	local hovered = canInteract(win, bounds)
	local key = tostring(win.id) .. ":" .. label .. ":" .. widgetIndex
	local clicked = hovered and Interaction.IsPressed(key)
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(key)
	end

	win:QueueDrawAtLayer(2, function()
		local px, py = win.X + x, win.Y + y
		local bgColor = Globals.Colors.Item
		if Interaction._PressState[key] then
			bgColor = Globals.Colors.ItemActive
		elseif hovered then
			bgColor = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(bgColor))
		Common.DrawFilledRect(px, py, px + width, py + height)
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawOutlinedRect(px, py, px + width, py + height)
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		Common.DrawText(px + padding, py + padding, label)
	end)

	return clicked
end

return Button

end)
__bundle_register("TimMenu.Window", function(require, _LOADED, __bundle_register, __bundle_modules)
local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local DrawManager = require("TimMenu.DrawManager")
local lmbx = globals -- alias for Lmaobox API

local Window = {}
Window.__index = Window

local function applyDefaults(params)
	-- Provide a fallback for each setting if not provided
	return {
		title = params.title or "Untitled",
		id = params.id or params.title,
		visible = (params.visible == nil) and true or params.visible,
		X = params.X or (Globals.Defaults.DEFAULT_X + math.random(0, 150)),
		Y = params.Y or (Globals.Defaults.DEFAULT_Y + math.random(0, 50)),
		W = params.W or Globals.Defaults.DEFAULT_W,
		H = params.H or Globals.Defaults.DEFAULT_H,
	}
end

--- __close metamethod: cleans up window state.
function Window:__close()
	self.lastFrame = nil
	self.IsDragging = false
	self.DragPos = { X = 0, Y = 0 }
end

function Window:update()
	-- Mark this window as touched this frame for pruning
	self._lastFrameTouched = lmbx.FrameCount()
end

function Window.new(params)
	-- Ensure parameters exist
	if type(params) == "string" then
		params = { title = params }
	end
	params = applyDefaults(params)

	-- Create our window object with simple composition
	local self = setmetatable({}, Window)
	self.title = params.title
	self.id = params.id
	self.visible = params.visible
	self.X = params.X
	self.Y = params.Y
	self.W = params.W
	self.H = params.H
	self._lastFrameTouched = lmbx.FrameCount() -- Initialize touch timestamp
	self.IsDragging = false
	self.DragPos = { X = 0, Y = 0 }
	-- Set __close metamethod so it auto-cleans when used as a to-be-closed variable.
	local mt = getmetatable(self)
	mt.__close = Window.__close

	self.cursorX = 0
	self.cursorY = 0
	self.lineHeight = 0
	-- Initialize per-widget blocking regions for popup widgets
	self._widgetBlockedRegions = {}
	return self
end

--- Queue a drawing function under a specified layer
function Window:QueueDrawAtLayer(layer, drawFunc, ...)
	DrawManager.Enqueue(self.id, layer, drawFunc, ...)
end

--- Hit test: is a point inside this window (including title bar and bottom padding)?
function Window:_HitTest(x, y)
	-- Hit test entire window area (title, content, and bottom padding)
	local titleHeight = Globals.Defaults.TITLE_BAR_HEIGHT
	local bottomPad = Globals.Defaults.WINDOW_CONTENT_PADDING
	return x >= self.X and x <= self.X + self.W and y >= self.Y and y <= self.Y + titleHeight + self.H + bottomPad
end

--- Update window logic: dragging only; mark touched only in Begin()
function Window:_UpdateLogic(mx, my, isFocused, pressed, down, released)
	-- Use static title bar height for dragging region
	local titleHeight = Globals.Defaults.TITLE_BAR_HEIGHT

	-- Start dragging if focused and pressed in title bar
	if isFocused and pressed and my >= self.Y and my <= self.Y + titleHeight then
		self.IsDragging = true
		self.DragPos = { X = mx - self.X, Y = my - self.Y }
	end

	-- Continue dragging while mouse button held
	if self.IsDragging then
		if down then
			self.X = mx - self.DragPos.X
			self.Y = my - self.DragPos.Y
		elseif released then
			self.IsDragging = false
		end
	end
end

--- Draw the entire window: chrome and queued widget layers
function Window:_Draw()
	draw.SetFont(Globals.Style.Font)
	local txtWidth, txtHeight = draw.GetTextSize(self.title)
	-- Draw title bar at static height and center text vertically
	local titleHeight = Globals.Defaults.TITLE_BAR_HEIGHT
	local bottomPad = Globals.Defaults.WINDOW_CONTENT_PADDING

	-- Background
	draw.Color(table.unpack(Globals.Colors.Window))
	-- Extend background with bottom padding
	Common.DrawFilledRect(self.X, self.Y + titleHeight, self.X + self.W, self.Y + titleHeight + self.H + bottomPad)

	-- Title bar
	draw.Color(table.unpack(Globals.Colors.Title))
	Common.DrawFilledRect(self.X, self.Y, self.X + self.W, self.Y + titleHeight)

	-- Border
	if Globals.Style.EnableWindowBorder then
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		-- Outline around full window including title and bottom padding
		Common.DrawOutlinedRect(self.X, self.Y, self.X + self.W, self.Y + titleHeight + self.H + bottomPad)
	end

	-- Title text
	draw.Color(table.unpack(Globals.Colors.Text))
	local titleX
	if self._hasHeaderTabs then
		titleX = self.X + Globals.Defaults.WINDOW_CONTENT_PADDING
	else
		titleX = self.X + (self.W - txtWidth) / 2
	end
	Common.DrawText(titleX, self.Y + (titleHeight - txtHeight) / 2, self.title)

	-- (All widget draw calls are now collected centrally by DrawManager)
end

--- Calculates widget position and updates window size if needed
--- @param width number The widget width
--- @param height number The widget height
--- @return number, number The x, y coordinates for the widget
function Window:AddWidget(width, height)
	local padding = Globals.Defaults.WINDOW_CONTENT_PADDING
	local x = self.cursorX
	local y = self.cursorY

	-- Calculate x position based on alignment
	if Globals.Style.Alignment == "center" then
		x = math.max(padding, math.floor((self.W - width) * 0.5))
	end

	-- Update window dimensions if needed
	self.W = math.max(self.W, x + width + padding)
	self.lineHeight = math.max(self.lineHeight, height)
	self.H = math.max(self.H, y + self.lineHeight)

	-- Update cursor position for the *next* widget on this line
	self.cursorX = self.cursorX + width + Globals.Defaults.ITEM_SPACING

	return x, y
end

--- Provide a simple way to "new line" to place subsequent widgets below
--- Resets horizontal position and advances vertically.
function Window:NextLine(spacing)
	spacing = spacing or Globals.Defaults.WINDOW_CONTENT_PADDING
	self.cursorY = self.cursorY + self.lineHeight + spacing
	self.cursorX = Globals.Defaults.WINDOW_CONTENT_PADDING -- reset to left padding
	local endOfLineY = self.cursorY -- Y position *before* resetting lineHeight
	self.lineHeight = 0
	-- Expand window if needed, considering the end of the previous line
	self.H = math.max(self.H, endOfLineY)
end

--- Advances the cursor horizontally to place the next widget on the same line.
function Window:SameLine(spacing)
	-- Default spacing is Globals.Defaults.ITEM_SPACING
	spacing = spacing or Globals.Defaults.ITEM_SPACING
	self.cursorX = self.cursorX + spacing -- Add specified spacing
	-- Note: We don't add widget width here, AddWidget already does that
	-- and advances cursorX *after* returning the position.
end

--- Adds vertical spacing without resetting the horizontal cursor position.
function Window:Spacing(verticalSpacing)
	-- Default spacing is half the content padding
	verticalSpacing = verticalSpacing or (Globals.Defaults.WINDOW_CONTENT_PADDING / 2)
	-- Use current line height + spacing to advance Y
	self.cursorY = self.cursorY + self.lineHeight + verticalSpacing
	self.lineHeight = 0 -- Reset line height for the *next* line that might start here
	-- Expand window if needed
	if self.cursorY > self.H then
		self.H = self.cursorY
	end
	-- Important: Do NOT reset cursorX here.
end

--- Reset the layout cursor for widgets (called on Begin)
function Window:resetCursor()
	local padding = Globals.Defaults.WINDOW_CONTENT_PADDING
	self.cursorX = padding
	self.cursorY = Globals.Defaults.TITLE_BAR_HEIGHT + padding
	self.lineHeight = 0
	-- Clear any widget blocking regions at start of frame
	self._widgetBlockedRegions = {}
	-- Clear header tabs flag so titles center if no header tabs
	self._hasHeaderTabs = false
end

return Window

end)
return __bundle_require("__root")