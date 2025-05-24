local Common = require("TimMenu.Common")
local Globals = require("TimMenu.Globals")

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

return DrawHelpers
