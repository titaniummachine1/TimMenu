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
			end
		elseif entry.active then
			entry.active = false
			for k, _ in pairs(entry.debouncedKeys) do
				entry.debouncedKeys[k] = false
			end
		end
	end

	if entry.active then
		local isShiftDown = input.IsButtonDown(KEY_LSHIFT) or input.IsButtonDown(KEY_RSHIFT)

		-- Handle character keys from KeyCodeToCharTable
		for keyCode, _ in pairs(KeyCodeToCharTable) do
			if input.IsButtonDown(keyCode) then
				if not entry.debouncedKeys[keyCode] then
					local char = MapKeyCodeToChar(keyCode, isShiftDown)
					if char then
						entry.text = entry.text .. char
						changed = true
					end
					entry.debouncedKeys[keyCode] = true
				end
			else
				if entry.debouncedKeys[keyCode] then -- Key released
					entry.debouncedKeys[keyCode] = false
				end
			end
		end

		-- Handle special keys (Backspace, Enter, Escape) separately with similar debounce
		local specialActionKeys = { KEY_BACKSPACE, KEY_ENTER, KEY_PAD_ENTER, KEY_ESCAPE }
		for _, keyCode in ipairs(specialActionKeys) do
			if input.IsButtonDown(keyCode) then
				if not entry.debouncedKeys[keyCode] then
					if keyCode == KEY_BACKSPACE then
						if #entry.text > 0 then
							entry.text = string.sub(entry.text, 1, -2)
							changed = true
						end
					elseif keyCode == KEY_ENTER or keyCode == KEY_PAD_ENTER then
						entry.active = false
						for k, _ in pairs(entry.debouncedKeys) do
							entry.debouncedKeys[k] = false
						end
					elseif keyCode == KEY_ESCAPE then
						entry.active = false
						for k, _ in pairs(entry.debouncedKeys) do
							entry.debouncedKeys[k] = false
						end
					end
					entry.debouncedKeys[keyCode] = true
				end
			else
				if entry.debouncedKeys[keyCode] then -- Key released
					entry.debouncedKeys[keyCode] = false
				end
			end
		end
	else
		-- If not active, ensure all keys are marked as released for debounce state for next activation
		if entry.active == false and next(entry.debouncedKeys) ~= nil then
			for k, _ in pairs(entry.debouncedKeys) do
				entry.debouncedKeys[k] = false
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
