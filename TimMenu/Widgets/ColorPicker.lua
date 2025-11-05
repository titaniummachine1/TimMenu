local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Utils = require("TimMenu.Utils")
local Interaction = require("TimMenu.Interaction")
local DrawHelpers = require("TimMenu.DrawHelpers")
local DrawManager = require("TimMenu.DrawManager")
local WidgetBase = require("TimMenu.WidgetBase")

-- HSV to RGB conversion
local function hsvToRGB(h, s, v)
	local r, g, b
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	i = i % 6
	if i == 0 then
		r, g, b = v, t, p
	elseif i == 1 then
		r, g, b = q, v, p
	elseif i == 2 then
		r, g, b = p, v, t
	elseif i == 3 then
		r, g, b = p, q, v
	elseif i == 4 then
		r, g, b = t, p, v
	elseif i == 5 then
		r, g, b = v, p, q
	end
	return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

-- RGB to HSV conversion
local function rgbToHSV(r, g, b)
	r, g, b = r / 255, g / 255, b / 255
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local h, s, v = 0, 0, max
	local delta = max - min
	if max ~= 0 then
		s = delta / max
	end
	if delta ~= 0 then
		if max == r then
			h = (g - b) / delta
			if g < b then
				h = h + 6
			end
		elseif max == g then
			h = (b - r) / delta + 2
		elseif max == b then
			h = (r - g) / delta + 4
		end
		h = h / 6
	end
	return h, s, v
end

local function ColorPicker(win, label, initColor)
	assert(type(win) == "table", "ColorPicker: win must be a table")
	assert(type(label) == "string", "ColorPicker: label must be a string")
	assert(
		type(initColor) == "table" and #initColor >= 3,
		"ColorPicker: initColor must be a table of at least 3 numbers"
	)

	-- Layout calculations
	draw.SetFont(Globals.Style.Font)
	local txtW, txtH = draw.GetTextSize(label)
	local padding = Globals.Style.ItemPadding
	local colorSize = Globals.Style.ItemSize
	local previewSize = colorSize + (padding * 2)
	local height = math.max(previewSize, txtH + (padding * 2))
	local arrowBoxW = height
	local width = previewSize + padding + txtW + padding + arrowBoxW

	local ctx = WidgetBase.Setup(win, "ColorPicker", label, width, height)
	local absX, absY = ctx.absX, ctx.absY

	-- State management
	local state = Utils.GetState(win, ctx.widgetKey, {
		open = false,
		hue = 0,
		sat = 0,
		initialized = false,
		color = { initColor[1], initColor[2], initColor[3], initColor[4] or 255 },
	})

	-- Initialize hue/saturation from initial color
	if not state.initialized then
		local h, s = rgbToHSV(state.color[1], state.color[2], state.color[3])
		state.hue = h
		state.sat = s
		state.initialized = true
	end

	-- Image data for color wheel (using the preloaded image)
	local imageData = Globals.Images.ColorPicker.Interactive
	local sliderHeight = 20
	local popupBounds = {
		x = absX,
		y = absY + height,
		w = imageData.width,
		h = imageData.height + sliderHeight,
	}

	-- Interaction
	local bounds = ctx.bounds
	local hovered, pressed, clicked = WidgetBase.ProcessInteraction(ctx, state.open)

	-- Maintain popup blocked regions while open
	if state.open then
		win._widgetBlockedRegions = { popupBounds }
	end

	-- Toggle popup on field click
	if clicked and hovered and not state.open then
		state.open = true
		-- Bring window to front
		for i, id in ipairs(TimMenuGlobal.order) do
			if id == win.id then
				table.remove(TimMenuGlobal.order, i)
				break
			end
		end
		table.insert(TimMenuGlobal.order, win.id)
	end

	if state.open then
		-- Pixel selection inside popup
		local mx, my = table.unpack(input.GetMousePos())
		local px = math.floor(mx - popupBounds.x)
		local py = math.floor(my - popupBounds.y)
		if
			px >= 0
			and py >= 0
			and px < imageData.width
			and py < imageData.height
			and input.IsButtonDown(MOUSE_LEFT)
		then
			local idx = (py * imageData.width + px) * 4 + 1
			local r = string.byte(imageData.data, idx)
			local g = string.byte(imageData.data, idx + 1)
			local b = string.byte(imageData.data, idx + 2)
			local a = string.byte(imageData.data, idx + 3)
			if a ~= 0 then
				state.color[1], state.color[2], state.color[3] = r, g, b
				state.selX, state.selY = px, py
			end
		end

		-- Alpha slider interaction
		local sliderBounds =
			{ x = popupBounds.x, y = popupBounds.y + imageData.height, w = popupBounds.w, h = sliderHeight }
		local _, sPressed = Interaction.Process(win, ctx.widgetKey .. ":alpha", sliderBounds, state.open)
		if sPressed then
			local mx2, _ = table.unpack(input.GetMousePos())
			local newA = math.floor(((mx2 - sliderBounds.x) / sliderBounds.w) * 255)
			state.color[4] = math.max(0, math.min(255, newA))
		end

		-- Close popup when mouse leaves both field and popup regions
		local mx3, my3 = TimMenuGlobal.mouseX, TimMenuGlobal.mouseY
		local inField = mx3 >= absX and mx3 <= absX + width and my3 >= absY and my3 <= absY + height
		local inPopup = mx3 >= popupBounds.x
			and mx3 <= popupBounds.x + popupBounds.w
			and my3 >= popupBounds.y
			and my3 <= popupBounds.y + popupBounds.h
		if not inField and not inPopup then
			state.open = false
			win._widgetBlockedRegions = {}
		end
	end

	-- Draw field
	local px, py = absX, absY
	local bg = Globals.Colors.Item
	if pressed then
		bg = Globals.Colors.ItemActive
	elseif hovered then
		bg = Globals.Colors.ItemHover
	end
	local mainW = width - arrowBoxW
	local arrowX = px + mainW
	local colorY = py + (height - colorSize) * 0.5
	local colorX = px + padding
	local colorX2 = colorX + colorSize
	Common.QueueRect(win, Globals.Layers.WidgetBackground, px, py, px + mainW, py + height, bg, nil)
	Common.QueueRect(
		win,
		Globals.Layers.WidgetBackground,
		arrowX,
		py,
		arrowX + arrowBoxW,
		py + height,
		Globals.Colors.ArrowBoxBg,
		nil
	)
	Common.QueueOutlinedRect(
		win,
		Globals.Layers.WidgetOutline,
		px,
		py,
		px + width,
		py + height,
		Globals.Colors.WindowBorder
	)

	-- Draw color preview
	Common.QueueRect(
		win,
		Globals.Layers.WidgetFill,
		colorX,
		colorY,
		colorX2,
		colorY + colorSize,
		state.color,
		nil
	)
	Common.QueueText(
		win,
		Globals.Layers.WidgetText,
		colorX2 + padding,
		py + (height - txtH) * 0.5,
		label,
		Globals.Colors.Text
	)

	-- Draw arrow
	draw.SetFont(Globals.Style.Font)
	local arrowCharW, arrowCharH = draw.GetTextSize("▼")
	local triW, triH = arrowCharW * 0.5, arrowCharH * 0.5
	local triX = arrowX + (arrowBoxW - triW) / 2
	local triY = py + (height - triH) / 2
	win:QueueDrawAtLayer(Globals.Layers.WidgetText, function()
		DrawHelpers.DrawArrow(triX, triY, triW, triH, state.open and "up" or "down", Globals.Colors.Text)
	end)

	-- Draw popup if open - use dedicated popup layer that's always on top
	if state.open then
		local popupLayer = Globals.POPUP_LAYER_BASE

		-- Popup background
		DrawManager.Enqueue(win.id, popupLayer, function()
			Common.SetColor(Globals.Colors.Window)
			Common.DrawFilledRect(
				popupBounds.x,
				popupBounds.y,
				popupBounds.x + popupBounds.w,
				popupBounds.y + popupBounds.h
			)
		end)

		-- Popup image
		DrawManager.Enqueue(win.id, popupLayer, function(tex, x0, y0, w, h)
			draw.Color(255, 255, 255, 255)
			draw.TexturedRect(tex, x0, y0, x0 + w, y0 + h)
		end, imageData.texture, popupBounds.x, popupBounds.y, imageData.width, imageData.height)

		-- Popup outline
		DrawManager.Enqueue(win.id, popupLayer, function()
			Common.SetColor(Globals.Colors.WindowBorder)
			Common.DrawOutlinedRect(
				popupBounds.x,
				popupBounds.y,
				popupBounds.x + popupBounds.w,
				popupBounds.y + popupBounds.h
			)
		end)

		-- Selection marker
		if state.selX and state.selY then
			local cx = popupBounds.x + state.selX
			local cy = popupBounds.y + state.selY
			DrawManager.Enqueue(win.id, popupLayer + 1, function()
				Common.SetColor(Globals.Colors.WindowBorder)
				draw.OutlinedCircle(cx, cy, 5, 16)
				draw.ColoredCircle(cx, cy, 4, 255, 255, 255, 150)
			end)
		end

		-- Alpha slider
		local sliderBounds =
			{ x = popupBounds.x, y = popupBounds.y + imageData.height, w = popupBounds.w, h = sliderHeight }
		DrawManager.Enqueue(win.id, popupLayer, function()
			Common.SetColor(Globals.Colors.Window)
			Common.DrawFilledRect(
				sliderBounds.x,
				sliderBounds.y,
				sliderBounds.x + sliderBounds.w,
				sliderBounds.y + sliderBounds.h
			)
			local filledW = (state.color[4] / 255) * sliderBounds.w
			Common.SetColor(Globals.Colors.ItemActive)
			Common.DrawFilledRect(
				sliderBounds.x,
				sliderBounds.y,
				sliderBounds.x + filledW,
				sliderBounds.y + sliderBounds.h
			)
			Common.SetColor(Globals.Colors.WindowBorder)
			Common.DrawOutlinedRect(
				sliderBounds.x,
				sliderBounds.y,
				sliderBounds.x + sliderBounds.w,
				sliderBounds.y + sliderBounds.h
			)
		end)

		-- Alpha slider text
		local alphaText = "Alpha: " .. tostring(state.color[4])
		DrawManager.Enqueue(win.id, popupLayer + 1, function()
			draw.SetFont(Globals.Style.Font)
			local textW, textH = draw.GetTextSize(alphaText)
			Common.SetColor(Globals.Colors.Text)
			Common.DrawText(
				sliderBounds.x + (sliderBounds.w - textW) / 2,
				sliderBounds.y + (sliderBounds.h - textH) / 2,
				alphaText
			)
		end)
	end

	return state.color
end

return ColorPicker
