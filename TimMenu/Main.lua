-- Main module for the TimMenu library
local TimMenu = {}

local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local Utils = require("TimMenu.Utils")
local Window = require("TimMenu.Window")
local Widgets = require("TimMenu.Widgets")  -- new require

local currentFrameCount = 0
local windowsThisFrame = 0

-- Refresh function to clear loaded modules
function TimMenu.Refresh()
    package.loaded["TimMenu"] = nil
end

local function Setup()
    TimMenu.Refresh()

    if not TimMenuGlobal then
        -- Initialize TimMenu
        TimMenuGlobal = {}
        TimMenuGlobal.windows = {}  -- no weak references now
        TimMenuGlobal.order = {}
        TimMenuGlobal.CapturedWindow = nil
        TimMenuGlobal.LastWindowDrawnKey = nil
    end
end

Setup()

--- Begins a new or updates an existing window.
--- @param title string Window title.
--- @param visible? boolean Whether the window is visible (default: true).
--- @param id? string|number Unique identifier (default: title).
--- @return boolean, table Visible flag and the window table.
function TimMenu.Begin(title, visible, id)
    -- At the start of a new frame, reset the window counter
    local frame = globals.FrameCount()
    if frame ~= currentFrameCount then
        currentFrameCount = frame
        windowsThisFrame = 0
    end
    windowsThisFrame = windowsThisFrame + 1

    TimMenu.Refresh()
    assert(type(title) == "string", "TimMenu.Begin requires a string title")
    visible = (visible == nil) and true or visible
    if type(visible) == "string" then id, visible = visible, true end
    local key = (id or title)
    TimMenuGlobal.LastWindowDrawnKey = key  -- Use global instead of local lastkey

    local currentFrame = globals.FrameCount()
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
        win.visible = visible -- onl value tha can and should change sometimes
    end

    if visible and not engine.IsTakingScreenshot() then
        win.lastFrame = currentFrame
        local mX, mY = table.unpack(input.GetMousePos())
        local titleHeight = Globals.Defaults.TITLE_BAR_HEIGHT

        local InteractedWindowKey = Utils.GetWindowUnderMouse(TimMenuGlobal.order, TimMenuGlobal.windows, mX, mY, titleHeight)
        local btnPressed = input.IsButtonPressed(MOUSE_LEFT)

        if InteractedWindowKey == key then
            if btnPressed then
                -- Bring window to front
                local index = table.find(TimMenuGlobal.order, key)
                if index then
                    table.remove(TimMenuGlobal.order, index)
                    table.insert(TimMenuGlobal.order, key)
                end

                -- Start dragging if in title bar
                if mY <= win.Y + titleHeight then
                    win.IsDragging = true
                    win.DragPos = { X = mX - win.X, Y = mY - win.Y }
                    TimMenuGlobal.CapturedWindow = key
                end
            end
        end

        --[[
        Update the dragging position.(outside to prevent slipery windows)
        We avoid re-checking for mouse interaction here to ensure smooth dragging, even if the window is moved quickly.
        ]]
        if TimMenuGlobal.CapturedWindow == key and win.IsDragging then
            win.X = mX - win.DragPos.X
            win.Y = mY - win.DragPos.Y
        end

        -- Stop dragging when mouse button is released
        if input.IsButtonReleased(MOUSE_LEFT) then
            win.IsDragging = false
            TimMenuGlobal.CapturedWindow = nil
        end
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

    -- Count how many windows we have total
    local totalWindows = #TimMenuGlobal.order

    -- Only draw all windows when we're on the last End() call for this frame
    if windowsThisFrame == totalWindows then
        for i = 1, #TimMenuGlobal.order do
            local key = TimMenuGlobal.order[i]
            local win = TimMenuGlobal.windows[key]
            if win and win.visible then
                win:draw()
            end
        end
    end
end

--- Returns the current window (last drawn window).
function TimMenu.GetCurrentWindow()
    if TimMenuGlobal.LastWindowDrawnKey then
        return TimMenuGlobal.windows[TimMenuGlobal.LastWindowDrawnKey]
    end
end

--- Calls the Widgets.Button API on the current window.
--- Returns true if clicked.
function TimMenu.Button(label)
    local win = TimMenu.GetCurrentWindow()
    if win then
        return Widgets.Button(win, label)
    end
    return false
end

--- Displays debug information.
function TimMenu.ShowDebug()
    local currentFrame = globals.FrameCount()
    draw.SetFont(Globals.Style.Font)
    draw.Color(255,255,255,255)
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
