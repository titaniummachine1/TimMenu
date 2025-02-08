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
    local threshold = 5  -- Maximum number of frames a window can go without being drawn.
    for key, win in pairs(TimMenu.windows) do
        if not win.lastFrame or (currentFrame - win.lastFrame) >= threshold then
            TimMenu.windows[key] = nil
        end
    end
end

--------------------------------------------------------------------------------
--[[ TimMenu API Functions ]]
--------------------------------------------------------------------------------

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
    if visible == nil then visible = true end

    local key = id or title
    if type(key) ~= "string" then key = tostring(key) end

    -- Prune any orphaned windows first.
    PruneOrphanedWindows()

    local currentFrame = globals.FrameCount()
    local win = TimMenu.windows[key]
    if not win then
        -- Create a new window with default position and size.
        win = {
            title = title,
            id = key,
            visible = visible,
            x = Static.Defaults.DEFAULT_X,
            y = Static.Defaults.DEFAULT_Y,
            w = Static.Defaults.DEFAULT_W,
            h = Static.Defaults.DEFAULT_H,
        }
        TimMenu.windows[key] = win
    else
        -- Update the visible flag.
        win.visible = visible
    end

    if visible then
        -- Update the window's last drawn frame.
        win.lastFrame = currentFrame
        -- Clamp window positions to the screen bounds.
        local screenWidth, screenHeight = draw.GetScreenSize()
        win.x = Common.Clamp(win.x, 0)
        win.y = Common.Clamp(win.y, 0)
        -- Draw the window.
        TimMenu.DrawWindow(win)
    end

    return visible, win
end

--- Ends the current window.
function TimMenu.End()
    -- Placeholder for additional finishing logic if needed.
end

--- Draws the window (its frame, title bar, and border) based on its stored position and size.
---@param win table
function TimMenu.DrawWindow(win)
    assert(win and type(win) == "table", "DrawWindow requires a window table")

    -- Draw window background using Static.Colors.Window.
    draw.Color(table.unpack(Static.Colors.Window or {30, 30, 30, 255}))
    draw.FilledRect(win.x, win.y + Static.Defaults.TITLE_BAR_HEIGHT, win.x + win.w, win.y + win.h)

    -- Draw title bar background using Static.Colors.Title.
    draw.Color(table.unpack(Static.Colors.Title or {55, 100, 215, 255}))
    draw.FilledRect(win.x, win.y, win.x + win.w, win.y + Static.Defaults.TITLE_BAR_HEIGHT)

    -- Draw title text centered using Static.Colors.Text.
    draw.SetFont(Static.Style.Font)
    local txtWidth, txtHeight = draw.GetTextSize(win.title)
    local titleX = Common.Clamp(win.x + (win.w - txtWidth) / 2)
    local titleY = Common.Clamp(win.y + (Static.Defaults.TITLE_BAR_HEIGHT - txtHeight) / 2)
    draw.Color(table.unpack(Static.Colors.Text or {255, 255, 255, 255}))
    draw.Text(titleX, titleY, win.title)

    -- Draw window border using Static.Colors.WindowBorder.
    draw.Color(table.unpack(Static.Colors.WindowBorder or {55, 100, 215, 255}))
    draw.OutlinedRect(win.x, win.y, win.x + win.w, win.y + win.h)
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
