--[[ Test script to demonstrate the sector positioning fix ]]

local TimMenu = require("TimMenu")

local function TestSectorFix()
    if not TimMenu.Begin("Sector Position Test") then
        return
    end

    -- Test 1: Two sectors side by side (this was broken before the fix)
    TimMenu.BeginSector("Left Sector")
    TimMenu.Checkbox("Option 1", false)
    TimMenu.Checkbox("Option 2", true)
    TimMenu.EndSector(true) -- true = stay on same line

    TimMenu.BeginSector("Right Sector")
    TimMenu.Checkbox("Setting 1", false)
    TimMenu.Checkbox("Setting 2", true)
    TimMenu.EndSector() -- false = move to next line (default)

    -- Test 2: Three sectors in one row
    TimMenu.BeginSector("First")
    TimMenu.Checkbox("A", false)
    TimMenu.EndSector(true)

    TimMenu.BeginSector("Second")
    TimMenu.Checkbox("B", true)
    TimMenu.EndSector(true)

    TimMenu.BeginSector("Third")
    TimMenu.Checkbox("C", false)
    TimMenu.EndSector() -- Move to next line after third

    -- Test 3: Backwards compatibility - sectors without parameter work as before
    TimMenu.BeginSector("Standalone")
    TimMenu.Checkbox("Solo Option", false)
    TimMenu.EndSector() -- No parameter = old behavior (move to next line)

    TimMenu.End()
end

-- Register the test
callbacks.Register("Draw", "sector_test", TestSectorFix)

print("Sector positioning fix test loaded!")
print("Use TimMenu.EndSector(true) to keep sectors on same line")
print("Use TimMenu.EndSector() or TimMenu.EndSector(false) to move to next line")
