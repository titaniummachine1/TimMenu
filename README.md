# TimMenu

Titanium Immediate-Mode Menu for Lmaobox

A lightweight, immediate-mode GUI library for Lmaobox scripts, allowing rapid construction of in-game menus with minimal boilerplate.

Showcase: https://github.com/user-attachments/assets/311ee265-7a12-4caa-a9ad-f793e5ada073

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
- `TimMenu.ShowDebug()`

### Layout

- `TimMenu.NextLine([spacing])`
- `TimMenu.SameLine([spacing])`
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

- Use `SameLine()` to place widgets horizontally.
- Use `BeginSector`/`EndSector` to group widgets in bordered panels.
- After dragging windows, widgets automatically snap to their new positions.

## License

MIT License. See [LICENSE](LICENSE) for details.
