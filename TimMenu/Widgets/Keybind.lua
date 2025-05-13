local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

-- Mapping from Lmaobox key constants to human-readable names
local keyNames = {
	[KEY_0] = "0",
	[KEY_1] = "1",
	[KEY_2] = "2",
	[KEY_3] = "3",
	[KEY_4] = "4",
	[KEY_5] = "5",
	[KEY_6] = "6",
	[KEY_7] = "7",
	[KEY_8] = "8",
	[KEY_9] = "9",
	[KEY_A] = "A",
	[KEY_B] = "B",
	[KEY_C] = "C",
	[KEY_D] = "D",
	[KEY_E] = "E",
	[KEY_F] = "F",
	[KEY_G] = "G",
	[KEY_H] = "H",
	[KEY_I] = "I",
	[KEY_J] = "J",
	[KEY_K] = "K",
	[KEY_L] = "L",
	[KEY_M] = "M",
	[KEY_N] = "N",
	[KEY_O] = "O",
	[KEY_P] = "P",
	[KEY_Q] = "Q",
	[KEY_R] = "R",
	[KEY_S] = "S",
	[KEY_T] = "T",
	[KEY_U] = "U",
	[KEY_V] = "V",
	[KEY_W] = "W",
	[KEY_X] = "X",
	[KEY_Y] = "Y",
	[KEY_Z] = "Z",
	[KEY_SPACE] = "SPACE",
	[KEY_ENTER] = "ENTER",
	[KEY_BACKSPACE] = "BACKSPACE",
}

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
		entry = { keycode = currentKey or 0, listening = false, changed = false }
		win._keybinds[key] = entry
	else
		entry.changed = false
	end

	-- Determine displayed label
	local display
	if entry.listening then
		display = "<press key>"
	else
		-- Use mapping table or fall back to code
		display = keyNames[entry.keycode] or (entry.keycode > 0 and tostring(entry.keycode) or "<none>")
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
	if hovered and Interaction.IsPressed(key) then
		entry.listening = true
	end
	-- Capture key when listening
	if entry.listening then
		-- Wait for mouse release to avoid capturing the click as a key
		if not input.IsButtonDown(MOUSE_LEFT) then
			for code = 1, 255 do
				-- Skip mouse button code
				if code ~= MOUSE_LEFT and input.IsButtonPressed(code) then
					entry.keycode = code
					entry.changed = true
					entry.listening = false
					break
				end
			end
		end
	end
	if not input.IsButtonDown(MOUSE_LEFT) then
		Interaction.Release(key)
	end

	-- Draw
	win:QueueDrawAtLayer(2, function()
		local bg = Globals.Colors.Item
		if entry.listening then
			bg = Globals.Colors.ItemActive
		elseif hovered then
			bg = Globals.Colors.ItemHover
		end
		draw.Color(table.unpack(bg))
		Common.DrawFilledRect(absX, absY, absX + width, absY + height)
		-- Border
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		Common.DrawOutlinedRect(absX, absY, absX + width, absY + height)
		-- Text
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		Common.DrawText(absX + pad, absY + pad, fullLabel)
	end)

	return entry.keycode, entry.changed
end

return Keybind
