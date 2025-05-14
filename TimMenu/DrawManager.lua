local DrawManager = { queue = {} }

--- Enqueue a draw call under a given window and layer
---@param windowId string the ID of the window
---@param layer number draw layer for ordering
---@param fn function the draw function
---@param ... any additional arguments for fn
function DrawManager.Enqueue(windowId, layer, fn, ...)
	table.insert(DrawManager.queue, {
		windowId = windowId,
		layer = layer,
		fn = fn,
		args = { ... },
	})
end

--- Flush all queued draw calls in proper back-to-front order
---@param zOrder table an array of window IDs in z-order (back to front)
function DrawManager.Flush(zOrder)
	-- Sort by window z-order then layer
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
		return a.layer < b.layer
	end)

	-- Execute all draw functions
	for _, entry in ipairs(DrawManager.queue) do
		entry.fn(table.unpack(entry.args))
	end

	-- Clear queue for next frame
	DrawManager.queue = {}
end

return DrawManager
