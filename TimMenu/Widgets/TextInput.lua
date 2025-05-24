local WidgetBase = require("TimMenu.WidgetBase")
local Draw = require("TimMenu.Draw")
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
