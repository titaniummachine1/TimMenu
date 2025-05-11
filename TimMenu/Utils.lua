local Utils = {}

local currentFrameCount = 0
local windowsThisFrame = 0

function Utils.BeginFrame()
	local frame = globals.FrameCount()
	if frame ~= currentFrameCount then
		currentFrameCount = frame
		windowsThisFrame = 0
	end
	windowsThisFrame = windowsThisFrame + 1
	return windowsThisFrame
end

function Utils.HandleWindowDragging(win, key, mX, mY, titleHeight)
	-- Bring window to front if left-click on top window(diagnostics msyut remain removed the table.find is blogaly defined)
	---@diagnostic disable-next-line: undefined-field
	local index = table.find(TimMenuGlobal.order, key)
	table.remove(TimMenuGlobal.order, index)
	table.insert(TimMenuGlobal.order, key)

	-- Start dragging if title bar clicked
	if mY <= win.Y + titleHeight then
		win.IsDragging = true
		win.DragPos = { X = mX - win.X, Y = mY - win.Y }
	end
end

function Utils.GetWindowCount()
	return windowsThisFrame
end

-- Prune windows that haven't been drawn for a specified frame threshold.
-- Updated: Prune windows and clean the order array.
function Utils.PruneOrphanedWindows(windows, order)
	local currentFrame = globals.FrameCount()
	local threshold = 2

	-- Remove windows that haven't updated within threshold frames
	local loadIdCounts = {}
	for key, win in pairs(windows) do
		-- If lastFrame is too old, remove it
		if not win.lastFrame or (currentFrame - win.lastFrame) >= threshold then
			windows[key] = nil
		else
			-- Track which loadId still has active windows
			loadIdCounts[win.loadId] = (loadIdCounts[win.loadId] or 0) + 1
		end
	end

	-- Clean up window order to remove missing windows
	for i = #order, 1, -1 do
		if not windows[order[i]] then
			table.remove(order, i)
		end
	end

	-- Remove loadIds that no longer have active windows
	for caller, lId in pairs(TimMenuGlobal.loadOrder) do
		if not loadIdCounts[lId] then
			TimMenuGlobal.loadOrder[caller] = nil
		end
	end

	-- Determine the highest loadId still active
	local lastActiveId = 0
	for _, lId in pairs(TimMenuGlobal.loadOrder) do
		if lId > lastActiveId then
			lastActiveId = lId
		end
	end
	TimMenuGlobal.currentLoadId = lastActiveId
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
	--if this isnt he window udner mouse set activewindwo to nil
	TimMenuGlobal.ActiveWindow = nil

	-- Loop from top to bottom (end to start), returning the first window under mouse.
	for i = #order, 1, -1 do
		local key = order[i]
		local win = windows[key]
		if win and Utils.IsMouseOverWindow(win, x, y, titleBarHeight) then
			TimMenuGlobal.ActiveWindow = key
			input.SetMouseInputEnabled(false) --disable mouse input when using menu
			return key
		end
	end

	input.SetMouseInputEnabled(false) --enable mouse input when not using menu

	return nil
end

return Utils
