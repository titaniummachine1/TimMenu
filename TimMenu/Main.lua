local TimMenu = {}

-- Monkey-patch draw.* to ensure integer coordinates in all draw calls
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

-- Simplified global state
local function Setup()
	TimMenuGlobal = {
		windows = {}, -- Stores window objects, keyed by ID
		order = {}, -- Array of window IDs, defining Z-order (last = topmost)
	}
end

Setup()

-- Local variable to track the window currently being defined by Begin/End
local _currentWindow = nil

local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local Utils = require("TimMenu.Utils")
local Window = require("TimMenu.Window")
local Widgets = require("TimMenu.Widgets")

print("[TimMenu/Main.lua] Utils loaded:", type(Utils), Utils) -- See if Utils is a table
if Utils then
	print("[TimMenu/Main.lua] Utils.BeginFrame type:", type(Utils.BeginFrame)) -- See if BeginFrame is a function
end

local function getOrCreateWindow(key, title, visible)
	local win = TimMenuGlobal.windows[key]
	if not win then
		win = Window.new({ title = title, id = key, visible = visible })
		TimMenuGlobal.windows[key] = win
		table.insert(TimMenuGlobal.order, key) -- Add to end (top) by default
	else
		win.visible = visible -- Update visibility if it already exists
	end
	return win
end

function TimMenu.Begin(title, visible, id)
	assert(type(title) == "string", "TimMenu.Begin requires a string title")
	visible = (visible == nil) and true or visible
	if type(visible) == "string" then -- Handle shorthand TimMenu.Begin("Title", "id")
		id, visible = visible, true
	end
	local key = (id or title)

	local win = getOrCreateWindow(key, title, visible)
	win:update() -- This will now mark it as touched this frame

	_currentWindow = win -- Set for widget calls

	-- Reset window's internal layout cursor for this frame's widgets
	win:resetCursor()

	-- Clear per-frame widget counter for unique widget IDs
	win._widgetCounter = 0

	-- Clear any previously recorded sectors for this window each frame
	win._sectorStack = {}

	if not win.visible or (gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot()) then
		return false
	end

	return true, win
end

function TimMenu.End()
	-- This is now a no-op. Drawing and main logic are handled by _TimMenu_GlobalDraw.
	_currentWindow = nil -- Clear current window context
end

function TimMenu.GetCurrentWindow()
	return _currentWindow
end

--- Calls the Widgets.Button API on the current window.
function TimMenu.Button(label)
	local win = TimMenu.GetCurrentWindow()
	if win then
		return Widgets.Button(win, label)
	end
	return false
end

--- Draws a checkbox and returns its new state.
function TimMenu.Checkbox(label, state)
	local win = TimMenu.GetCurrentWindow()
	if win then
		return Widgets.Checkbox(win, label, state) -- State will be managed by the window now
	end
	return state
end

--- Draws static text in the current window.
--- @param text string The string to display.
function TimMenu.Text(text)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return
	end
	-- Measure text
	draw.SetFont(Globals.Style.Font)
	local w, h = draw.GetTextSize(text)
	-- Reserve space in layout
	local x, y = win:AddWidget(w, h)
	-- Queue drawing at base layer
	win:QueueDrawAtLayer(1, function()
		draw.Color(table.unpack(Globals.Colors.Text))
		draw.SetFont(Globals.Style.Font)
		draw.Text(win.X + x, win.Y + y, text)
	end)
end

--- Displays debug information.
function TimMenu.ShowDebug()
	local currentFrame = globals.FrameCount()
	draw.SetFont(Globals.Style.Font)
	draw.Color(255, 255, 255, 255)
	local headerX, headerY = 20, 20
	local lineSpacing = 20

	local windowCount = 0
	for _ in pairs(TimMenuGlobal.windows) do
		windowCount = windowCount + 1
	end
	draw.Text(headerX, headerY, "Active Windows (" .. windowCount .. "):")

	local yOffset = headerY + lineSpacing
	-- Iterate in Z-order for debug display
	for i = 1, #TimMenuGlobal.order do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win then
			local delay = currentFrame - (win._lastFrameTouched or currentFrame)
			local info = "ID: " .. key .. " | " .. win.title .. " (Z: " .. i .. ", Delay: " .. delay .. ")"
			if not win.visible then
				info = info .. " (Hidden)"
			end
			draw.Text(headerX, yOffset, info)
			yOffset = yOffset + lineSpacing
		end
	end
end

--- Moves the cursor to the next line in the current window, respecting sectors.
function TimMenu.NextLine(spacing)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return
	end
	-- default vertical gap between lines (double padding)
	local pad = Globals.Defaults.WINDOW_CONTENT_PADDING
	local actualSpacing = spacing or (pad * 3)
	-- advance to next line with increased gap
	win:NextLine(actualSpacing)
	-- apply sector indentation
	local depth = win._sectorStack and #win._sectorStack or 0
	win.cursorX = pad + (depth * pad)
end

--- Draws a slider and returns the new value and whether it changed.
function TimMenu.Slider(label, value, min, max, step)
	local win = TimMenu.GetCurrentWindow()
	if win then
		return Widgets.Slider(win, label, value, min, max, step)
	end
	return value, false
end

--- Draws a horizontal separator in the current window; optional centered label.
function TimMenu.Separator(label)
	local win = TimMenu.GetCurrentWindow()
	if win then
		return Widgets.Separator(win, label)
	end
end

--- Begins a visual sector grouping; widgets until EndSector are enclosed.
---@param label string optional title for the sector
function TimMenu.BeginSector(label)
	local win = TimMenu.GetCurrentWindow()
	if not win then
		return
	end
	-- initialize sector stack
	win._sectorStack = win._sectorStack or {}
	-- persistent storage for sector sizes
	win._sectorSizes = win._sectorSizes or {}
	-- capture current cursor as sector origin
	local startX, startY = win.cursorX, win.cursorY
	local pad = Globals.Defaults.WINDOW_CONTENT_PADDING
	-- restore previous max extents if available
	local stored = win._sectorSizes[label]
	local sector = {
		startX = startX,
		startY = startY,
		maxX = stored and (startX + stored.width - pad) or startX,
		maxY = stored and (startY + stored.height - pad) or startY,
		label = label,
		padding = pad,
		origAdd = win.AddWidget,
	}
	table.insert(win._sectorStack, sector)
	-- override AddWidget & NextLine to track extents within this sector
	sector.origNext = win.NextLine
	win.AddWidget = function(self, w, h)
		local x, y = sector.origAdd(self, w, h)
		-- track widest and tallest widget positions
		sector.maxX = math.max(sector.maxX, x + w)
		sector.maxY = math.max(sector.maxY, y + h)
		return x, y
	end
	win.NextLine = function(self, spacing)
		sector.origNext(self, spacing)
		-- track y position after line break
		sector.maxY = math.max(sector.maxY, self.cursorY)
	end
	-- indent cursor for sector padding
	win.cursorX = sector.startX + sector.padding
	win.cursorY = sector.startY + sector.padding
end

--- Ends the named sector, drawing its background and border and restoring layout.
---@param label string sector name to end
function TimMenu.EndSector(label)
	local win = TimMenu.GetCurrentWindow()
	if not win or not win._sectorStack or #win._sectorStack == 0 then
		return
	end
	-- pop last sector
	local sector = win._sectorStack[#win._sectorStack]
	if sector.label ~= label then
		error("Mismatched EndSector: expected '" .. tostring(sector.label) .. "', got '" .. tostring(label) .. "'")
	end
	table.remove(win._sectorStack)
	-- restore AddWidget and NextLine
	win.AddWidget = sector.origAdd
	win.NextLine = sector.origNext
	local pad = sector.padding
	-- compute sector dimensions (+padding)
	local width = (sector.maxX - sector.startX) + pad
	local height = (sector.maxY - sector.startY) + pad
	-- store persistent sector size to avoid shrinking below max content size
	win._sectorSizes = win._sectorSizes or {}
	local prev = win._sectorSizes[sector.label]
	if not prev or width > prev.width then
		win._sectorSizes[sector.label] = { width = width, height = height }
	end
	local absX = win.X + sector.startX
	local absY = win.Y + sector.startY
	-- draw background behind sector
	do
		local fnFill = function()
			draw.Color(table.unpack(Globals.Colors.FrameBorder))
			Common.DrawFilledRect(absX, absY, absX + width, absY + height)
		end
		table.insert(win.Layers[1], 1, { fn = fnFill, args = {} })
	end
	-- draw border and optional header label
	win:QueueDrawAtLayer(5, function()
		draw.Color(table.unpack(Globals.Colors.WindowBorder))
		if type(sector.label) == "string" then
			draw.SetFont(Globals.Style.Font)
			local tw, th = draw.GetTextSize(sector.label)
			local labelX = absX + (width - tw) / 2
			local lineY = absY
			-- left border segment
			Common.DrawLine(absX, lineY, labelX - pad, lineY)
			-- label text
			draw.Color(table.unpack(Globals.Colors.Text))
			Common.DrawText(labelX, lineY - math.floor(th / 2), sector.label)
			-- right border segment
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawLine(labelX + tw + pad, lineY, absX + width, lineY)
		else
			Common.DrawLine(absX, absY, absX + width, absY)
		end
		-- bottom border
		Common.DrawLine(absX, absY + height, absX + width, absY + height)
		-- left border
		Common.DrawLine(absX, absY, absX, absY + height)
		-- right border
		Common.DrawLine(absX + width, absY, absX + width, absY + height)
	end)
	-- move parent cursor to right of this sector (allow horizontal stacking)
	win.cursorX = sector.startX + width + pad
	win.cursorY = sector.startY
end

-- Named function for the global draw callback
local function _TimMenu_GlobalDraw()
	local mouseX, mouseY = table.unpack(input.GetMousePos())
	local focusedWindowKey = nil

	-- 1. Pruning Pass: Remove windows not updated this frame
	local currentFrame = globals.FrameCount()
	local keysToRemove = {}
	for key, win in pairs(TimMenuGlobal.windows) do
		if not win._lastFrameTouched or (currentFrame - win._lastFrameTouched) > 1 then
			table.insert(keysToRemove, key)
		end
	end
	for _, key in ipairs(keysToRemove) do
		TimMenuGlobal.windows[key] = nil
		for i = #TimMenuGlobal.order, 1, -1 do
			if TimMenuGlobal.order[i] == key then
				table.remove(TimMenuGlobal.order, i)
				break
			end
		end
	end

	-- 2. Determine Focused Window (topmost under mouse)
	-- Iterate from top of z-order (end of table) downwards
	for i = #TimMenuGlobal.order, 1, -1 do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win and win.visible and win:_HitTest(mouseX, mouseY) then
			focusedWindowKey = key
			break -- Found the topmost, stop searching
		end
	end

	-- 3. Interaction Logic Pass (iterate all windows, but only focused one interacts fully)
	for i = 1, #TimMenuGlobal.order do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win and win.visible then
			local isFocused = (key == focusedWindowKey)
			win:_UpdateLogic(
				mouseX,
				mouseY,
				isFocused,
				input.IsButtonPressed(MOUSE_LEFT),
				input.IsButtonDown(MOUSE_LEFT),
				input.IsButtonReleased(MOUSE_LEFT)
			)

			-- Click-to-front and start drag
			if isFocused and input.IsButtonPressed(MOUSE_LEFT) then
				-- Bring to front
				if TimMenuGlobal.order[#TimMenuGlobal.order] ~= key then -- if not already at front
					for j, v_key in ipairs(TimMenuGlobal.order) do
						if v_key == key then
							table.remove(TimMenuGlobal.order, j)
							break
						end
					end
					table.insert(TimMenuGlobal.order, key)
				end
				-- Start dragging if click was in title bar (logic inside _UpdateLogic)
			end
		end
	end

	-- 4. Draw Pass (iterate in new Z-order)
	for i = 1, #TimMenuGlobal.order do
		local key = TimMenuGlobal.order[i]
		local win = TimMenuGlobal.windows[key]
		if win and win.visible then
			win:_Draw()
		end
	end
end

-- Register the global draw callback
callbacks.Unregister("Draw", "TimMenu_GlobalDraw")
callbacks.Register("Draw", "TimMenu_GlobalDraw", _TimMenu_GlobalDraw)

--[[ Play sound when loaded -- consider if this is still desired with centralized model ]]
engine.PlaySound("hl1/fvox/activated.wav")

return TimMenu
