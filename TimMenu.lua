-- TimMenu.lua
-- A simple library for multi-window integration with automatic cleanup.
-- Usage: Simply call TimMenu.Begin("Title", [uniqueID]) and TimMenu.End() in your Draw callback.
-- Windows that are not drawn for 5 frames are automatically removed.
-- If you start drawing a window again, it reappears.
--
-- Optionally unload lnxLib if needed (ensuring a fresh copy)
if UnloadLib then
    UnloadLib()
end

-- Import lnxLib
---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
assert(lnxLib.GetVersion() >= 1.000, "lnxLib version is too old, please update it!")

local Fonts   = lnxLib.UI.Fonts
local Notify  = lnxLib.UI.Notify
local KeyHelper = lnxLib.Utils.KeyHelper
local Input   = lnxLib.Utils.Input
local Timer   = lnxLib.Utils.Timer

-- Create the module table.
TimMenu = TimMenu or {}
-- Windows are stored as a table keyed by a unique ID.
TimMenu.windows = TimMenu.windows or {}

-- Refresh method to force reloading this module if needed.
function TimMenu.Refresh()
    package.loaded["TimMenu"] = nil
end
TimMenu.Refresh() -- Refresh if run manually

-- Set a default font for drawing text.
local defaultFont = Fonts.Verdana or draw.CreateFont("Verdana", 15, 500)

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

--- Begins a window with the given title and optional unique ID.
--- If no ID is provided, the title is used as the key.
---@param title string
---@param id? any  Optional unique identifier (string or number); will be converted to string.
---@return boolean true if the window is (re)opened, and the window table.
function TimMenu.Begin(title, id)
    assert(type(title) == "string", "TimMenu.Begin requires a string title")
    local key = id or title
    if type(key) ~= "string" then key = tostring(key) end

    -- Prune any orphaned windows first.
    PruneOrphanedWindows()

    local currentFrame = globals.FrameCount()
    local win = TimMenu.windows[key]
    if not win then
        win = { title = title, id = key }
        TimMenu.windows[key] = win
    end
    -- Update the window's last drawn frame.
    win.lastFrame = currentFrame
    return true, win
end

--- Ends the current window.
function TimMenu.End()
    -- Placeholder: add any finishing logic here if needed.
end

--- Draws debug information about the currently registered windows.
--- (Optional: For debugging purposes.)
function TimMenu.ShowDebug()
    local currentFrame = globals.FrameCount()

    draw.SetFont(defaultFont)
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
-- Unload Callback: Clean up the module on unload.
--------------------------------------------------------------------------------
local function OnUnload()
    package.loaded["TimMenu"] = nil
end

callbacks.Unregister("Unload", "TimMenu_Unload")
callbacks.Register("Unload", "TimMenu_Unload", OnUnload)

--------------------------------------------------------------------------------
-- Return the module table.
--------------------------------------------------------------------------------
return TimMenu
