local Utils = require("TimMenu.Utils")
local Globals = require("TimMenu.Globals")

--[[ Imported by: Widgets, Utils, others ]]
--

local Interaction = {}

-- Internal debouncing table shared by all widgets
local PressState = {}

----------------------------------------------------
-- Helper: point-in-bounds (small, local only)
----------------------------------------------------
local function inBounds(x, y, b)
	return x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h
end

----------------------------------------------------
-- Public: Z-aware hover check
----------------------------------------------------
function Interaction.IsHovered(win, bounds)
	local mX, mY = table.unpack(input.GetMousePos())
	if not inBounds(mX, mY, bounds) then
		return false
	end

	-- Block if covered by higher windows
	if Utils.IsPointBlocked(TimMenuGlobal.order, TimMenuGlobal.windows, mX, mY, win.id) then
		return false
	end

	-- Block if inside any widget-level exclusion region (e.g. dropdown pop-ups)
	if win._widgetBlockedRegions then
		for _, region in ipairs(win._widgetBlockedRegions) do
			if inBounds(mX, mY, region) then
				return false
			end
		end
	end

	return true
end

----------------------------------------------------
-- Public: one-shot click that respects hover/open state
----------------------------------------------------
function Interaction.ConsumeWidgetClick(win, hovered, isOpen)
	-- Only consume if the widget is interactable from here
	if not hovered and not isOpen then
		return false
	end
	return Utils.ConsumeClick()
end

----------------------------------------------------
-- Public: close a popup if user clicks outside both field & popup
----------------------------------------------------
function Interaction.ClosePopupOnOutsideClick(entry, mouseX, mouseY, fieldBounds, popupBounds, win)
	if not entry.open then
		return
	end

	-- If click is outside both field & popup, close and clear block regions
	if not inBounds(mouseX, mouseY, fieldBounds) and not inBounds(mouseX, mouseY, popupBounds) then
		entry.open = false
		win._widgetBlockedRegions = {}
	end
end

----------------------------------------------------
-- Optional helpers for manual debouncing (rarely needed now)
----------------------------------------------------
function Interaction.IsPressed(key)
	if input.IsButtonPressed(MOUSE_LEFT) and not PressState[key] then
		PressState[key] = true
		return true
	end
	return false
end

function Interaction.Release(key)
	PressState[key] = false
end

Interaction._PressState = PressState -- expose for debugging

return Interaction
