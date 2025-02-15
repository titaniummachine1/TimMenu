-- Main module for the TimMenu library
local TimMenu = {}

local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local Utils = require("TimMenu.Utils")
local Window = require("TimMenu.Window")
local Widgets = require("TimMenu.Widgets") -- new require

local function Setup()
    -- Initialize TimMenu
    TimMenuGlobal = {}
    TimMenuGlobal.windows = {}
    TimMenuGlobal.order = {}
    TimMenuGlobal.loadOrder = {}          -- Track which script loaded windows in what order
    TimMenuGlobal.currentLoadId = 0       -- Current script's load ID
    TimMenuGlobal.ActiveWindow = nil      -- track the window under mouse
    TimMenuGlobal.lastWindowKey = nil     -- to store the last started window
end

Setup()

--- Begins a new or updates an existing window.
--- @param title string Window title.
--- @param visible? boolean Whether the window is visible (default: true).
--- @param id? string|number Unique identifier (default: title).
--- @return boolean, table? (if false, window is either not visible or a screenshot is being taken)
function TimMenu.Begin(title, visible, id)
    -- Track new script loads
    local caller = debug.getinfo(2, "S").source
    local loadId = TimMenuGlobal.loadOrder[caller]
    if not loadId then
        TimMenuGlobal.currentLoadId = TimMenuGlobal.currentLoadId + 1
        loadId = TimMenuGlobal.currentLoadId
        TimMenuGlobal.loadOrder[caller] = loadId
    end

    local windowCallIndex = Utils.BeginFrame()

    assert(type(title) == "string", "TimMenu.Begin requires a string title")
    visible = (visible == nil) and true or visible
    if type(visible) == "string" then id, visible = visible, true end
    local key = (id or title)
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
        win.loadId = loadId
        TimMenuGlobal.windows[key] = win
        table.insert(TimMenuGlobal.order, key)
    else
        win.visible = visible
    end

    -- Update window properties
    win:update()

    -- Set the current window key for widget calls (ensures correct window context)
    TimMenuGlobal.lastWindowKey = key

    -- Return false if window is not visible or if a screenshot is being taken
    if not visible or (gui.GetValue("clean screenshots") == 1 and engine.IsTakingScreenshot()) then
        return false
    end

    -- Handle window interaction
    local mX, mY = table.unpack(input.GetMousePos())
    local titleHeight = Globals.Defaults.TITLE_BAR_HEIGHT

    -- Only check for new window interaction if we're not already dragging
    if not win.IsDragging then
        local isTopWindow = Utils.GetWindowUnderMouse(TimMenuGlobal.order, TimMenuGlobal.windows, mX, mY, titleHeight) ==
        key

        if isTopWindow and input.IsButtonPressed(MOUSE_LEFT) then
            Utils.HandleWindowDragging(win, key, mX, mY, titleHeight)
        end
    end

    -- Update window position while dragging - don't check if mouse is over window
    if win.IsDragging then
        win.X = mX - win.DragPos.X
        win.Y = mY - win.DragPos.Y
        -- Keep window as active while dragging
        TimMenuGlobal.ActiveWindow = key
    end

    -- Stop dragging only on mouse release
    if win.IsDragging and input.IsButtonReleased(MOUSE_LEFT) then
        win.IsDragging = false
        -- Recheck which window is under mouse after stopping drag
        TimMenuGlobal.ActiveWindow = Utils.GetWindowUnderMouse(TimMenuGlobal.order, TimMenuGlobal.windows, mX, mY,
            titleHeight)
    end

    -- Reset widget layout counters each frame using content padding.
    local padding = Globals.Defaults.WINDOW_CONTENT_PADDING
    win.cursorX = padding
    win.cursorY = Globals.Defaults.TITLE_BAR_HEIGHT + padding
    win.lineHeight = 0

    return true, win
end

--- Ends the current window and triggers drawing of all visible windows.
function TimMenu.End()
    assert(TimMenuGlobal, "TimMenuGlobal is nil in End()")

    -- Always try to prune - Utils.PruneOrphanedWindows will check if we should
    Utils.PruneOrphanedWindows(TimMenuGlobal.windows, TimMenuGlobal.order)

    -- Only draw if this script's loadId matches TimMenuGlobal.currentLoadId
    local caller = debug.getinfo(2, "S").source
    local myLoadId = TimMenuGlobal.loadOrder[caller]
    if myLoadId and myLoadId == TimMenuGlobal.currentLoadId then
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
    if win then
        return Widgets.Button(win, label)
    end
    return false
end

--- Displays debug information.
function TimMenu.ShowDebug()
    local currentFrame = globals.FrameCount()
    draw.SetFont(Globals.Style.Font)
    draw.Color(255, 255, 255, 255)
    local headerX, headerY = 20, 20
    local lineSpacing = 20

    local count = 0
    for _ in pairs(TimMenuGlobal.windows) do
        count = count + 1
    end

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
