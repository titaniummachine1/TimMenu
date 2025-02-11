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
