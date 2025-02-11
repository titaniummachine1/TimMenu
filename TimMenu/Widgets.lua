local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")

local Widgets = {}

--- Renders a button with given label, updates window size, and returns true if clicked.
function Widgets.Button(win, label)
    -- Measure text size
    draw.SetFont(Globals.Style.Font)
    local textWidth, textHeight = draw.GetTextSize(label)
    local padding = Globals.Style.ItemPadding
    local width = textWidth + (padding * 2)
    local height = textHeight + (padding * 2)

    -- Let the window auto-expand
    win:AddWidget(width, height)

    -- We must capture current position for drawing
    local x = win.cursorX - width
    local y = win.cursorY
    if Globals.Style.Alignment == "center" then
        x = math.max(0, (win.W - width) * 0.5)
    end

    -- Check for click
    local hovered, clicked = Common.GetInteraction(win.X + x, win.Y + y, width, height)

    -- Queue some drawing
    win:QueueDrawAtLayer(2, function()
        if hovered then
            draw.Color(100,100,100,255)
        else
            draw.Color(80,80,80,255)
        end
        draw.FilledRect(win.X + x, win.Y + y, win.X + x + width, win.Y + y + height)
        draw.Color(255,255,255,255)
        local textX = win.X + x + padding
        local textY = win.Y + y + padding
        draw.Text(textX, textY, label)
    end)

    return clicked
end

return Widgets
