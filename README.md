# TimMenu


[![Latest Release](https://img.shields.io/github/v/release/titaniummachine1/TimMenu?label=Download%20Latest)](https://github.com/titaniummachine1/TimMenu/releases/latest)

Titanium Immediate-Mode Menu for Lmaobox

A lightweight, immediate-mode GUI library for Lmaobox scripts, allowing rapid construction of in-game menus with minimal boilerplate.

https://github.com/user-attachments/assets/7b0481bd-3382-4f84-833e-2cb8094ed448

## Installation

1. Run the bundler:

   ```bat
   Bundle.bat
   ```

   This will produce `TimMenu.lua` in your workspace.

2. Copy `TimMenu.lua` to your Lmaobox scripts folder (e.g., `%localappdata%\Scripts`).

## Usage

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

- `bool = TimMenu.Begin(title, [visible, [id]])`
- `TimMenu.End()`

### Layout

- `TimMenu.NextLine([spacing])`
- `TimMenu.Spacing(amount)`

### Basic Widgets

- `TimMenu.Text(text)`
- `clicked = TimMenu.Button(label [, selected])`
- `newState = TimMenu.Checkbox(label, state)`
- `newText, changed = TimMenu.TextInput(label, text)`
- `newValue, changed = TimMenu.Slider(label, value, min, max, step)`
- `newIndex, changed = TimMenu.Selector(label, selectedIndex, options)`
- `newIndex, changed = TimMenu.Dropdown(label, selectedIndex, options)`
- `newIndex, changed = TimMenu.Combo(label, selectedIndex, options)`
- `newIndex = TimMenu.TabControl(id, tabs, currentTabIndex)`
- `TimMenu.Separator([label])`
- `TimMenu.BeginSector(label)` / `TimMenu.EndSector(label)`

### Customization

All colors and styles can be tweaked via the `Globals` module:

```lua
local Globals = require("TimMenu.Globals")
Globals.Colors.Window = {40, 40, 40, 255}
Globals.Style.ItemPadding = 8
```

## Tips

- Use `BeginSector`/`EndSector` to group widgets in bordered panels.
- After dragging windows, widgets automatically snap to their new positions.

## Changelog

### Fixed Keybind Widget Lag

- Keybind widget now recalculates its display label immediately after a key press and dynamically computes its draw position inside the rendering callback, eliminating frame delay when dragging windows.

### Fixed TabControl Header Lag

- Header-mode tabs now calculate their offsets relative to the window's current position at draw time, preventing one-frame lag during window movement.

## License

MIT License. See [LICENSE](LICENSE) for details.
