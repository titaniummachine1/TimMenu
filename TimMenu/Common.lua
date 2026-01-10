local Common = {}

--------------------------------------------------------------------------------------
-- Standalone Input Helper (Fixed to use Engine Enums)
--------------------------------------------------------------------------------------

local KeyNames = {
	[KEY_SEMICOLON] = "SEMICOLON",
	[KEY_APOSTROPHE] = "APOSTROPHE",
	[KEY_BACKQUOTE] = "BACKQUOTE",
	[KEY_COMMA] = "COMMA",
	[KEY_PERIOD] = "PERIOD",
	[KEY_SLASH] = "SLASH",
	[KEY_BACKSLASH] = "BACKSLASH",
	[KEY_MINUS] = "MINUS",
	[KEY_EQUAL] = "EQUAL",
	[KEY_ENTER] = "ENTER",
	[KEY_SPACE] = "SPACE",
	[KEY_BACKSPACE] = "BACKSPACE",
	[KEY_TAB] = "TAB",
	[KEY_CAPSLOCK] = "CAPSLOCK",
	[KEY_NUMLOCK] = "NUMLOCK",
	[KEY_ESCAPE] = "ESCAPE",
	[KEY_SCROLLLOCK] = "SCROLLLOCK",
	[KEY_INSERT] = "INSERT",
	[KEY_DELETE] = "DELETE",
	[KEY_HOME] = "HOME",
	[KEY_END] = "END",
	[KEY_PAGEUP] = "PAGEUP",
	[KEY_PAGEDOWN] = "PAGEDOWN",
	[KEY_BREAK] = "BREAK",
	[KEY_LSHIFT] = "LSHIFT",
	[KEY_RSHIFT] = "RSHIFT",
	[KEY_LALT] = "LALT",
	[KEY_RALT] = "RALT",
	[KEY_LCONTROL] = "LCONTROL",
	[KEY_RCONTROL] = "RCONTROL",
	[KEY_UP] = "UP",
	[KEY_LEFT] = "LEFT",
	[KEY_DOWN] = "DOWN",
	[KEY_RIGHT] = "RIGHT",
	[MOUSE_LEFT] = "LMB",
	[MOUSE_RIGHT] = "RMB",
	[MOUSE_MIDDLE] = "MMB",
	[MOUSE_4] = "MOUSE4",
	[MOUSE_5] = "MOUSE5",
}

-- Automatically fill numbers 0-9 and A-Z using the same logic as LNXlib
-- This maps the Engine Enums to strings correctly
for i = KEY_0, KEY_9 do
	KeyNames[i] = tostring(i - KEY_0)
end

for i = KEY_A, KEY_Z do
	KeyNames[i] = string.char(65 + (i - KEY_A))
end

for i = KEY_PAD_0, KEY_PAD_9 do
	KeyNames[i] = "KP_" .. tostring(i - KEY_PAD_0)
end

for i = KEY_F1, KEY_F12 do
	KeyNames[i] = "F" .. tostring(i - KEY_F1 + 1)
end

-- Simple input helper
Common.Input = {
	GetKeyName = function(keyCode)
		-- Return the mapped name, or the numeric ID if not found
		return KeyNames[keyCode] or ("KEY_" .. tostring(keyCode))
	end,

	-- Helper to get what is currently being pressed (useful for binding keys)
	GetPressedKey = function()
		for i = KEY_FIRST, KEY_LAST do
			if input.IsButtonDown(i) then
				return i
			end
		end
		return nil
	end,
}

--------------------------------------------------------------------------------
-- Common Functions
--------------------------------------------------------------------------------

local Utils = require("TimMenu.Utils")
local Globals = require("TimMenu.Globals")

function Common.Refresh()
	package.loaded["TimMenu"] = nil
end

---@param value number
---@return number
function Common.RoundNearest(value)
	return math.floor(value + 0.5)
end

---@param x number Top-left x coordinate of the area
---@param y number Top-left y coordinate of the area
---@param w number Width of the area
---@param h number Height of the area
---@return boolean true if mouse is in rect, false otherwise
function Common.IsMouseInRect(x, y, w, h)
	local mX, mY = table.unpack(input.GetMousePos())
	return (mX >= x) and (mX <= x + w) and (mY >= y) and (mY <= y + h)
end

--------------------------------------------------------------------------------
-- Draw Wrappers
--------------------------------------------------------------------------------

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function Common.DrawFilledRect(x1, y1, x2, y2)
	draw.FilledRect(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function Common.DrawOutlinedRect(x1, y1, x2, y2)
	draw.OutlinedRect(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function Common.DrawLine(x1, y1, x2, y2)
	if draw.Line then
		draw.Line(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
	end
end

---@param x number
---@param y number
---@param text string
function Common.DrawText(x, y, text)
	draw.Text(math.floor(x), math.floor(y), text)
end

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
-- Color & Draw Queue Helpers
--------------------------------------------------------------------------------

---@param colorTbl table {r,g,b,a}
function Common.SetColor(colorTbl)
	draw.Color(table.unpack(colorTbl))
end

---@param window table Window object
---@param layer number Draw layer
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param fillColor table optional, defaults to Globals.Colors.Item
---@param borderColor table|nil optional
function Common.QueueRect(window, layer, x1, y1, x2, y2, fillColor, borderColor)
	local relX = x1 - window.X
	local relY = y1 - window.Y
	local width = x2 - x1
	local height = y2 - y1
	window:QueueDrawAtLayer(layer, function()
		Common.SetColor(fillColor or Globals.Colors.Item)
		Common.DrawFilledRect(window.X + relX, window.Y + relY, window.X + relX + width, window.Y + relY + height)
		if borderColor then
			Common.SetColor(borderColor)
			Common.DrawOutlinedRect(window.X + relX, window.Y + relY, window.X + relX + width, window.Y + relY + height)
		end
	end)
end

---@param window table Window object
---@param layer number Draw layer
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param colorTbl table optional, defaults to Globals.Colors.Text
function Common.QueueLine(window, layer, x1, y1, x2, y2, colorTbl)
	local relX1, relY1 = x1 - window.X, y1 - window.Y
	local relX2, relY2 = x2 - window.X, y2 - window.Y
	window:QueueDrawAtLayer(layer, function()
		Common.SetColor(colorTbl or Globals.Colors.Text)
		Common.DrawLine(window.X + relX1, window.Y + relY1, window.X + relX2, window.Y + relY2)
	end)
end

---@param window table Window object
---@param layer number Draw layer for text
---@param x number
---@param y number
---@param text string
---@param colorTbl table optional, defaults to Globals.Colors.Text
function Common.QueueText(window, layer, x, y, text, colorTbl, fontId)
	local relX = x - window.X
	local relY = y - window.Y
	window:QueueDrawAtLayer(layer, function()
		draw.SetFont(fontId or Globals.Style.Font)
		Common.SetColor(colorTbl or Globals.Colors.Text)
		Common.DrawText(window.X + relX, window.Y + relY, text)
	end)
end

---@param window table Window object
---@param layer number Draw layer
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param colorTbl table optional, defaults to Globals.Colors.WindowBorder
function Common.QueueOutlinedRect(window, layer, x1, y1, x2, y2, colorTbl)
	local relX = x1 - window.X
	local relY = y1 - window.Y
	local width = x2 - x1
	local height = y2 - y1
	window:QueueDrawAtLayer(layer, function()
		Common.SetColor(colorTbl or Globals.Colors.WindowBorder)
		Common.DrawOutlinedRect(window.X + relX, window.Y + relY, window.X + relX + width, window.Y + relY + height)
	end)
end

---@param text string
---@param maxWidth number
---@return string
function Common.TruncateText(text, maxWidth)
	local fullW = select(1, draw.GetTextSize(text))
	if fullW <= maxWidth then
		return text
	end
	local truncated, currW = "", 0
	for i = #text, 1, -1 do
		local ch = text:sub(i, i)
		local cw = select(1, draw.GetTextSize(ch))
		if currW + cw <= maxWidth then
			truncated = ch .. truncated
			currW = currW + cw
		else
			break
		end
	end
	return "..." .. truncated
end

--------------------------------------------------------------------------------
-- Unload Callback
--------------------------------------------------------------------------------

local function OnUnload()
	input.SetMouseInputEnabled(false)
	Utils.PruneOrphanedWindows(TimMenuGlobal.windows, TimMenuGlobal.order)
	print("Unloading TimMenu")
	-- Unregister callbacks to prevent conflicts on reload
	callbacks.Unregister("Draw", "zTimMenu_GlobalDraw")
	package.loaded["TimMenu"] = nil
end

callbacks.Unregister("Unload", "TimMenu_Unload")
callbacks.Register("Unload", "TimMenu_Unload", OnUnload)

return Common
