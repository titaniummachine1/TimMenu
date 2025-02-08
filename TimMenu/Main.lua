-- A lightweight multi-window library.

local Common = require("TimMenu.Common")
local Static = require("TimMenu.Static")
local Utils  = require("TimMenu.Utils")

TimMenu = TimMenu or {}
TimMenu.windows = TimMenu.windows or {}
TimMenu.order   = TimMenu.order or {} -- Window order: bottom-first, top-last
TimMenu.CapturedWindow = TimMenu.CapturedWindow or nil

function TimMenu.Refresh()
    package.loaded["TimMenu"] = nil
end
TimMenu.Refresh()

--------------------------------------------------------------------------------
-- API Functions
--------------------------------------------------------------------------------

--- Begins a new or updates an existing window.
--- @param title string Window title.
--- @param visible? boolean Whether the window is visible (default: true).
--- @param id? string|number Unique identifier (default: title).
--- @return boolean, table Visible flag and the window table.
function TimMenu.Begin(title, visible, id)
    assert(type(title) == "string", "TimMenu.Begin requires a string title")
    visible = (visible == nil) and true or visible
    if type(visible) == "string" then id, visible = visible, true end
    local key = (id or title)
    if type(key) ~= "string" then key = tostring(key) end

    local currentFrame = globals.FrameCount()
    Utils.PruneOrphanedWindows(TimMenu.windows, currentFrame, 2)

    local win = TimMenu.windows[key]
    if not win then
        win = {
            title   = title,
            id      = key,
            visible = visible,
            X       = Static.Defaults.DEFAULT_X,
            Y       = Static.Defaults.DEFAULT_Y,
            W       = Static.Defaults.DEFAULT_W,
            H       = Static.Defaults.DEFAULT_H,
        }
        TimMenu.windows[key] = win
        table.insert(TimMenu.order, key)
    else
        win.visible = visible
    end

    if visible then
        if (gui.GetValue("clean screenshots") == 1 and not engine.IsTakingScreenshot()) then
            win.lastFrame = currentFrame
            win.X = Common.Clamp(win.X)
            win.Y = Common.Clamp(win.Y)
            TimMenu.LastWindowDrawnKey = key
        end

        local screenWidth, screenHeight = draw.GetScreenSize()
        local titleText = win.title
        draw.SetFont(Static.Style.Font)
        local txtWidth, txtHeight = draw.GetTextSize(titleText)
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
            Common.HandleWindowDrag(win, Static.Defaults.TITLE_BAR_HEIGHT, screenWidth, screenHeight)
        end
    end

    return visible, win
end

--- Ends the current window.
--- Draws all visible windows if the top visible window matches the latest drawn.
function TimMenu.End()
    if not input.IsButtonDown(MOUSE_LEFT) then
        TimMenu.CapturedWindow = nil
    end
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
                local success, err = pcall(TimMenu.DrawWindow, win)
                if not success then
                    print("Error drawing window " .. key .. ": " .. err)
                end
            end
        end
    end
end

--- Renders the given window.
--- @param win table Window object.
function TimMenu.DrawWindow(win)
    assert(win and type(win) == "table", "DrawWindow requires a window table")
    draw.Color(table.unpack(Static.Colors.Window or {30,30,30,255}))
    draw.FilledRect(win.X, win.Y + Static.Defaults.TITLE_BAR_HEIGHT, win.X + win.W, win.Y + win.H)

    draw.Color(table.unpack(Static.Colors.Title or {55,100,215,255}))
    draw.FilledRect(win.X, win.Y, win.X + win.W, win.Y + Static.Defaults.TITLE_BAR_HEIGHT)

    draw.SetFont(Static.Style.Font)
    local txtWidth, txtHeight = draw.GetTextSize(win.title)
    local titleX = Common.Clamp(win.X + (win.W - txtWidth) / 2)
    local titleY = Common.Clamp(win.Y + (Static.Defaults.TITLE_BAR_HEIGHT - txtHeight) / 2)
    draw.Color(table.unpack(Static.Colors.Text or {255,255,255,255}))
    draw.Text(titleX, titleY, win.title)

    draw.Color(table.unpack(Static.Colors.WindowBorder or {55,100,215,255}))
    draw.OutlinedRect(win.X, win.Y, win.X + win.W, win.Y + win.H)
end

--- Displays debug information about active windows.
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

return TimMenu
