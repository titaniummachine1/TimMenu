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
    -- Set __close metamethod so it auto-cleans when used as a to-be-closed variable.
    local mt = getmetatable(self)
    mt.__close = Window.__close
    -- Define a default update method to avoid nil errors.
    self.update = function(self, currentFrame)
        self.lastFrame = currentFrame
    end
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

function Window:draw()
    local titleText = self.title
    draw.SetFont(Globals.Style.Font)
    local txtWidth, txtHeight = draw.GetTextSize(titleText)
    local titleHeight = txtHeight + Globals.Style.ItemPadding

    draw.Color(table.unpack(Globals.Colors.Window or {30,30,30,255}))
    draw.FilledRect(self.X, self.Y + titleHeight, self.X + self.W, self.Y + self.H)

    draw.Color(table.unpack(Globals.Colors.Title or {55,100,215,255}))
    draw.FilledRect(self.X, self.Y, self.X + self.W, self.Y + titleHeight)

    local titleX = Common.Clamp(self.X + (self.W - txtWidth) / 2)
    local titleY = Common.Clamp(self.Y + (titleHeight - txtHeight) / 2)
    draw.Color(table.unpack(Globals.Colors.Text or {255,255,255,255}))
    draw.Text(titleX, titleY, titleText)

    draw.Color(table.unpack(Globals.Colors.WindowBorder or {55,100,215,255}))
    draw.OutlinedRect(self.X, self.Y, self.X + self.W, self.Y + self.H)
end

--- __close metamethod: cleans up window state.
function Window:__close()
    self.lastFrame = nil
    self.IsDragging = false
    self.DragPos = { X = 0, Y = 0 }
end

return Window
