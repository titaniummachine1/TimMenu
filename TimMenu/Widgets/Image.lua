local Interaction = require("TimMenu.Interaction")
local DrawManager = require("TimMenu.DrawManager")
local Globals = require("TimMenu.Globals")
local draw = draw

--- Draws a textured rectangle with hover/press/click handling and pixel lookup, allowing scaling.
--- @param win table Window object
--- @param tex any Texture identifier or table {texture,width,height,data}
--- @param targetW number optional draw width (default = image width)
--- @param targetH number optional draw height (default = image height)
--- @param data string optional raw RGBA data when tex is texture id
--- @return boolean hovered, boolean pressed, boolean clicked, number absX, number absY, number localX, number localY, number r, number g, number b, number a
local function Image(win, tex, targetW, targetH, data)
	assert(type(win) == "table", "Image: win must be a table")
	-- Determine source image and raw data
	local texture, sourceW, sourceH, raw
	if type(tex) == "table" and tex.texture then
		texture = tex.texture
		sourceW = tex.width
		sourceH = tex.height
		raw = tex.data
	else
		texture = tex
		sourceW = targetW
		sourceH = targetH
		raw = data
	end
	assert(texture, "Image: texture must not be nil")
	assert(type(sourceW) == "number" and type(sourceH) == "number", "Image: image width and height must be numbers")
	-- Target draw size
	local drawW = (targetW and type(targetW) == "number") and targetW or sourceW
	local drawH = (targetH and type(targetH) == "number") and targetH or sourceH

	-- Reserve layout space
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetKey = win.id .. ":Image:" .. win._widgetCounter
	local xRel, yRel = win:AddWidget(drawW, drawH)
	local absX, absY = win.X + xRel, win.Y + yRel

	-- Process interaction
	local hovered, pressed, clicked =
		Interaction.Process(win, widgetKey, { x = absX, y = absY, w = drawW, h = drawH }, false)

	-- Draw the (possibly scaled) image
	DrawManager.Enqueue(win.id, Globals.Layers.WidgetBackground, function()
		draw.Color(255, 255, 255, 255)
		draw.TexturedRect(texture, absX, absY, absX + drawW, absY + drawH)
	end)

	-- Mouse-local coordinates within drawn image
	local mx, my = table.unpack(input.GetMousePos())
	local localX = math.floor(mx - absX)
	local localY = math.floor(my - absY)

	-- Map to source pixel coordinates for lookup
	local r, g, b, a
	if raw and localX >= 0 and localY >= 0 and localX < drawW and localY < drawH then
		local srcX = math.floor(localX * sourceW / drawW)
		local srcY = math.floor(localY * sourceH / drawH)
		local idx = (srcY * sourceW + srcX) * 4 + 1
		r = string.byte(raw, idx)
		g = string.byte(raw, idx + 1)
		b = string.byte(raw, idx + 2)
		a = string.byte(raw, idx + 3)
	end

	return hovered, pressed, clicked, absX, absY, localX, localY, r, g, b, a
end

return Image
