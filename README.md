# TimMenu

[![Commit Activity](https://img.shields.io/github/commit-activity/m/titaniummachine1/TimMenu)](https://github.com/titaniummachine1/TimMenu/commits/main)
[![Release Date](https://img.shields.io/github/release-date/titaniummachine1/TimMenu)](https://github.com/titaniummachine1/TimMenu/releases/latest)
[![All Releases](https://img.shields.io/github/downloads/titaniummachine1/TimMenu/total)](https://github.com/titaniummachine1/TimMenu/releases)

## Download Latest

[![Download Latest](https://img.shields.io/badge/Download-Latest-blue?style=for-the-badge&logo=github)](https://github.com/titaniummachine1/TimMenu/releases/latest)

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
    TimMenu.End() -- Always call End() to clean up
end

callbacks.Register("Draw", "ExampleDraw", OnDraw)
```

## API Reference

### Window Management

- Begin: `bool = TimMenu.Begin(title, [visible, [id]])`
- BeginSafe: `bool = TimMenu.BeginSafe(title, [visible, [id]])` - Safe version with error handling
- End: `TimMenu.End()` - Always call to clean up window state
- EndSafe: `TimMenu.EndSafe()` - Safe version with error handling

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
    TimMenu.End() -- Always call End() to clean up
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
    TimMenu.End() -- Always call End() to clean up
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
    TimMenu.End() -- Always call End() to clean up
end
```

## Recommended Safe Usage Pattern

For robust menu creation, use the safe versions of Begin/End with proper error handling:

```lua
local TimMenu = require("TimMenu")

local function CreateSafeMenu()
    if TimMenu.BeginSafe("My Safe Menu") then
        -- Your widgets here
        local value = TimMenu.Slider("Test Slider", 50, 0, 100, 1)
        if TimMenu.Button("Test Button") then
            print("Button clicked!")
        end
    end
    TimMenu.EndSafe() -- Always called, even if there are errors
end

callbacks.Register("Draw", "SafeMenu", CreateSafeMenu)
```

## Error Detection and Debugging

TimMenu now includes comprehensive assertions and error checking to help debug issues:

### Assertion Coverage

- **Parameter validation** - All functions validate input parameters with detailed error messages
- **Window state validation** - Ensures windows are in valid states before operations
- **Layout validation** - Catches layout issues like infinite expansion, invalid spacing
- **Widget usage validation** - Ensures widgets are only called within Begin/End blocks
- **Dimension validation** - Prevents windows from growing beyond reasonable limits (5000px threshold)
- **Position validation** - Detects invalid window positions that could cause issues

### Common Error Messages

When assertions fail, you'll see detailed error messages like:
```
[TimMenu] Begin: Parameter 'title' cannot be empty string
[TimMenu] AddWidget: Window dimensions too large W=6000, H=3000 (possible infinite expansion)
[TimMenu] NextLine: Must be called between TimMenu.Begin() and TimMenu.End()
[TimMenu] Slider: min (50) must be less than max (25)
[TimMenu] Dropdown: options table cannot be empty
```

### Debugging Tips

- **Enable assertions** by running in debug mode - they help catch issues early
- **Check error messages** carefully - they tell you exactly what went wrong and where
- **Use BeginSafe/EndSafe** for production code to handle assertion failures gracefully
- **Monitor window dimensions** - if windows grow beyond 5000px, there's likely an infinite expansion bug

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
TimMenu.End() -- Always call End() to clean up
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

### Added Comprehensive Assertions and Error Detection

- **Complete assertion coverage** - Added parameter validation, state checks, and error detection throughout the codebase
- **Detailed error messages** - All assertion failures provide specific information about what went wrong and where
- **Window dimension limits** - Added 5000px threshold to catch infinite expansion issues early
- **Layout validation** - Added checks for invalid spacing, cursor positions, and widget placement
- **Widget usage validation** - Ensures all widgets are called within proper Begin/End blocks
- **Parameter type checking** - Validates all function parameters with descriptive error messages
- **Safe wrapper functions** - BeginSafe() and EndSafe() provide error handling for production use
- **Debugging documentation** - Added comprehensive debugging guide with common error patterns

## License

MIT License. See [LICENSE](LICENSE) for details.
