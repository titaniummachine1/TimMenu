local Globals = {}

-- Color definitions
Globals.Colors = {
	Title = { 55, 100, 215, 255 },
	Text = { 255, 255, 255, 255 },
	Window = { 30, 30, 30, 255 },
	Item = { 50, 50, 50, 255 },
	ItemHover = { 60, 60, 60, 255 },
	ItemActive = { 70, 70, 70, 255 },
	Highlight = { 180, 180, 180, 100 },
	HighlightActive = { 240, 240, 200, 140 },
	WindowBorder = { 55, 100, 215, 255 },
	FrameBorder = { 0, 0, 0, 200 },
	SectorBackground = { 20, 20, 20, 255 },
	Border = { 0, 0, 0, 200 },
	TabSelectedUnderline = { 255, 255, 255, 255 }, -- Default to white, adjust as needed
	WidgetOutline = { 100, 100, 100, 77 }, -- Based on WindowBorder with custom alpha
	ArrowBoxBg = { 55, 100, 215, 255 }, -- Background for the dropdown/combo arrow box
}

-- Style settings
Globals.Style = {
	Font = draw.CreateFont("Verdana", 14, 510), -- "verdana.ttf",
	ItemPadding = 5,
	ItemMargin = 5,
	FramePadding = 5,
	ItemSize = 10,
	WindowBorder = true,
	FrameBorder = false,
	ButtonBorder = false,
	CheckboxBorder = false,
	SliderBorder = false,
	Border = false,
	Popup = false,
	Alignment = "left", -- or "center"
}

Globals.Defaults = {
	DEFAULT_X = 100,
	DEFAULT_Y = 100,
	DEFAULT_W = 300,
	DEFAULT_H = 200,
	SLIDER_WIDTH = 250, -- Default slider width from ImMenu
	TITLE_BAR_HEIGHT = 30,
	WINDOW_CONTENT_PADDING = 10,
	ITEM_SPACING = 5, -- Spacing between items on the same line
}

return Globals
