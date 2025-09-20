local TimMenu = {}

local function Setup()
	TimMenuGlobal = {
		windows = {},
		order = {},
		InputState = {
			isLeftMouseDown = false,
			wasLeftMouseDownLastFrame = false,
		},
	}
end

Setup()

local nextWidgetFont = nil

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

local _currentWindow = nil

-- Assertion utilities for debugging
local function assertType(value, expectedType, funcName, paramName)
	if type(value) ~= expectedType then
		error(string.format("[TimMenu] %s: Parameter '%s' must be %s, got %s",
			funcName or "unknown", paramName or "unknown", expectedType, type(value)))
	end
end

local function assertNotNil(value, funcName, paramName)
	if value == nil then
		error(string.format("[TimMenu] %s: Parameter '%s' cannot be nil",
			funcName or "unknown", paramName or "unknown"))
	end
end

local function assertValidWindow(funcName)
	local win = _currentWindow
	if not win then
		error(string.format("[TimMenu] %s: No active window. Call TimMenu.Begin() first",
			funcName or "unknown"))
	end
	if not win.visible then
		error(string.format("[TimMenu] %s: Current window '%s' is not visible",
			funcName or "unknown", win.title or "unknown"))
	end
end

local function assertInBeginBlock(funcName)
	if not _currentWindow then
		error(string.format("[TimMenu] %s: Must be called between TimMenu.Begin() and TimMenu.End()",
			funcName or "unknown"))
	end
end

local function assertValidString(str, funcName, paramName)
	assertNotNil(str, funcName, paramName)
	assertType(str, "string", funcName, paramName)
	if str == "" then
		error(string.format("[TimMenu] %s: Parameter '%s' cannot be empty string",
			funcName or "unknown", paramName or "unknown"))
	end
end

local function assertValidNumber(num, funcName, paramName)
	assertNotNil(num, funcName, paramName)
	assertType(num, "number", funcName, paramName)
end

local function assertValidBoolean(bool, funcName, paramName)
	assertNotNil(bool, funcName, paramName)
	assertType(bool, "boolean", funcName, paramName)
end

local function assertValidTable(tbl, funcName, paramName)
	assertNotNil(tbl, funcName, paramName)
	assertType(tbl, "table", funcName, paramName)
end

local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local Utils = require("TimMenu.Utils")
local Window = require("TimMenu.Window")
local SectorWidget = require("TimMenu.Layout.Sector")
local SeparatorLayout = require("TimMenu.Layout.Separator")
local DrawManager = require("TimMenu.DrawManager")
local Widgets = require("TimMenu.Widgets")

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

function TimMenu.Begin(title, visible, id)
	-- Validate parameters
	assertValidString(title, "Begin", "title")

	-- Handle the visible parameter variations
	if visible ~= nil then
		if type(visible) == "string" then
			-- visible was actually the id parameter
			id = visible
			visible = true
		else
			-- visible is a boolean
			assertValidBoolean(visible, "Begin", "visible")
		end
	end

	-- id can be nil, but if provided must be string or number
	if id ~= nil then
		assertType(id, "string", "Begin", "id")
		assertValidString(id, "Begin", "id")
	end

	local key = (id or title)

	-- Validate global state
	if not TimMenuGlobal then
		error("[TimMenu] Begin: TimMenu not properly initialized. Call Setup() first")
	end

	if not TimMenuGlobal.windows then
		error("[TimMenu] Begin: Window management not initialized")
	end

	local win = getOrCreateWindow(key, title, visible or true)

	-- Reset window state for this frame
	_currentWindow = win
	win:resetCursor()
	win._widgetCounter = 0
	win._sectorStack = {}
	win._widgetBounds = {}

	-- Validate window state
	if not win.visible then
		error(string.format("[TimMenu] Begin: Window '%s' is not visible", title))
	end

	-- Mark window as touched only when it's actually being used
	win:update()

	return true, win
end

function TimMenu.BeginSafe(title, visible, id)
	-- Helper function that ensures End() is always called
	local success, result = pcall(function()
		return TimMenu.Begin(title, visible, id)
	end)

	if success then
		return result
	else
		print("[TimMenu] Error in Begin:", result)
		return false
	end
end

function TimMenu.EndSafe()
	-- Helper function that ensures End() is always called safely
	local success, result = pcall(function()
		TimMenu.End()
	end)

	if not success then
		print("[TimMenu] Error in End:", result)
	end
end

function TimMenu.End()
	assertInBeginBlock("End")
	if not _currentWindow then
		error("[TimMenu] End: No active window to end")
	end
	_currentWindow = nil
end

function TimMenu.GetCurrentWindow()
	return _currentWindow
end

function TimMenu.Button(label)
	assertInBeginBlock("Button")
	assertValidString(label, "Button", "label")

	local win = TimMenu.GetCurrentWindow()
	if not win then
		error("[TimMenu] Button: No active window")
	end

	local prevFont = applyNextWidgetFont()
	local clicked = Widgets.Button(win, label)
	restoreWidgetFont(prevFont)
	return clicked
end

function TimMenu.Checkbox(label, state)
	assertInBeginBlock("Checkbox")
	assertValidString(label, "Checkbox", "label")
	assertValidBoolean(state, "Checkbox", "state")

	local win = TimMenu.GetCurrentWindow()
	if not win then
		error("[TimMenu] Checkbox: No active window")
	end

	local prevFont = applyNextWidgetFont()
	local newState, clicked = Widgets.Checkbox(win, label, state)
	restoreWidgetFont(prevFont)
	return newState, clicked
end

function TimMenu.Text(text)
	assertInBeginBlock("Text")
	assertValidString(text, "Text", "text")

	local win = TimMenu.GetCurrentWindow()
	if not win then
		error("[TimMenu] Text: No active window")
	end

	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetIndex = win._widgetCounter

	draw.SetFont(Globals.Style.Font)
	local w, h = draw.GetTextSize(text)
	local x, y = win:AddWidget(w, h)
	local absX, absY = win.X + x, win.Y + y

	local bounds = { x = absX, y = absY, w = w, h = h }
	Widgets.Tooltip.StoreWidgetBounds(win, widgetIndex, bounds)

	Common.QueueText(win, 1, absX, absY, text, Globals.Colors.Text)
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
	assertInBeginBlock("NextLine")

	local win = TimMenu.GetCurrentWindow()
	if win then
		if spacing ~= nil then
			assertValidNumber(spacing, "NextLine", "spacing")
		end
		win:NextLine(spacing)
	end
end

function TimMenu.SameLine(spacing)
	assertInBeginBlock("SameLine")

	local win = TimMenu.GetCurrentWindow()
	if win then
		if spacing ~= nil then
			assertValidNumber(spacing, "SameLine", "spacing")
		end
		win:SameLine(spacing)
	end
end

function TimMenu.Spacing(verticalSpacing)
	assertInBeginBlock("Spacing")

	local win = TimMenu.GetCurrentWindow()
	if win then
		if verticalSpacing ~= nil then
			assertValidNumber(verticalSpacing, "Spacing", "verticalSpacing")
		end
		win:Spacing(verticalSpacing)
	end
end

function TimMenu.Slider(label, value, min, max, step)
	assertInBeginBlock("Slider")
	assertValidString(label, "Slider", "label")
	assertValidNumber(value, "Slider", "value")
	assertValidNumber(min, "Slider", "min")
	assertValidNumber(max, "Slider", "max")
	assertValidNumber(step, "Slider", "step")

	if min >= max then
		error(string.format("[TimMenu] Slider: min (%s) must be less than max (%s)", min, max))
	end

	if step <= 0 then
		error(string.format("[TimMenu] Slider: step (%s) must be positive", step))
	end

	local win = TimMenu.GetCurrentWindow()
	if not win then
		error("[TimMenu] Slider: No active window")
	end

	local prevFont = applyNextWidgetFont()
	local newValue, changed = Widgets.Slider(win, label, value, min, max, step)
	restoreWidgetFont(prevFont)
	return newValue, changed
end

function TimMenu.Separator(label)
	assertInBeginBlock("Separator")

	local win = TimMenu.GetCurrentWindow()
	if not win then
		error("[TimMenu] Separator: No active window")
	end

	return SeparatorLayout.Draw(win, label)
end

function TimMenu.TextInput(label, text)
	assertInBeginBlock("TextInput")
	assertValidString(label, "TextInput", "label")
	assertValidString(text, "TextInput", "text")

	local win = TimMenu.GetCurrentWindow()
	if not win then
		error("[TimMenu] TextInput: No active window")
	end

	local prevFont = applyNextWidgetFont()
	local newText, changed = Widgets.TextInput(win, label, text)
	restoreWidgetFont(prevFont)
	return newText, changed
end

function TimMenu.Dropdown(label, selectedIndex, options)
	assertInBeginBlock("Dropdown")
	assertValidString(label, "Dropdown", "label")
	assertValidNumber(selectedIndex, "Dropdown", "selectedIndex")
	assertValidTable(options, "Dropdown", "options")

	if #options == 0 then
		error("[TimMenu] Dropdown: options table cannot be empty")
	end

	local win = TimMenu.GetCurrentWindow()
	if not win then
		error("[TimMenu] Dropdown: No active window")
	end

	local prevFont = applyNextWidgetFont()
	local newIdx, changed = Widgets.Dropdown(win, label, selectedIndex, options)
	restoreWidgetFont(prevFont)
	return newIdx, changed
end

function TimMenu.Combo(label, selectedTable, options)
	assertInBeginBlock("Combo")
	assertValidString(label, "Combo", "label")
	assertValidTable(selectedTable, "Combo", "selectedTable")
	assertValidTable(options, "Combo", "options")

	if #options == 0 then
		error("[TimMenu] Combo: options table cannot be empty")
	end

	local win = TimMenu.GetCurrentWindow()
	if not win then
		error("[TimMenu] Combo: No active window")
	end

	local prevFont = applyNextWidgetFont()
	local newTable, changed = Widgets.Combo(win, label, selectedTable, options)
	restoreWidgetFont(prevFont)
	return newTable, changed
end

function TimMenu.Selector(label, selectedIndex, options)
	assertInBeginBlock("Selector")
	assertValidString(label, "Selector", "label")
	assertValidNumber(selectedIndex, "Selector", "selectedIndex")
	assertValidTable(options, "Selector", "options")

	if #options == 0 then
		error("[TimMenu] Selector: options table cannot be empty")
	end

	local win = TimMenu.GetCurrentWindow()
	if not win then
		error("[TimMenu] Selector: No active window")
	end

	local prevFont = applyNextWidgetFont()
	local newIdx, changed = Widgets.Selector(win, label, selectedIndex, options)
	restoreWidgetFont(prevFont)
	return newIdx, changed
end

function TimMenu.TabControl(id, tabs, defaultSelection)
	assertInBeginBlock("TabControl")
	assertValidString(id, "TabControl", "id")
	assertValidTable(tabs, "TabControl", "tabs")

	if #tabs == 0 then
		error("[TimMenu] TabControl: tabs table cannot be empty")
	end

	local win = TimMenu.GetCurrentWindow()
	if not win then
		error("[TimMenu] TabControl: No active window")
	end

	local prevFont = applyNextWidgetFont()
	local newIndex, changed = Widgets.TabControl(win, id, tabs, defaultSelection)
	restoreWidgetFont(prevFont)
	if type(defaultSelection) == "string" then
		return tabs[newIndex], changed
	end
	return newIndex, changed
end

function TimMenu.BeginSector(label)
	assertInBeginBlock("BeginSector")
	assertValidString(label, "BeginSector", "label")

	local win = TimMenu.GetCurrentWindow()
	if not win then
		error("[TimMenu] BeginSector: No active window")
	end

	SectorWidget.Begin(win, label)
end

function TimMenu.EndSector()
	assertInBeginBlock("EndSector")

	local win = TimMenu.GetCurrentWindow()
	if not win then
		error("[TimMenu] EndSector: No active window")
	end

	if not win._sectorStack or #win._sectorStack == 0 then
		error("[TimMenu] EndSector: No active sector to end. Call BeginSector() first")
	end

	SectorWidget.End(win)
end

local reRegistered = false
local function _TimMenu_GlobalDraw()
	TimMenuGlobal.InputState.wasLeftMouseDownLastFrame = TimMenuGlobal.InputState.isLeftMouseDown
	TimMenuGlobal.InputState.isLeftMouseDown = input.IsButtonDown(MOUSE_LEFT)

	local mouseX, mouseY = table.unpack(input.GetMousePos())
	TimMenuGlobal.mouseX, TimMenuGlobal.mouseY = mouseX, mouseY
	local focusedWindowKey = nil

	local currentFrame = globals.FrameCount()
	local keysToRemove = {}
	for key, win in pairs(TimMenuGlobal.windows) do
		if not win._lastFrameTouched or (currentFrame - win._lastFrameTouched) > 60 then -- 60 frames = ~1 second
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

	for i = #TimMenuGlobal.order, 1, -1 do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win and win.visible and win:_HitTest(mouseX, mouseY) then
			focusedWindowKey = key
			break
		end
	end

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

			if isFocused and input.IsButtonPressed(MOUSE_LEFT) then
				if TimMenuGlobal.order[#TimMenuGlobal.order] ~= key then
					for j, v_key in ipairs(TimMenuGlobal.order) do
						if v_key == key then
							table.remove(TimMenuGlobal.order, j)
							break
						end
					end
					table.insert(TimMenuGlobal.order, key)
				end
			end
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

callbacks.Unregister("Draw", "TimMenu_GlobalDraw")
callbacks.Unregister("Draw", "zTimMenu_GlobalDraw")
callbacks.Register("Draw", "zTimMenu_GlobalDraw", _TimMenu_GlobalDraw)

function TimMenu.Textbox(label, text)
	return TimMenu.TextInput(label, text)
end

function TimMenu.Keybind(label, currentKey)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return currentKey, false
	end
	local prevFont = applyNextWidgetFont()
	local keycode, changed = Widgets.Keybind(win, label, currentKey)
	restoreWidgetFont(prevFont)
	return keycode, changed
end

function TimMenu.FontSet(name, size, weight)
	Globals.Style.FontName = name
	Globals.Style.FontSize = size
	Globals.Style.FontWeight = weight
	Globals.ReloadFonts()
end

function TimMenu.FontSetBold(name, size, weight)
	Globals.Style.FontBoldName = name
	Globals.Style.FontBoldSize = size
	Globals.Style.FontBoldWeight = weight
	Globals.ReloadFonts()
end

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

function TimMenu.ColorPicker(label, color)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return color, false
	end
	local newColor, changed = Widgets.ColorPicker(win, label, color)
	return newColor, changed
end

function TimMenu.Tooltip(text)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return
	end
	Widgets.Tooltip.AttachToLastWidget(win, text)
end

_G.TimMenu = TimMenu
return TimMenu
