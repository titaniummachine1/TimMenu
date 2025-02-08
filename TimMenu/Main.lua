-- Main module for the TimMenu library

local Common = require("TimMenu.Common")
local Static = require("TimMenu.Static")
local Utils = require("TimMenu.Utils")
local Window = require("TimMenu.Window")
local WidgetStack = require("TimMenu.widgets.WidgetStack")
local WindowState = require("TimMenu.WindowState")  -- global persistent state

local TimMenu = {}

-- Initialize TimMenu
TimMenu.windows = WindowState.windows  -- shared state: key -> Window instance
TimMenu.order = WindowState.order
TimMenu.CapturedWindow = nil
TimMenu.LastWindowDrawnKey = nil
TimMenu.WidgetStack = WidgetStack

-- Refresh function to clear loaded modules
function TimMenu.Refresh()
    package.loaded["TimMenu.Common"] = nil
    package.loaded["TimMenu.Static"] = nil
    package.loaded["TimMenu.Utils"] = nil
    package.loaded["TimMenu.Window"] = nil
    package.loaded["TimMenu.widgets.WidgetStack"] = nil
end

--- Begins a new or updates an existing window.
--- @param title string Window title.
--- @param visible? boolean Whether the window is visible (default: true).
--- @param id? string|number Unique identifier (default: title).
--- @return boolean, table Visible flag and the window table.
function TimMenu.Begin(title, visible, id)
    TimMenu.Refresh()
    assert(type(title) == "string", "TimMenu.Begin requires a string title")
    visible = (visible == nil) and true or visible
    if type(visible) == "string" then id, visible = visible, true end
    local key = (id or title)
    if type(key) ~= "string" then key = tostring(key) end

    local currentFrame = globals.FrameCount()
    local win = TimMenu.windows[key]
    
    -- Create new window if needed
    if not win then
        win = Window.new({
            title = title,
            id = key,
            visible = visible,
            X = Static.Defaults.DEFAULT_X + math.random(0, 150),
            Y = Static.Defaults.DEFAULT_Y + math.random(0, 50),
            W = Static.Defaults.DEFAULT_W,
            H = Static.Defaults.DEFAULT_H,
        })
        TimMenu.windows[key] = win
        table.insert(TimMenu.order, key)
    else
        win.visible = visible
    end

    if visible then
        win.lastFrame = currentFrame
        TimMenu.LastWindowDrawnKey = key

        -- Handle mouse interaction
        local mX, mY = table.unpack(input.GetMousePos())
        local titleHeight = Static.Defaults.TITLE_BAR_HEIGHT

        -- Find topmost window being clicked (check from front to back)
        local isTopWindow = true
        for i = #TimMenu.order, 1, -1 do
            local checkKey = TimMenu.order[i]
            if checkKey == key then break end -- Stop when we reach current window
            local checkWin = TimMenu.windows[checkKey]
            if checkWin and checkWin.visible then
                -- If a window above this one contains the mouse, this isn't the top window
                if mX >= checkWin.X and mX <= checkWin.X + checkWin.W and
                   mY >= checkWin.Y and mY <= checkWin.Y + checkWin.H + titleHeight then
                    isTopWindow = false
                    break
                end
            end
        end

        -- Only handle mouse interaction if this is the topmost window at the mouse position
        if isTopWindow and mX >= win.X and mX <= win.X + win.W and
           mY >= win.Y and mY <= win.Y + win.H + titleHeight then
            if input.IsButtonPressed(MOUSE_LEFT) then
                -- Move window to end of order (top)
                for i, k in ipairs(TimMenu.order) do
                    if k == key then
                        table.remove(TimMenu.order, i)
                        table.insert(TimMenu.order, key)
                        break
                    end
                end

                -- If clicked in title bar, start dragging
                if mY <= win.Y + titleHeight then
                    win.IsDragging = true
                    win.DragPos = { X = mX - win.X, Y = mY - win.Y }
                    TimMenu.CapturedWindow = key
                end
            end
        end

        -- Handle dragging
        if TimMenu.CapturedWindow == key and win.IsDragging then
            win.X = mX - win.DragPos.X
            win.Y = mY - win.DragPos.Y

            -- Stop dragging when mouse released
            if not input.IsButtonDown(MOUSE_LEFT) then
                win.IsDragging = false
                TimMenu.CapturedWindow = nil
            end
        end
    end

    return visible, win
end

--- Ends the current window.
function TimMenu.End()
    -- Release captured window if mouse released
    if not input.IsButtonDown(MOUSE_LEFT) then
        TimMenu.CapturedWindow = nil
    end

    -- Draw all visible windows in order (bottom to top)
    for i = 1, #TimMenu.order do
        local key = TimMenu.order[i]
        local win = TimMenu.windows[key]
        if win and win.visible then
            win:draw()
        end
    end
end

--- Displays debug information.
function TimMenu.ShowDebug()
    local currentFrame = globals.FrameCount()
    draw.SetFont(Static.Style.Font)
    draw.Color(255,255,255,255)
    local headerX, headerY = 20, 20
    local lineSpacing = 20

    local count = 0
    for _ in pairs(TimMenu.windows) do count = count + 1 end

    draw.Text(headerX, headerY, "Active Windows (" .. count .. "):")
    local yOffset = headerY + lineSpacing
    for key, win in pairs(TimMenu.windows) do
        local delay = currentFrame - (win.lastFrame or currentFrame)
        local info = "ID: " .. key .. " | " .. win.title .. " (Delay: " .. delay .. ")"
        draw.Text(headerX, yOffset, info)
        yOffset = yOffset + lineSpacing
    end
end

-- Load widgets and attach them to TimMenu
local Widgets = {}
Widgets.Button = require("TimMenu.widgets.Button")
-- Future widgets can be added to Widgets here

-- Attach widget functions to TimMenu
--TimMenu.Button = Widgets.Button.Draw
TimMenu.Widgets = Widgets

return TimMenu
