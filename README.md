# TimMenu

[![Commit Activity](https://img.shields.io/github/commit-activity/m/titaniummachine1/TimMenu)](https://github.com/titaniummachine1/TimMenu/commits/main)
[![Release Date](https://img.shields.io/github/release-date/titaniummachine1/TimMenu)](https://github.com/titaniummachine1/TimMenu/releases/latest)
[![All Releases](https://img.shields.io/github/downloads/titaniummachine1/TimMenu/total)](https://github.com/titaniummachine1/TimMenu/releases)

## Download Latest

[![Download Latest](https://img.shields.io/github/downloads/titaniummachine1/TimMenu/total.svg?style=for-the-badge&logo=download&label=Download%20Latest)](https://github.com/titaniummachine1/TimMenu/releases/download/v1.8.4/TimMenu.lua)

Terminator's Immediate-Mode Menu for Lmaobox

A GUI library for Lmaobox scripts, offering a convenient immediate-mode style API built on a retained-mode foundation. It's designed for light usage and rapid construction of in-game menus.

![image](https://github.com/user-attachments/assets/bf428a3c-02c8-465b-b1ce-3a8f1246f50f)

https://github.com/user-attachments/assets/7498dcd1-8b20-4347-bf32-6c1419b679c2

## Installation

To install, download the latest release using the badge at the top of this page, then:

1. Unzip or extract the downloaded package.
2. Copy `TimMenu.lua` into your Lmaobox scripts folder (e.g., `%localappdata%\Scripts`).

## Usage

Building a menu with TimMenu is like writing a document: widgets are added from left to right, and `TimMenu.NextLine()` moves the cursor to the beginning of the next line, ready for more widgets.

```lua
local TimMenu = require("TimMenu")

local isChecked = false
local sliderValue = 50

local function OnDraw()
    if TimMenu.Begin("Example Window") then
        TimMenu.Text("Hello, Lmaobox!")

        isChecked = TimMenu.Checkbox("Enable Feature", isChecked)
        TimMenu.NextLine()

        if TimMenu.Button("Click Me") then
            print("Button clicked!")
        end
        TimMenu.NextLine()

        sliderValue = TimMenu.Slider("Value", sliderValue, 0, 100, 1)
        print("Current slider value:", sliderValue)

    end
end

callbacks.Register("Draw", "ExampleDraw", OnDraw)
```

## API Reference

### Window Management

- Begin: `bool = TimMenu.Begin(title, [visible, [id]])`

### Layout

- NextLine: `TimMenu.NextLine([spacing])`
- Spacing: `TimMenu.Spacing(amount)`
- Separator: `TimMenu.Separator([label])`
- BeginSector: `TimMenu.BeginSector(label)`
- EndSector: `TimMenu.EndSector()`

### Basic Widgets

**All widgets now use simplified single-return APIs:**

- Text: `TimMenu.Text(text)`
- Button: `clicked = TimMenu.Button(label)`
- Checkbox: `checked = TimMenu.Checkbox(label, checked)`
- TextInput: `text = TimMenu.TextInput(label, text)`
- Slider: `value = TimMenu.Slider(label, value, min, max, step)`
- Selector: `selectedIndex = TimMenu.Selector(label, selectedIndex, options)`
- Dropdown: `selectedIndex = TimMenu.Dropdown(label, selectedIndex, options)`
- Combo: `selectedItems = TimMenu.Combo(label, selectedItems, options)`
- TabControl: `selectedTab = TimMenu.TabControl(id, tabs, selectedTab)`
- Keybind: `keyCode = TimMenu.Keybind(label, keyCode)`
- ColorPicker: `color = TimMenu.ColorPicker(label, color)`

### Advanced Widgets

- Image: `hovered, pressed, clicked = TimMenu.Image(texture, width, height, [raw_data])`
- Tooltip: `TimMenu.Tooltip(text)` - Shows tooltip for the last widget

### Customization

All colors and styles can be tweaked via the `Globals` module:

```lua
TimMenu.Globals.Colors.Window = {40, 40, 40, 255}
TimMenu.Globals.Style.ItemPadding = 8
```

## Widget Usage Examples

### Simple State Management

```lua
-- Each widget modifies and returns its value directly
local volume = 50
local enabled = true
local selectedOption = 1
local options = {"Low", "Medium", "High"}

local function OnDraw()
    if TimMenu.Begin("Settings") then
        enabled = TimMenu.Checkbox("Enable Audio", enabled)

        if enabled then
            volume = TimMenu.Slider("Volume", volume, 0, 100, 5)
            selectedOption = TimMenu.Dropdown("Quality", selectedOption, options)
        end
    end
end
```

### Color Picker Example

```lua
local backgroundColor = {30, 30, 30, 255}  -- RGBA

local function OnDraw()
    if TimMenu.Begin("Color Settings") then
        backgroundColor = TimMenu.ColorPicker("Background Color", backgroundColor)
        TimMenu.Text(string.format("RGB: %d, %d, %d, %d",
            backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4]))
    end
end
```

### Multi-Selection with Combo

```lua
local features = {"Feature A", "Feature B", "Feature C"}
local enabledFeatures = {true, false, true}  -- Which features are enabled

local function OnDraw()
    if TimMenu.Begin("Feature Selection") then
        enabledFeatures = TimMenu.Combo("Enabled Features", enabledFeatures, features)

        -- Show which features are enabled
        for i, feature in ipairs(features) do
            if enabledFeatures[i] then
                TimMenu.Text("✓ " .. feature .. " is enabled")
            end
        end
    end
end
```

## Tips

- Use `BeginSector`/`EndSector` to group widgets in bordered panels.
- Sectors can be easily stacked horizontally and vertically
- All widgets return their current value - no need to track "changed" flags
- Values are automatically maintained between frames by the widget system

## Sector Grouping

Use `TimMenu.BeginSector(label)` and `TimMenu.EndSector()` to enclose widgets in a shaded, bordered panel. Nested sectors will automatically lighten the background more as depth increases.

Example:

```lua
if TimMenu.Begin("Example Window") then
    -- Start a grouped panel
    TimMenu.BeginSector("Settings")
    -- Place widgets inside the sector
    local volume = TimMenu.Slider("Volume", 50, 0, 100, 1)
    TimMenu.EndSector()
end
```

## Changelog

### Simplified Widget APIs (Latest)

- **BREAKING CHANGE**: All widgets now return single values instead of value + changed pairs
- Simplified API: `value = Widget("Label", value)` instead of `value, changed = Widget("Label", value)`
- Removed confusing "changed" flags - just use the returned values directly
- Updated all example code to use the new simplified patterns
- Much cleaner and more intuitive widget usage

### Fixed Keybind Widget Lag

- Keybind widget now recalculates its display label immediately after a key press and dynamically computes its draw position inside the rendering callback, eliminating frame delay when dragging windows.

### Fixed TabControl Header Lag

- Header-mode tabs now calculate their offsets relative to the window's current position at draw time, preventing one-frame lag during window movement.

## License

MIT License. See [LICENSE](LICENSE) for details.
