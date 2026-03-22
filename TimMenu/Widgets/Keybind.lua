local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")

-- Modes: 0: Always On, 1: Hold, 2: Toggle
local MODES = Globals.KeybindModes

---@class KeybindState
---@field key number
---@field mode number

-- Draws a keybinding widget; returns new key state table and whether it changed.
local function Keybind(win, label, kbState)
	assert(type(win) == "table", "Keybind: win must be a table")
	assert(type(label) == "string", "Keybind: label must be a string")

	-- Normalize legacy number to table
	if type(kbState) == "number" then
		kbState = { key = kbState, mode = 1 } -- Default to Hold
	end
	kbState = kbState or { key = 0, mode = 0 } -- Default to Always On

	-- Persistent internal state for listening
	win._keybinds = win._keybinds or {}
	local stateKey = tostring(win.id) .. ":keybind_state:" .. label
	local entry = win._keybinds[stateKey]
	if not entry then
		entry = { listening = false, waitingRelease = false }
		win._keybinds[stateKey] = entry
	end

	-- Interaction bounds
	draw.SetFont(Globals.Style.Font)
	local pad = Globals.Style.ItemPadding
	
	local keyName = "NONE"
	if kbState.key > 0 then
		keyName = Common.Input.GetKeyName(kbState.key)
		if keyName == "UNKNOWN" then keyName = tostring(kbState.key) end
	end
	
	local modeName = MODES[kbState.mode] or "Unknown"
	local displayText = string.format("[%s] %s", modeName, entry.listening and "<press key>" or keyName)
	local labelFull = label .. ": " .. displayText
	
	local txtW, txtH = draw.GetTextSize(labelFull)
	local width = txtW + pad * 2
	local height = txtH + pad * 2

	-- Layout
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + pad
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y
	local bounds = { x = absX, y = absY, w = width, h = height }

	-- Interaction
	local widgetId = stateKey .. ":" .. (win._widgetCounter or 0)
	local hovered, pressed, clicked = Interaction.Process(win, widgetId, bounds, entry.listening)
	
	local changed = false
	
	-- Left Click: Cycle modes (when not listening)
	if clicked and not entry.listening then
		kbState.mode = (kbState.mode + 1) % 3
		changed = true
	end
	
	-- Right Click: Start listening (in process, we can check for secondary mouse)
	if hovered and input.IsButtonPressed(MOUSE_RIGHT) and not entry.listening then
		entry.listening = true
		entry.waitingRelease = true
	end

	-- Capture Logic
	if entry.listening then
		if entry.waitingRelease then
			if not input.IsButtonDown(MOUSE_LEFT) and not input.IsButtonDown(MOUSE_RIGHT) then
				entry.waitingRelease = false
			end
		else
			-- Scan for ANY key/mouse button
			-- Mouse buttons in Lmaobox are usually in a specific range or constants
			for code = 1, 255 do
				if input.IsButtonPressed(code) then
					-- ESC to cancel/clear
					if code == KEY_ESCAPE then
						kbState.key = 0
						entry.listening = false
						changed = true
						break
					end
					
					kbState.key = code
					entry.listening = false
					changed = true
					break
				end
			end
		end
	end

	-- Draw
	win:QueueDrawAtLayer(Globals.Layers.WidgetBackground, function()
		local px, py = win.X + x, win.Y + y
		local bg = Globals.Colors.Item
		if entry.listening then
			bg = Globals.Colors.ItemActive
		elseif hovered then
			bg = Globals.Colors.ItemHover
		end
		
		Common.SetColor(bg)
		Common.DrawFilledRect(px, py, px + width, py + height)
		
		Common.SetColor(Globals.Colors.WindowBorder)
		Common.DrawOutlinedRect(px, py, px + width, py + height)
		
		Common.SetColor(Globals.Colors.Text)
		draw.SetFont(Globals.Style.Font)
		Common.DrawText(px + pad, py + pad, labelFull)
	end)

	return kbState, changed
end

return Keybind
