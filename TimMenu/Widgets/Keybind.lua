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

	-- Unified interaction processing for click to start/stop listening
	local widgetKey = key .. ":" .. win._widgetCounter
	local hovered, pressed, clicked = Interaction.Process(win, widgetKey, bounds, entry.listening)
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
		Common.SetColor(bg)
		Common.DrawFilledRect(px, py, px + width, py + height)
		-- Border
		Common.SetColor(Globals.Colors.WindowBorder)
		Common.DrawOutlinedRect(px, py, px + width, py + height)
		-- Text
		Common.SetColor(Globals.Colors.Text)
		draw.SetFont(Globals.Style.Font)
		Common.DrawText(px + pad, py + pad, fullLabel)
	end)

	return entry.keycode, entry.changed
end

return Keybind
