-- Main module for the TimMenu library
local TimMenu = {}

package.loaded["TimMenu"] = nil

local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local Utils = require("TimMenu.Utils")
local Window = require("TimMenu.Window")
local Widgets = require("TimMenu.Widgets") -- new require

local function Setup()
    if not TimMenuGlobal then
        -- Initialize TimMenu
        TimMenuGlobal = {}
        TimMenuGlobal.windows = {}
        TimMenuGlobal.order = {}
        TimMenuGlobal.ActiveWindow = nil -- Add ActiveWindow to track which window is being hovered over
        TimMenuGlobal.lastWindowKey = nil
    end
end

-- Modified Refresh to preserve TimMenuGlobal
function TimMenu.Refresh()
    -- Don't clear TimMenu if it's already initialized
    TimMenuGlobal = nil
    package.loaded["TimMenu"] = nil
end

Setup()

--- Begins a new or updates an existing window.
--- @param title string Window title.
--- @param visible? boolean Whether the window is visible (default: true).
--- @param id? string|number Unique identifier (default: title).
--- @return table? window table.(if nil means it wasnt visible or taking screenshot)
function TimMenu.Begin(title, visible, id)
    if not visible or engine.IsTakingScreenshot() then
        return nil
    end

    --input parsing--
    assert(type(title) == "string", "TimMenu.Begin requires a string title")
    visible = (visible == nil) and true or visible
    if type(visible) == "string" then id, visible = visible, true end
    local key = (id or title)
    --input parsing--

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
        win.visible = visible
    end

    --keep this window alive from pruning--
    local currentFrame = globals.FrameCount()
    win.lastFrame = currentFrame

    -- Handle window interaction
    local mX, mY = table.unpack(input.GetMousePos())
    local titleHeight = Globals.Defaults.TITLE_BAR_HEIGHT
    local isTopWindow = Utils.GetWindowUnderMouse(TimMenuGlobal.order, TimMenuGlobal.windows, mX, mY, titleHeight) == key

    -- Handle window focus and dragging
    if isTopWindow and input.IsButtonPressed(MOUSE_LEFT) then
        -- Bring window to front
        local index = table.find(TimMenuGlobal.order, key) --index is known to exist in order

        table.remove(TimMenuGlobal.order, index) --remove from current position
        table.insert(TimMenuGlobal.order, key) --add to start of order

        -- Start dragging if clicked in title bar
        if mY <= win.Y + titleHeight then
            win.IsDragging = true
            win.DragPos = { X = mX - win.X, Y = mY - win.Y }
        end
    end

    -- Update window position while dragging
    if TimMenuGlobal.ActiveWindow == key and win.IsDragging then
        win.X = mX - win.DragPos.X
        win.Y = mY - win.DragPos.Y
    end

    -- Stop dragging on mouse release
    if win.IsDragging and input.IsButtonReleased(MOUSE_LEFT) then
        win.IsDragging = false
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

    -- Draw all windows when processing the last window
    if Utils.GetWindowCount() == #TimMenuGlobal.order then
        for i = 1, #TimMenuGlobal.order do
            local win = TimMenuGlobal.windows[TimMenuGlobal.order[i]]
            if win and win.visible then
                win:draw()
            end
        end
    end
end

--- Returns the current window (last drawn window).
function TimMenu.GetCurrentWindow()
    if TimMenuGlobal.lastWindowKey then
        return TimMenuGlobal.windows[TimMenuGlobal.lastWindowKey]
    end
end

--- Calls the Widgets.Button API on the current window.
--- Returns true if clicked.
function TimMenu.Button(label)
    local win = TimMenu.GetCurrentWindow()
    -- Only process button if we're in the correct window context
    if win and TimMenuGlobal.ActiveWindow == win.id then
        return Widgets.Button(win, label)
    end
    return false
end

--- Displays debug information...
function TimMenu.ShowDebug()
    local currentFrame = globals.FrameCount()
    draw.SetFont(Globals.Style.Font)
    draw.Color(255, 255, 255, 255)
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
