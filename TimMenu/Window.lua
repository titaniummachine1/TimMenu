local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local DrawManager = require("TimMenu.DrawManager")
local ShapeUtils = require("TimMenu.ShapeUtils")
local lmbx = globals -- alias for Lmaobox API

TimMenuSpawnGlobal = TimMenuSpawnGlobal or { nextIndex = 0 }
local sharedSpawnState = TimMenuSpawnGlobal

local function getWindowRectForSpawn(win, fallbackHeight)
	if type(win) ~= "table" then
		return nil
	end
	local x = win.X
	local y = win.Y
	local w = win.W
	local h = win.H
	if type(x) ~= "number" or type(y) ~= "number" or type(w) ~= "number" or type(h) ~= "number" then
		return nil
	end
	if h <= 0 then
		h = fallbackHeight
	end
	if h < Globals.Defaults.TITLE_BAR_HEIGHT then
		h = Globals.Defaults.TITLE_BAR_HEIGHT
	end
	return { x = x, y = y, w = w, h = h }
end

local function overlapArea(a, b)
	local left = math.max(a.x, b.x)
	local right = math.min(a.x + a.w, b.x + b.w)
	if right <= left then
		return 0
	end
	local top = math.max(a.y, b.y)
	local bottom = math.min(a.y + a.h, b.y + b.h)
	if bottom <= top then
		return 0
	end
	return (right - left) * (bottom - top)
end

local function getCandidateObscureScore(candidateRect, fallbackHeight)
	local totalOverlap = 0
	if type(TimMenuGlobal) ~= "table" or type(TimMenuGlobal.windows) ~= "table" then
		return totalOverlap
	end

	for _, win in pairs(TimMenuGlobal.windows) do
		local winRect = getWindowRectForSpawn(win, fallbackHeight)
		if winRect then
			totalOverlap = totalOverlap + overlapArea(candidateRect, winRect)
		end
	end

	return totalOverlap
end

local function randomInRange(minValue, maxValue)
	if maxValue <= minValue then
		return minValue
	end
	return math.random(minValue, maxValue)
end

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function topLeftDistanceScore(x, y)
	return x + y
end

local function isBetterCandidate(testOverlap, testDistance, bestOverlap, bestDistance)
	if testOverlap < bestOverlap then
		return true
	end
	if testOverlap > bestOverlap then
		return false
	end
	return testDistance < bestDistance
end

local function getDefaultSpawnPosition(windowWidth, windowHeight)
	local baseX = Globals.Defaults.DEFAULT_X
	local baseY = Globals.Defaults.DEFAULT_Y
	local padX = Globals.Defaults.WINDOW_CONTENT_PADDING
	local padY = Globals.Defaults.WINDOW_CONTENT_PADDING
	local estimatedHeight = windowHeight
	if type(estimatedHeight) ~= "number" or estimatedHeight <= 0 then
		estimatedHeight = Globals.Defaults.TITLE_BAR_HEIGHT + padY * 10
	end
	if estimatedHeight < Globals.Defaults.TITLE_BAR_HEIGHT then
		estimatedHeight = Globals.Defaults.TITLE_BAR_HEIGHT
	end

	sharedSpawnState.nextIndex = (sharedSpawnState.nextIndex or 0) + 1
	if sharedSpawnState.nextIndex > 10000 then
		sharedSpawnState.nextIndex = 1
	end

	local minX = padX
	local minY = padY
	local maxX = baseX + 300
	local maxY = baseY + 200
	local hasScreenBounds = false

	local okScreenSize, screenW, screenH = pcall(draw.GetScreenSize)
	if okScreenSize and type(screenW) == "number" and type(screenH) == "number" and screenW > 0 and screenH > 0 then
		hasScreenBounds = true
		minX = 0
		minY = 0
		maxX = math.floor(screenW - windowWidth)
		maxY = math.floor(screenH - estimatedHeight)

		if maxX < minX then
			maxX = minX
		end
		if maxY < minY then
			maxY = minY
		end
	else
		maxX = math.max(minX, baseX + 300)
		maxY = math.max(minY, baseY + 200)
	end

	local bestX = randomInRange(minX, maxX)
	local bestY = randomInRange(minY, maxY)
	local bestRect = { x = bestX, y = bestY, w = windowWidth, h = estimatedHeight }
	local bestScore = getCandidateObscureScore(bestRect, estimatedHeight)
	local bestDistance = topLeftDistanceScore(bestX, bestY)

	for _ = 2, 10 do
		local testX = randomInRange(minX, maxX)
		local testY = randomInRange(minY, maxY)
		local testRect = { x = testX, y = testY, w = windowWidth, h = estimatedHeight }
		local testScore = getCandidateObscureScore(testRect, estimatedHeight)
		local testDistance = topLeftDistanceScore(testX, testY)
		if isBetterCandidate(testScore, testDistance, bestScore, bestDistance) then
			bestScore = testScore
			bestDistance = testDistance
			bestX = testX
			bestY = testY
		end
	end

	if hasScreenBounds then
		bestX = clamp(bestX, minX, maxX)
		bestY = clamp(bestY, minY, maxY)
	end

	return bestX, bestY
end

local Window = {}
Window.__index = Window

local function applyDefaults(params)
	local defaultW = params.W or Globals.Defaults.DEFAULT_W
	local defaultH = params.H or Globals.Defaults.DEFAULT_H
	local defaultX, defaultY = getDefaultSpawnPosition(defaultW, defaultH)
	-- Provide a fallback for each setting if not provided
	return {
		title = params.title or "Untitled",
		id = params.id or params.title,
		visible = (params.visible == nil) and true or params.visible,
		X = params.X or defaultX,
		Y = params.Y or defaultY,
		W = defaultW,
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
	-- Initialize click shapes for precise hit testing
	self._clickShapes = {}
	-- Flag to prevent focus changes during popup interactions
	self._preventFocusChange = false
	self._requestedNextLineSpacing = nil
	return self
end

--- Queue a drawing function under a specified numeric layer
function Window:QueueDrawAtLayer(layer, drawFunc, ...)
	-- Only integer layer values are supported
	DrawManager.Enqueue(self.id, layer, drawFunc, ...)
end

--- Hit test: is a point inside this window (including title bar, content area, and popups)?
function Window:_HitTest(x, y)
	-- Check main window bounds (title bar + content area)
	local titleHeight = Globals.Defaults.TITLE_BAR_HEIGHT
	local mainBounds = x >= self.X and x <= self.X + self.W and y >= self.Y and y <= self.Y + self.H

	-- If main bounds pass, return true
	if mainBounds then
		return true
	end

	-- Check if point is in any popup regions (extended volume)
	if self._widgetBlockedRegions then
		for _, region in ipairs(self._widgetBlockedRegions) do
			if x >= region.x and x <= region.x + region.w and y >= region.y and y <= region.y + region.h then
				return true
			end
		end
	end

	return false
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

	-- Background
	Common.SetColor(Globals.Colors.Window)
	-- Background covers title + content area (no extra padding)
	Common.DrawFilledRect(self.X, self.Y + titleHeight, self.X + self.W, self.Y + self.H)

	-- Title bar
	Common.SetColor(Globals.Colors.Title)
	Common.DrawFilledRect(self.X, self.Y, self.X + self.W, self.Y + titleHeight)

	-- Border
	if Globals.Style.EnableWindowBorder then
		Common.SetColor(Globals.Colors.WindowBorder)
		-- Outline around full window including title and content area
		Common.DrawOutlinedRect(self.X, self.Y, self.X + self.W, self.Y + self.H)
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
	self.H = math.max(self.H, y + self.lineHeight + padding)

	-- Update cursor position for the *next* widget on this line
	local horizontalSpacing = Globals.Style.ItemSpacingX or Globals.Defaults.ITEM_SPACING
	self.cursorX = self.cursorX + width + horizontalSpacing

	return x, y
end

--- Register a click shape for precise hit testing
---@param id string Unique identifier for this shape
---@param shape table Shape definition (type, bounds, etc.)
---@param focusWeight number Focus priority (0=no focus change, 1=normal, 2=high)
---@param metadata table Optional additional data
function Window:AddClickShape(id, shape, focusWeight, metadata)
	focusWeight = focusWeight or 1
	metadata = metadata or {}

	self._clickShapes[id] = {
		shape = shape,
		focusWeight = focusWeight,
		metadata = metadata,
	}
end

--- Remove a click shape by ID
---@param id string Shape identifier to remove
function Window:RemoveClickShape(id)
	self._clickShapes[id] = nil
end

--- Get the click shape at a specific point
---@param x number X coordinate
---@param y number Y coordinate
---@return string|nil shapeId, table|nil shapeData
function Window:GetClickShapeAt(x, y)
	for id, shapeData in pairs(self._clickShapes) do
		if ShapeUtils.PointInShape(x, y, shapeData.shape) then
			return id, shapeData
		end
	end
	return nil, nil
end

--- Check if clicking at this point should change focus
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean
function Window:ShouldChangeFocus(x, y)
	-- If flag is set, prevent focus changes (used during popup interactions)
	if self._preventFocusChange then
		return false
	end

	-- Check if point is in any popup region
	if self._widgetBlockedRegions then
		for _, region in ipairs(self._widgetBlockedRegions) do
			if x >= region.x and x <= region.x + region.w and y >= region.y and y <= region.y + region.h then
				return false -- Don't change focus if clicking popup area
			end
		end
	end

	return true -- Allow focus change for regular window areas
end

--- Get the focus weight of a click shape at a point
---@param x number X coordinate
---@param y number Y coordinate
---@return number
function Window:GetFocusWeight(x, y)
	local _, shapeData = self:GetClickShapeAt(x, y)
	return shapeData and shapeData.focusWeight or 0
end

--- Provide a simple way to "new line" to place subsequent widgets below
--- Resets horizontal position and advances vertically.
function Window:NextLine(spacing)
	local baseSpacing = Globals.Style.ItemSpacingY or Globals.Defaults.WINDOW_CONTENT_PADDING
	spacing = spacing or baseSpacing
	if self._requestedNextLineSpacing then
		spacing = math.max(spacing, self._requestedNextLineSpacing)
		self._requestedNextLineSpacing = nil
	end
	self.cursorY = self.cursorY + self.lineHeight + spacing
	self.cursorX = Globals.Defaults.WINDOW_CONTENT_PADDING -- reset to left padding
	local endOfLineY = self.cursorY -- Y position *before* resetting lineHeight
	self.lineHeight = 0
	-- Expand window if needed, considering the end of the previous line
	self.H = math.max(self.H, endOfLineY)
end

--- Advances the cursor horizontally to place the next widget on the same line.
function Window:SameLine(spacing)
	local defaultSpacing = Globals.Style.ItemSpacingX or Globals.Defaults.ITEM_SPACING
	spacing = spacing or defaultSpacing
	self.cursorX = self.cursorX + spacing -- Add specified spacing
	-- Note: We don't add widget width here, AddWidget already does that
	-- and advances cursorX *after* returning the position.
end

--- Adds vertical spacing without resetting the horizontal cursor position.
function Window:Spacing(verticalSpacing)
	local baseSpacing = Globals.Style.ItemSpacingY or Globals.Defaults.WINDOW_CONTENT_PADDING
	verticalSpacing = verticalSpacing or math.floor(baseSpacing * 0.5)
	-- Use current line height + spacing to advance Y
	self.cursorY = self.cursorY + self.lineHeight + verticalSpacing
	self.lineHeight = 0 -- Reset line height for the *next* line that might start here
	-- Expand window if needed
	if self.cursorY > self.H then
		self.H = self.cursorY
	end
	-- Important: Do NOT reset cursorX here.
end

--- Allows a widget to request a minimum spacing before the next line starts.
function Window:RequestNextLineSpacing(minSpacing)
	if type(minSpacing) ~= "number" then
		return
	end
	if minSpacing <= 0 then
		return
	end
	if not self._requestedNextLineSpacing or minSpacing > self._requestedNextLineSpacing then
		self._requestedNextLineSpacing = minSpacing
	end
end

--- Reset the layout cursor for widgets (called on Begin)
function Window:resetCursor()
	local padding = Globals.Defaults.WINDOW_CONTENT_PADDING
	self.cursorX = padding
	self.cursorY = Globals.Defaults.TITLE_BAR_HEIGHT + padding
	self.lineHeight = 0
	self._requestedNextLineSpacing = nil
	-- Clear any widget blocking regions at start of frame
	self._widgetBlockedRegions = {}
	-- Clear click shapes at start of frame (they're re-registered each frame)
	self._clickShapes = {}
	-- Clear header tabs flag so titles center if no header tabs
	self._hasHeaderTabs = false
	-- Reset window size to defaults to allow shrinking
	self.W = Globals.Defaults.DEFAULT_W
	self.H = Globals.Defaults.DEFAULT_H
	-- Clear sector sizes to allow sectors to shrink each frame
	self._sectorSizes = {}
end

return Window
