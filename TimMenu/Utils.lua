local lmbx = globals -- alias for Lmaobox API
local Utils = {}

function Utils.GetWindowCount()
	return windowsThisFrame
end

-- Prune windows that haven't been drawn for a specified frame threshold.
-- Updated: Prune windows and clean the order array.
function Utils.PruneOrphanedWindows(windows, order)
	-- Prune windows not updated in the last 2 frames
	local currentFrame = lmbx.FrameCount()
	local threshold = 2
	for key, win in pairs(windows) do
		if not win.lastFrame or (currentFrame - win.lastFrame) >= threshold then
			windows[key] = nil
		end
	end
	-- Clean up window order to remove missing windows
	for i = #order, 1, -1 do
		if not windows[order[i]] then
			table.remove(order, i)
		end
	end
end

function Utils.IsMouseOverWindow(win, mouseX, mouseY, titleHeight)
	return mouseX >= win.X and mouseX <= win.X + win.W and mouseY >= win.Y and mouseY <= win.Y + win.H
end

-- Add new function to check if a point is blocked by any window above
function Utils.IsPointBlocked(order, windows, x, y, currentWindowKey)
	-- Check all windows above current window in z-order
	local foundCurrent = false
	for i = #order, 1, -1 do
		local key = order[i]
		if key == currentWindowKey then
			foundCurrent = true
			break
		end
		local win = windows[key]
		if win and win.visible and Utils.IsMouseOverWindow(win, x, y, win.H) then
			return true -- Point is blocked by a window above
		end
	end
	return false
end

-- Returns the top window key at a given point.
function Utils.GetWindowUnderMouse(order, windows, x, y, titleBarHeight)
	-- Return the first (topmost) window under the point
	for i = #order, 1, -1 do
		local key = order[i]
		local win = windows[key]
		if win and Utils.IsMouseOverWindow(win, x, y, titleBarHeight) then
			input.SetMouseInputEnabled(false) -- disable game UI
			return key
		end
	end

	input.SetMouseInputEnabled(false) -- enable game UI

	return nil
end

-- Click consumption: returns true once per press until release
local clickConsumed = false
function Utils.ConsumeClick()
	if input.IsButtonPressed(MOUSE_LEFT) and not clickConsumed then
		clickConsumed = true
		return true
	elseif not input.IsButtonDown(MOUSE_LEFT) then
		clickConsumed = false
	end
	return false
end

--- Retrieve or initialize a per-window widget state by unique key.
---@param win table Window object
---@param key string Unique identifier for the widget instance
---@param default any Default value or table to use if state not present
---@return any the state stored for this key
function Utils.GetState(win, key, default)
	win._widgetStates = win._widgetStates or {}
	local entry = win._widgetStates[key]
	if entry == nil then
		if type(default) == "table" then
			entry = {}
			for k, v in pairs(default) do
				entry[k] = v
			end
		else
			entry = default
		end
		win._widgetStates[key] = entry
	end
	return entry
end

return Utils
