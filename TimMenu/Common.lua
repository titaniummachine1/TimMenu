local Utils = require("TimMenu.Utils")
local Globals = require("TimMenu.Globals")

local Common = {}

--------------------------------------------------------------------------------------
-- Library Loading
--------------------------------------------------------------------------------------

local function downloadFile(url)
	local body = http.Get(url)
	if body and body ~= "" then
		return body
	else
		error("Failed to download file from " .. url)
	end
end

local latestReleaseURL = "https://github.com/lnx00/Lmaobox-Library/releases/latest/download/lnxLib.lua"

local function loadLNXlib()
	local libLoaded, Lib = pcall(require, "LNXlib")
	if not libLoaded or not Lib.GetVersion or Lib.GetVersion() < 1.0 then
		print("LNXlib not found or version is too old. Attempting to download the latest version...")

		local lnxLibContent = downloadFile(latestReleaseURL)
		local lnxLibFunction, loadError = load(lnxLibContent)
		if lnxLibFunction then
			lnxLibFunction()
			libLoaded, Lib = pcall(require, "LNXlib")
			if not libLoaded then
				error("Failed to load LNXlib after downloading: " .. loadError)
			end
		else
			error("Error loading lnxLib: " .. loadError)
		end
	end
	return Lib
end

local Lib = loadLNXlib()

-- Expose required functionality
Common.Lib = Lib
Common.Fonts = Lib.UI.Fonts
Common.KeyHelper = Lib.Utils.KeyHelper
Common.Input = Lib.Utils.Input
Common.Timer = Lib.Utils.Timer
Common.Log = Lib.Utils.Logger.new("TimMenu")
Common.Notify = Lib.UI.Notify
Common.Math = Lib.Utils.Math
Common.Conversion = Lib.Utils.Conversion

--------------------------------------------------------------------------------
-- Common Functions
--------------------------------------------------------------------------------

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
function Common.QueueText(window, layer, x, y, text, colorTbl)
	local relX = x - window.X
	local relY = y - window.Y
	window:QueueDrawAtLayer(layer, function()
		draw.SetFont(Globals.Style.Font)
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
	package.loaded["TimMenu"] = nil
end

callbacks.Unregister("Unload", "TimMenu_Unload")
callbacks.Register("Unload", "TimMenu_Unload", OnUnload)

-- Ensure all draw positions are integers
do
	local origFilled = draw.FilledRect
	draw.FilledRect = function(x1, y1, x2, y2)
		origFilled(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
	end

	local origOutlined = draw.OutlinedRect
	draw.OutlinedRect = function(x1, y1, x2, y2)
		origOutlined(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
	end

	local origLine = draw.Line
	if origLine then
		draw.Line = function(x1, y1, x2, y2)
			origLine(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
		end
	end

	local origText = draw.Text
	draw.Text = function(x, y, text)
		origText(math.floor(x), math.floor(y), text)
	end

	local origTextured = draw.TexturedRect
	if origTextured then
		draw.TexturedRect = function(id, x1, y1, x2, y2)
			origTextured(id, math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
		end
	end
end

return Common
