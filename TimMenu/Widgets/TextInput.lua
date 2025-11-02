local WidgetBase = require("TimMenu.WidgetBase")
local Draw = require("TimMenu.Draw")
local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

-- Simplified key mapping - generate programmatically where possible
local KeyCodeToCharTable = {}

-- Generate letter mappings
for i = 0, 25 do
	local key = _G["KEY_" .. string.char(65 + i)]
	if key then
		KeyCodeToCharTable[key] = { string.char(97 + i), string.char(65 + i) }
	end
end

-- Generate number mappings
for i = 0, 9 do
	local key = _G["KEY_" .. i]
	if key then
		local shifted = string.char(41 + i) -- )!@#$%^&*(
		if i == 0 then shifted = ")" end
		KeyCodeToCharTable[key] = { tostring(i), shifted }
	end
end

-- Special characters
local specialChars = {
	[KEY_SPACE] = { " ", " " },
	[KEY_MINUS] = { "-", "_" },
	[KEY_EQUAL] = { "=", "+" },
	[KEY_LBRACKET] = { "[", "{" },
	[KEY_RBRACKET] = { "]", "}" },
	[KEY_BACKSLASH] = { "\\", "|" },
	[KEY_SEMICOLON] = { ";", ":" },
	[KEY_APOSTROPHE] = { "'", '"' },
	[KEY_COMMA] = { ",", "<" },
	[KEY_PERIOD] = { ".", ">" },
	[KEY_SLASH] = { "/", "?" },
	[KEY_BACKQUOTE] = { "`", "~" },
}

for key, chars in pairs(specialChars) do
	KeyCodeToCharTable[key] = chars
end

-- Numpad mappings (same for both shift states)
for i = 0, 9 do
	local key = _G["KEY_PAD_" .. i]
	if key then
		KeyCodeToCharTable[key] = { tostring(i), tostring(i) }
	end
end

local numpadSpecial = {
	[KEY_PAD_DECIMAL] = { ".", "." },
	[KEY_PAD_DIVIDE] = { "/", "/" },
	[KEY_PAD_MULTIPLY] = { "*", "*" },
	[KEY_PAD_MINUS] = { "-", "-" },
	[KEY_PAD_PLUS] = { "+", "+" },
}

for key, chars in pairs(numpadSpecial) do
	KeyCodeToCharTable[key] = chars
end

local function MapKeyCodeToChar(keyCode, isShiftDown)
	local entry = KeyCodeToCharTable[keyCode]
	if entry then
		return isShiftDown and entry[2] or entry[1]
	end
	return nil
end

-- Helper for key repeat logic
local function handleKeyRepeat(entry, keyCode, currentTime, action)
	local state = entry.keyStates[keyCode] or {}
	local KEY_REPEAT_INITIAL_DELAY = 0.4
	local KEY_REPEAT_INTERVAL = 0.05

	if input.IsButtonDown(keyCode) then
		if not state.firstDownTime then
			action()
			state.firstDownTime = currentTime
			state.lastRepeatTime = currentTime
		elseif state.firstDownTime and (currentTime - state.firstDownTime > KEY_REPEAT_INITIAL_DELAY)
			and (currentTime - state.lastRepeatTime > KEY_REPEAT_INTERVAL) then
			action()
			state.lastRepeatTime = currentTime
		end
	else
		state.firstDownTime = nil
		state.lastRepeatTime = nil
	end

	entry.keyStates[keyCode] = state
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

	-- Unified mouse interaction for activation/deactivation
	local widgetKey = win.id .. ":TextInput:" .. label .. ":" .. win._widgetCounter
	local hovered, pressed, clicked = Interaction.Process(win, widgetKey, bounds, false)
	local changed = false
	if clicked and not entry.active then
		entry.active = true
		-- reset states on activation
		for k in pairs(entry.debouncedKeys) do
			entry.debouncedKeys[k] = false
		end
		entry.keyStates = {}
	elseif input.IsButtonPressed(MOUSE_LEFT) and entry.active and not hovered then
		entry.active = false
		for k in pairs(entry.debouncedKeys) do
			entry.debouncedKeys[k] = false
		end
		entry.keyStates = {}
	end

	if entry.active then
		local lmbx_globals = _G.globals
		local currentTime = lmbx_globals and lmbx_globals.RealTime and lmbx_globals.RealTime() or 0
		local isShiftDown = input.IsButtonDown(KEY_LSHIFT) or input.IsButtonDown(KEY_RSHIFT)

		-- Handle character input keys with repeat
		for keyCode, _ in pairs(KeyCodeToCharTable) do
			handleKeyRepeat(entry, keyCode, currentTime, function()
				local char = MapKeyCodeToChar(keyCode, isShiftDown)
				if char then
					entry.text = entry.text .. char
				end
			end)
		end

		-- Handle Backspace with repeat
		handleKeyRepeat(entry, KEY_BACKSPACE, currentTime, function()
			if #entry.text > 0 then
				entry.text = string.sub(entry.text, 1, -2)
			end
		end)

		-- Handle single-action keys (Enter, Escape)
		local singleActionKeys = { KEY_ENTER, KEY_PAD_ENTER, KEY_ESCAPE }
		for _, keyCode in ipairs(singleActionKeys) do
			if input.IsButtonPressed(keyCode) then
				entry.active = false
				for k in pairs(entry.debouncedKeys) do
					entry.debouncedKeys[k] = false
				end
				entry.keyStates = {}
			end
		end
	else
		-- Reset key states when not active
		for k in pairs(entry.debouncedKeys) do
			entry.debouncedKeys[k] = false
		end
		entry.keyStates = {}
	end

	-- Draw the text input using queued primitives at appropriate layers
	local px, py = absX, absY
	-- Background color
	local bgColor = Globals.Colors.Item
	if entry.active then
		bgColor = Globals.Colors.ItemActive
	elseif hovered then
		bgColor = Globals.Colors.ItemHover
	end
	-- Determine text content and color (placeholder vs actual)
	local textContentForDisplay, textColor
	if entry.text == "" and not entry.active then
		textContentForDisplay = label
		textColor = { 180, 180, 180, 255 }
	else
		textContentForDisplay = entry.text
		textColor = Globals.Colors.Text
	end
	-- Truncate and append blinking cursor if needed
	local availableWidthForText = width - (pad * 2)
	if entry.active then
		local cursorW = draw.GetTextSize("|")
		local wideCharPadding = draw.GetTextSize("O")
		availableWidthForText = availableWidthForText - cursorW - wideCharPadding - pad
	end
	-- Build final drawable text
	local finalDrawableText = textContentForDisplay
	local textContentWidth = draw.GetTextSize(textContentForDisplay)
	if textContentWidth > availableWidthForText and availableWidthForText > 0 then
		local truncated, currW = "", 0
		for i = #textContentForDisplay, 1, -1 do
			local ch = textContentForDisplay:sub(i, i)
			local cw = draw.GetTextSize(ch)
			if currW + cw <= availableWidthForText then
				truncated = ch .. truncated
				currW = currW + cw
			else
				break
			end
		end
		finalDrawableText = "..." .. truncated
	end
	if entry.active then
		local t = (_G.globals and _G.globals.RealTime and _G.globals.RealTime() or 0)
		if math.floor(t * 2.5) % 2 == 0 then
			finalDrawableText = finalDrawableText .. "|"
		else
			finalDrawableText = finalDrawableText .. " "
		end
	end
	-- Queue drawing primitives
	Common.QueueRect(win, Globals.Layers.WidgetBackground, px, py, px + width, py + height, bgColor, nil)
	Common.QueueText(win, Globals.Layers.WidgetText, px + pad, py + (height - txtH) / 2, finalDrawableText, textColor)
	Common.QueueOutlinedRect(
		win,
		Globals.Layers.WidgetOutline,
		px,
		py,
		px + width,
		py + height,
		Globals.Colors.WidgetOutline
	)

	return entry.text
end

return TextInput
