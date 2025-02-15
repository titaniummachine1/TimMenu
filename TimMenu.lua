local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
-- Main module for the TimMenu library
local TimMenu = {}

package.loaded["TimMenu"] = nil

local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local Utils = require("TimMenu.Utils")
local Window = require("TimMenu.Window")
local Widgets = require("TimMenu.Widgets") -- new require

local function Setup()
    if not TimMenuGlobal then
        -- Initialize TimMenu
        TimMenuGlobal = {}
        TimMenuGlobal.windows = {}
        TimMenuGlobal.order = {}
        TimMenuGlobal.ActiveWindow = nil -- Add ActiveWindow to track which window is being hovered over
        TimMenuGlobal.lastWindowKey = nil
    end
end

-- Modified Refresh to preserve TimMenuGlobal
function TimMenu.Refresh()
    -- Don't clear TimMenu if it's already initialized
    TimMenuGlobal = nil
    package.loaded["TimMenu"] = nil
end

Setup()

--- Begins a new or updates an existing window.
--- @param title string Window title.
--- @param visible? boolean Whether the window is visible (default: true).
--- @param id? string|number Unique identifier (default: title).
--- @return table? window table.(if nil means it wasnt visible or taking screenshot)
function TimMenu.Begin(title, visible, id)
    if not visible or engine.IsTakingScreenshot() then
        return nil
    end

    --input parsing--
    assert(type(title) == "string", "TimMenu.Begin requires a string title")
    visible = (visible == nil) and true or visible
    if type(visible) == "string" then id, visible = visible, true end
    local key = (id or title)
    --input parsing--

    local win = TimMenuGlobal.windows[key]

    -- Create new window if needed
    if not win then
        win = Window.new({
            title = title,
            id = key,
            visible = visible,
            X = Globals.Defaults.DEFAULT_X + math.random(0, 150),
            Y = Globals.Defaults.DEFAULT_Y + math.random(0, 50),
            W = Globals.Defaults.DEFAULT_W,
            H = Globals.Defaults.DEFAULT_H,
        })
        TimMenuGlobal.windows[key] = win
        table.insert(TimMenuGlobal.order, key)
    else
        win.visible = visible
    end

    --keep this window alive from pruning--
    local currentFrame = globals.FrameCount()
    win.lastFrame = currentFrame

    -- Handle window interaction
    local mX, mY = table.unpack(input.GetMousePos())
    local titleHeight = Globals.Defaults.TITLE_BAR_HEIGHT
    local isTopWindow = Utils.GetWindowUnderMouse(TimMenuGlobal.order, TimMenuGlobal.windows, mX, mY, titleHeight) == key

    -- Handle window focus and dragging
    if isTopWindow and input.IsButtonPressed(MOUSE_LEFT) then
        -- Bring window to front
        local index = table.find(TimMenuGlobal.order, key) --index is known to exist in order

        table.remove(TimMenuGlobal.order, index) --remove from current position
        table.insert(TimMenuGlobal.order, key) --add to start of order

        -- Start dragging if clicked in title bar
        if mY <= win.Y + titleHeight then
            win.IsDragging = true
            win.DragPos = { X = mX - win.X, Y = mY - win.Y }
        end
    end

    -- Update window position while dragging
    if TimMenuGlobal.ActiveWindow == key and win.IsDragging then
        win.X = mX - win.DragPos.X
        win.Y = mY - win.DragPos.Y
    end

    -- Stop dragging on mouse release
    if win.IsDragging and input.IsButtonReleased(MOUSE_LEFT) then
        win.IsDragging = false
    end

    -- Reset widget layout counters each frame using content padding.
    local padding = Globals.Defaults.WINDOW_CONTENT_PADDING
    win.cursorX = padding
    win.cursorY = Globals.Defaults.TITLE_BAR_HEIGHT + padding
    win.lineHeight = 0

    return win
end

--- Ends the current window.
function TimMenu.End()
    Utils.PruneOrphanedWindows(TimMenuGlobal.windows, TimMenuGlobal.order)

    -- Draw all windows when processing the last window
    if Utils.GetWindowCount() == #TimMenuGlobal.order then
        for i = 1, #TimMenuGlobal.order do
            local win = TimMenuGlobal.windows[TimMenuGlobal.order[i]]
            if win and win.visible then
                win:draw()
            end
        end
    end
end

--- Returns the current window (last drawn window).
function TimMenu.GetCurrentWindow()
    if TimMenuGlobal.lastWindowKey then
        return TimMenuGlobal.windows[TimMenuGlobal.lastWindowKey]
    end
end

--- Calls the Widgets.Button API on the current window.
--- Returns true if clicked.
function TimMenu.Button(label)
    local win = TimMenu.GetCurrentWindow()
    -- Only process button if we're in the correct window context
    if win and TimMenuGlobal.ActiveWindow == win.id then
        return Widgets.Button(win, label)
    end
    return false
end

--- Displays debug information...
function TimMenu.ShowDebug()
    local currentFrame = globals.FrameCount()
    draw.SetFont(Globals.Style.Font)
    draw.Color(255, 255, 255, 255)
    local headerX, headerY = 20, 20
    local lineSpacing = 20

    local count = 0
    for _ in pairs(TimMenuGlobal.windows) do count = count + 1 end

    draw.Text(headerX, headerY, "Active Windows (" .. count .. "):")
    local yOffset = headerY + lineSpacing
    for key, win in pairs(TimMenuGlobal.windows) do
        local delay = currentFrame - (win.lastFrame or currentFrame)
        local info = "ID: " .. key .. " | " .. win.title .. " (Delay: " .. delay .. ")"
        draw.Text(headerX, yOffset, info)
        yOffset = yOffset + lineSpacing
    end
end

return TimMenu

end)
__bundle_register("TimMenu.Widgets", function(require, _LOADED, __bundle_register, __bundle_modules)
local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Utils = require("TimMenu.Utils")  -- Add Utils requirement

local Widgets = {}

--- Renders a button with given label, updates window size, and returns true if clicked.
function Widgets.Button(win, label)
    -- Measure text size
    draw.SetFont(Globals.Style.Font)
    local textWidth, textHeight = draw.GetTextSize(label)
    local padding = Globals.Style.ItemPadding
    local width = textWidth + (padding * 2)  -- Include left and right internal padding
    local height = textHeight + (padding * 2)

    -- Add left padding if we're not at window start
    if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
        win.cursorX = win.cursorX + padding
    end

    -- Get widget coordinates while auto-expanding the window.
    local x, y = win:AddWidget(width, height)
    local absX, absY = win.X + x, win.Y + y

    -- First check if our window is the one being interacted with
    local hovered = false
    local clicked = false

    -- Check if this button's window is topmost at the button's position
    local topWindowKey = Utils.GetWindowUnderMouse(
        TimMenuGlobal.order,
        TimMenuGlobal.windows,
        absX + (width/2),  -- check center of button
        absY + (height/2),
        win.H + Globals.Defaults.TITLE_BAR_HEIGHT
    )

    -- Only process interaction if this window is topmost
    if topWindowKey == win.id then
        local mX, mY = table.unpack(input.GetMousePos())
        hovered = (mX >= absX) and (mX <= absX + width) and
                 (mY >= absY) and (mY <= absY + height)
        
        if hovered and input.IsButtonPressed(MOUSE_LEFT) then
            clicked = true
        end
    end

    -- Queue drawing with proper hover state
    win:QueueDrawAtLayer(2, function()
        if hovered then
            draw.Color(100,100,100,255)
        else
            draw.Color(80,80,80,255)
        end
        draw.FilledRect(absX, absY, absX + width, absY + height)
        draw.Color(255,255,255,255)
        local textX = absX + padding
        local textY = absY + padding
        draw.Text(textX, textY, label)
    end)

    return clicked
end

return Widgets

end)
__bundle_register("TimMenu.Utils", function(require, _LOADED, __bundle_register, __bundle_modules)
local Utils = {}

local currentFrameCount = 0
local windowsThisFrame = 0

function Utils.BeginFrame()
    local frame = globals.FrameCount()
    if frame ~= currentFrameCount then
        currentFrameCount = frame
        windowsThisFrame = 0
    end
    windowsThisFrame = windowsThisFrame + 1
    return windowsThisFrame
end

function Utils.GetWindowCount()
    return windowsThisFrame
end

-- Prune windows that haven't been drawn for a specified frame threshold.
-- Updated: Prune windows and clean the order array.
function Utils.PruneOrphanedWindows(windows, order)
    local threshold = 2
    local currentFrame = globals.FrameCount()
    for key, win in pairs(windows) do
        if not win.lastFrame or (currentFrame - win.lastFrame) >= threshold then
            windows[key] = nil
        end
    end
    -- Clean the order array by removing keys without corresponding windows.
    if order then
        for i = #order, 1, -1 do
            local key = order[i]
            if not windows[key] then
                table.remove(order, i)
            end
        end
    end
end

function Utils.IsMouseOverWindow(win, mouseX, mouseY, titleHeight)
    return mouseX >= win.X
       and mouseX <= win.X + win.W
       and mouseY >= win.Y
       and mouseY <= win.Y + win.H
end

-- Returns the top window key at a given point.
function Utils.GetWindowUnderMouse(order, windows, x, y, titleBarHeight)
    --if this isnt he window udner mouse set activewindwo to nil
    TimMenuGlobal.ActiveWindow = nil

    -- Loop from top to bottom (end to start), returning the first window under mouse.
    for i = #order, 1, -1 do
        local key = order[i]
        local win = windows[key]
        if win and Utils.IsMouseOverWindow(win, x, y, titleBarHeight) then
            TimMenuGlobal.ActiveWindow = key
            input.SetMouseInputEnabled(false) --disable mouse input when using menu
            return key
        end
    end

    input.SetMouseInputEnabled(true) --enable mouse input when not using menu

    return nil
end

return Utils

end)
__bundle_register("TimMenu.Common", function(require, _LOADED, __bundle_register, __bundle_modules)
---@diagnostic disable: duplicate-set-field, undefined-field
---@class Common

local Common = {}

local Globals = require("TimMenu.Globals") -- Import the Globals module for Colors and Style.

-- Attempt to unload any existing LNXlib instance
local function safeUnload()
    pcall(UnloadLib)
end

-- Load and validate LNXlib
local function loadLNXlib()
    local libLoaded, Lib = pcall(require, "LNXlib")
    if not libLoaded then
        error("Failed to load LNXlib. Please ensure it is installed correctly.")
    end

    if not Lib.GetVersion or Lib.GetVersion() < 1.0 then
        error("LNXlib version is too old. Please update to version 1.0 or newer.")
    end

    return Lib
end

-- Initialize library
safeUnload()
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

--- Clamps a floating-point value to the closest integer.
---@param value number
---@return number
function Common.Clamp(value)
    return math.floor(value + 0.5)
end

-- Track button state globally
local wasPressed = false

-- New: Helper function for mouse interaction within a rectangle.
function Common.GetInteraction(x, y, w, h)
    local mX, mY = table.unpack(input.GetMousePos())
    local hovered = (mX >= x) and (mX <= x + w) and (mY >= y) and (mY <= y + h)
    local isPressed = input.IsButtonDown(MOUSE_LEFT)

    -- Only trigger click when button is pressed and wasn't pressed last frame
    local clicked = hovered and isPressed and not wasPressed

    -- Update state for next frame
    wasPressed = isPressed

    return hovered, clicked
end

--------------------------------------------------------------------------------
-- Unload Callback: Clean up the module on unload.
--------------------------------------------------------------------------------

local function OnUnload()                        -- Called when the script is unloaded
    UnloadLib()                                  --unloading lualib
    input.SetMouseInputEnabled(true)             --enable mouse input(hopefuly prevent soft lock on load)
    engine.PlaySound("hl1/fvox/deactivated.wav") --deactivated
    TimMenu.Refresh()                            --refreshing menu
end

callbacks.Unregister("Unload", "TimMenu_Unload")
callbacks.Register("Unload", "TimMenu_Unload", OnUnload)

--[[ Play sound when loaded ]] --
engine.PlaySound("hl1/fvox/activated.wav")

return Common

end)
__bundle_register("TimMenu.Globals", function(require, _LOADED, __bundle_register, __bundle_modules)
local Globals = {}

-- Color definitions
Globals.Colors = {
    Title = { 55, 100, 215, 255 },
    Text = { 255, 255, 255, 255 },
    Window = { 30, 30, 30, 255 },
    Item = { 50, 50, 50, 255 },
    ItemHover = { 60, 60, 60, 255 },
    ItemActive = { 70, 70, 70, 255 },
    Highlight = { 180, 180, 180, 100 },
    HighlightActive = { 240, 240, 240, 140 },
    WindowBorder = { 55, 100, 215, 255 },
    FrameBorder = { 0, 0, 0, 200 },
    Border = { 0, 0, 0, 200 }
}

-- Style settings
Globals.Style = {
    Font = draw.CreateFont("Verdana", 14, 510), -- "verdana.ttf",
    ItemPadding = 5,
    ItemMargin = 5,
    FramePadding = 5,
    ItemSize = 10,
    WindowBorder = true,
    FrameBorder = false,
    ButtonBorder = false,
    CheckboxBorder = false,
    SliderBorder = false,
    Border = false,
    Popup = false,
    Alignment = "left"  -- or "center"
}

Globals.Defaults = {
    DEFAULT_X = 50,
    DEFAULT_Y = 150,
    DEFAULT_W = 100,
    DEFAULT_H = 50,
    TITLE_BAR_HEIGHT = 25,
    WINDOW_CONTENT_PADDING = 10  -- added for inner padding on all sides
}

return Globals

end)
__bundle_register("TimMenu.Window", function(require, _LOADED, __bundle_register, __bundle_modules)
local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")

local Window = {}
Window.__index = Window

local function CreateDefaultParams(title, id, visible)
    return {
        title = title,
        id = id or title,
        visible = (visible == nil) and true or visible,
        X = Globals.Defaults.DEFAULT_X + math.random(0, 150),
        Y = Globals.Defaults.DEFAULT_Y + math.random(0, 50),
        W = Globals.Defaults.DEFAULT_W,
        H = Globals.Defaults.DEFAULT_H
    }
end

function Window.new(params)
    if type(params) == "string" then
        params = CreateDefaultParams(params)
    end
    local self = setmetatable({}, Window) -- normal metatable, no weak mode
    self.title   = params.title
    self.id      = params.id or params.title
    self.visible = (params.visible == nil) and true or params.visible
    self.X       = params.X or (Globals.Defaults.DEFAULT_X + math.random(0, 150))
    self.Y       = params.Y or (Globals.Defaults.DEFAULT_Y + math.random(0, 50))
    self.W       = params.W or Globals.Defaults.DEFAULT_W
    self.H       = params.H or Globals.Defaults.DEFAULT_H
    self.lastFrame = nil
    self.IsDragging = false
    self.DragPos = { X = 0, Y = 0 }
    -- Initialize a table of layers
    self.Layers = {}
    for i = 1, 5 do
        self.Layers[i] = {}
    end
    -- Set __close metamethod so it auto-cleans when used as a to-be-closed variable.
    local mt = getmetatable(self)
    mt.__close = Window.__close
    -- Define a default update method to avoid nil errors.
    self.update = function(self, currentFrame)
        self.lastFrame = currentFrame
    end
    self.cursorX = 0
    self.cursorY = 0
    self.lineHeight = 0
    return self
end

function Window:update(currentFrame)
    if self.visible and (gui.GetValue("clean screenshots") == 1 and not engine.IsTakingScreenshot()) then
        self.lastFrame = currentFrame
        self.X = Common.Clamp(self.X)
        self.Y = Common.Clamp(self.Y)
    end
end

-- Removed the handleDrag function as dragging is now handled in Main.lua.

-- Queue a drawing function under a specified layer
function Window:QueueDrawAtLayer(layer, drawFunc, ...)
    if self.Layers[layer] then
        table.insert(self.Layers[layer], { fn = drawFunc, args = { ... } })
    end
end

-- Pre-calculate static colors
local DefaultWindowColor = Globals.Colors.Window or {30,30,30,255}
local DefaultTitleColor = Globals.Colors.Title or {55,100,215,255}
local DefaultTextColor = Globals.Colors.Text or {255,255,255,255}
local DefaultBorderColor = Globals.Colors.WindowBorder or {55,100,215,255}

function Window:draw()
    draw.SetFont(Globals.Style.Font)
    local txtWidth, txtHeight = draw.GetTextSize(self.title)
    local titleHeight = txtHeight + Globals.Style.ItemPadding

    -- Draw window parts in order: background, title bar, border, text
    draw.Color(table.unpack(DefaultWindowColor))
    draw.FilledRect(self.X, self.Y + titleHeight, self.X + self.W, self.Y + self.H)

    draw.Color(table.unpack(DefaultTitleColor))
    draw.FilledRect(self.X, self.Y, self.X + self.W, self.Y + titleHeight)

    draw.Color(table.unpack(DefaultBorderColor))
    draw.OutlinedRect(self.X, self.Y, self.X + self.W, self.Y + self.H)

    -- Draw title text last
    local titleX = Common.Clamp(self.X + (self.W - txtWidth) / 2)
    local titleY = Common.Clamp(self.Y + (titleHeight - txtHeight) / 2)
    draw.Color(table.unpack(DefaultTextColor))
    draw.Text(titleX, titleY, self.title)

    -- Process widget layers in order
    for layer = 1, #self.Layers do
        local layerEntries = self.Layers[layer]
        for _, entry in ipairs(layerEntries) do
            entry.fn(table.unpack(entry.args))
        end
        self.Layers[layer] = {} -- Clear after processing
    end
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

    -- Update cursor position
    self.cursorX = x + width

    return x, y
end

--- Provide a simple way to "new line" to place subsequent widgets below
function Window:NextLine(spacing)
    spacing = spacing or 5
    self.cursorY = self.cursorY + self.lineHeight + spacing
    self.cursorX = Globals.Defaults.WINDOW_CONTENT_PADDING  -- reset to left padding
    self.lineHeight = 0
    -- Expand window if needed
    if self.cursorY > self.H then
        self.H = self.cursorY
    end
end

--- __close metamethod: cleans up window state.
function Window:__close()
    self.lastFrame = nil
    self.IsDragging = false
    self.DragPos = { X = 0, Y = 0 }
end

return Window

end)
return __bundle_require("__root")