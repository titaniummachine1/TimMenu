-- Main module for the TimMenu library
local TimMenu = {}

local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local Utils = require("TimMenu.Utils")
local Window = require("TimMenu.Window")

local lastkey = nil

-- Refresh function to clear loaded modules
function TimMenu.Refresh()
    package.loaded["TimMenu"] = nil
end

local function Setup()
    TimMenu.Refresh()

    if not TimMenuGlobal then
        -- Initialize TimMenu
        TimMenuGlobal = {}
        TimMenuGlobal.windows = {}
        setmetatable(TimMenuGlobal.windows, { __mode = "v" }) -- weak values so unused windows are gc'd
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
    TimMenu.Refresh()
    assert(type(title) == "string", "TimMenu.Begin requires a string title")
    visible = (visible == nil) and true or visible
    if type(visible) == "string" then id, visible = visible, true end
    local key = (id or title)
    lastkey = key --keep for last draw check

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

        -- Handle mouse interaction
        local mX, mY = table.unpack(input.GetMousePos())
        local titleHeight = Globals.Defaults.TITLE_BAR_HEIGHT

        local topKey = Utils.GetWindowUnderMouse(TimMenuGlobal.order, TimMenuGlobal.windows, mX, mY, titleHeight)
        if topKey == key then
            if input.IsButtonPressed(MOUSE_LEFT) then
                -- Move window to end of order (top)
                local index = table.find(TimMenuGlobal.order, key)
                if index then
                    table.remove(TimMenuGlobal.order, index)
                    table.insert(TimMenuGlobal.order, key)
                end

                -- If clicked in title bar, start dragging
                if mY <= win.Y + titleHeight then
                    win.IsDragging = true
                    win.DragPos = { X = mX - win.X, Y = mY - win.Y }
                    TimMenuGlobal.CapturedWindow = key
                end
            end
        end

        -- Handle dragging
        if TimMenuGlobal.CapturedWindow == key and win.IsDragging then
            win.X = mX - win.DragPos.X
            win.Y = mY - win.DragPos.Y

            -- Stop dragging when mouse released
            if input.IsButtonReleased(MOUSE_LEFT) then
                win.IsDragging = false
                TimMenuGlobal.CapturedWindow = nil
            end
        end
    end

    return win
end

--- Ends the current window.
function TimMenu.End()
    --proly need to be executed by each window in case 9/10 failed
    Utils.PruneOrphanedWindows(TimMenuGlobal.windows, TimMenuGlobal.order)

    --if this window is last in order then draw windows
    if lastkey ~= TimMenuGlobal.order[#TimMenuGlobal.order] then
        return
    end

    -- Draw all visible windows in order (bottom to top)
    for i = 1, #TimMenuGlobal.order do
        local key = TimMenuGlobal.order[i]
        local win = TimMenuGlobal.windows[key]
        if win and win.visible then
            win:draw()
        end
    end
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
