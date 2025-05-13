local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

local function TextInput(win, label, text)
	assert(type(win) == "table", "TextInput: win must be a table")
	assert(type(label) == "string", "TextInput: label must be a string")
	assert(text == nil or type(text) == "string", "TextInput: text must be a string or nil")
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
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + pad
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y
	local bounds = { x = absX, y = absY, w = width, h = height }
	local hovered = Interaction.IsHovered(win, bounds)
	if hovered and input.IsButtonPressed(MOUSE_LEFT) then
		entry.active = true
	elseif entry.active and input.IsButtonPressed(MOUSE_LEFT) and not hovered then
		entry.active = false
	end
	local changed = false
	if entry.active then
		if input.IsButtonPressed(KEY_BACKSPACE) then
			entry.text = entry.text:sub(1, -2)
			changed = true
		end
		if input.IsButtonPressed(KEY_SPACE) then
			entry.text = entry.text .. " "
			changed = true
		end
		for code = 65, 90 do
			if input.IsButtonPressed(code) then
				entry.text = entry.text .. string.char(code)
				changed = true
			end
		end
		for code = 48, 57 do
			if input.IsButtonPressed(code) then
				entry.text = entry.text .. string.char(code)
				changed = true
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
		draw.Color(table.unpack(Globals.Colors.Text))
		Common.DrawText(px + pad, py + pad, entry.text)
	end)
	return entry.text, changed
end

return TextInput
