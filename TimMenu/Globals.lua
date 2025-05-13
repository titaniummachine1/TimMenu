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
	Font = draw.CreateFont("Verdana", 14, 700), -- Now Verdana Bold for general widget text
	FontBold = draw.CreateFont("Arial Black", 14, 510), -- Now Arial Black for TabControl labels
	ItemPadding = 7, -- Increased from 5 to 7 for potentially wider tab label font
	ItemMargin = 5,
	ItemSize = 10,
	EnableWindowBorder = true,
	FrameBorder = false,
	ButtonBorder = false,
	CheckboxBorder = false,
	SliderBorder = false,
	Border = false,
	Popup = false,
	Alignment = "left", -- or "center"
	Scale = 1.2, -- Scaling factor for UI elements (1 = 100%)
	TabBackground = true, -- Enable background fill for tabs; disable via this flag if needed
}

Globals.Defaults = {
	DEFAULT_X = 100,
	DEFAULT_Y = 100,
	DEFAULT_W = 300,
	DEFAULT_H = 200,
	SLIDER_WIDTH = 250, -- Default slider width from ImMenu
	TITLE_BAR_HEIGHT = 30,
	WINDOW_CONTENT_PADDING = 10,
	ITEM_SPACING = 8, -- Increased from 5 to 8 for better header tab spacing
	DebugHeaderX = 20,
	DebugHeaderY = 20,
	DebugLineSpacing = 20,
}

-- Scale UI elements based on Style.Scale
local scale = Globals.Style.Scale or 1
-- Recreate font with scaled size
-- Globals.Style.Font will now be Verdana Bold (previously FontBold)
Globals.Style.Font = draw.CreateFont("Verdana", math.ceil(14 * scale), 700)
-- Globals.Style.FontBold will now be Arial Black (previously Font)
Globals.Style.FontBold = draw.CreateFont("Arial Black", math.ceil(14 * scale), 510)

-- Scale style metrics
Globals.Style.ItemPadding = math.ceil(Globals.Style.ItemPadding * scale) -- This will apply scaling to the new base value
Globals.Style.ItemMargin = math.ceil(Globals.Style.ItemMargin * scale)
Globals.Style.ItemSize = math.ceil(Globals.Style.ItemSize * scale)
-- Scale default dimensions
Globals.Defaults.DEFAULT_W = math.ceil(Globals.Defaults.DEFAULT_W * scale)
Globals.Defaults.DEFAULT_H = math.ceil(Globals.Defaults.DEFAULT_H * scale)
Globals.Defaults.SLIDER_WIDTH = math.ceil(Globals.Defaults.SLIDER_WIDTH * scale)
Globals.Defaults.TITLE_BAR_HEIGHT = math.ceil(Globals.Defaults.TITLE_BAR_HEIGHT * scale)
Globals.Defaults.WINDOW_CONTENT_PADDING = math.ceil(Globals.Defaults.WINDOW_CONTENT_PADDING * scale)
Globals.Defaults.ITEM_SPACING = math.ceil(Globals.Defaults.ITEM_SPACING * scale) -- Will apply scaling to the new base value
Globals.Defaults.DebugHeaderX = math.ceil(Globals.Defaults.DebugHeaderX * scale)
Globals.Defaults.DebugHeaderY = math.ceil(Globals.Defaults.DebugHeaderY * scale)
Globals.Defaults.DebugLineSpacing = math.ceil(Globals.Defaults.DebugLineSpacing * scale)

return Globals
