local Common = {}

--------------------------------------------------------------------------------------
-- Standalone Input Helper (Credit: LNXlib for inspiration)
--------------------------------------------------------------------------------------

-- Key name mapping for common keys (using actual numeric codes)
local KeyNames = {
	-- Mouse buttons
	[1] = "MOUSE_LEFT",
	[2] = "MOUSE_RIGHT",
	[3] = "MOUSE_MIDDLE",
	[4] = "MOUSE_4",
	[5] = "MOUSE_5",

	-- Letters (A-Z = 65-90)
	[65] = "A",
	[66] = "B",
	[67] = "C",
	[68] = "D",
	[69] = "E",
	[70] = "F",
	[71] = "G",
	[72] = "H",
	[73] = "I",
	[74] = "J",
	[75] = "K",
	[76] = "L",
	[77] = "M",
	[78] = "N",
	[79] = "O",
	[80] = "P",
	[81] = "Q",
	[82] = "R",
	[83] = "S",
	[84] = "T",
	[85] = "U",
	[86] = "V",
	[87] = "W",
	[88] = "X",
	[89] = "Y",
	[90] = "Z",

	-- Numbers (0-9 = 48-57)
	[48] = "0",
	[49] = "1",
	[50] = "2",
	[51] = "3",
	[52] = "4",
	[53] = "5",
	[54] = "6",
	[55] = "7",
	[56] = "8",
	[57] = "9",

	-- Numpad (256-271)
	[256] = "NUMPAD_0",
	[257] = "NUMPAD_1",
	[258] = "NUMPAD_2",
	[259] = "NUMPAD_3",
	[260] = "NUMPAD_4",
	[261] = "NUMPAD_5",
	[262] = "NUMPAD_6",
	[263] = "NUMPAD_7",
	[264] = "NUMPAD_8",
	[265] = "NUMPAD_9",
	[266] = "NUMPAD_MULTIPLY",
	[267] = "NUMPAD_ADD",
	[268] = "NUMPAD_ENTER",
	[269] = "NUMPAD_SUBTRACT",
	[270] = "NUMPAD_DECIMAL",
	[271] = "NUMPAD_DIVIDE",

	-- Function keys (280-291)
	[280] = "F1",
	[281] = "F2",
	[282] = "F3",
	[283] = "F4",
	[284] = "F5",
	[285] = "F6",
	[286] = "F7",
	[287] = "F8",
	[288] = "F9",
	[289] = "F10",
	[290] = "F11",
	[291] = "F12",

	-- Special keys (actual numeric codes)
	[32] = "SPACE",
	[13] = "ENTER",
	[27] = "ESCAPE",
	[8] = "BACKSPACE",
	[9] = "TAB",
	[20] = "CAPSLOCK",
	[16] = "SHIFT",
	[17] = "CTRL",
	[18] = "ALT",
	[59] = "SEMICOLON",
	[39] = "APOSTROPHE",
	[96] = "BACKQUOTE",
	[44] = "COMMA",
	[46] = "PERIOD",
	[47] = "SLASH",
	[92] = "BACKSLASH",
	[45] = "MINUS",
	[61] = "EQUAL",
	[219] = "LBRACKET",
	[221] = "RBRACKET",
	[186] = "SEMICOLON",
	[222] = "APOSTROPHE",
	[192] = "BACKQUOTE",

	-- Arrow keys
	[200] = "UP",
	[208] = "DOWN",
	[203] = "LEFT",
	[205] = "RIGHT",

	-- Page/Home/End keys
	[201] = "PAGE_UP",
	[207] = "PAGE_DOWN",
	[199] = "HOME",
	[211] = "END",
	[210] = "INSERT",
	[212] = "DELETE",
}

-- Simple input helper
Common.Input = {
	GetKeyName = function(keyCode)
		return KeyNames[keyCode] or ("UNKNOWN_" .. tostring(keyCode))
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
