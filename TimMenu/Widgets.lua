local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Utils = require("TimMenu.Utils")

local Widgets = {}

-- Helper function to check if a point is within bounds
local function isInBounds(x, y, bounds)
    return x >= bounds.x and x <= bounds.x + bounds.w
       and y >= bounds.y and y <= bounds.y + bounds.h
end

-- Helper to check if widget can be interacted with
local function canInteract(win, bounds)
    -- First check if window is active
    if TimMenuGlobal.ActiveWindow ~= win.id then
        return false
    end

    local mX, mY = table.unpack(input.GetMousePos())
    
    -- Check if mouse is within bounds
    if not isInBounds(mX, mY, bounds) then
        return false
    end

    -- Check if point is blocked by any window above this one
    if Utils.IsPointBlocked(TimMenuGlobal.order, TimMenuGlobal.windows, mX, mY, win.id) then
        return false
    end

    return true
end

function Widgets.Button(win, label)
    -- Calculate dimensions
    draw.SetFont(Globals.Style.Font)
    local textWidth, textHeight = draw.GetTextSize(label)
    local padding = Globals.Style.ItemPadding
    local width = textWidth + (padding * 2)
    local height = textHeight + (padding * 2)

    -- Handle padding between widgets
    if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
        win.cursorX = win.cursorX + padding
    end

    -- Get widget position
    local x, y = win:AddWidget(width, height)
    local absX, absY = win.X + x, win.Y + y

    -- Define bounds for interaction checking
    local bounds = {
        x = absX,
        y = absY,
        w = width,
        h = height
    }

    -- Handle interaction
    local hovered = canInteract(win, bounds)
    local clicked = hovered and input.IsButtonPressed(MOUSE_LEFT)

    -- Queue drawing
    win:QueueDrawAtLayer(2, function()
        draw.Color(table.unpack(hovered and {100,100,100,255} or {80,80,80,255}))
        draw.FilledRect(absX, absY, absX + width, absY + height)
        draw.Color(255,255,255,255)
        draw.Text(absX + padding, absY + padding, label)
    end)

    return clicked
end

return Widgets
