local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local DrawManager = require("TimMenu.DrawManager")
local lmbx = globals -- alias for Lmaobox API

local Window = {}
Window.__index = Window

-- Assertion utilities for window debugging
local function assertValidWindowDimensions(win, funcName)
	if win.W <= 0 or win.H <= 0 then
		error(string.format("[TimMenu] %s: Invalid window dimensions W=%d, H=%d", funcName or "unknown", win.W, win.H))
	end

	if win.W > 5000 or win.H > 5000 then
		error(
			string.format(
				"[TimMenu] %s: Window dimensions too large W=%d, H=%d (possible infinite expansion)",
				funcName or "unknown",
				win.W,
				win.H
			)
		)
	end
end

local function assertValidPosition(win, funcName)
	if win.X < -10000 or win.X > 10000 or win.Y < -10000 or win.Y > 10000 then
		error(string.format("[TimMenu] %s: Invalid window position X=%d, Y=%d", funcName or "unknown", win.X, win.Y))
	end
end

local function applyDefaults(params)
	-- Provide a fallback for each setting if not provided
	return {
		title = params.title or "Untitled",
		id = params.id or params.title,
		visible = (params.visible == nil) and true or params.visible,
		X = params.X or (Globals.Defaults.DEFAULT_X + math.random(0, 150)),
		Y = params.Y or (Globals.Defaults.DEFAULT_Y + math.random(0, 50)),
		W = params.W or Globals.Defaults.DEFAULT_W,
		H = params.H or Globals.Defaults.DEFAULT_H,
	}
end

--- __close metamethod: cleans up window state.
function Window:__close()
	self.lastFrame = nil
	self.IsDragging = false
	self.DragPos = { X = 0, Y = 0 }
end

function Window:update()
	-- Mark this window as touched this frame for pruning
	self._lastFrameTouched = lmbx.FrameCount()
end

function Window.new(params)
	-- Ensure parameters exist
	if type(params) == "string" then
		params = { title = params }
	end

	if not params then
		error("[TimMenu] Window.new: params cannot be nil")
	end

	if not params.title then
		error("[TimMenu] Window.new: title is required")
	end

	params = applyDefaults(params)

	-- Create our window object with simple composition
	local self = setmetatable({}, Window)
	self.title = params.title
	self.id = params.id
	self.visible = params.visible
	self.X = params.X
	self.Y = params.Y
	self.W = params.W
	self.H = params.H
	self._lastFrameTouched = lmbx.FrameCount() -- Initialize touch timestamp
	self.IsDragging = false
	self.DragPos = { X = 0, Y = 0 }

	-- Validate initial state
	assertValidWindowDimensions(self, "Window.new")
	assertValidPosition(self, "Window.new")

	-- Set __close metamethod so it auto-cleans when used as a to-be-closed variable.
	local mt = getmetatable(self)
	mt.__close = Window.__close

	self.cursorX = 0
	self.cursorY = 0
	self.lineHeight = 0
	-- Initialize per-widget blocking regions for popup widgets
	self._widgetBlockedRegions = {}
	return self
end

--- Queue a drawing function under a specified numeric layer
function Window:QueueDrawAtLayer(layer, drawFunc, ...)
	-- Only integer layer values are supported
	DrawManager.Enqueue(self.id, layer, drawFunc, ...)
end

--- Hit test: is a point inside this window (including title bar and bottom padding)?
function Window:_HitTest(x, y)
	-- Hit test entire window area (title, content, and bottom padding)
	local titleHeight = Globals.Defaults.TITLE_BAR_HEIGHT
	local bottomPad = Globals.Defaults.WINDOW_CONTENT_PADDING
	return x >= self.X and x <= self.X + self.W and y >= self.Y and y <= self.Y + titleHeight + self.H + bottomPad
end

--- Update window logic: dragging only; mark touched only in Begin()
function Window:_UpdateLogic(mx, my, isFocused, pressed, down, released)
	-- Use static title bar height for dragging region
	local titleHeight = Globals.Defaults.TITLE_BAR_HEIGHT

	-- Start dragging if focused and pressed in title bar
	if isFocused and pressed and my >= self.Y and my <= self.Y + titleHeight then
		self.IsDragging = true
		self.DragPos = { X = mx - self.X, Y = my - self.Y }
	end

	-- Continue dragging while mouse button held
	if self.IsDragging then
		if down then
			self.X = mx - self.DragPos.X
			self.Y = my - self.DragPos.Y
		elseif released then
			self.IsDragging = false
		end
	end
end

--- Draw the entire window: chrome and queued widget layers
function Window:_Draw()
	draw.SetFont(Globals.Style.Font)
	local txtWidth, txtHeight = draw.GetTextSize(self.title)
	-- Draw title bar at static height and center text vertically
	local titleHeight = Globals.Defaults.TITLE_BAR_HEIGHT
	local bottomPad = Globals.Defaults.WINDOW_CONTENT_PADDING

	-- Background
	Common.SetColor(Globals.Colors.Window)
	-- Extend background with bottom padding
	Common.DrawFilledRect(self.X, self.Y + titleHeight, self.X + self.W, self.Y + titleHeight + self.H + bottomPad)

	-- Title bar
	Common.SetColor(Globals.Colors.Title)
	Common.DrawFilledRect(self.X, self.Y, self.X + self.W, self.Y + titleHeight)

	-- Border
	if Globals.Style.EnableWindowBorder then
		Common.SetColor(Globals.Colors.WindowBorder)
		-- Outline around full window including title and bottom padding
		Common.DrawOutlinedRect(self.X, self.Y, self.X + self.W, self.Y + titleHeight + self.H + bottomPad)
	end

	-- Title text
	Common.SetColor(Globals.Colors.Text)
	local titleX
	if self._hasHeaderTabs then
		titleX = self.X + Globals.Defaults.WINDOW_CONTENT_PADDING
	else
		titleX = self.X + (self.W - txtWidth) / 2
	end
	Common.DrawText(titleX, self.Y + (titleHeight - txtHeight) / 2, self.title)

	-- (All widget draw calls are now collected centrally by DrawManager)
end

--- Calculates widget position and updates window size if needed
--- @param width number The widget width
--- @param height number The widget height
--- @return number, number The x, y coordinates for the widget
function Window:AddWidget(width, height)
	-- Validate parameters
	if type(width) ~= "number" or type(height) ~= "number" then
		error(
			string.format(
				"[TimMenu] AddWidget: width and height must be numbers, got %s, %s",
				type(width),
				type(height)
			)
		)
	end

	if width < 0 or height < 0 then
		error(string.format("[TimMenu] AddWidget: width and height must be non-negative, got %d, %d", width, height))
	end

	local padding = Globals.Defaults.WINDOW_CONTENT_PADDING
	local x = self.cursorX
	local y = self.cursorY

	-- Calculate x position based on alignment
	if Globals.Style.Alignment == "center" then
		x = math.max(padding, math.floor((self.W - width) * 0.5))
	end

	-- Validate current state before expansion
	assertValidWindowDimensions(self, "AddWidget")
	assertValidPosition(self, "AddWidget")

	-- Update window dimensions if needed
	self.W = math.max(self.W, x + width + padding)
	self.lineHeight = math.max(self.lineHeight, height)
	self.H = math.max(self.H, y + self.lineHeight)

	-- Check for potential infinite expansion
	assertValidWindowDimensions(self, "AddWidget")

	-- Update cursor position for the *next* widget on this line
	self.cursorX = self.cursorX + width + Globals.Defaults.ITEM_SPACING

	return x, y
end

--- Provide a simple way to "new line" to place subsequent widgets below
--- Resets horizontal position and advances vertically.
function Window:NextLine(spacing)
	spacing = spacing or Globals.Defaults.WINDOW_CONTENT_PADDING

	-- Validate spacing parameter
	if type(spacing) ~= "number" then
		error(string.format("[TimMenu] NextLine: spacing must be number, got %s", type(spacing)))
	end

	if spacing < 0 then
		error(string.format("[TimMenu] NextLine: spacing must be non-negative, got %d", spacing))
	end

	-- Validate current state
	assertValidWindowDimensions(self, "NextLine")

	self.cursorY = self.cursorY + self.lineHeight + spacing
	self.cursorX = Globals.Defaults.WINDOW_CONTENT_PADDING -- reset to left padding
	local endOfLineY = self.cursorY -- Y position *before* resetting lineHeight
	self.lineHeight = 0
	-- Expand window if needed, considering the end of the previous line
	self.H = math.max(self.H, endOfLineY)

	-- Check for potential infinite expansion
	assertValidWindowDimensions(self, "NextLine")
end

--- Advances the cursor horizontally to place the next widget on the same line.
function Window:SameLine(spacing)
	-- Default spacing is Globals.Defaults.ITEM_SPACING
	spacing = spacing or Globals.Defaults.ITEM_SPACING

	-- Validate spacing parameter
	if type(spacing) ~= "number" then
		error(string.format("[TimMenu] SameLine: spacing must be number, got %s", type(spacing)))
	end

	if spacing < 0 then
		error(string.format("[TimMenu] SameLine: spacing must be non-negative, got %d", spacing))
	end

	-- Validate current state
	assertValidWindowDimensions(self, "SameLine")

	self.cursorX = self.cursorX + spacing -- Add specified spacing
	-- Note: We don't add widget width here, AddWidget already does that
	-- and advances cursorX *after* returning the position.
end

--- Adds vertical spacing without resetting the horizontal cursor position.
function Window:Spacing(verticalSpacing)
	-- Default spacing is half the content padding
	verticalSpacing = verticalSpacing or (Globals.Defaults.WINDOW_CONTENT_PADDING / 2)

	-- Validate spacing parameter
	if type(verticalSpacing) ~= "number" then
		error(string.format("[TimMenu] Spacing: verticalSpacing must be number, got %s", type(verticalSpacing)))
	end

	if verticalSpacing < 0 then
		error(string.format("[TimMenu] Spacing: verticalSpacing must be non-negative, got %d", verticalSpacing))
	end

	-- Validate current state
	assertValidWindowDimensions(self, "Spacing")

	-- Use current line height + spacing to advance Y
	self.cursorY = self.cursorY + self.lineHeight + verticalSpacing
	self.lineHeight = 0 -- Reset line height for the *next* line that might start here
	-- Expand window if needed
	if self.cursorY > self.H then
		self.H = self.cursorY
	end
	-- Important: Do NOT reset cursorX here.

	-- Check for potential infinite expansion
	assertValidWindowDimensions(self, "Spacing")
end

--- Reset the layout cursor for widgets (called on Begin)
function Window:resetCursor()
	local padding = Globals.Defaults.WINDOW_CONTENT_PADDING

	-- Validate padding
	if type(padding) ~= "number" or padding < 0 then
		error(string.format("[TimMenu] resetCursor: Invalid padding value %s", tostring(padding)))
	end

	-- Reset cursor positions
	self.cursorX = padding
	self.cursorY = Globals.Defaults.TITLE_BAR_HEIGHT + padding
	self.lineHeight = 0

	-- Validate new cursor positions
	if self.cursorX < 0 or self.cursorY < 0 then
		error(string.format("[TimMenu] resetCursor: Invalid cursor position X=%d, Y=%d",
			self.cursorX, self.cursorY))
	end

	-- Clear any widget blocking regions at start of frame
	self._widgetBlockedRegions = {}
	-- Clear header tabs flag so titles center if no header tabs
	self._hasHeaderTabs = false
	-- Reset window size to defaults to allow shrinking
	self.W = Globals.Defaults.DEFAULT_W
	self.H = Globals.Defaults.DEFAULT_H
	-- Clear sector sizes to allow sectors to shrink each frame
	self._sectorSizes = {}

	-- Validate reset dimensions
	assertValidWindowDimensions(self, "resetCursor")
end

return Window
