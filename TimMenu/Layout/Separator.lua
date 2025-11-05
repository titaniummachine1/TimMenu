local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")

local LayoutSeparator = {}

local function makeBoundsResolver(win)
    local pad = Globals.Defaults.WINDOW_CONTENT_PADDING
    local sectorStack = win._sectorStack
    local activeSector = sectorStack and sectorStack[#sectorStack]

    if activeSector then
        local capturedSector = activeSector
        return function()
            local left = capturedSector.startX + capturedSector.padding
            local right = math.max(left, capturedSector.maxX)
            return left, right
        end
    end

    return function()
        local left = pad
        local right = math.max(left, win.W - pad)
        return left, right
    end
end

local function drawLabelSeparator(win, y, label, resolveBounds)
    draw.SetFont(Globals.Style.Font)
    local textWidth, textHeight = draw.GetTextSize(label)
    local sepPad = Globals.Style.ItemPadding or Globals.Defaults.WINDOW_CONTENT_PADDING
    local absY = win.Y + y
    local left, right = resolveBounds()
    local absLeft = win.X + left
    local absRight = win.X + right
    local innerWidth = absRight - absLeft
    if innerWidth <= 0 then
        return
    end

    local textX = absLeft + math.max(0, (innerWidth - textWidth) / 2)
    local centerY = absY + math.floor(textHeight / 2)
    local leftLineEnd = math.max(absLeft, textX - sepPad)
    local rightLineStart = math.min(absRight, textX + textWidth + sepPad)

    Common.SetColor(Globals.Colors.WindowBorder)
    if leftLineEnd > absLeft then
        Common.DrawLine(absLeft, centerY, leftLineEnd, centerY)
    end
    Common.SetColor(Globals.Colors.Text)
    Common.DrawText(textX, absY, label)
    Common.SetColor(Globals.Colors.WindowBorder)
    if rightLineStart < absRight then
        Common.DrawLine(rightLineStart, centerY, absRight, centerY)
    end
end

local function drawLineSeparator(win, y, resolveBounds)
    local left, right = resolveBounds()
    local absLeft = win.X + left
    local absRight = win.X + right
    if absRight <= absLeft then
        return
    end
    local absY = win.Y + y
    Common.SetColor(Globals.Colors.WindowBorder)
    Common.DrawLine(absLeft, absY, absRight, absY)
end

-- The main separator function, to be called by TimMenu.Separator
function LayoutSeparator.Draw(win, label)
    assert(type(win) == "table", "Separator: win must be a table")
    assert(label == nil or type(label) == "string", "Separator: label must be a string or nil")
    local pad = Globals.Defaults.WINDOW_CONTENT_PADDING
    local vpad = Globals.Style.ItemPadding
    if win.cursorX > pad then
        win:NextLine(0)
    end
    win:NextLine(vpad)

    local height = 1
    if type(label) == "string" then
        draw.SetFont(Globals.Style.Font)
        local _, textHeight = draw.GetTextSize(label)
        height = math.max(1, textHeight)
    end

    local _, y = win:AddWidget(0, height)
    local resolveBounds = makeBoundsResolver(win)

    win:QueueDrawAtLayer(1, function()
        if type(label) == "string" then
            drawLabelSeparator(win, y, label, resolveBounds)
        else
            drawLineSeparator(win, y, resolveBounds)
        end
    end)

    win:NextLine(vpad)
end

return LayoutSeparator
