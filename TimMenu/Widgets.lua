-- Widget module aggregator
-- Provides centralized access to all widget types
--
-- SIMPLIFIED API - All widgets now use single return values:
--   checked = Checkbox(win, "Enable Feature", checked)
--   value = Slider(win, "Volume", value, minValue, maxValue, stepValue)
--   selectedIndex = Dropdown(win, "Pick Item", selectedIndex, options)
--   selectedIndex = Selector(win, "Choose Option", selectedIndex, options)
--   selectedItems = Combo(win, "Multi Select", selectedItems, options)
--   selectedTab = TabControl(win, "Tabs", selectedTab, tabNames)
--   keyCode = Keybind(win, "Hotkey", keyCode)
--   color = ColorPicker(win, "Pick Color", color)
--   text = TextInput(win, "Enter text", text)
--   clicked = Button(win, "Click Me")  -- Returns boolean

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
