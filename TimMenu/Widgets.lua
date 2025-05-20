-- Widgets aggregator: delegate to individual widget modules
local Button = require("TimMenu.Widgets.Button")
local Checkbox = require("TimMenu.Widgets.Checkbox")
local Slider = require("TimMenu.Widgets.Slider")
local TextInput = require("TimMenu.Widgets.TextInput")
local Dropdown = require("TimMenu.Widgets.Dropdown")
local Combo = require("TimMenu.Widgets.Combo")
local Selector = require("TimMenu.Widgets.Selector")
local TabControl = require("TimMenu.Widgets.TabControl")
local Keybind = require("TimMenu.Widgets.Keybind")

return {
	Button = Button,
	Checkbox = Checkbox,
	Slider = Slider,
	TextInput = TextInput,
	Dropdown = Dropdown,
	Combo = Combo,
	Selector = Selector,
	TabControl = TabControl,
	Keybind = Keybind,
}
