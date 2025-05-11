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
	HighlightActive = { 240, 240, 240, 140 },
	WindowBorder = { 55, 100, 215, 255 },
	FrameBorder = { 0, 0, 0, 200 },
	Border = { 0, 0, 0, 200 },
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
	DEFAULT_X = 50,
	DEFAULT_Y = 150,
	DEFAULT_W = 100, -- ImMenu default window width
	DEFAULT_H = 100, -- ImMenu default window height
	SLIDER_WIDTH = 250, -- Default slider width from ImMenu
	TITLE_BAR_HEIGHT = 25,
	WINDOW_CONTENT_PADDING = 10, -- added for inner padding on all sides
}

return Globals
