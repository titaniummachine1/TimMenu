local Utils = {}

function Utils.PruneOrphanedWindows(windows, order)
	local currentFrame = globals.FrameCount()
	local threshold = 2
	for key, win in pairs(windows) do
		if not win.lastFrame or (currentFrame - win.lastFrame) >= threshold then
			windows[key] = nil
		end
	end
	for i = #order, 1, -1 do
		if not windows[order[i]] then
			table.remove(order, i)
		end
	end
end

function Utils.IsMouseOverWindow(win, mouseX, mouseY, titleHeight)
	return mouseX >= win.X and mouseX <= win.X + win.W and mouseY >= win.Y and mouseY <= win.Y + win.H
end

function Utils.IsPointBlocked(order, windows, x, y, currentWindowKey)
	local foundCurrent = false
	for i = #order, 1, -1 do
		local key = order[i]
		if key == currentWindowKey then
			foundCurrent = true
			break
		end
		local win = windows[key]
		if win and win.visible and Utils.IsMouseOverWindow(win, x, y, win.H) then
			return true
		end
	end
	return false
end

function Utils.GetWindowUnderMouse(order, windows, x, y, titleBarHeight)
	for i = #order, 1, -1 do
		local key = order[i]
		local win = windows[key]
		if win and Utils.IsMouseOverWindow(win, x, y, titleBarHeight) then
			input.SetMouseInputEnabled(false)
			return key
		end
	end
	input.SetMouseInputEnabled(false)
	return nil
end

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
