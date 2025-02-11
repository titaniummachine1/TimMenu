local Utils = {}

-- Prune windows that haven't been drawn for a specified frame threshold.
-- Updated: Prune windows and clean the order array.
function Utils.PruneOrphanedWindows(windows, order)
    local threshold = 2
    local currentFrame = globals.FrameCount()
    for key, win in pairs(windows) do
        if not win.lastFrame or (currentFrame - win.lastFrame) >= threshold then
            windows[key] = nil
        end
    end
    -- Clean the order array by removing keys without corresponding windows.
    if order then
        for i = #order, 1, -1 do
            local key = order[i]
            if not windows[key] then
                table.remove(order, i)
            end
        end
    end
end

function Utils.IsMouseOverWindow(win, mouseX, mouseY, titleHeight)
    return mouseX >= win.X
       and mouseX <= win.X + win.W
       and mouseY >= win.Y
       and mouseY <= win.Y + win.H + titleHeight
end

-- Returns the top window key at a given point.
function Utils.GetWindowUnderMouse(order, windows, x, y, titleBarHeight)
    -- Loop from top to bottom (end to start), returning the first window under mouse.
    for i = #order, 1, -1 do
        local key = order[i]
        local win = windows[key]
        if win and Utils.IsMouseOverWindow(win, x, y, titleBarHeight) then
            return key
        end
    end
    return nil
end

return Utils
