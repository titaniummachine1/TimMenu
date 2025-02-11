local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")

local Window = {}
Window.__index = Window

function Window.new(params)
    local self = {}
    setmetatable(self, Window) -- normal metatable, no weak mode
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

function Window:draw()
    local titleText = self.title
    draw.SetFont(Globals.Style.Font)
    local txtWidth, txtHeight = draw.GetTextSize(titleText)
    local titleHeight = txtHeight + Globals.Style.ItemPadding

    -- Draw window background.
    draw.Color(table.unpack(Globals.Colors.Window or {30,30,30,255}))
    draw.FilledRect(self.X, self.Y + titleHeight, self.X + self.W, self.Y + self.H)

    -- Process widget layers immediately so widgets appear.
    for i = 1, #self.Layers do
        for _, entry in ipairs(self.Layers[i]) do
            entry.fn(table.unpack(entry.args))
        end
    end

    -- Then draw the title bar and window border on top.
    draw.Color(table.unpack(Globals.Colors.Title or {55,100,215,255}))
    draw.FilledRect(self.X, self.Y, self.X + self.W, self.Y + titleHeight)

    local titleX = Common.Clamp(self.X + (self.W - txtWidth) / 2)
    local titleY = Common.Clamp(self.Y + (titleHeight - txtHeight) / 2)
    draw.Color(table.unpack(Globals.Colors.Text or {255,255,255,255}))
    draw.Text(titleX, titleY, titleText)

    draw.Color(table.unpack(Globals.Colors.WindowBorder or {55,100,215,255}))
    draw.OutlinedRect(self.X, self.Y, self.X + self.W, self.Y + self.H)

    -- Clear layer calls for the next frame.
    for i = 1, #self.Layers do
        self.Layers[i] = {}
    end
end

--- Called when adding a widget so the window auto-expands to fit content.
--- width, height: the widget's measured size
function Window:AddWidget(width, height)
    local x = self.cursorX
    -- If centered, place the widget in the horizontal center
    if Globals.Style.Alignment == "center" then
        x = math.max(0, (self.W - width) * 0.5)
    end

    -- Expand window if needed
    if (x + width) > self.W then
        self.W = x + width
    end
    if height > self.lineHeight then
        self.lineHeight = height
    end

    self.cursorX = x + width
    local neededHeight = self.cursorY + self.lineHeight
    if neededHeight > self.H then
        self.H = neededHeight
    end
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
