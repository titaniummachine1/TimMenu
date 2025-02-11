local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")

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

    -- Check for click using absolute coordinates.
    local hovered, clicked = Common.GetInteraction(win.X + x, win.Y + y, width, height)

    -- Queue button drawing.
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
