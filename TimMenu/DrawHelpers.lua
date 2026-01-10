local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")
local ShapeUtils = require("TimMenu.ShapeUtils")

--[[ Imported by: Widgets, TabControl, etc. ]]
--

local DrawHelpers = {}

----------------------------------------------------
-- DrawArrow : draws a simple filled arrow (up, down, left, or right)
-- absX, absY : top-left corner of bounding box
-- w, h       : width / height of bounding box
-- direction  : "up" | "down" | "left" | "right"
-- colorTbl   : {r,g,b,a}
----------------------------------------------------
function DrawHelpers.DrawArrow(absX, absY, w, h, direction, colorTbl)
	Common.SetColor(colorTbl or Globals.Colors.Text)

	if direction == "up" then
		Common.DrawLine(absX, absY + h, absX + w / 2, absY) -- /\ left edge
		Common.DrawLine(absX + w / 2, absY, absX + w, absY + h) -- /\ right edge
	elseif direction == "down" then
		Common.DrawLine(absX, absY, absX + w / 2, absY + h) -- \/ left edge
		Common.DrawLine(absX + w / 2, absY + h, absX + w, absY) -- \/ right edge
	elseif direction == "left" then
		Common.DrawLine(absX + w, absY, absX, absY + h / 2) -- < top edge
		Common.DrawLine(absX, absY + h / 2, absX + w, absY + h) -- < bottom edge
	elseif direction == "right" then
		Common.DrawLine(absX, absY, absX + w, absY + h / 2) -- > top edge
		Common.DrawLine(absX + w, absY + h / 2, absX, absY + h) -- > bottom edge
	end
end

----------------------------------------------------
-- DrawLabeledBox : draws a filled rect with border + centered label
----------------------------------------------------
function DrawHelpers.DrawLabeledBox(absX, absY, w, h, label, bgCol, borderCol)
	Common.SetColor(bgCol or Globals.Colors.Item)
	Common.DrawFilledRect(absX, absY, absX + w, absY + h)

	Common.SetColor(borderCol or Globals.Colors.WindowBorder)
	Common.DrawOutlinedRect(absX, absY, absX + w, absY + h)

	Common.SetColor(Globals.Colors.Text)
	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(label)
	Common.DrawText(absX + (w - txtW) / 2, absY + (h - txtH) / 2, label)
end

----------------------------------------------------
-- DrawRoundedRect : draws a rounded rectangle
-- absX, absY : top-left corner
-- w, h       : width / height
-- radius     : corner radius
-- colorTbl   : {r,g,b,a}
----------------------------------------------------
function DrawHelpers.DrawRoundedRect(absX, absY, w, h, radius, colorTbl)
	radius = math.min(radius, math.min(w, h) / 2) -- Clamp radius

	Common.SetColor(colorTbl or Globals.Colors.Item)

	-- Draw central rectangle (excluding corners)
	if w > radius * 2 and h > radius * 2 then
		Common.DrawFilledRect(absX + radius, absY, absX + w - radius, absY + h)
		Common.DrawFilledRect(absX, absY + radius, absX + w, absY + h - radius)
	end

	-- Draw corner circles using line approximation
	local corners = {
		{ cx = absX + radius, cy = absY + radius }, -- Top-left
		{ cx = absX + w - radius, cy = absY + radius }, -- Top-right
		{ cx = absX + radius, cy = absY + h - radius }, -- Bottom-left
		{ cx = absX + w - radius, cy = absY + h - radius }, -- Bottom-right
	}

	for _, corner in ipairs(corners) do
		DrawHelpers.DrawFilledCircle(corner.cx, corner.cy, radius)
	end
end

----------------------------------------------------
-- DrawFilledCircle : draws a filled circle using line approximation
-- cx, cy     : center coordinates
-- radius     : circle radius
----------------------------------------------------
function DrawHelpers.DrawFilledCircle(cx, cy, radius)
	-- Simple approximation using horizontal lines
	for y = -radius, radius do
		local x = math.sqrt(radius * radius - y * y)
		Common.DrawLine(cx - x, cy + y, cx + x, cy + y)
	end
end

----------------------------------------------------
-- DrawRoundedRectOutline : draws outline of rounded rectangle
-- absX, absY : top-left corner
-- w, h       : width / height
-- radius     : corner radius
-- colorTbl   : {r,g,b,a}
----------------------------------------------------
function DrawHelpers.DrawRoundedRectOutline(absX, absY, w, h, radius, colorTbl)
	radius = math.min(radius, math.min(w, h) / 2) -- Clamp radius

	Common.SetColor(colorTbl or Globals.Colors.WindowBorder)

	-- Draw edge lines (excluding corners)
	if w > radius * 2 then
		Common.DrawLine(absX + radius, absY, absX + w - radius, absY) -- Top
		Common.DrawLine(absX + radius, absY + h, absX + w - radius, absY + h) -- Bottom
	end
	if h > radius * 2 then
		Common.DrawLine(absX, absY + radius, absX, absY + h - radius) -- Left
		Common.DrawLine(absX + w, absY + radius, absX + w, absY + h - radius) -- Right
	end

	-- Draw corner arcs using line approximation
	local corners = {
		{ cx = absX + radius, cy = absY + radius, startAngle = math.pi, endAngle = math.pi * 1.5 }, -- Top-left
		{ cx = absX + w - radius, cy = absY + radius, startAngle = math.pi * 1.5, endAngle = 0 }, -- Top-right
		{ cx = absX + radius, cy = absY + h - radius, startAngle = math.pi * 0.5, endAngle = math.pi }, -- Bottom-left
		{ cx = absX + w - radius, cy = absY + h - radius, startAngle = 0, endAngle = math.pi * 0.5 }, -- Bottom-right
	}

	for _, corner in ipairs(corners) do
		DrawHelpers.DrawArc(corner.cx, corner.cy, radius, corner.startAngle, corner.endAngle)
	end
end

----------------------------------------------------
-- DrawArc : draws an arc using line approximation
-- cx, cy     : center coordinates
-- radius     : arc radius
-- startAngle : starting angle in radians
-- endAngle   : ending angle in radians
----------------------------------------------------
function DrawHelpers.DrawArc(cx, cy, radius, startAngle, endAngle)
	local steps = math.max(8, math.floor(math.abs(endAngle - startAngle) * radius / 2))
	local angleStep = (endAngle - startAngle) / steps

	local prevX = cx + radius * math.cos(startAngle)
	local prevY = cy + radius * math.sin(startAngle)

	for i = 1, steps do
		local angle = startAngle + i * angleStep
		local x = cx + radius * math.cos(angle)
		local y = cy + radius * math.sin(angle)
		Common.DrawLine(prevX, prevY, x, y)
		prevX, prevY = x, y
	end
end

return DrawHelpers
