# TimMenu

[![Commit Activity](https://img.shields.io/github/commit-activity/m/titaniummachine1/TimMenu)](https://github.com/titaniummachine1/TimMenu/commits/main)
[![Release Date](https://img.shields.io/github/release-date/titaniummachine1/TimMenu)](https://github.com/titaniummachine1/TimMenu/releases/latest)
[![All Releases](https://img.shields.io/github/downloads/titaniummachine1/TimMenu/total)](https://github.com/titaniummachine1/TimMenu/releases)

## Download Latest

[![Download Latest](https://img.shields.io/github/downloads/titaniummachine1/TimMenu/total.svg?style=for-the-badge&logo=download&label=Download%20Latest)](https://github.com/titaniummachine1/TimMenu/archive/refs/tags/v1.8.8.zip)

Terminator's Immediate-Mode Menu for Lmaobox

A GUI library for Lmaobox scripts, offering a convenient immediate-mode style API built on a retained-mode foundation. It's designed for light usage and rapid construction of in-game menus.

[https://github.com/user-attachments/assets/7498dcd1-8b20-4347-bf32-6c1419b679c2](https://github.com/user-attachments/assets/7498dcd1-8b20-4347-bf32-6c1419b679c2)



## Installation

To install, download the latest release using the badge at the top of this page, then:

1. Unzip or extract the downloaded package.
2. Copy `TimMenu.lua` into your Lmaobox scripts folder (e.g., `%localappdata%\Scripts`).

## Standalone API Guide

TimMenu is now a **fully standalone** library. It does not require LNXlib or other external dependencies.

### Core Concepts

- **Immediate Mode**: You define the UI every frame. If you stop calling a widget function, it disappears.
- **Layout**: Widgets are placed left-to-right. Use `NextLine()` to move down.
- **Volume Claim**: The menu handles "Hit Testing" by treating the window and its popups as a single volume. If a dropdown sticks out, it still belongs to that window, preventing clicks from falling through to background elements.

---

## API Reference

### Window Management

- **Begin**: `bool = TimMenu.Begin(title, [visibleOrOptions, [idOrOptions, [options]]])`
- Starts a new window context. Returns true if the window is expanded.

### Visibility Behavior

- By default, `TimMenu.Begin("My Window")` follows `gui.IsMenuOpen()`.
- Use `ShowAlways = true` to keep a menu visible even when the Lmaobox menu is closed.
- `LboxIndependent = true` is still supported as a compatibility alias.

```lua
if TimMenu.Begin("Visible With Lmaobox") then
    TimMenu.Text("This window hides when the Lmaobox menu is closed.")
end

if TimMenu.Begin("Always Visible", { ShowAlways = true }) then
    TimMenu.Text("This window ignores gui.IsMenuOpen().")
end
```

### Layout Controls

| Function                  | Usage                           | Description                                     |
| ------------------------- | ------------------------------- | ----------------------------------------------- |
| **`NextLine([spacing])`** | `TimMenu.NextLine(5)`           | Moves the cursor to the next row.               |
| **`Spacing(amount)`**     | `TimMenu.Spacing(10)`           | Adds horizontal or vertical blank space.        |
| **`Separator([label])`**  | `TimMenu.Separator("Settings")` | Draws a horizontal line with an optional label. |
| **`BeginSector(label)`**  | `TimMenu.BeginSector("Main")`   | Starts a bordered group/panel.                  |
| **`EndSector()`**         | `TimMenu.EndSector()`           | Closes the current group/panel.                 |

### Basic Widgets

**All widgets use simplified single-return APIs:**

- **Text**: `TimMenu.Text(text)`
- **Button**: `clicked = TimMenu.Button(label)`
- **Checkbox**: `checked = TimMenu.Checkbox(label, checked)`
- **TextInput**: `text = TimMenu.TextInput(label, text)`
- **Slider**: `value = TimMenu.Slider(label, value, min, max, step)`
- **Selector**: `selectedIndex = TimMenu.Selector(label, index, options)`
- **Dropdown**: `selectedIndex = TimMenu.Dropdown(label, index, options)`
- **Combo**: `selectedItems = TimMenu.Combo(label, selectedTable, options)`
- **TabControl**: `selectedTab = TimMenu.TabControl(id, tabs, selectedTab)`
- **Keybind**: `keyCode = TimMenu.Keybind(label, keyCode)`
- **ColorPicker**: `color = TimMenu.ColorPicker(label, color)`

### Customization

```lua
-- Global style tweaks via the Globals module
TimMenu.Globals.Colors.Window = {40, 40, 40, 255}
TimMenu.Globals.Style.ItemPadding = 8

```

---

## Usage Examples

### Simple Window Logic

```lua
local TimMenu = require("TimMenu")

local isChecked = false
local sliderValue = 50
local windowOptions = {
    ShowAlways = false,
}

local function OnDraw()
    if TimMenu.Begin("Example Window", windowOptions) then
        isChecked = TimMenu.Checkbox("Enable Feature", isChecked)
        TimMenu.NextLine()

        if TimMenu.Button("Reset Value") then
            sliderValue = 50
        end
        TimMenu.NextLine()

        sliderValue = TimMenu.Slider("Value", sliderValue, 0, 100, 1)
    end
end

callbacks.Register("Draw", "ExampleDraw", OnDraw)

```

### Recent Changes In v1.8.8

- New windows now try multiple random spawn positions and choose the least-overlapping candidate.
- Spawn placement stays inside screen bounds when screen size is available.
- Ties in spawn placement prefer positions closer to the top-left of the screen.
- Menu visibility now follows the Lmaobox menu by default, with `ShowAlways` available as an override.

### Grouping with Sectors

```lua
if TimMenu.Begin("Settings") then
    TimMenu.BeginSector("Audio")
        local vol = TimMenu.Slider("Volume", 50, 0, 100, 1)
    TimMenu.EndSector()
end

```

## Tips

- Sectors can be nested; backgrounds lighten automatically as depth increases.
- All widgets return their current value - no need to track "changed" flags manually.
- The volume hit-testing ensures that popups sticking out of windows correctly capture focus.

## License

MIT License. See [LICENSE](https://www.google.com/search?q=LICENSE) for details.
