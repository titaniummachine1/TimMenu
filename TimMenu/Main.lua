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
    local key = id or title
    if type(key) ~= "string" then key = tostring(key) end

    local currentFrame = globals.FrameCount()

    -- Prune orphaned windows
    Utils.PruneOrphanedWindows(TimMenu.windows, currentFrame, 2)

    local win = TimMenu.windows[key]
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
        if (gui.GetValue("clean screenshots") == 1 and not engine.IsTakingScreenshot()) then
            win:update(currentFrame)
            TimMenu.LastWindowDrawnKey = key
        end

        local screenWidth, screenHeight = draw.GetScreenSize()
        draw.SetFont(Static.Style.Font)
        local txtWidth, txtHeight = draw.GetTextSize(win.title)
        local titleHeight = txtHeight + Static.Style.ItemPadding

        local mX, mY = table.unpack(input.GetMousePos())
        local topKey = Utils.GetTopWindowAtPoint(TimMenu.order, TimMenu.windows, mX, mY, Static.Defaults.TITLE_BAR_HEIGHT)
        if topKey == key then
            local hovered, clicked = Common.GetInteraction(win.X, win.Y, win.W, titleHeight)
            if clicked then
                win.IsDragging = false
                TimMenu.CapturedWindow = key
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
            win:handleDrag(screenWidth, screenHeight, Static.Defaults.TITLE_BAR_HEIGHT)
        end
    end

    return visible, win
end

--- Ends the current window.
function TimMenu.End()
    if not input.IsButtonDown(MOUSE_LEFT) then
        TimMenu.CapturedWindow = nil
    end

    -- Removed orphan cleanup loop since __close handles cleanup on unload.
    local topVisible = nil
    for i = #TimMenu.order, 1, -1 do
        local key = TimMenu.order[i]
        local win = TimMenu.windows[key]
        if win and win.visible then
            topVisible = key
            break
        end
    end
    if TimMenu.LastWindowDrawnKey and TimMenu.LastWindowDrawnKey == topVisible then
        for i = 1, #TimMenu.order do
            local key = TimMenu.order[i]
            local win = TimMenu.windows[key]
            if win and win.visible then
                local success, err = pcall(function() win:draw() end)
                if not success then
                    print("Error drawing window " .. key .. ": " .. err)
                end
            end
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
