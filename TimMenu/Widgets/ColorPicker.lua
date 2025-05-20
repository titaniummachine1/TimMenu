local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")
local Interaction = require("TimMenu.Interaction")
local Utils = require("TimMenu.Utils")
local DrawManager = require("TimMenu.DrawManager")
local DrawHelpers = require("TimMenu.DrawHelpers")
-- Use the preloaded interactive color picker image
local imageData = Globals.Images.ColorPicker.Interactive
local draw = draw

-- Helper: convert RGB (0-255) to HSV components (h in [0,1), s,v in [0,1])
local function rgbToHSV(r, g, b)
	r, g, b = r / 255, g / 255, b / 255
	local maxc = math.max(r, g, b)
	local minc = math.min(r, g, b)
	local v = maxc
	local d = maxc - minc
	local s = (maxc == 0) and 0 or d / maxc
	local h = 0
	if d ~= 0 then
		if maxc == r then
			h = (g - b) / d % 6
		elseif maxc == g then
			h = (b - r) / d + 2
		else
			h = (r - g) / d + 4
		end
		h = h / 6
	end
	return h, s, v
end

-- Helper: convert HSV (h in [0,1), s,v in [0,1]) to RGB (0-255)
local function hsvToRGB(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	i = i % 6
	local r, g, b
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
	else
		r, g, b = v, p, q
	end
	return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

--- Draw a color picker field and popup circle. Returns new color and whether it changed.
---@param win table
---@param label string
---@param initColor table {r,g,b,a}
---@return table newColor, boolean changed
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
	local boxSize = Globals.Style.ItemSize + (padding * 2)
	local arrowBoxW = boxSize
	local extraPadding = padding -- Additional padding before the arrow box
	local width = boxSize + padding + txtW + extraPadding + arrowBoxW
	local height = boxSize
	if win.cursorX > Globals.Defaults.WINDOW_CONTENT_PADDING then
		win.cursorX = win.cursorX + padding
	end
	local x, y = win:AddWidget(width, height)
	local absX, absY = win.X + x, win.Y + y

	-- LSTATEKEY
	-- Define a persistent state key separate from interaction key so state.open persists
	local stateKey = win.id .. ":ColorPicker:" .. label
	win._widgetCounter = (win._widgetCounter or 0) + 1
	local widgetKey = stateKey .. ":" .. win._widgetCounter
	-- Persistent state stored by stateKey, not widgetKey
	local state = Utils.GetState(win, stateKey, {
		open = false,
		hue = 0,
		sat = 0,
		initialized = false,
		color = { initColor[1], initColor[2], initColor[3], initColor[4] or 255 },
	})
	local changed = false

	-- Initialize hue/saturation from initial color
	if not state.initialized then
		local h, s = rgbToHSV(state.color[1], state.color[2], state.color[3])
		state.hue = h
		state.sat = s
		state.initialized = true
	end

	-- Field interaction
	local hovered, pressed, clicked =
		Interaction.Process(win, widgetKey, { x = absX, y = absY, w = width, h = height }, state.open)
	local sliderHeight = Globals.Style.ItemSize
	local popupHeight = imageData.height + padding + sliderHeight
	local popupBounds = { x = absX, y = absY + height, w = imageData.width, h = popupHeight }

	-- Toggle popup on field click
	if clicked and hovered and not state.open then
		state.open = true
		win._widgetBlockedRegions = { popupBounds }
		-- bring window to front
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
			and input.IsButtonPressed(MOUSE_LEFT)
		then
			local idx = (py * imageData.width + px) * 4 + 1
			local r = string.byte(imageData.data, idx)
			local g = string.byte(imageData.data, idx + 1)
			local b = string.byte(imageData.data, idx + 2)
			local a = string.byte(imageData.data, idx + 3)
			if a ~= 0 then
				state.color[1], state.color[2], state.color[3] = r, g, b
				state.selX, state.selY = px, py
				changed = true
			end
		end

		-- Alpha slider interaction
		local sliderBounds =
			{ x = popupBounds.x, y = popupBounds.y + imageData.height + padding, w = popupBounds.w, h = sliderHeight }
		local _, sPressed = Interaction.Process(win, widgetKey .. ":alpha", sliderBounds, state.open)
		if sPressed then
			local mx2, _ = table.unpack(input.GetMousePos())
			local newA = math.floor(((mx2 - sliderBounds.x) / sliderBounds.w) * 255)
			state.color[4] = math.max(0, math.min(255, newA))
			changed = true
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
	Common.QueueRect(win, Globals.Layers.WidgetBackground, px, py, px + mainW, py + height, bg)
	Common.QueueRect(
		win,
		Globals.Layers.WidgetBackground,
		px + mainW,
		py,
		px + width,
		py + height,
		Globals.Colors.ArrowBoxBg
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
	local inner = state.color
	Common.QueueRect(
		win,
		Globals.Layers.WidgetFill,
		px + padding,
		py + padding,
		px + boxSize - padding,
		py + boxSize - padding,
		inner
	)
	Common.QueueText(
		win,
		Globals.Layers.WidgetText,
		px + boxSize + padding,
		py + (height - txtH) * 0.5,
		label,
		Globals.Colors.Text
	)

	-- Use dropdown-style arrow sizing
	draw.SetFont(Globals.Style.Font) -- Ensure font for arrow char measurement
	local arrowCharW, arrowCharH = draw.GetTextSize("▼")
	local triW, triH = arrowCharW * 0.5, arrowCharH * 0.5
	local triX = px + mainW + (arrowBoxW - triW) / 2
	local triY = py + (height - triH) / 2
	win:QueueDrawAtLayer(Globals.Layers.WidgetText, function()
		DrawHelpers.DrawArrow(triX, triY, triW, triH, state.open and "up" or "down", Globals.Colors.Text)
	end)

	-- Draw popup only when open so it respects sector layer offsets
	if state.open then
		-- Always draw popup above all sector content using a high layer
		local popupLayer = Globals.Layers.Popup + Globals.LayersPerGroup * 100
		-- Popup background fill
		DrawManager.Enqueue(win.id, popupLayer, function()
			Common.SetColor(Globals.Colors.Window)
			Common.DrawFilledRect(
				popupBounds.x,
				popupBounds.y,
				popupBounds.x + imageData.width,
				popupBounds.y + imageData.height
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
				popupBounds.x + imageData.width,
				popupBounds.y + imageData.height
			)
		end)

		-- Draw selection marker
		if state.selX and state.selY then
			local cx = popupBounds.x + state.selX
			local cy = popupBounds.y + state.selY
			DrawManager.Enqueue(win.id, popupLayer + 1, function()
				Common.SetColor(Globals.Colors.WindowBorder)
				Common.DrawOutlinedRect(cx - 3, cy - 3, cx + 3, cy + 3)
				Common.SetColor({ 255, 255, 255, 150 })
				Common.DrawFilledRect(cx - 2, cy - 2, cx + 2, cy + 2)
			end)
		end

		-- Draw alpha slider
		local sliderBounds =
			{ x = popupBounds.x, y = popupBounds.y + imageData.height + padding, w = popupBounds.w, h = sliderHeight }
		DrawManager.Enqueue(win.id, popupLayer, function()
			-- Slider track background
			Common.SetColor(Globals.Colors.Item)
			Common.DrawFilledRect(
				sliderBounds.x,
				sliderBounds.y,
				sliderBounds.x + sliderBounds.w,
				sliderBounds.y + sliderBounds.h
			)
			-- Filled portion
			local filledW = (state.color[4] / 255) * sliderBounds.w
			Common.SetColor(Globals.Colors.ItemActive)
			Common.DrawFilledRect(
				sliderBounds.x,
				sliderBounds.y,
				sliderBounds.x + filledW,
				sliderBounds.y + sliderBounds.h
			)
			-- Slider outline
			Common.SetColor(Globals.Colors.WindowBorder)
			Common.DrawOutlinedRect(
				sliderBounds.x,
				sliderBounds.y,
				sliderBounds.x + sliderBounds.w,
				sliderBounds.y + sliderBounds.h
			)
		end)
	end

	return state.color, changed
end

return ColorPicker
