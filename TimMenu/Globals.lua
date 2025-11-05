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
	SectorBackground = { 30, 30, 30, 255 },
	Border = { 0, 0, 0, 200 },
	TabSelectedUnderline = { 255, 255, 255, 255 },
	WidgetOutline = { 100, 100, 100, 77 },
	ArrowBoxBg = { 55, 100, 215, 255 },
	DropdownSelected = { 90, 90, 90, 255 },
	DropdownSelectedHover = { 110, 110, 110, 255 },
}

-- Style settings
Globals.Style = {
	FontName = "Verdana",
	FontSize = 14,
	FontWeight = 700,
	FontBoldName = "Arial Black",
	FontBoldSize = 17,
	FontBoldWeight = 400,
	ItemPadding = 7,
	ItemMargin = 5,
	ItemSpacingX = 8,
	ItemSpacingY = 8,
	ItemSize = 10,
	EnableWindowBorder = true,
	FrameBorder = false,
	ButtonBorder = false,
	CheckboxBorder = false,
	SliderBorder = false,
	Border = false,
	Popup = false,
	Alignment = "left",
	Scale = 1.2,
	TabBackground = true,
}

Globals.Defaults = {
	DEFAULT_X = 100,
	DEFAULT_Y = 100,
	DEFAULT_W = 300,
	DEFAULT_H = 0,
	SLIDER_WIDTH = 250,
	TITLE_BAR_HEIGHT = 30,
	WINDOW_CONTENT_PADDING = 8,
	ITEM_SPACING = 8,
	DebugHeaderX = 20,
	DebugHeaderY = 20,
	DebugLineSpacing = 8,
}

-- Font management
local fontCache = {}
local function GetOrCreateFont(name, size, weight)
	local key = name .. ":" .. size .. ":" .. weight
	if not fontCache[key] then
		fontCache[key] = draw.CreateFont(name, size, weight)
	end
	return fontCache[key]
end

local function SetupFonts()
	local scale = Globals.Style.Scale or 1
	local fSize = math.ceil(Globals.Style.FontSize * scale)
	local bSize = math.ceil(Globals.Style.FontBoldSize * scale)
	Globals.Style.Font = GetOrCreateFont(Globals.Style.FontName, fSize, Globals.Style.FontWeight)
	Globals.Style.FontBold = GetOrCreateFont(Globals.Style.FontBoldName, bSize, Globals.Style.FontBoldWeight)
end
SetupFonts()
Globals.ReloadFonts = SetupFonts

-- Preserve default font settings for quick reset
Globals.DefaultFontSettings = {
	FontName = Globals.Style.FontName,
	FontSize = Globals.Style.FontSize,
	FontWeight = Globals.Style.FontWeight,
	FontBoldName = Globals.Style.FontBoldName,
	FontBoldSize = Globals.Style.FontBoldSize,
	FontBoldWeight = Globals.Style.FontBoldWeight,
}

-- Scale style metrics
local scale = Globals.Style.Scale or 1
Globals.Style.ItemPadding = math.ceil(Globals.Style.ItemPadding * scale)
Globals.Style.ItemMargin = math.ceil(Globals.Style.ItemMargin * scale)
Globals.Style.ItemSpacingX = math.ceil((Globals.Style.ItemSpacingX or Globals.Defaults.ITEM_SPACING) * scale)
Globals.Style.ItemSpacingY = math.ceil((Globals.Style.ItemSpacingY or Globals.Defaults.WINDOW_CONTENT_PADDING) * scale)
Globals.Style.ItemSize = math.ceil(Globals.Style.ItemSize * scale)

-- Scale default dimensions
Globals.Defaults.DEFAULT_W = math.ceil(Globals.Defaults.DEFAULT_W * scale)
Globals.Defaults.DEFAULT_H = math.ceil(Globals.Defaults.DEFAULT_H * scale)
Globals.Defaults.SLIDER_WIDTH = math.ceil(Globals.Defaults.SLIDER_WIDTH * scale)
Globals.Defaults.TITLE_BAR_HEIGHT = math.ceil(Globals.Defaults.TITLE_BAR_HEIGHT * scale)
Globals.Defaults.WINDOW_CONTENT_PADDING = math.ceil(Globals.Defaults.WINDOW_CONTENT_PADDING * scale)
Globals.Defaults.ITEM_SPACING = Globals.Style.ItemSpacingX
Globals.Defaults.DebugHeaderX = math.ceil(Globals.Defaults.DebugHeaderX * scale)
Globals.Defaults.DebugHeaderY = math.ceil(Globals.Defaults.DebugHeaderY * scale)
Globals.Defaults.DebugLineSpacing = math.ceil(Globals.Defaults.DebugLineSpacing * scale)

-- Draw Layers Enumeration
Globals.Layers = {
	WindowBackground = 0,
	TitleBar = 1,
	WidgetBackground = 2,
	WidgetFill = 3,
	WidgetOutline = 4,
	WidgetText = 5,
	Popup = 6,
}

Globals.LayersPerGroup = 10

-- Popup layer that's always on top (above all sectors)
Globals.POPUP_LAYER_BASE = 1000

-- Preload interactive widget images
local ImgDecoder = require("TimMenu.images.imageDecoder")
Globals.Images = Globals.Images or {}
Globals.Images.ColorPicker = { Interactive = ImgDecoder }

return Globals
