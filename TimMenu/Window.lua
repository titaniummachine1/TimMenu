local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local DrawManager = require("TimMenu.DrawManager")
local lmbx = globals -- alias for Lmaobox API

local Window = {}
Window.__index = Window

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
	local padding = Globals.Defaults.WINDOW_CONTENT_PADDING
	local x = self.cursorX
	local y = self.cursorY

	-- Calculate x position based on alignment
	if Globals.Style.Alignment == "center" then
		x = math.max(padding, math.floor((self.W - width) * 0.5))
	end

	-- Update window dimensions if needed
	self.W = math.max(self.W, x + width + padding)
	self.lineHeight = math.max(self.lineHeight, height)
	self.H = math.max(self.H, y + self.lineHeight)

	-- Update cursor position for the *next* widget on this line
	self.cursorX = self.cursorX + width + Globals.Defaults.ITEM_SPACING

	return x, y
end

--- Provide a simple way to "new line" to place subsequent widgets below
--- Resets horizontal position and advances vertically.
function Window:NextLine(spacing)
	spacing = spacing or Globals.Defaults.WINDOW_CONTENT_PADDING
	self.cursorY = self.cursorY + self.lineHeight + spacing
	self.cursorX = Globals.Defaults.WINDOW_CONTENT_PADDING -- reset to left padding
	local endOfLineY = self.cursorY -- Y position *before* resetting lineHeight
	self.lineHeight = 0
	-- Expand window if needed, considering the end of the previous line
	self.H = math.max(self.H, endOfLineY)
end

--- Advances the cursor horizontally to place the next widget on the same line.
function Window:SameLine(spacing)
	-- Default spacing is Globals.Defaults.ITEM_SPACING
	spacing = spacing or Globals.Defaults.ITEM_SPACING
	self.cursorX = self.cursorX + spacing -- Add specified spacing
	-- Note: We don't add widget width here, AddWidget already does that
	-- and advances cursorX *after* returning the position.
end

--- Adds vertical spacing without resetting the horizontal cursor position.
function Window:Spacing(verticalSpacing)
	-- Default spacing is half the content padding
	verticalSpacing = verticalSpacing or (Globals.Defaults.WINDOW_CONTENT_PADDING / 2)
	-- Use current line height + spacing to advance Y
	self.cursorY = self.cursorY + self.lineHeight + verticalSpacing
	self.lineHeight = 0 -- Reset line height for the *next* line that might start here
	-- Expand window if needed
	if self.cursorY > self.H then
		self.H = self.cursorY
	end
	-- Important: Do NOT reset cursorX here.
end

--- Reset the layout cursor for widgets (called on Begin)
function Window:resetCursor()
	local padding = Globals.Defaults.WINDOW_CONTENT_PADDING
	self.cursorX = padding
	self.cursorY = Globals.Defaults.TITLE_BAR_HEIGHT + padding
	self.lineHeight = 0
	-- Clear any widget blocking regions at start of frame
	self._widgetBlockedRegions = {}
	-- Clear header tabs flag so titles center if no header tabs
	self._hasHeaderTabs = false
end

return Window
