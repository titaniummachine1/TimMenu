-- TimMenu.lua
-- A simple library for multi-window integration with automatic cleanup.
-- Usage: Simply call TimMenu.Begin("Title", [visible], [uniqueID]) and TimMenu.End() in your Draw callback.
-- Windows that are not drawn for 5 frames are automatically removed.
-- If you start drawing a window again (with visible = true), it reappears.
-- This version uses a separate static module for Colors and Style.

-- Import the LNXlib module using common
local Common = require("TimMenu.Common")

-- Import the static module for Colors and Style.
local Static = require("TimMenu.Static")  -- This module should return a table with .Colors and .Style

-- Create the module table.
TimMenu = TimMenu or {}
-- Windows are stored as a table keyed by a unique ID.
TimMenu.windows = TimMenu.windows or {}

-- Initialize new globals for window ordering and capturing
TimMenu.order = TimMenu.order or {}  -- Array of window keys in draw order (bottom-first, top-last)
TimMenu.CapturedWindow = TimMenu.CapturedWindow or nil

-- Refresh method to force reloading this module if needed.
function TimMenu.Refresh()
    package.loaded["TimMenu"] = nil
end
TimMenu.Refresh() -- Refresh if run manually

--------------------------------------------------------------------------------
--[[ Helper: Prune Orphaned Windows ]]
--------------------------------------------------------------------------------
-- This function uses globals.FrameCount() to determine if a window hasn't been drawn
-- for at least 5 frames.
local function PruneOrphanedWindows()
    local currentFrame = globals.FrameCount()
    local threshold = 2  -- Maximum number of frames a window can go without being drawn.
    for key, win in pairs(TimMenu.windows) do
        if not win.lastFrame or (currentFrame - win.lastFrame) >= threshold then
            TimMenu.windows[key] = nil
        end
    end
end

--------------------------------------------------------------------------------
--[[ TimMenu API Functions ]]
--------------------------------------------------------------------------------

-- New: Helper function to return the top window key at a given point.
function TimMenu.GetTopWindowAtPoint(x, y)
    for i = #TimMenu.order, 1, -1 do
        local key = TimMenu.order[i]
        local win = TimMenu.windows[key]
        if win and (x >= win.X and x <= win.X + win.W and y >= win.Y and y <= win.Y + Static.Defaults.TITLE_BAR_HEIGHT) then
            return key
        end
    end
    return nil
end

--- Begins a window with the given title, optional visibility flag, and optional unique ID.
--- If no unique ID is provided, the title is used.
--- Parameters:
---   title (string): The window title.
---   visible (boolean, optional): Whether the window should be drawn (defaults to true).
---   id (optional): A unique identifier (string or number) for the window.
--- Returns:
---   visible (boolean) and the window table.
function TimMenu.Begin(title, visible, id)
    assert(type(title) == "string", "TimMenu.Begin requires a string title")
    if visible == nil then 
        visible = true 
    end
    -- If the second parameter is a string, treat it as the unique id and default visible to true.
    if type(visible) == "string" then
        id = visible
        visible = true
    end
    local key = id or title
    if type(key) ~= "string" then key = tostring(key) end

    PruneOrphanedWindows()

    local currentFrame = globals.FrameCount()
    local win = TimMenu.windows[key]
    if not win then
        win = {
            title = title,
            id = key,
            visible = visible,
            X = Static.Defaults.DEFAULT_X,
            Y = Static.Defaults.DEFAULT_Y,
            W = Static.Defaults.DEFAULT_W,
            H = Static.Defaults.DEFAULT_H,
        }
        TimMenu.windows[key] = win
        table.insert(TimMenu.order, key)  -- add new window to order
    else
        win.visible = visible
    end

    if visible then
        if (gui.GetValue("clean screenshots") == 1 and not engine.IsTakingScreenshot()) then
            win.lastFrame = currentFrame
            win.X = Common.Clamp(win.X)
            win.Y = Common.Clamp(win.Y)
            -- Removed immediate drawing call:
            -- TimMenu.DrawWindow(win)
            TimMenu.LastWindowDrawnKey = key  -- update last drawn key
        end

        local screenWidth, screenHeight = draw.GetScreenSize()
        local titleText = win.title
        draw.SetFont(Static.Style.Font)
        local txtWidth, txtHeight = draw.GetTextSize(titleText)
        local titleHeight = txtHeight + Static.Style.ItemPadding

        local mX, mY = table.unpack(input.GetMousePos())
        local topKey = TimMenu.GetTopWindowAtPoint(mX, mY)
        if topKey == key then
            local hovered, clicked = Common.GetInteraction(win.X, win.Y, win.W, titleHeight)
            if clicked then
                -- Reset drag offset for new click and capture the window
                win.IsDragging = false
                TimMenu.CapturedWindow = key
                -- Bring window on top by removing and reinserting its key
                for i, k in ipairs(TimMenu.order) do
                    if k == key then
                        table.remove(TimMenu.order, i)
                        break
                    end
                end
                table.insert(TimMenu.order, key)
            end
        end

        if TimMenu.CapturedWindow == key then
            Common.HandleWindowDrag(win, Static.Defaults.TITLE_BAR_HEIGHT, screenWidth, screenHeight)
        end
    end

    return visible, win
end

--- Ends the current window.
function TimMenu.End()
    if not input.IsButtonDown(MOUSE_LEFT) then
        TimMenu.CapturedWindow = nil
    end
    -- Determine the top visible window key.
    local topVisible = nil
    for i = #TimMenu.order, 1, -1 do
        local key = TimMenu.order[i]
        local win = TimMenu.windows[key]
        if win and win.visible then
            topVisible = key
            break
        end
    end
    -- Only draw if the top visible window key matches the last window drawn.
    if TimMenu.LastWindowDrawnKey and TimMenu.LastWindowDrawnKey == topVisible then
        for i = 1, #TimMenu.order do
            local key = TimMenu.order[i]
            local win = TimMenu.windows[key]
            if win and win.visible then
                local success, err = pcall(TimMenu.DrawWindow, win)
                if not success then
                    print("Error drawing window " .. key .. ": " .. err)
                end
            end
        end
    end
    return
end

--- Draws the window (its frame, title bar, and border) based on its stored position and size.
---@param win table
function TimMenu.DrawWindow(win)
    assert(win and type(win) == "table", "DrawWindow requires a window table")

    draw.Color(table.unpack(Static.Colors.Window or {30, 30, 30, 255}))
    draw.FilledRect(win.X, win.Y + Static.Defaults.TITLE_BAR_HEIGHT, win.X + win.W, win.Y + win.H)

    draw.Color(table.unpack(Static.Colors.Title or {55, 100, 215, 255}))
    draw.FilledRect(win.X, win.Y, win.X + win.W, win.Y + Static.Defaults.TITLE_BAR_HEIGHT)

    draw.SetFont(Static.Style.Font)
    local txtWidth, txtHeight = draw.GetTextSize(win.title)
    local titleX = Common.Clamp(win.X + (win.W - txtWidth) / 2)
    local titleY = Common.Clamp(win.Y + (Static.Defaults.TITLE_BAR_HEIGHT - txtHeight) / 2)
    draw.Color(table.unpack(Static.Colors.Text or {255, 255, 255, 255}))
    draw.Text(titleX, titleY, win.title)

    draw.Color(table.unpack(Static.Colors.WindowBorder or {55, 100, 215, 255}))
    draw.OutlinedRect(win.X, win.Y, win.X + win.W, win.Y + win.H)
end

--- Draws debug information about the currently registered windows.
--- (Optional: For debugging purposes.)
function TimMenu.ShowDebug()
    local currentFrame = globals.FrameCount()

    draw.SetFont(Static.Style.Font)
    draw.Color(255, 255, 255, 255)

    local headerX, headerY = 20, 20
    local lineSpacing = 20

    -- Count active windows.
    local count = 0
    for _ in pairs(TimMenu.windows) do
        count = count + 1
    end

    local headerText = "Active Windows (" .. tostring(count) .. "):"
    draw.Text(headerX, headerY, headerText)

    local yOffset = headerY + lineSpacing
    for key, win in pairs(TimMenu.windows) do
        local delay = currentFrame - (win.lastFrame or currentFrame)
        local info = "ID: " .. key .. " | Title: " .. win.title .. " (Delay: " .. tostring(delay) .. ")"
        draw.Text(headerX, yOffset, info)
        yOffset = yOffset + lineSpacing
    end
end

--------------------------------------------------------------------------------
-- Return the module table.
--------------------------------------------------------------------------------
return TimMenu
