local DrawManager = { queue = {}, _nextSeq = 0 }

--- Enqueue a draw call under a given window and layer
---@param windowId string the ID of the window
---@param layer number draw layer for ordering
---@param fn function the draw function
---@param ... any additional arguments for fn
function DrawManager.Enqueue(windowId, layer, fn, ...)
	-- assign a sequence for stable ordering among same-layer entries
	DrawManager._nextSeq = DrawManager._nextSeq + 1
	table.insert(DrawManager.queue, {
		windowId = windowId,
		layer = layer,
		fn = fn,
		args = { ... },
		seq = DrawManager._nextSeq,
	})
end

--- Flush all queued draw calls in proper back-to-front order
---@param zOrder table an array of window IDs in z-order (back to front)
function DrawManager.Flush(zOrder)
	-- Sort by window z-order then layer, then by insertion sequence to avoid z-fighting
	table.sort(DrawManager.queue, function(a, b)
		local za, zb
		for i, id in ipairs(zOrder) do
			if id == a.windowId then
				za = i
			end
			if id == b.windowId then
				zb = i
			end
		end
		if za ~= zb then
			return za < zb
		end
		if a.layer ~= b.layer then
			return a.layer < b.layer
		end
		return a.seq < b.seq
	end)

	-- Execute all draw functions
	for _, entry in ipairs(DrawManager.queue) do
		entry.fn(table.unpack(entry.args))
	end

	-- Clear queue for next frame
	DrawManager.queue = {}
end

--- Flush queued draw calls for a single window, sorted by layer
---@param windowId string the ID of the window to flush
function DrawManager.FlushWindow(windowId)
	local keep = {}
	local toFlush = {}
	-- Separate entries for this window
	for _, entry in ipairs(DrawManager.queue) do
		if entry.windowId == windowId then
			table.insert(toFlush, entry)
		else
			table.insert(keep, entry)
		end
	end
	-- Sort this window's entries by layer (with sequence tiebreak)
	table.sort(toFlush, function(a, b)
		if a.layer ~= b.layer then
			return a.layer < b.layer
		end
		return a.seq < b.seq
	end)
	-- Execute draw calls for this window
	for _, entry in ipairs(toFlush) do
		entry.fn(table.unpack(entry.args))
	end
	-- Retain entries for other windows
	DrawManager.queue = keep
end

return DrawManager
