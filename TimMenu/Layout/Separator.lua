local Globals = require("TimMenu.Globals")
local Common = require("TimMenu.Common")

local LayoutSeparator = {}

-- The main separator function, to be called by TimMenu.Separator
function LayoutSeparator.Draw(win, label)
	assert(type(win) == "table", "Separator: win must be a table")
	assert(label == nil or type(label) == "string", "Separator: label must be a string or nil")
	local pad = Globals.Defaults.WINDOW_CONTENT_PADDING
	local vpad = Globals.Style.ItemPadding
	-- ensure on its own line
	if win.cursorX > pad then
		win:NextLine(0)
	end
	win:NextLine(vpad)
	local totalWidth = win.W - (pad * 2)
	if type(label) == "string" then
		draw.SetFont(Globals.Style.Font)
		local textWidth, textHeight = draw.GetTextSize(label)
		local x, y = win:AddWidget(totalWidth, textHeight)
		win:QueueDrawAtLayer(1, function()
			local absX, absY = win.X + x, win.Y + y
			local centerY = absY + math.floor(textHeight / 2)
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawLine(absX, centerY, absX + (totalWidth - textWidth) / 2 - Globals.Style.ItemPadding, centerY)
			draw.Color(table.unpack(Globals.Colors.Text))
			Common.DrawText(absX + (totalWidth - textWidth) / 2, absY, label)
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawLine(
				absX + (totalWidth + textWidth) / 2 + Globals.Style.ItemPadding,
				centerY,
				absX + totalWidth,
				centerY
			)
		end)
	else
		local x, y = win:AddWidget(totalWidth, 1)
		win:QueueDrawAtLayer(1, function()
			local absX, absY = win.X + x, win.Y + y
			draw.Color(table.unpack(Globals.Colors.WindowBorder))
			Common.DrawLine(absX, absY, absX + totalWidth, absY)
		end)
	end
	win:NextLine(vpad)
end

return LayoutSeparator
