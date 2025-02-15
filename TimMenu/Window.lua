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

--- __close metamethod: cleans up window state.
function Window:__close()
    self.lastFrame = nil
    self.IsDragging = false
    self.DragPos = { X = 0, Y = 0 }
end

function Window:update()
    self.lastFrame = globals.FrameCount()
end

function Window.new(params)
    if type(params) == "string" then
        params = CreateDefaultParams(params)
    end
    local self      = setmetatable({}, Window) -- normal metatable, no weak mode
    self.title      = params.title
    self.id         = params.id or params.title
    self.visible    = (params.visible == nil) and true or params.visible
    self.X          = params.X or (Globals.Defaults.DEFAULT_X + math.random(0, 150))
    self.Y          = params.Y or (Globals.Defaults.DEFAULT_Y + math.random(0, 50))
    self.W          = params.W or Globals.Defaults.DEFAULT_W
    self.H          = params.H or Globals.Defaults.DEFAULT_H
    self.lastFrame  = nil
    self.IsDragging = false
    self.DragPos    = { X = 0, Y = 0 }
    -- Initialize a table of layers
    self.Layers     = {}
    for i = 1, 5 do
        self.Layers[i] = {}
    end
    -- Set __close metamethod so it auto-cleans when used as a to-be-closed variable.
    local mt = getmetatable(self)
    mt.__close = Window.__close

    self.cursorX = 0
    self.cursorY = 0
    self.lineHeight = 0
    return self
end

-- Queue a drawing function under a specified layer
function Window:QueueDrawAtLayer(layer, drawFunc, ...)
    if self.Layers[layer] then
        table.insert(self.Layers[layer], { fn = drawFunc, args = { ... } })
    end
end

-- Pre-calculate static colors
local DefaultWindowColor = Globals.Colors.Window or { 30, 30, 30, 255 }
local DefaultTitleColor = Globals.Colors.Title or { 55, 100, 215, 255 }
local DefaultTextColor = Globals.Colors.Text or { 255, 255, 255, 255 }
local DefaultBorderColor = Globals.Colors.WindowBorder or { 55, 100, 215, 255 }

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
    self.cursorX = Globals.Defaults.WINDOW_CONTENT_PADDING -- reset to left padding
    self.lineHeight = 0
    -- Expand window if needed
    if self.cursorY > self.H then
        self.H = self.cursorY
    end
end

return Window
