# TimMenu

[![Commit Activity](https://img.shields.io/github/commit-activity/m/titaniummachine1/TimMenu)](https://github.com/titaniummachine1/TimMenu/commits/main)
[![Release Date](https://img.shields.io/github/release-date/titaniummachine1/TimMenu)](https://github.com/titaniummachine1/TimMenu/releases/latest)
[![All Releases](https://img.shields.io/github/downloads/titaniummachine1/TimMenu/total)](https://github.com/titaniummachine1/TimMenu/releases)

## Download Latest

[![Download Latest](https://img.shields.io/badge/Download-Latest-blue?style=for-the-badge&logo=github)](https://github.com/titaniummachine1/TimMenu/releases/latest)

Terminator's Immediate-Mode Menu for Lmaobox

A GUI library for Lmaobox scripts, offering a convenient immediate-mode style API built on a retained-mode foundation. It's designed for light usage and rapid construction of in-game menus.


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

        sliderValue, changed = TimMenu.Slider("Value", sliderValue, 0, 100, 1)
        if changed then
            print("Slider:", sliderValue)
        end

        TimMenu.End()
    end
end

callbacks.Register("Draw", "ExampleDraw", OnDraw)
```

## API Reference

### Window Management

- Begin: `bool = TimMenu.Begin(title, [visible, [id]])`
- End: `TimMenu.End()`

### Layout

- NextLine: `TimMenu.NextLine([spacing])`
- Spacing: `TimMenu.Spacing(amount)`
- Separator: `TimMenu.Separator([label])`
- BeginSector: `TimMenu.BeginSector(label)`
- EndSector: `TimMenu.EndSector()`

### Basic Widgets

- Text: `TimMenu.Text(text)`
- Button: `clicked = TimMenu.Button(label [, selected])`
- Checkbox: `newState = TimMenu.Checkbox(label, state)`
- TextInput: `newText, changed = TimMenu.TextInput(label, text)`
- Slider: `newValue, changed = TimMenu.Slider(label, value, min, max, step)`
- Selector: `newIndex, changed = TimMenu.Selector(label, selectedIndex, options)`
- Dropdown: `newIndex, changed = TimMenu.Dropdown(label, selectedIndex, options)`
- Combo: `newIndex, changed = TimMenu.Combo(label, selectedIndex, options)`
- TabControl: `newIndex = TimMenu.TabControl(id, tabs, currentTabIndex)`

### Customization

All colors and styles can be tweaked via the `Globals` module:

```lua
TimMenu.Globals.Colors.Window = {40, 40, 40, 255}
TimMenu.Globals.Style.ItemPadding = 8
```

## Tips

- Use `BeginSector`/`EndSector` to group widgets in bordered panels.
- sectors can be easly stacked horizontaly and verticaly

## Sector Grouping

Use `TimMenu.BeginSector(label)` and `TimMenu.EndSector()` to enclose widgets in a shaded, bordered panel. Nested sectors will automatically lighten the background more as depth increases.

Example:

```lua
if TimMenu.Begin("Example Window") then
    -- Start a grouped panel
    TimMenu.BeginSector("Settings")
    -- Place widgets inside the sector
    local volume, changed = TimMenu.Slider("Volume", 50, 0, 100, 1)
    TimMenu.EndSector()

    TimMenu.End()
end
```

## Changelog

### Fixed Keybind Widget Lag

- Keybind widget now recalculates its display label immediately after a key press and dynamically computes its draw position inside the rendering callback, eliminating frame delay when dragging windows.

### Fixed TabControl Header Lag

- Header-mode tabs now calculate their offsets relative to the window's current position at draw time, preventing one-frame lag during window movement.

## License

MIT License. See [LICENSE](LICENSE) for details.
