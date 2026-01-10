local ShapeUtils = {}

--- Point in rectangle test
---@param x number Point X coordinate
---@param y number Point Y coordinate
---@param rect table {x, y, w, h} Rectangle bounds
---@return boolean
function ShapeUtils.PointInRect(x, y, rect)
	return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

--- Point in rounded rectangle test
---@param x number Point X coordinate
---@param y number Point Y coordinate
---@param rect table {x, y, w, h} Rectangle bounds
---@param radius number Corner radius
---@return boolean
function ShapeUtils.PointInRoundedRect(x, y, rect, radius)
	if radius <= 0 then
		return ShapeUtils.PointInRect(x, y, rect)
	end

	-- Quick reject if outside bounding box
	if not ShapeUtils.PointInRect(x, y, rect) then
		return false
	end

	-- Check if point is in central rectangle (not near corners)
	local centralX = rect.x + radius
	local centralY = rect.y + radius
	local centralW = rect.w - (radius * 2)
	local centralH = rect.h - (radius * 2)

	if x >= centralX and x <= centralX + centralW and y >= centralY and y <= centralY + centralH then
		return true
	end

	-- Check corner circles
	local corners = {
		{ x = rect.x + radius, y = rect.y + radius }, -- Top-left
		{ x = rect.x + rect.w - radius, y = rect.y + radius }, -- Top-right
		{ x = rect.x + radius, y = rect.y + rect.h - radius }, -- Bottom-left
		{ x = rect.x + rect.w - radius, y = rect.y + rect.h - radius }, -- Bottom-right
	}

	for _, corner in ipairs(corners) do
		local dx = x - corner.x
		local dy = y - corner.y
		if dx * dx + dy * dy <= radius * radius then
			return true
		end
	end

	return false
end

--- Point in circle test
---@param x number Point X coordinate
---@param y number Point Y coordinate
---@param cx number Circle center X
---@param cy number Circle center Y
---@param radius number Circle radius
---@return boolean
function ShapeUtils.PointInCircle(x, y, cx, cy, radius)
	local dx = x - cx
	local dy = y - cy
	return dx * dx + dy * dy <= radius * radius
end

--- Point in ellipse test
---@param x number Point X coordinate
---@param y number Point Y coordinate
---@param cx number Ellipse center X
---@param cy number Ellipse center Y
---@param rx number Ellipse X radius
---@param ry number Ellipse Y radius
---@return boolean
function ShapeUtils.PointInEllipse(x, y, cx, cy, rx, ry)
	local dx = (x - cx) / rx
	local dy = (y - cy) / ry
	return dx * dx + dy * dy <= 1
end

--- Point in polygon test (ray casting algorithm)
---@param x number Point X coordinate
---@param y number Point Y coordinate
---@param vertices table Array of {x, y} points
---@return boolean
function ShapeUtils.PointInPolygon(x, y, vertices)
	local inside = false
	local n = #vertices

	if n < 3 then
		return false
	end

	local j = n
	for i = 1, n do
		local vi = vertices[i]
		local vj = vertices[j]

		if ((vi.y > y) ~= (vj.y > y)) and (x < (vj.x - vi.x) * (y - vi.y) / (vj.y - vi.y) + vi.x) then
			inside = not inside
		end
		j = i
	end

	return inside
end

--- Generic point in shape test
---@param x number Point X coordinate
---@param y number Point Y coordinate
---@param shape table Shape definition with type and data
---@return boolean
function ShapeUtils.PointInShape(x, y, shape)
	assert(shape and shape.type, "ShapeUtils.PointInShape: shape must have type")

	if shape.type == "rectangle" then
		return ShapeUtils.PointInRect(x, y, shape)
	elseif shape.type == "rounded_rect" then
		return ShapeUtils.PointInRoundedRect(x, y, shape, shape.radius or 0)
	elseif shape.type == "circle" then
		return ShapeUtils.PointInCircle(x, y, shape.cx, shape.cy, shape.radius)
	elseif shape.type == "ellipse" then
		return ShapeUtils.PointInEllipse(x, y, shape.cx, shape.cy, shape.rx, shape.ry)
	elseif shape.type == "polygon" then
		return ShapeUtils.PointInPolygon(x, y, shape.vertices)
	else
		error("ShapeUtils.PointInShape: Unknown shape type: " .. tostring(shape.type))
	end
end

return ShapeUtils
