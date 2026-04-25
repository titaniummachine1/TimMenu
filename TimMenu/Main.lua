local TimMenu = {}

local function Setup()
	TimMenuGlobal = {
		windows = {},
		order = {},
		InputState = {
			isLeftMouseDown = false,
			wasLeftMouseDownLastFrame = false,
		},
		kbStates = {}, -- Store toggle states for keybinds { [key] = bool }
	}
end

Setup()

local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local Utils = require("TimMenu.Utils")
local Window = require("TimMenu.Window")
local SectorWidget = require("TimMenu.Layout.Sector")
local SeparatorLayout = require("TimMenu.Layout.Separator")
local DrawManager = require("TimMenu.DrawManager")
local Widgets = require("TimMenu.Widgets")

local nextWidgetFont = nil

TimMenu.Options = {
	Visibility = {
		ShowAlways = false,
		LboxIndependent = false,
	},
}

local function resolveShowAlwaysOption(optionsTable, fallbackValue)
	local resolvedValue = fallbackValue and true or false
	if type(optionsTable) ~= "table" then
		return resolvedValue
	end
	if optionsTable.ShowAlways ~= nil then
		return optionsTable.ShowAlways and true or false
	end
	if optionsTable.showAlways ~= nil then
		return optionsTable.showAlways and true or false
	end
	if optionsTable.LboxIndependent ~= nil then
		return optionsTable.LboxIndependent and true or false
	end
	return resolvedValue
end

function TimMenu.SetVisibilityOptions(options)
	if type(options) ~= "table" then
		return
	end
	local visibilityOptions = TimMenu.Options.Visibility
	local showAlways = resolveShowAlwaysOption(options, visibilityOptions.ShowAlways)
	visibilityOptions.ShowAlways = showAlways
	visibilityOptions.LboxIndependent = showAlways
end

function TimMenu.GetVisibilityOptions()
	return {
		ShowAlways = TimMenu.Options.Visibility.ShowAlways,
		LboxIndependent = TimMenu.Options.Visibility.LboxIndependent,
	}
end

function TimMenu.SetFontNext(name, size, weight)
	nextWidgetFont = { name = name, size = size, weight = weight }
end

local _currentWindow = nil

local function applyPendingFont(win)
	if not nextWidgetFont then
		return
	end
	local fontId = Globals.GetFont(nextWidgetFont.name, nextWidgetFont.size, nextWidgetFont.weight)
	win._fontContext.current = fontId
	Globals.Style.Font = fontId
	draw.SetFont(fontId)
	nextWidgetFont = nil
end

local function getActiveFont(win)
	return win._fontContext.current or win._fontContext.default
end

local function withCurrentWindow(func, ...)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return
	end
	return func(win, ...)
end

local function getOrCreateWindow(key, title, visible)
	local win = TimMenuGlobal.windows[key]
	if not win then
		win = Window.new({ title = title, id = key, visible = visible })
		TimMenuGlobal.windows[key] = win
		table.insert(TimMenuGlobal.order, key)
	else
		win.visible = visible
	end
	return win
end

local function resolveBeginArgs(visible, id, options)
	local resolvedVisible = visible
	local resolvedId = id
	local resolvedOptions = options

	if type(resolvedVisible) == "table" and resolvedId == nil and resolvedOptions == nil then
		resolvedOptions = resolvedVisible
		resolvedVisible = nil
	end

	if type(resolvedVisible) == "string" then
		resolvedId = resolvedVisible
		resolvedVisible = nil
	end

	if type(resolvedId) == "table" and resolvedOptions == nil then
		resolvedOptions = resolvedId
		resolvedId = nil
	end

	if type(resolvedOptions) ~= "table" then
		resolvedOptions = nil
	end

	if resolvedVisible == nil and resolvedOptions and resolvedOptions.visible ~= nil then
		resolvedVisible = resolvedOptions.visible
	end

	if resolvedVisible == nil then
		resolvedVisible = true
	end

	local showAlways = resolveShowAlwaysOption(resolvedOptions, TimMenu.Options.Visibility.ShowAlways)

	if not showAlways then
		resolvedVisible = resolvedVisible and gui.IsMenuOpen()
	end

	return resolvedVisible, resolvedId
end

function TimMenu.Begin(title, visible, id, options)
	TimMenu.FontReset()
	local resolvedVisible, resolvedId = resolveBeginArgs(visible, id, options)
	local key = (resolvedId or title)

	local win = getOrCreateWindow(key, title, resolvedVisible)
	win:update()

	_currentWindow = win
	win:resetCursor()
	win._widgetCounter = 0
	win._sectorStack = {}
	win._widgetBounds = {}
	win._fontContext = win._fontContext or {}
	win._fontContext.default = Globals.Style.Font
	win._fontContext.current = win._fontContext.default
	Globals.Style.Font = win._fontContext.current
	draw.SetFont(win._fontContext.current)

	if not win.visible or (gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot()) then
		return false
	end

	return true, win
end

function TimMenu.End()
	_currentWindow = nil
end

function TimMenu.GetCurrentWindow()
	return _currentWindow
end

function TimMenu.Button(label)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return false
	end
	applyPendingFont(win)
	return Widgets.Button(win, label)
end

function TimMenu.Checkbox(label, state)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return state, false
	end
	applyPendingFont(win)
	return Widgets.Checkbox(win, label, state)
end

function TimMenu.Text(text)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return
	end

	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter

	applyPendingFont(win)
	local fontId = getActiveFont(win)
	draw.SetFont(fontId)
	local w, h = draw.GetTextSize(text)
	local x, y = win:AddWidget(w, h)
	local absX, absY = win.X + x, win.Y + y

	local bounds = { x = absX, y = absY, w = w, h = h }
	Widgets.Tooltip.StoreWidgetBounds(win, widgetIndex, bounds)

	Common.QueueText(win, Globals.Layers.WidgetText, absX, absY, text, Globals.Colors.Text, fontId)
end

function TimMenu.ShowDebug()
	local currentFrame = globals.FrameCount()
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

function TimMenu.NextLine(spacing)
	return withCurrentWindow(function(win, spacing)
		win:NextLine(spacing)
	end, spacing)
end

function TimMenu.SameLine(spacing)
	return withCurrentWindow(function(win, spacing)
		win:SameLine(spacing)
	end, spacing)
end

function TimMenu.Spacing(verticalSpacing)
	return withCurrentWindow(function(win, verticalSpacing)
		win:Spacing(verticalSpacing)
	end, verticalSpacing)
end

function TimMenu.Slider(label, value, min, max, step)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return value, false
	end
	applyPendingFont(win)
	return Widgets.Slider(win, label, value, min, max, step)
end

function TimMenu.Separator(label)
	return withCurrentWindow(function(win, label)
		return SeparatorLayout.Draw(win, label)
	end, label)
end

function TimMenu.TextInput(label, text)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return text, false
	end
	applyPendingFont(win)
	return Widgets.TextInput(win, label, text)
end

function TimMenu.Dropdown(label, selectedIndex, options)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return selectedIndex, false
	end
	applyPendingFont(win)
	return Widgets.Dropdown(win, label, selectedIndex, options)
end

function TimMenu.Combo(label, selectedTable, options)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return selectedTable, false
	end
	applyPendingFont(win)
	return Widgets.Combo(win, label, selectedTable, options)
end

function TimMenu.Selector(label, selectedIndex, options)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return selectedIndex, false
	end
	applyPendingFont(win)
	return Widgets.Selector(win, label, selectedIndex, options)
end

function TimMenu.TabControl(id, tabs, defaultSelection)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		if type(defaultSelection) == "string" then
			return tabs[1] or "", false
		else
			return 1, false
		end
	end
	applyPendingFont(win)
	local newIndex, changed = Widgets.TabControl(win, id, tabs, defaultSelection)
	if type(defaultSelection) == "string" then
		return tabs[newIndex], changed
	end
	return newIndex, changed
end

function TimMenu.BeginSector(label)
	return withCurrentWindow(function(win, label)
		SectorWidget.Begin(win, label)
	end, label)
end

function TimMenu.EndSector()
	local win = TimMenu.GetCurrentWindow()
	if not win or not win._sectorStack or #win._sectorStack == 0 then
		return
	end
	SectorWidget.End(win)
end

-- Update toggle states in GlobalDraw
local function UpdateKeybindToggles()
	-- This should be called once per frame.
	-- We iterate through all keys and update toggle state if pressed.
	for code = 1, 255 do
		if input.IsButtonPressed(code) then
			TimMenuGlobal.kbStates[code] = not TimMenuGlobal.kbStates[code]
		end
	end
end

local reRegistered = false
local function _TimMenu_GlobalDraw()
	UpdateKeybindToggles()
	TimMenuGlobal.InputState.wasLeftMouseDownLastFrame = TimMenuGlobal.InputState.isLeftMouseDown
	TimMenuGlobal.InputState.isLeftMouseDown = input.IsButtonDown(MOUSE_LEFT)

	local mouseX, mouseY = table.unpack(input.GetMousePos())
	TimMenuGlobal.mouseX, TimMenuGlobal.mouseY = mouseX, mouseY

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

	-- PRIMARY FOCUS LOOP: Top-to-bottom search for window under mouse
	local windowUnderMouse = nil
	local mousePressed = input.IsButtonPressed(MOUSE_LEFT)

	for i = #TimMenuGlobal.order, 1, -1 do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win and win.visible and win:_HitTest(mouseX, mouseY) then
			windowUnderMouse = key
			break -- FOUND THE TOPMOST OWNER. STOP SEARCHING.
		end
	end

	-- Handle focus changes only when clicking
	if mousePressed and windowUnderMouse then
		-- Bring the owner window to front
		if TimMenuGlobal.order[#TimMenuGlobal.order] ~= windowUnderMouse then
			for j, v_key in ipairs(TimMenuGlobal.order) do
				if v_key == windowUnderMouse then
					table.remove(TimMenuGlobal.order, j)
					break
				end
			end
			table.insert(TimMenuGlobal.order, windowUnderMouse)
		end
	end

	-- Update logic for all visible windows
	for i = 1, #TimMenuGlobal.order do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win and win.visible then
			local isFocused = (key == windowUnderMouse)
			win:_UpdateLogic(
				mouseX,
				mouseY,
				isFocused,
				input.IsButtonPressed(MOUSE_LEFT),
				input.IsButtonDown(MOUSE_LEFT),
				input.IsButtonReleased(MOUSE_LEFT)
			)
		end
	end

	for i = 1, #TimMenuGlobal.order do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win and win.visible then
			win:_Draw()
			DrawManager.FlushWindow(key)
		end
	end

	for i = 1, #TimMenuGlobal.order do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win and win.visible then
			Widgets.Tooltip.ProcessWindowTooltips(win)
		end
	end

	if not reRegistered then
		callbacks.Unregister("Draw", "zTimMenu_GlobalDraw")
		callbacks.Register("Draw", "zTimMenu_GlobalDraw", _TimMenu_GlobalDraw)
		reRegistered = true
	end
end

callbacks.Unregister("Draw", "zTimMenu_GlobalDraw")
callbacks.Register("Draw", "zTimMenu_GlobalDraw", _TimMenu_GlobalDraw)

function TimMenu.Keybind(label, currentKey)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return currentKey, false
	end
	applyPendingFont(win)
	return Widgets.Keybind(win, label, currentKey)
end

local function setFontStyle(style, name, size, weight)
	Globals.Style[style .. "Name"] = name
	Globals.Style[style .. "Size"] = size
	Globals.Style[style .. "Weight"] = weight
	Globals.ReloadFonts()
end

function TimMenu.FontSet(name, size, weight)
	setFontStyle("Font", name, size, weight)
end

function TimMenu.FontSetBold(name, size, weight)
	setFontStyle("FontBold", name, size, weight)
end

function TimMenu.FontReset()
	local d = Globals.DefaultFontSettings
	setFontStyle("Font", d.FontName, d.FontSize, d.FontWeight)
	setFontStyle("FontBold", d.FontBoldName, d.FontBoldSize, d.FontBoldWeight)
end

function TimMenu.ColorPicker(label, color)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return color, false
	end
	applyPendingFont(win)
	return Widgets.ColorPicker(win, label, color)
end

function TimMenu.Tooltip(text)
	return withCurrentWindow(function(win, text)
		Widgets.Tooltip.AttachToLastWidget(win, text)
	end, text)
end

-- --- Keybind System API ---

--- Checks if a keybind is active based on its mode and state.
---@param kbTable table|number { key = number, mode = number } or legacy keycode
---@return boolean
function TimMenu.IsKeybindActive(kbTable)
	if not kbTable then
		return false
	end

	-- Legacy support
	local key, mode
	if type(kbTable) == "number" then
		key = kbTable
		mode = 1 -- Hold
	elseif type(kbTable) == "table" then
		key = kbTable.key or 0
		mode = kbTable.mode or 0
	else
		return false
	end

	-- Always On
	if mode == 0 then
		return true
	end

	-- No key bound
	if key == 0 then
		return false
	end

	-- Hold
	if mode == 1 then
		return input.IsButtonDown(key)
	end

	-- Toggle
	if mode == 2 then
		return TimMenuGlobal.kbStates[key] == true
	end

	return false
end

_G.TimMenu = TimMenu
return TimMenu
