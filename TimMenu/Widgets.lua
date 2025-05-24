-- Widget module aggregator
-- Provides centralized access to all widget types

local Widgets = {
	Button = require("TimMenu.Widgets.Button"),
	Checkbox = require("TimMenu.Widgets.Checkbox"),
	Slider = require("TimMenu.Widgets.Slider"),
	TextInput = require("TimMenu.Widgets.TextInput"),
	Dropdown = require("TimMenu.Widgets.Dropdown"),
	Combo = require("TimMenu.Widgets.Combo"),
	Selector = require("TimMenu.Widgets.Selector"),
	TabControl = require("TimMenu.Widgets.TabControl"),
	Keybind = require("TimMenu.Widgets.Keybind"),
	ColorPicker = require("TimMenu.Widgets.ColorPicker"),
	Tooltip = require("TimMenu.Widgets.Tooltip"),
	Image = require("TimMenu.Widgets.Image"),
}

return Widgets
