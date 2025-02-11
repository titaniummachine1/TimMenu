local Utils = {}

-- Prune windows that haven't been drawn for a specified frame threshold.
function Utils.PruneOrphanedWindows(windows)
    local threshold = 2
    local currentFrame = globals.FrameCount()
    for key, win in pairs(windows) do
        if not win.lastFrame or (currentFrame - win.lastFrame) >= threshold then
            windows[key] = nil
        end
    end
end

-- Returns the top window key at a given point.
function Utils.GetTopWindowAtPoint(order, windows, x, y, titleBarHeight)
    for i = #order, 1, -1 do
        local key = order[i]
        local win = windows[key]
        if win then
            local withinXBounds = x >= win.X and x <= win.X + win.W
            local withinYBounds = y >= win.Y and y <= win.Y + titleBarHeight
            if withinXBounds and withinYBounds then
                return key
            end
        end
    end
    return nil
end

return Utils
